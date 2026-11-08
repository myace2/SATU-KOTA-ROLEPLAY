
---@type WeedSharedConfig
local sharedConfig = require 'config.shared'

---@type WeedClientConfig
local config = require 'config.client'

---@type table<string, WeedPlant[]>
local propertyPlants = {}

---@type WeedPlant[]
local outsidePlants = {}

local currentProperty = exports.qbx_core:GetPlayerData()?.metadata?.currentPropertyId
local plantsSpawned = false
local closestTarget = 0

local propertyPlantObjects = {}
local outsidePlantObjects = {}

currentProperty = currentProperty and tostring(currentProperty) or nil

-- =========================================================
-- PLANT OBJECT MANAGEMENT
-- =========================================================

local function removePlantObject(objectStore, id)
    local entry = objectStore[id]

    if not entry then return end

    if entry.entity and DoesEntityExist(entry.entity) then
        DeleteEntity(entry.entity)
    end

    objectStore[id] = nil
end

local function reconcilePlantObjects(plants, objectStore)
    local seen = {}

    for i = 1, #plants do
        local plant = plants[i]
        local id = plant.id

        local plantConfig = sharedConfig.plants[plant.sort]
        if not plantConfig then goto continue end

        local stageModel = plantConfig.stages[plant.stage]
        if not stageModel then goto continue end

        local model = joaat(stageModel)

        seen[id] = true

        local entry = objectStore[id]

        -- Hapus objek jika entity hilang atau model berubah.
        if entry and (
            not DoesEntityExist(entry.entity)
            or entry.model ~= model
        ) then
            removePlantObject(objectStore, id)
            entry = nil
        end

        -- Buat objek hanya jika belum tersedia.
        if not entry then
            RequestModel(model)

            while not HasModelLoaded(model) do
                Wait(0)
            end

            local plantProp = CreateObject(
                model,
                plant.coords.x,
                plant.coords.y,
                plant.coords.z,
                false,
                false,
                false
            )

            if plantProp ~= 0 then
                PlaceObjectOnGroundProperly(plantProp)
                FreezeEntityPosition(plantProp, true)
                SetEntityAsMissionEntity(plantProp, true, true)

                objectStore[id] = {
                    entity = plantProp,
                    model = model
                }
            end

            SetModelAsNoLongerNeeded(model)
        end

        ::continue::
    end

    -- Bersihkan tanaman yang sudah tidak ada dalam data terbaru.
    for id in pairs(objectStore) do
        if not seen[id] then
            removePlantObject(objectStore, id)
        end
    end
end

local function spawnPropertyPlants()
    if plantsSpawned or not currentProperty then return end

    reconcilePlantObjects(
        propertyPlants[currentProperty] or {},
        propertyPlantObjects
    )

    plantsSpawned = true
end

local function spawnOutsidePlants()
    if plantsSpawned or currentProperty then return end

    reconcilePlantObjects(
        outsidePlants,
        outsidePlantObjects
    )

    plantsSpawned = true
end

local function despawnPropertyPlants(property)
    if not property then return end

    for id in pairs(propertyPlantObjects) do
        removePlantObject(propertyPlantObjects, id)
    end

    propertyPlants[property] = {}
    plantsSpawned = false
end

local function despawnOutsidePlants(property)
    if property then return end

    for id in pairs(outsidePlantObjects) do
        removePlantObject(outsidePlantObjects, id)
    end

    outsidePlants = {}
    plantsSpawned = false
end

-- =========================================================
-- PLANT INTERACTION / STATS
-- =========================================================


local function updatePlantStats()
    if not plantsSpawned then
        closestTarget = 0
        return 1000
    end

    local tbl = currentProperty and propertyPlants[currentProperty] or outsidePlants
    local sleep = 1000

    closestTarget = 0

    for i = 1, #tbl do
        local plant = tbl[i]
        local plantConfig = sharedConfig.plants[plant.sort]

        if not plantConfig then
            goto continue
        end

        local gender = plant.gender == 'female' and 'F' or 'M'
        local plyDistance = #(GetEntityCoords(cache.ped) - plant.coords)

        -- Tampilkan informasi saat pemain mendekati tanaman
        if plyDistance < 1.5 then
            closestTarget = i

            if plant.health > 0 then
                sleep = 0

                local totalStages = #plantConfig.stages
                local currentStage = tonumber(plant.stage) or 1
                local stageProgress = tonumber(plant.stageProgress) or 0

                -- Hitung persentase pertumbuhan keseluruhan
                local growthPercent

                if currentStage >= totalStages then
                    growthPercent = 100
                else
                    stageProgress = math.max(0, math.min(100, stageProgress))

                    growthPercent = (
                        ((currentStage - 1) + (stageProgress / 100))
                        / (totalStages - 1)
                    ) * 100
                end

                growthPercent = math.floor(growthPercent + 0.5)

                local growthLabel = ('Growth: ~g~%s%%~w~'):format(growthPercent)

                local plantLabel = (
                    '%s%s~w~ [%s] | %s ~b~%s~w~ | %s ~b~%s~w~'
                ):format(
                    locale('text.sort'),
                    plantConfig.label,
                    gender,
                    locale('text.nutrition'),
                    plant.food,
                    locale('text.health'),
                    plant.health
                )

                -- Tampilkan progres pertumbuhan
                qbx.drawText3d({
                    text = growthLabel,
                    coords = vec3(
                        plant.coords.x,
                        plant.coords.y,
                        plant.coords.z + 0.45
                    )
                })

                -- Tampilkan informasi tanaman
                qbx.drawText3d({
                    text = plantLabel,
                    coords = plant.coords
                })

                -- Jika tanaman sudah mencapai 100%, tampilkan instruksi panen
                if growthPercent >= 100 then
                    qbx.drawText3d({
                        text = locale('text.harvest_plant'),
                        coords = vec3(
                            plant.coords.x,
                            plant.coords.y,
                            plant.coords.z + 0.2
                        )
                    })

                    if IsControlJustPressed(0, 38) then
                        if lib.progressCircle({
                            duration = 8000,
                            position = 'bottom',
                            label = locale('text.harvesting_plant'),
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                move = true,
                                car = true,
                                mouse = false,
                                combat = true,
                            },
                            anim = {
                                dict = 'amb@world_human_gardener_plant@male@base',
                                clip = 'base',
                            },
                        }) then
                            TriggerServerEvent(
                                'qbx_weed:server:harvestPlant',
                                currentProperty,
                                plant.id
                            )
                        else
                            exports.qbx_core:Notify(
                                locale('error.process_canceled'),
                                'error'
                            )
                        end

                        ClearPedTasks(cache.ped)
                    end
                end

            elseif plant.health <= 0 then
                sleep = 0

                qbx.drawText3d({
                    text = locale('error.plant_has_died'),
                    coords = plant.coords
                })

                if IsControlJustPressed(0, 38) then
                    if lib.progressCircle({
                        duration = 8000,
                        position = 'bottom',
                        label = locale('text.removing_the_plant'),
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            move = true,
                            car = true,
                            mouse = false,
                            combat = true,
                        },
                        anim = {
                            dict = 'amb@world_human_gardener_plant@male@base',
                            clip = 'base',
                        },
                    }) then
                        TriggerServerEvent(
                            'qbx_weed:server:removeDeadPlant',
                            currentProperty,
                            plant.id
                        )
                    else
                        exports.qbx_core:Notify(
                            locale('error.process_canceled'),
                            'error'
                        )
                    end

                    ClearPedTasks(cache.ped)
                end
            end
        end

        ::continue::
    end

    return sleep
end


-- =========================================================
-- PLANTING
-- =========================================================

local function placePlant(type, item)
    local plyCoords = GetOffsetFromEntityInWorldCoords(
        cache.ped,
        0,
        0.75,
        0
    )

    local closestPlant = 0

    for i = 1, #sharedConfig.stageProps do
        if closestPlant == 0 then
            closestPlant = GetClosestObjectOfType(
                plyCoords.x,
                plyCoords.y,
                plyCoords.z,
                0.8,
                joaat(sharedConfig.stageProps[i]),
                false,
                false,
                false
            )
        end
    end

    if closestPlant ~= 0 then
        return exports.qbx_core:Notify(
            locale('error.cant_place_here'),
            'error'
        )
    end

    LocalPlayer.state:set('invBusy', true, true)

    if lib.progressCircle({
        duration = 8000,
        position = 'bottom',
        label = locale('text.planting'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true,
        },
        anim = {
            dict = 'amb@world_human_gardener_plant@male@base',
            clip = 'base',
        },
    }) then
        TriggerServerEvent(
            'qbx_weed:server:placePlant',
            plyCoords,
            type,
            currentProperty,
            item.slot,
            item.name
        )
    else
        exports.qbx_core:Notify(
            locale('error.process_canceled'),
            'error'
        )
    end

    LocalPlayer.state:set('invBusy', false, true)
    ClearPedTasks(cache.ped)
end

exports('placePlant', placePlant)
RegisterNetEvent('qbx_weed:client:placePlant', placePlant)

-- =========================================================
-- PLANT FOOD
-- =========================================================

local function foodPlant()
    if closestTarget == 0 then
        return exports.qbx_core:Notify(
            locale('error.not_safe_here'),
            'error'
        )
    end

    local data = currentProperty
        and propertyPlants[currentProperty][closestTarget]
        or outsidePlants[closestTarget]

    if not data then return end

    local plyDistance = #(GetEntityCoords(cache.ped) - data.coords)

    if plyDistance >= 1.0 then
        return exports.qbx_core:Notify(
            locale('error.cant_place_here'),
            'error'
        )
    end

    if data.food == 100 then
        return exports.qbx_core:Notify(
            locale('error.not_need_nutrition'),
            'error'
        )
    end

    LocalPlayer.state:set('invBusy', true, true)

    if lib.progressCircle({
        duration = math.random(4000, 8000),
        position = 'bottom',
        label = locale('text.feeding_plant'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true,
        },
        anim = {
            dict = 'timetable@gardener@filling_can',
            clip = 'gar_ig_5_filling_can',
        },
    }) then
        TriggerServerEvent(
            'qbx_weed:server:foodPlant',
            currentProperty,
            data.id
        )
    else
        exports.qbx_core:Notify(
            locale('error.process_canceled'),
            'error'
        )
    end

    LocalPlayer.state:set('invBusy', false, true)
    ClearPedTasks(cache.ped)
end

exports('foodPlant', foodPlant)
RegisterNetEvent('qbx_weed:client:foodPlant', foodPlant)

-- =========================================================
-- PROPERTY CHANGE
-- =========================================================

RegisterNetEvent('qbx_core:client:onSetMetaData', function(meta, oldValue, value)
    if meta ~= 'currentPropertyId' then return end

    currentProperty = value and tostring(value) or nil

    if currentProperty then
        despawnOutsidePlants(oldValue)

        Wait(1000)

        local plants = lib.callback.await(
            'qbx_weed:server:getPropertyPlants',
            false,
            currentProperty
        )

        propertyPlants[currentProperty] = plants
        spawnPropertyPlants()
    else
        despawnPropertyPlants(oldValue)

        Wait(1000)

        propertyPlants[oldValue] = nil

        Wait(2000)

        spawnOutsidePlants()
    end
end)

-- =========================================================
-- REFRESH PROPERTY PLANTS
-- =========================================================

RegisterNetEvent('qbx_weed:client:refreshPropertyPlants', function(property)
    if not currentProperty or currentProperty ~= property then return end

    local plants = lib.callback.await(
        'qbx_weed:server:getPropertyPlants',
        false,
        property
    )

    propertyPlants[currentProperty] = plants

    reconcilePlantObjects(
        plants,
        propertyPlantObjects
    )

    plantsSpawned = true
end)

-- =========================================================
-- REFRESH PLANT STATS
-- =========================================================

RegisterNetEvent('qbx_weed:client:refreshPlantStats', function()
    if currentProperty then
        local plants = lib.callback.await(
            'qbx_weed:server:getPropertyPlants',
            false,
            currentProperty
        )

        propertyPlants[currentProperty] = plants

        reconcilePlantObjects(
            plants,
            propertyPlantObjects
        )
    else
        local ids = {}
        local playerCoords = GetEntityCoords(cache.ped)

        for i = 1, #outsidePlants do
            local plant = outsidePlants[i]

            if #(playerCoords - plant.coords) < config.outsidePlantsDistance then
                ids[#ids + 1] = plant.id
            end
        end

        local plants = lib.callback.await(
            'qbx_weed:server:getOutsidePlants',
            false,
            ids
        )

        outsidePlants = plants

        reconcilePlantObjects(
            plants,
            outsidePlantObjects
        )
    end

    plantsSpawned = true
end)

-- =========================================================
-- REFRESH OUTSIDE PLANTS
-- =========================================================

---@param plants table<number, vector3>
RegisterNetEvent('qbx_weed:client:refreshOutsidePlants', function(plants)
    if source == '' or GetInvokingResource() then return end
    if currentProperty then return end

    local closePlants = {}
    local playerCoords = GetEntityCoords(cache.ped)

    for id, coords in pairs(plants) do
        if #(playerCoords - coords) < config.outsidePlantsDistance then
            closePlants[#closePlants + 1] = id
        end
    end

    local newPlants = lib.callback.await(
        'qbx_weed:server:getOutsidePlants',
        false,
        closePlants
    )

    outsidePlants = newPlants

    reconcilePlantObjects(
        newPlants,
        outsidePlantObjects
    )

    plantsSpawned = true
end)

-- =========================================================
-- RESOURCE STOP
-- =========================================================

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    despawnPropertyPlants(currentProperty)
    despawnOutsidePlants(currentProperty)
end)

-- =========================================================
-- MAIN THREAD
-- =========================================================

CreateThread(function()
    while true do
        Wait(updatePlantStats())
    end
end)
