return {
    discordWebhook = nil, -- Replace nil with your webhook if you chose to use discord logging over ox_lib logging
    minOnDutyLogTimeMinutes = 30,
    formatDateTime = '%m-%d-%Y %H:%M',

    -- While the config boss menu creation still works, it is recommended to use the runtime export instead.
    -- Single menu: { coords = ..., size = ..., rotation = ..., type = ... }
    -- Multiple menus: { { coords = ..., size = ..., rotation = ..., type = ... }, { ... }  }
    ---@alias GroupName string
    ---@type table<GroupName, ZoneInfo|ZoneInfo[]>
    menus = {
        police = {
            coords = vec3(448.0, -973.4, 29.69),
            size = vec3(3.0, 3.0, 2.0),
            rotation = 0.0,
            type = 'job',
        },
        ambulance = {
            coords = vec3(1137.5, -1536.94, 35.38),
            size = vec3(3.0, 3.0, 2.0),
            rotation = 0.0,
            type = 'job',
        },
        mechanic = {
            coords = vec3(1160.72, -784.62, 57.6),
            size = vec3(3.0, 3.0, 2.0),
            rotation = 0.0,
            type = 'job',
        },
        goverment = {
            coords = vec3(-568.66, -194.03, 38.22),
            size = vec3(3.0, 3.0, 2.0),
            rotation = 0.0,
            type = 'job',
        },
        lostmc = {
            {
                coords = vec3(983.69, -90.92, 74.85),
                size = vec3(1.5, 1.5, 1.5),
                rotation = 39.68,
                type = 'gang',
            },
            {
                coords = vec3(976.2, -100.57, 74.87),
                size = vec3(1.5, 1.5, 1.5),
                rotation = 42.76,
                type = 'gang',
            },
        },
        vagos = {
            coords = vec3(351.18, -2054.92, 22.09),
            size = vec3(1.5, 1.5, 1.5),
            rotation = 39.68,
            type = 'gang',
        },
    },
}
