local config = require 'config'
local buyerPed

local function openSellMenu()
    local inventory = exports.ox_inventory:GetPlayerItems()
    local options = {}

    for _, item in pairs(inventory or {}) do
        local price = config.prices[item.name]
        local count = item.count or item.amount or 0

        if price and count > 0 then
            options[#options + 1] = {
                title = item.label or item.name,
                description = ('Jumlah: %s | Harga satuan: $%s'):format(count, price),
                icon = 'sack-dollar',
                arrow = true,
                onSelect = function()
                    local input = lib.inputDialog('Jual Material', {
                        {
                            type = 'number',
                            label = ('Jumlah (tersedia: %s)'):format(count),
                            description = ('Total maksimal: $%s'):format(count * price),
                            min = 1,
                            max = math.min(count, config.maxSellAmount),
                            required = true,
                        }
                    })

                    if not input or not input[1] then return end
                    TriggerServerEvent('qbx_materialbuyer:server:sellItem', item.name, input[1])
                end,
            }
        end
    end

    if #options == 0 then
        options[1] = {
            title = 'Tidak ada material',
            description = 'Kamu tidak memiliki material yang dapat dijual.',
            icon = 'ban',
            disabled = true,
        }
    end

    lib.registerContext({
        id = 'qbx_materialbuyer_menu',
        title = 'Material Buyer',
        options = options,
    })
    lib.showContext('qbx_materialbuyer_menu')
end

CreateThread(function()
    local model = joaat(config.location.pedModel)
    lib.requestModel(model)

    buyerPed = CreatePed(
        0,
        model,
        config.location.coords.x,
        config.location.coords.y,
        config.location.coords.z - 1.0,
        config.location.heading,
        false,
        true
    )

    SetEntityAsMissionEntity(buyerPed, true, true)
    SetEntityInvincible(buyerPed, true)
    FreezeEntityPosition(buyerPed, true)
    SetBlockingOfNonTemporaryEvents(buyerPed, true)
    SetModelAsNoLongerNeeded(model)

    exports.ox_target:addLocalEntity(buyerPed, {
        {
            name = 'qbx_materialbuyer_sell',
            icon = 'fa-solid fa-recycle',
            label = 'Jual Material',
            distance = 2.0,
            onSelect = openSellMenu,
        }
    })

    if config.blip.enabled then
        local blip = AddBlipForCoord(config.blip.coords.x, config.blip.coords.y, config.blip.coords.z)
        SetBlipSprite(blip, config.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, config.blip.scale)
        SetBlipColour(blip, config.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(config.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if buyerPed and DoesEntityExist(buyerPed) then
        exports.ox_target:removeLocalEntity(buyerPed, 'qbx_materialbuyer_sell')
        DeleteEntity(buyerPed)
    end
end)
