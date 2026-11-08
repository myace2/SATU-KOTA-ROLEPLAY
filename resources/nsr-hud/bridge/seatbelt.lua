--[[
    NSR HUD Ultimate — Seatbelt System & Integration Bridge (bridge/seatbelt.lua)
    Uses KeyDown command mapping ('B' / '/seatbelt') with a 500ms debounce so a single press
    buckles and stays buckled until pressed again or exiting the vehicle.
]]

NSRSeatbelt = {
    Mode = 'builtin',
    Buckled = false,
    LastToggleTime = 0,
    LastSpeed = 0.0,
    LastVelocity = vector3(0.0, 0.0, 0.0)
}

function NSRSeatbelt.IsSupportedForCategory(category)
    return category == 'car'
end

function NSRSeatbelt.SetBuckled(state, showNotification)
    NSRSeatbelt.Buckled = (state == true)
    local ped = PlayerPedId()
    if ped and ped ~= 0 then
        -- Flag 32 = PED_FLAG_CAN_FLY_THRU_WINDSCREEN (false when buckled)
        SetPedConfigFlag(ped, 32, not NSRSeatbelt.Buckled)
    end
    if LocalPlayer and LocalPlayer.state then
        pcall(function()
            LocalPlayer.state:set('seatbelt', NSRSeatbelt.Buckled, false)
        end)
    end
    -- Force immediate Vehicle HUD NUI refresh
    if NSRVehicleHUD then
        NSRVehicleHUD.LastPayload = {}
    end
    if showNotification and NSRMain and NSRMain.Notify then
        NSRMain.Notify('info', NSRLocale.Translate(NSRSeatbelt.Buckled and 'notify.seatbelt_on' or 'notify.seatbelt_off'))
    end
end

function NSRSeatbelt.Toggle(showNotification)
    if NSRSeatbelt.Mode == 'disabled' then return false end
    local now = GetGameTimer()
    -- 500ms debounce prevents any conflict with external seatbelt scripts bound to the same key
    if (now - NSRSeatbelt.LastToggleTime) < 500 then
        return true, NSRSeatbelt.Buckled
    end

    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return false end
    local veh = GetVehiclePedIsIn(ped, false)
    local vClass = GetVehicleClass(veh)
    local category = NSRConstants.VehicleClassCategories[vClass] or 'car'
    if not NSRSeatbelt.IsSupportedForCategory(category) then
        return false
    end

    NSRSeatbelt.LastToggleTime = now
    NSRSeatbelt.SetBuckled(not NSRSeatbelt.Buckled, showNotification ~= false)
    return true, NSRSeatbelt.Buckled
end

function NSRSeatbelt.Initialize()
    local configured = (Config and Config.Integrations and Config.Integrations.Seatbelt) or 'auto'
    if configured == 'disabled' or (Config.Vehicle and Config.Vehicle.Seatbelt and Config.Vehicle.Seatbelt.Enabled == false) then
        NSRSeatbelt.Mode = 'disabled'
        return
    end
    NSRSeatbelt.Mode = configured == 'auto' and 'builtin' or configured

    -- Listen to external seatbelt events with 500ms debounce so pressing 'B' never double-toggles
    RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function(explicitState)
        local now = GetGameTimer()
        if (now - NSRSeatbelt.LastToggleTime) < 500 then return end
        NSRSeatbelt.LastToggleTime = now
        if type(explicitState) == 'boolean' then
            NSRSeatbelt.SetBuckled(explicitState, true)
        else
            NSRSeatbelt.SetBuckled(not NSRSeatbelt.Buckled, true)
        end
    end)

    RegisterNetEvent('hud:client:UpdateSeatbelt', function(state)
        local now = GetGameTimer()
        if (now - NSRSeatbelt.LastToggleTime) < 500 then return end
        if type(state) == 'boolean' and state ~= NSRSeatbelt.Buckled then
            NSRSeatbelt.LastToggleTime = now
            NSRSeatbelt.SetBuckled(state, false)
        end
    end)

    -- Dedicated per-frame exit lock thread ONLY active while buckled inside a vehicle
    CreateThread(function()
        while true do
            if NSRSeatbelt.Buckled then
                local sbCfg = Config.Vehicle and Config.Vehicle.Seatbelt or {}
                if sbCfg.PreventExitWhenBuckled ~= false then
                    DisableControlAction(0, 75, true)  -- INPUT_VEH_EXIT
                    DisableControlAction(27, 75, true)
                end
                Wait(0)
            else
                Wait(350)
            end
        end
    end)

    NSRUtils.Debug(('Seatbelt system initialized: %s'):format(NSRSeatbelt.Mode))
end

function NSRSeatbelt.GetStatus(vehicle, category)
    if NSRSeatbelt.Mode == 'disabled' or not NSRSeatbelt.IsSupportedForCategory(category) then
        return nil
    end
    return NSRSeatbelt.Buckled == true
end

function NSRSeatbelt.OnExitVehicle()
    if NSRSeatbelt.Buckled then
        NSRSeatbelt.SetBuckled(false, false)
    end
    NSRSeatbelt.LastSpeed = 0.0
end

function NSRSeatbelt.Tick(ped, vehicle, category)
    if NSRSeatbelt.Mode == 'disabled' or not NSRSeatbelt.IsSupportedForCategory(category) then
        return
    end

    if not NSRSeatbelt.Buckled then
        local sbCfg = Config.Vehicle and Config.Vehicle.Seatbelt or {}
        local currentSpeedKmh = GetEntitySpeed(vehicle) * 3.6
        local speedDrop = NSRSeatbelt.LastSpeed - currentSpeedKmh
        local threshold = tonumber(sbCfg.EjectSpeedThresholdKmh) or 95.0
        local minDrop = tonumber(sbCfg.MinDecelerationForEject) or 42.0

        if NSRSeatbelt.LastSpeed >= threshold and speedDrop >= minDrop and HasEntityCollidedWithAnything(vehicle) then
            local coords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 1.4, 0.4)
            SetEntityCoords(ped, coords.x, coords.y, coords.z, true, true, true, false)
            SetEntityVelocity(ped, NSRSeatbelt.LastVelocity.x * 0.45, NSRSeatbelt.LastVelocity.y * 0.45, NSRSeatbelt.LastVelocity.z * 0.45)
            SetPedToRagdoll(ped, 2500, 2500, 0, false, false, false)
        end
        NSRSeatbelt.LastSpeed = currentSpeedKmh
        NSRSeatbelt.LastVelocity = GetEntityVelocity(vehicle)
    else
        NSRSeatbelt.LastSpeed = GetEntitySpeed(vehicle) * 3.6
        NSRSeatbelt.LastVelocity = GetEntityVelocity(vehicle)
    end
end
