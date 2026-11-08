--[[
    NSR HUD Ultimate — Vehicle Keys & Lock Integration Bridge (bridge/vehicle_keys.lua)
    Supports: 'auto', 'qbx_vehiclekeys', 'qb-vehiclekeys', 'qs-vehiclekeys', 'wasabi_carlock', 'native'
]]

NSRVehicleKeys = {
    ActiveProvider = 'native'
}

function NSRVehicleKeys.Initialize()
    local configured = (Config and Config.Integrations and Config.Integrations.VehicleKeys) or 'auto'
    if configured == 'auto' then
        if NSRUtils.IsResourceStarted('qbx_vehiclekeys') then
            NSRVehicleKeys.ActiveProvider = 'qbx_vehiclekeys'
        elseif NSRUtils.IsResourceStarted('qb-vehiclekeys') then
            NSRVehicleKeys.ActiveProvider = 'qb-vehiclekeys'
        elseif NSRUtils.IsResourceStarted('qs-vehiclekeys') then
            NSRVehicleKeys.ActiveProvider = 'qs-vehiclekeys'
        elseif NSRUtils.IsResourceStarted('wasabi_carlock') then
            NSRVehicleKeys.ActiveProvider = 'wasabi_carlock'
        else
            NSRVehicleKeys.ActiveProvider = 'native'
        end
    else
        NSRVehicleKeys.ActiveProvider = configured
    end
    NSRUtils.Debug(('Vehicle keys integration initialized: %s'):format(NSRVehicleKeys.ActiveProvider))
end

function NSRVehicleKeys.IsLocked(vehicle)
    if not vehicle or vehicle == 0 then return false end
    local status = GetVehicleDoorLockStatus(vehicle)
    -- In GTA V: 1 = unlocked, 0 = none, 2 = locked, 3 = locked for player, 4 = locked inside
    return status ~= nil and status >= 2
end

function NSRVehicleKeys.ToggleLock(vehicle)
    if not vehicle or vehicle == 0 then return false end
    local ped = PlayerPedId()
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return false, 'driver_only'
    end

    local currentlyLocked = NSRVehicleKeys.IsLocked(vehicle)
    local targetState = currentlyLocked and 1 or 2
    SetVehicleDoorsLocked(vehicle, targetState)
    PlayVehicleDoorCloseSound(vehicle, 1)
    return true, not currentlyLocked
end
