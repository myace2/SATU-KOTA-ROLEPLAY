local QBCore = nil
local ESX = nil
local PlayerData = {}
local hunger = 100
local thirst = 100
local stress = 0
local drunk = 0
local playerJob = 'Civilian'
local playerGang = 'None'
local serverName = Config.ServerName or 'Server'

RegisterNetEvent('hud:client:UpdateStress', function(value)
    stress = math.max(0, math.min(100, tonumber(value) or 0))
end)

local lastMinimap = {
    left = -1,
    bottom = -1,
    width = -1,
    height = -1
}

local lastScreen = {
    x = -1,
    y = -1,
    safezone = -1
}

local function ForceSmallMinimapBurst(frames)
    frames = frames or 60
    for _ = 1, frames do
        SetRadarBigmapEnabled(false, false)
        Wait(0)
    end
end

CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(250)
    end

    Wait(1000)
    DisplayRadar(true)
    ForceSmallMinimapBurst(120)
end)

AddEventHandler('playerSpawned', function()
    CreateThread(function()
        Wait(1000)
        DisplayRadar(true)
        ForceSmallMinimapBurst(120)
    end)
end)

CreateThread(function()
    if Config.Framework == 'qb-core' then
        QBCore = exports['qb-core']:GetCoreObject()
        while not QBCore do
            Wait(100)
        end
    else
        ESX = exports['es_extended']:getSharedObject()
        while not ESX do
            Wait(100)
        end
    end
end)

local lastValues = {
    health = 0,
    armor = 0,
    food = 0,
    water = 0,
    stress = 0,
    drunk = 0,
    energy = 100,
    serverName = '',
    job = '',
    gang = '',
    id = 0,
    location = ""
}

function GetLocationText()
    if not Config.ShowLocation then return "" end
    
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
    return street
end

local function updatePlayerGroups()
    if not QBCore or not QBCore.Functions then return end

    local data = QBCore.Functions.GetPlayerData()
    if not data then return end

    if data.job then
        local jobLabel = data.job.label or data.job.name or 'Civilian'
        local gradeName = data.job.grade and data.job.grade.name
        playerJob = gradeName and ('%s - %s'):format(jobLabel, gradeName) or jobLabel
    end

    if data.gang then
        if data.gang.name == 'none' then
            playerGang = 'None'
        else
            local gangLabel = data.gang.label or data.gang.name or 'Gang'
            local gangGrade = data.gang.isboss and 'Boss' or (data.gang.grade and data.gang.grade.name) or 'Member'
            playerGang = ('%s - %s'):format(gangLabel, gangGrade)
        end
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', updatePlayerGroups)
RegisterNetEvent('QBCore:Client:OnJobUpdate', updatePlayerGroups)
RegisterNetEvent('QBCore:Client:OnGangUpdate', updatePlayerGroups)

local function GetMinimapAnchor()
    local resX, resY = GetActiveScreenResolution()
    local aspectRatio = GetAspectRatio()

    local scaleX = 1 / resX
    local scaleY = 1 / resY

    local minimapRawX, minimapRawY
    local widthNorm, heightNorm

    SetScriptGfxAlign(string.byte('L'), string.byte('B'))
    if IsBigmapActive() then
        minimapRawX, minimapRawY = GetScriptGfxPosition(-0.003975, 0.022 + (-0.460416666))
        widthNorm = scaleX * (resX / (2.52 * aspectRatio))
        heightNorm = scaleY * (resY / (2.3374))
    else
        minimapRawX, minimapRawY = GetScriptGfxPosition(-0.0045, 0.002 + (-0.188888))
        widthNorm = scaleX * (resX / (4 * aspectRatio))
        heightNorm = scaleY * (resY / (5.674))
    end
    ResetScriptGfxAlign()

    local left = minimapRawX * resX
    local top = minimapRawY * resY
    local width = widthNorm * resX
    local height = heightNorm * resY
    local bottom = resY - (top + height)

    return {
        left = left,
        bottom = bottom,
        width = width,
        height = height
    }
end

local function updateMinimapLayout()
    local resX, resY = GetActiveScreenResolution()
    local safezone = GetSafeZoneSize()

    if resX ~= lastScreen.x or resY ~= lastScreen.y or safezone ~= lastScreen.safezone then
        lastScreen.x = resX
        lastScreen.y = resY
        lastScreen.safezone = safezone

        lastMinimap.left = -1
        lastMinimap.bottom = -1
        lastMinimap.width = -1
        lastMinimap.height = -1
    end

    local anchor = GetMinimapAnchor()

    if math.abs(anchor.left - lastMinimap.left) > 0.5 or
       math.abs(anchor.bottom - lastMinimap.bottom) > 0.5 or
       math.abs(anchor.width - lastMinimap.width) > 0.5 or
       math.abs(anchor.height - lastMinimap.height) > 0.5 then
        lastMinimap.left = anchor.left
        lastMinimap.bottom = anchor.bottom
        lastMinimap.width = anchor.width
        lastMinimap.height = anchor.height

        SendNUIMessage({
            type = 'updateMinimap',
            left = anchor.left,
            bottom = anchor.bottom,
            width = anchor.width,
            height = anchor.height,
            padding = Config.MinimapPadding or 12
        })
    end
end

function updateHUD()
    local ped = PlayerPedId()
    local health = GetEntityHealth(ped)
    local armor = GetPedArmour(ped)
    stress = tonumber(LocalPlayer.state.stress) or 0
    drunk = tonumber(LocalPlayer.state.drunk) or 0
    local energy = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
    local currentId = Config.ShowPlayerId and GetPlayerServerId(PlayerId()) or 0
    local location = GetLocationText()
    
    if health < 100 then
        health = 0
    else
        health = health - 100
    end

    health = math.floor(health + 0.5)
    armor = math.floor(armor + 0.5)
    hunger = math.floor(hunger + 0.5)
    thirst = math.floor(thirst + 0.5)
    stress = math.floor(stress + 0.5)
    drunk = math.floor(drunk + 0.5)
    energy = math.floor(energy + 0.5)

    if health ~= lastValues.health or 
       armor ~= lastValues.armor or 
       hunger ~= lastValues.food or 
       thirst ~= lastValues.water or
    stress ~= lastValues.stress or
    drunk ~= lastValues.drunk or
    energy ~= lastValues.energy or
    serverName ~= lastValues.serverName or
    playerJob ~= lastValues.job or
    playerGang ~= lastValues.gang or
       currentId ~= lastValues.id or
       location ~= lastValues.location then
        
        lastValues.health = health
        lastValues.armor = armor
        lastValues.food = hunger
        lastValues.water = thirst
        lastValues.stress = stress
        lastValues.drunk = drunk
        lastValues.energy = energy
        lastValues.serverName = serverName
        lastValues.job = playerJob
        lastValues.gang = playerGang
        lastValues.id = currentId
        lastValues.location = location
        
        SendNUIMessage({
            type = 'updateStatusHud',
            show = true,
            health = health,
            armor = armor,
            food = hunger,
            water = thirst,
            stress = stress,
            drunk = drunk,
            energy = energy,
            serverName = serverName,
            job = playerJob,
            gang = playerGang,
            id = currentId,
            location = location,
            showId = Config.ShowPlayerId,
            showLocation = Config.ShowLocation
        })
    end
end

CreateThread(function()
    while true do
        updateHUD()
        Wait(Config.UpdateInterval)
    end
end)

CreateThread(function()
    while true do
        updatePlayerGroups()
        Wait(1000)
    end
end)

CreateThread(function()
    local lastVehicleState

    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 and not IsThisModelABicycle(GetEntityModel(vehicle)) then
            local speed = math.floor(GetEntitySpeed(vehicle) * 3.6 + 0.5)
            local gear = GetVehicleCurrentGear(vehicle)
            if gear == 0 then gear = speed < 1 and 'N' or 'R' end

            local fuel = math.floor(math.max(0, math.min(100, GetVehicleFuelLevel(vehicle))) + 0.5)
            local rpm = math.floor(math.max(0, math.min(1, GetVehicleCurrentRpm(vehicle))) * 100 + 0.5)
            local engine = GetIsVehicleEngineRunning(vehicle)
            local seatbelt = LocalPlayer.state.seatbelt == true
            local stateKey = table.concat({speed, gear, fuel, rpm, tostring(engine), tostring(seatbelt)}, ':')

            if stateKey ~= lastVehicleState then
                SendNUIMessage({
                    type = 'updateSpeedometer',
                    show = true,
                    speed = speed,
                    gear = gear,
                    fuel = fuel,
                    rpm = rpm,
                    engine = engine,
                    seatbelt = seatbelt,
                    unit = Config.SpeedometerUnit or 'KM/H',
                    maxSpeed = Config.SpeedometerMaxSpeed or 300,
                })
                lastVehicleState = stateKey
            end
        else
            if lastVehicleState ~= false then
                SendNUIMessage({type = 'updateSpeedometer', show = false})
                lastVehicleState = false
            end
        end

        Wait(150)
    end
end)

local stressWhitelist = {
    [`WEAPON_PETROLCAN`] = true,
    [`WEAPON_HAZARDCAN`] = true,
    [`WEAPON_FIREEXTINGUISHER`] = true,
}

CreateThread(function()
    local nextShotStress = 0
    local nextSpeedStress = 0

    while true do
        local now = GetGameTimer()
        local ped = PlayerPedId()

        if Config.Stress.Enabled and LocalPlayer.state.isLoggedIn then
            if IsPedShooting(ped) and now >= nextShotStress then
                nextShotStress = now + 1000
                if not stressWhitelist[GetSelectedPedWeapon(ped)]
                    and math.random(1, 100) <= Config.Stress.ShootingChance then
                    TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                end
            end

            if now >= nextSpeedStress then
                nextSpeedStress = now + Config.Stress.SpeedingInterval
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                    local vehicleClass = GetVehicleClass(vehicle)
                    if vehicleClass ~= 13 and vehicleClass ~= 14 and vehicleClass ~= 15
                        and vehicleClass ~= 16 and vehicleClass ~= 21 then
                        local hasSeatbelt = LocalPlayer.state.seatbelt
                        local threshold = hasSeatbelt and Config.Stress.SpeedingThreshold
                            or Config.Stress.UnbuckledSpeedingThreshold
                        if GetEntitySpeed(vehicle) * 3.6 >= threshold then
                            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                        end
                    end
                end
            end
        end

        Wait(250)
    end
end)

CreateThread(function()
    if not Config.HideDefaultHudBars then return end

    local minimap = RequestScaleformMovie("minimap")
    ForceSmallMinimapBurst(30)

    local lastVisible = false
    local burstLeft = 0
    local lastScreenX, lastScreenY, lastSafezone = -1, -1, -1

    local function applyOverride()
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
    end

    while true do
        if IsPauseMenuActive() or IsRadarHidden() then
            lastVisible = false
            burstLeft = 0
            Wait(500)
        else
            local resX, resY = GetActiveScreenResolution()
            local safezone = GetSafeZoneSize()
            if resX ~= lastScreenX or resY ~= lastScreenY or safezone ~= lastSafezone then
                lastScreenX, lastScreenY, lastSafezone = resX, resY, safezone
                burstLeft = Config.HideDefaultHudBarsBurstFrames or 60
            end

            if not lastVisible then
                lastVisible = true
                burstLeft = Config.HideDefaultHudBarsBurstFrames or 60
            end

            if burstLeft > 0 then
                burstLeft = burstLeft - 1
                applyOverride()
                Wait(0)
            else
                applyOverride()
                Wait(Config.HideDefaultHudBarsInterval or 250)
            end
        end
    end
end)

CreateThread(function()
    while true do
        updateMinimapLayout()
        Wait(Config.MinimapUpdateInterval or 1000)
    end
end)

-- Framework events
if Config.Framework == 'qb-core' then
    -- QB
    RegisterNetEvent('hud:client:UpdateNeeds')
    AddEventHandler('hud:client:UpdateNeeds', function(newHunger, newThirst)
        hunger = math.floor(newHunger + 0.5)
        thirst = math.floor(newThirst + 0.5)
    end)
else
    -- ESX
    RegisterNetEvent('esx_status:onTick')
    AddEventHandler('esx_status:onTick', function(status)
        for _, status in ipairs(status) do
            if status.name == 'hunger' then
                hunger = math.floor(status.percent + 0.5)
            end
            if status.name == 'thirst' then
                thirst = math.floor(status.percent + 0.5)
            end
        end
    end)
end