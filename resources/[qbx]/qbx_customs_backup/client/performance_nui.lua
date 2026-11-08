
local VehicleClass = require 'client.enums.VehicleClass'
local config = require 'config.client'
local sharedConfig = require 'config.shared'

local originalMods = {}
local originalTurbo = false
local options = {}
local active = false

local function priceLabel(price)
    if type(price) ~= 'table' then
        return ('%s%s'):format(config.currency, price or 0)
    end

    local copy = table.clone(price)
    table.remove(copy, 1)

    for i = 1, #copy do
        copy[i] = ('%d: %s%s'):format(i, config.currency, copy[i])
    end

    return table.concat(copy, ' | ')
end

local function restoreAll()
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    for modId, originalIndex in pairs(originalMods) do
        SetVehicleMod(vehicle, modId, originalIndex, false)
    end

    ToggleVehicleMod(vehicle, 18, originalTurbo)
end

local function buildOptions()
    options = {}
    originalMods = {}

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return options
    end

    for _, mod in ipairs(config.mods) do
        local modCount = GetNumVehicleMods(vehicle, mod.id)

        if mod.category ~= 'performance'
            or mod.enabled == false
            or modCount == 0
        then
            goto continue
        end

        local values = {
            locale('menus.general.stock')
        }

        for i = -1, modCount - 1 do
            values[i + 2] = GetModLabel(vehicle, mod.id, i)
        end

        local currentMod = GetVehicleMod(vehicle, mod.id)
        originalMods[mod.id] = currentMod

        options[#options + 1] = {
            id = mod.id,
            label = mod.label,
            description = priceLabel(sharedConfig.prices[mod.id]),
            values = values,
            defaultIndex = currentMod + 2
        }

        ::continue::
    end

    originalTurbo = IsToggleModOn(vehicle, 18)

    if GetVehicleClass(vehicle) ~= VehicleClass.Cycles then
        options[#options + 1] = {
            id = 18,
            label = locale('menus.performance.turbo'),
            description = priceLabel(sharedConfig.prices[18]),
            values = {
                locale('menus.general.disabled'),
                locale('menus.general.enabled')
            },
            defaultIndex = originalTurbo and 2 or 1
        }
    end

    table.sort(options, function(a, b)
        return a.label < b.label
    end)

    return options
end

local function findOption(modId)
    for _, option in ipairs(options) do
        if option.id == modId then
            return option
        end
    end
end

local function applyOption(modId, index)
    local option = findOption(modId)

    if not option or not index or not option.values[index] then
        return false
    end

    if modId == 18 then
        ToggleVehicleMod(vehicle, 18, index == 2)
    else
        SetVehicleMod(vehicle, modId, index - 2, false)
    end

    return true
end

local function preview(modId, index)
    if not active then return false end

    modId = tonumber(modId)
    index = tonumber(index)

    if not modId or not index then return false end

    restoreAll()

    return applyOption(modId, index)
end

local function install(modId, index)
    if not active then return false end

    modId = tonumber(modId)
    index = tonumber(index)

    if not modId or not index then return false end

    local option = findOption(modId)

    if not option or not option.values[index] then
        return false
    end

    -- Kembalikan semua preview sebelum menghitung dan memasang upgrade.
    restoreAll()

    local duplicate
    local description

    if modId == 18 then
        local selectedTurbo = index == 2
        duplicate = originalTurbo == selectedTurbo

        description = ('%s %s'):format(
            locale('menus.performance.turbo'),
            selectedTurbo
                and string.lower(locale('menus.general.enabled'))
                or string.lower(locale('menus.general.disabled'))
        )
    else
        local selectedMod = index - 2
        duplicate = originalMods[modId] == selectedMod

        description = ('%s installed'):format(option.values[index])
    end

    -- Gunakan fungsi pembayaran asli agar validasi server tetap berjalan.
    local success = InstallMod(
        duplicate,
        modId,
        {
            description = description
        },
        index
    )

    if not success then
        restoreAll()
        return false
    end

    -- Upgrade berhasil. Kondisi kendaraan sekarang menjadi kondisi asli baru.
    buildOptions()

    SendNUIMessage({
        action = 'updatePerformance',
        options = options
    })

    return true
end

local function open()
    active = true

    local currentOptions = buildOptions()

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'performance',
        options = currentOptions
    })
end

local function close()
    if active then
        restoreAll()
    end

    active = false
end

local function back()
    close()
end

return {
    open = open,
    close = close,
    back = back,
    preview = preview,
    install = install
}
