local config = require 'config.client'
local hasTarget = false
local lastPed = {}
local stealingPed = nil
local stealData = {}
local currentOfferDrug = nil
local CurrentCops = 0
local textDrawn = false
local zoneMade = false

local function robberyPed()
    if config.useTarget then
        local targetStealingPed = NetworkGetNetworkIdFromEntity(stealingPed)
        local options = {
            {
                name = 'stealingped',
                icon = 'fas fa-magnifying-glass',
                label = locale('info.search_ped'),
                onSelect = function()
                    lib.playAnim(cache.ped, 'pickup_object', 'pickup_low', 8.0, -8.0, -1, 1, 0, false, false, false)
                    Wait(2000)
                    ClearPedTasks(cache.ped)
                    TriggerServerEvent('qb-drugs:server:giveStealItems')
                    TriggerEvent('inventory:client:ItemBox', exports.ox_inventory:Items()[stealData.item], 'add')
                    stealingPed = nil
                    stealData = {}
                    exports.ox_target:removeEntity(targetStealingPed, 'stealingped')
                end,
                canInteract = function()
                    if IsEntityDead(stealingPed) then
                        return true
                    end
                end
            }
        }
        exports.ox_target:addEntity(targetStealingPed, options)
        CreateThread(function()
            while stealingPed do
                local pos = GetEntityCoords(cache.ped)
                local pedpos = GetEntityCoords(stealingPed)
                local dist = #(pos - pedpos)
                if dist > 100 then
                    stealingPed = nil
                    stealData = {}
                    exports.ox_target:removeEntity(targetStealingPed, 'stealingped')
                    break
                end
                Wait(0)
            end
        end)
    else
        CreateThread(function()
            while stealingPed do
                if IsEntityDead(stealingPed) then
                    local pos = GetEntityCoords(cache.ped)
                    local pedpos = GetEntityCoords(stealingPed)
                    if not config.useTarget and #(pos - pedpos) < 1.5 then
                        if not textDrawn then
                            textDrawn = true
                            lib.showTextUI(locale('info.pick_up_button'))
                        end
                        if IsControlJustReleased(0, 38) then
                            lib.hideTextUI()
                            textDrawn = false
                            lib.playAnim(cache.ped, 'pickup_object', 'pickup_low', 8.0, -8.0, -1, 1, 0, false, false, false)
                            Wait(2000)
                            ClearPedTasks(cache.ped)
                            TriggerServerEvent('qb-drugs:server:giveStealItems')
                            TriggerEvent('inventory:client:ItemBox', exports.ox_inventory:Items()[stealData.item], 'add')
                            stealingPed = nil
                            stealData = {}
                        end
                    end
                else
                    local pos = GetEntityCoords(cache.ped)
                    local pedpos = GetEntityCoords(stealingPed)
                    if #(pos - pedpos) > 100 then
                        stealingPed = nil
                        stealData = {}
                        break
                    end
                end
                Wait(0)
            end
        end)
    end
end

local function sellToPed(ped)
    hasTarget = true
    local targetPedSale = NetworkGetNetworkIdFromEntity(ped)
    local optionNamesTargetPed = {'selldrugs', 'declineoffer'}

    for i = 1, #lastPed, 1 do
        if lastPed[i] == ped then
            hasTarget = false
            return
        end
    end

    local successChance = math.random(1, 100)
    local getRobbed = math.random(1, 100)
    if successChance <= config.successChance then hasTarget = false return end

    currentOfferDrug = lib.callback.await('qb-drugs:server:getDrugOffer', false)

    if currentOfferDrug == nil then
        hasTarget = false
        exports.qbx_core:Notify(locale('error.no_drugs_left'), 'error')
        return
    end

    SetEntityAsNoLongerNeeded(ped)
    ClearPedTasks(ped)

    local coords = GetEntityCoords(cache.ped, true)
    local pedCoords = GetEntityCoords(ped)
    local pedDist = #(coords - pedCoords)
    TaskGoStraightToCoord(ped, coords.x, coords.y, coords.z, getRobbed <= config.robberyChance and 15.0 or 1.2, -1, 0.0, 0.0)

    while pedDist > 1.5 do
        coords = GetEntityCoords(cache.ped, true)
        pedCoords = GetEntityCoords(ped)
        TaskGoStraightToCoord(ped, coords.x, coords.y, coords.z, getRobbed <= config.robberyChance and 15.0 or 1.2, -1, 0.0, 0.0)
        pedDist = #(coords - pedCoords)
        Wait(100)
    end

    TaskLookAtEntity(ped, cache.ped, 5500.0, 2048, 3)
    TaskTurnPedToFaceEntity(ped, cache.ped, 5500)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT', 0, false)

    if hasTarget then
        while pedDist < 1.5 and not IsPedDeadOrDying(ped, false) do
            local coords2 = GetEntityCoords(cache.ped, true)
            local pedCoords2 = GetEntityCoords(ped)
            local pedDist2 = #(coords2 - pedCoords2)
            if getRobbed <= config.robberyChance then
                TriggerServerEvent('qb-drugs:server:robCornerDrugs')
                exports.qbx_core:Notify(locale('info.has_been_robbed', currentOfferDrug.amount, currentOfferDrug.chosen.label))
                stealingPed = ped
                stealData = {
                    item = currentOfferDrug.chosen.item,
                    drugType = currentOfferDrug.idx,
                    amount = currentOfferDrug.amount,
                }
                hasTarget = false
                local moveTo = GetEntityCoords(cache.ped)
                local moveToCoords = vec3(moveTo.x + math.random(100, 500), moveTo.y + math.random(100, 500), moveTo.z)
                ClearPedTasksImmediately(ped)
                TaskGoStraightToCoord(ped, moveToCoords.x, moveToCoords.y, moveToCoords.z, 15.0, -1, 0.0, 0.0)
                lastPed[#lastPed + 1] = ped
                robberyPed()
                break
            else
                if pedDist2 < 1.5 then
                    if config.useTarget and not zoneMade then
                        zoneMade = true
                        local options = {
                            {
                                name = 'selldrugs',
                                icon = 'fas fa-hand-holding-dollar',
                                label = locale('info.target_drug_offer', currentOfferDrug.amount, currentOfferDrug.chosen.label, currentOfferDrug.total),
                                onSelect = function()
                                    TriggerServerEvent('qb-drugs:server:sellCornerDrugs')
                                    currentOfferDrug = nil
                                    hasTarget = false
                                    lib.playAnim(cache.ped, 'gestures@f@standing@casual', 'gesture_point', 3.0, 3.0, -1, 49, 0, false, false, false)
                                    Wait(650)
                                    ClearPedTasks(cache.ped)
                                    SetPedKeepTask(ped, false)
                                    SetEntityAsNoLongerNeeded(ped)
                                    ClearPedTasksImmediately(ped)
                                    lastPed[#lastPed + 1] = ped
                                    exports.ox_target:removeEntity(targetPedSale, optionNamesTargetPed)
                                end,
                            },
                            {
                                name = 'declineoffer',
                                icon = 'fas fa-x',
                                label = locale('info.decline_offer'),
                                onSelect = function()
                                    currentOfferDrug = nil
                                    exports.qbx_core:Notify(locale('error.offer_declined'), 'error')
                                    hasTarget = false
                                    SetPedKeepTask(ped, false)
                                    SetEntityAsNoLongerNeeded(ped)
                                    ClearPedTasksImmediately(ped)
                                    lastPed[#lastPed + 1] = ped
                                    exports.ox_target:removeEntity(targetPedSale, optionNamesTargetPed)
                                end,
                            },
                        }
                        exports.ox_target:addEntity(targetPedSale, options)
                    elseif not config.useTarget then
                        if not textDrawn then
                            textDrawn = true
                            lib.showTextUI(locale('info.drug_offer', currentOfferDrug.amount, currentOfferDrug.chosen.label, currentOfferDrug.total))
                        end
                        if IsControlJustPressed(0, 38) then
                            lib.hideTextUI()
                            textDrawn = false
                            TriggerServerEvent('qb-drugs:server:sellCornerDrugs')
                            hasTarget = false
                            lib.playAnim(cache.ped, 'gestures@f@standing@casual', 'gesture_point', 3.0, 3.0, -1, 49, 0, false, false, false)
                            Wait(650)
                            ClearPedTasks(cache.ped)
                            SetPedKeepTask(ped, false)
                            SetEntityAsNoLongerNeeded(ped)
                            ClearPedTasksImmediately(ped)
                            lastPed[#lastPed + 1] = ped
                            break
                        end
                        if IsControlJustPressed(0, 47) then
                            lib.hideTextUI()
                            textDrawn = false
                            exports.qbx_core:Notify(locale('error.offer_declined'), 'error')
                            hasTarget = false
                            SetPedKeepTask(ped, false)
                            SetEntityAsNoLongerNeeded(ped)
                            ClearPedTasksImmediately(ped)
                            lastPed[#lastPed + 1] = ped
                            break
                        end
                    end
                else
                    if config.useTarget then
                        zoneMade = false
                        exports.ox_target:removeEntity(targetPedSale, optionNamesTargetPed)
                    else
                        if textDrawn then
                            lib.hideTextUI()
                            textDrawn = false
                        end
                    end
                    hasTarget = false
                    SetPedKeepTask(ped, false)
                    SetEntityAsNoLongerNeeded(ped)
                    ClearPedTasksImmediately(ped)
                    lastPed[#lastPed + 1] = ped
                    break
                end
            end
            Wait(0)
        end
        Wait(math.random(4000, 7000))
    end
end

-- Target NPC directly to offer a drug sale; no radial menu or selling toggle needed.
exports.ox_target:addGlobalPed({
    {
        name = 'qbx_drugs_corner_sell',
        icon = 'fas fa-hand-holding-dollar',
        label = 'Tawarkan narkoba',
        distance = 3.0,
        canInteract = function(entity)
            if hasTarget or not DoesEntityExist(entity) then return false end
            if IsPedAPlayer(entity) or IsPedInAnyVehicle(entity, false) or IsPedDeadOrDying(entity, true) then
                return false
            end
            if GetPedType(entity) == 28 then return false end

            for i = 1, #lastPed do
                if lastPed[i] == entity then return false end
            end

            return true
        end,
        onSelect = function(data)
            if CurrentCops < config.minimumDrugSalePolice then
                exports.qbx_core:Notify(locale('error.not_enough_police', config.minimumDrugSalePolice), 'error')
                return
            end

            sellToPed(data.entity)
        end,
    },
})

-- Keep the police count updated for the target interaction.
RegisterNetEvent('police:SetCopCount', function(amount)
    CurrentCops = amount
end)
