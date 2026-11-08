--[[
    NSR HUD Ultimate — Nitro Integration Bridge (bridge/nitro.lua)
    Supports entity statebags (nitro / nitros), jg-mechanic, qb-mechanicjob, or custom adapters.
    Never displays fake nitro values when no nitro system is installed on the vehicle.
]]

NSRNitro = {
    ActiveProvider = 'statebag',
    ClientOverride = {}
}

function NSRNitro.Initialize()
    local configured = (Config and Config.Integrations and Config.Integrations.Nitro) or 'auto'
    if configured == 'disabled' then
        NSRNitro.ActiveProvider = 'disabled'
        return
    end
    NSRNitro.ActiveProvider = configured

    RegisterNetEvent('hud:client:UpdateNitrous', function(_, nitroLevel, isActive)
        NSRNitro.ClientOverride.level = tonumber(nitroLevel)
        NSRNitro.ClientOverride.active = isActive == true
    end)

    NSRUtils.Debug(('Nitro integration initialized: %s'):format(NSRNitro.ActiveProvider))
end

function NSRNitro.GetStatus(vehicle, category)
    if NSRNitro.ActiveProvider == 'disabled' or not vehicle or vehicle == 0 then
        return nil
    end
    if category ~= 'car' and category ~= 'motorcycle' then
        return nil
    end

    if Entity then
        local ok, st = pcall(function() return Entity(vehicle).state end)
        if ok and st then
            local lvl = tonumber(st.nitro or st.nitros or st.nitrousLevel)
            if lvl and lvl > 0 then
                return {
                    available = true,
                    level = NSRUtils.Round(NSRUtils.Clamp(lvl, 0, 100), 0),
                    active = (st.nitroActive == true or st.purgeActive == true)
                }
            end
        end
    end

    if NSRNitro.ClientOverride.level and NSRNitro.ClientOverride.level > 0 then
        return {
            available = true,
            level = NSRUtils.Round(NSRUtils.Clamp(NSRNitro.ClientOverride.level, 0, 100), 0),
            active = NSRNitro.ClientOverride.active == true
        }
    end

    return nil
end
