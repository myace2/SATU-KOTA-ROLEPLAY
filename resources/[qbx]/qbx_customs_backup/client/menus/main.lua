
mainLastIndex = 1
vehicle = 0
mainMenuId = 'customs-main'

local inMenu = false

local dragcam = require 'client.dragcam'
local startDragCam = dragcam.startDragCam
local stopDragCam = dragcam.stopDragCam

local performanceNui = require 'client.performance_nui'

openedWithExports = false

local function getCategories()
    local categories = {}

    if GetVehicleBodyHealth(vehicle) < 1000.0 then
        categories[#categories + 1] = 'repair'
        return categories
    end

    categories[#categories + 1] = 'performance'
    categories[#categories + 1] = 'parts'
    categories[#categories + 1] = 'colors'

    if DoesExtraExist(vehicle, 1) then
        categories[#categories + 1] = 'extras'
    end

    return categories
end

local function disableControls()
    inMenu = true

    CreateThread(function()
        while inMenu do
            Wait(0)

            DisableControlAction(0, 71, true)
            DisableControlAction(0, 72, true)

            for i = 81, 85 do
                DisableControlAction(0, i, true)
            end

            DisableControlAction(0, 106, true)
        end
    end)
end

-- Fungsi ini dipanggil ketika submenu ox_lib ditutup.
function showCustomsMainNui()
    if not inMenu then return end

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        categories = getCategories()
    })
end

local function closeCustomsNui()
    if not inMenu then return end

    performanceNui.close()

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'close'
    })

    inMenu = false

    stopDragCam()

    if not openedWithExports then
        lib.showTextUI(locale('textUI.tune'), {
            icon = 'fa-solid fa-car',
            position = 'left-center'
        })
    end

    TriggerServerEvent('qbx_customs:server:saveVehicleProps')
end

local function repair()
    local success = lib.callback.await(
        'qbx_customs:server:repair',
        false,
        GetVehicleBodyHealth(vehicle)
    )

    if success then
        exports.qbx_core:Notify(
            locale('notifications.success.repaired'),
            'success'
        )

        qbx.playAudio({
            audioName = 'PICK_UP',
            audioRef = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
        })

        local fuelLevel = GetVehicleFuelLevel(vehicle)

        SetVehicleFixed(vehicle)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleFuelLevel(vehicle, fuelLevel)
    else
        exports.qbx_core:Notify(
            locale('notifications.error.money'),
            'error'
        )
    end

    showCustomsMainNui()
end

local menuPaths = {
    parts = 'client.menus.parts',
    colors = 'client.menus.colors',
    extras = 'client.menus.extras'
}

RegisterNUICallback('close', function(_, cb)
    closeCustomsNui()
    cb({ ok = true })
end)

RegisterNUICallback('selectCategory', function(data, cb)
    local category = data and data.category

    if not category then
        cb({ ok = false })
        return
    end

    if category == 'performance' then
        performanceNui.open()
        cb({ ok = true })
        return
    end

    if category == 'repair' then
        SetNuiFocus(false, false)
        repair()
        cb({ ok = true })
        return
    end

    local menuPath = menuPaths[category]

    if not menuPath then
        cb({ ok = false })
        return
    end

    -- Tutup tampilan NUI, tetapi sesi customs tetap aktif.
    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'close'
    })

    local menuId = require(menuPath)()

    if menuId then
        lib.showMenu(menuId, 1)
    else
        showCustomsMainNui()
    end

    cb({ ok = true })
end)

RegisterNUICallback('performancePreview', function(data, cb)
    local success = performanceNui.preview(
        data.id,
        data.index
    )

    cb({
        ok = success
    })
end)

RegisterNUICallback('performanceInstall', function(data, cb)
    local success = performanceNui.install(
        data.id,
        data.index
    )

    cb({
        ok = success
    })
end)

RegisterNUICallback('performanceBack', function(_, cb)
    performanceNui.back()
    showCustomsMainNui()

    cb({ ok = true })
end)

lib.callback.register('qbx_customs:client:vehicleProps', function()
    return lib.getVehicleProperties(vehicle)
end)

local function openCustomsNui(useExports)
    if not cache.vehicle or inMenu then
        return false
    end

    openedWithExports = useExports == true

    vehicle = cache.vehicle

    SetVehicleModKit(vehicle, 0)

    disableControls()
    startDragCam(vehicle)

    showCustomsMainNui()

    return true
end

exports('OpenMenu', function()
    return openCustomsNui(true)
end)

return function()
    openCustomsNui(false)
end
