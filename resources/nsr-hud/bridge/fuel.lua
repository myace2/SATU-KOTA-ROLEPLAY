--[[
    NSR HUD Ultimate — Vehicle Fuel Integration Bridge (bridge/fuel.lua)
    Supports: 'auto', 'ox_fuel', 'LegacyFuel', 'cdn-fuel', 'ps-fuel', 'qb-fuel', 'native'
]]

NSRFuel = {
    ActiveProvider = 'native',
    Adapters = {}
}

function NSRFuel.RegisterAdapter(name, checkFn, getterFn)
    if type(name) ~= 'string' or type(getterFn) ~= 'function' then return end
    NSRFuel.Adapters[name] = {
        check = checkFn or function() return NSRUtils.IsResourceStarted(name) end,
        get = getterFn
    }
end

-- 1. ox_fuel (uses Entity(veh).state.fuel or GetVehicleFuelLevel)
NSRFuel.RegisterAdapter('ox_fuel', function()
    return NSRUtils.IsResourceStarted('ox_fuel')
end, function(vehicle)
    if Entity then
        local ok, st = pcall(function() return Entity(vehicle).state end)
        if ok and st and tonumber(st.fuel) then
            return tonumber(st.fuel)
        end
    end
    return GetVehicleFuelLevel(vehicle)
end)

-- 2. LegacyFuel (exports['LegacyFuel']:GetFuel(vehicle))
NSRFuel.RegisterAdapter('LegacyFuel', function()
    return NSRUtils.IsResourceStarted('LegacyFuel')
end, function(vehicle)
    local ok, val = pcall(function()
        return exports['LegacyFuel']:GetFuel(vehicle)
    end)
    if ok and tonumber(val) then return tonumber(val) end
    return GetVehicleFuelLevel(vehicle)
end)

-- 3. cdn-fuel (exports['cdn-fuel']:GetFuel(vehicle))
NSRFuel.RegisterAdapter('cdn-fuel', function()
    return NSRUtils.IsResourceStarted('cdn-fuel')
end, function(vehicle)
    local ok, val = pcall(function()
        return exports['cdn-fuel']:GetFuel(vehicle)
    end)
    if ok and tonumber(val) then return tonumber(val) end
    return GetVehicleFuelLevel(vehicle)
end)

-- 4. ps-fuel (exports['ps-fuel']:GetFuel(vehicle))
NSRFuel.RegisterAdapter('ps-fuel', function()
    return NSRUtils.IsResourceStarted('ps-fuel')
end, function(vehicle)
    local ok, val = pcall(function()
        return exports['ps-fuel']:GetFuel(vehicle)
    end)
    if ok and tonumber(val) then return tonumber(val) end
    return GetVehicleFuelLevel(vehicle)
end)

-- 5. qb-fuel (exports['qb-fuel']:GetFuel(vehicle))
NSRFuel.RegisterAdapter('qb-fuel', function()
    return NSRUtils.IsResourceStarted('qb-fuel')
end, function(vehicle)
    local ok, val = pcall(function()
        return exports['qb-fuel']:GetFuel(vehicle)
    end)
    if ok and tonumber(val) then return tonumber(val) end
    return GetVehicleFuelLevel(vehicle)
end)

-- 6. Native GTA V fallback
NSRFuel.RegisterAdapter('native', function()
    return true
end, function(vehicle)
    return GetVehicleFuelLevel(vehicle)
end)

function NSRFuel.Initialize()
    local configured = (Config and Config.Integrations and Config.Integrations.Fuel) or 'auto'
    if configured ~= 'auto' and NSRFuel.Adapters[configured] then
        if configured == 'native' or NSRFuel.Adapters[configured].check() then
            NSRFuel.ActiveProvider = configured
        else
            NSRUtils.Warn(('Configured fuel provider "%s" is not started. Falling back to native fuel.'):format(configured))
            NSRFuel.ActiveProvider = 'native'
        end
    else
        local order = { 'ox_fuel', 'cdn-fuel', 'LegacyFuel', 'ps-fuel', 'qb-fuel', 'native' }
        for i = 1, #order do
            local name = order[i]
            local ad = NSRFuel.Adapters[name]
            if ad and ad.check() then
                NSRFuel.ActiveProvider = name
                break
            end
        end
    end
    NSRUtils.Debug(('Fuel integration initialized: %s'):format(NSRFuel.ActiveProvider))
end

function NSRFuel.GetFuel(vehicle, category)
    if not vehicle or vehicle == 0 or category == 'bicycle' then
        return nil
    end
    local adapter = NSRFuel.Adapters[NSRFuel.ActiveProvider] or NSRFuel.Adapters.native
    local level = adapter.get(vehicle)
    if not tonumber(level) then
        level = GetVehicleFuelLevel(vehicle)
    end
    return NSRUtils.Round(NSRUtils.Clamp(tonumber(level) or 0, 0, 100), 0)
end
