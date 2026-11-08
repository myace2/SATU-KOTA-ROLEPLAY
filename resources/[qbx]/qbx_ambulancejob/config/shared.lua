return {
    checkInCost = 2000, -- Price for using the hospital check-in system
    minForCheckIn = 2, -- Minimum number of people with the ambulance job to prevent the check-in system from being used

    locations = { -- Various interaction points
        duty = {
            vec3(1137.42, -1546.41, 35.38),
        },
        vehicle = {
            vec4(1122.64, -1512.02, 34.69, 282.28),
        },
        helicopter = {
            vec4(1185.07, -1540.57, 39.4, 340.92),
        },
        armory = {
            {
                shopType = 'AmbulanceArmory',
                name = 'Armory',
                groups = { ambulance = 0 },
                inventory = {
                    { name = 'radio', price = 0 },
                    { name = 'bandage', price = 0 },
                    { name = 'painkillers', price = 0 },
                    { name = 'firstaid', price = 0 },
                    { name = 'weapon_flashlight', price = 0 },
                    { name = 'weapon_fireextinguisher', price = 0 },
                },
                locations = {
                    vec3(1150.43, -1554.99, 35.38)
                }
            }
        },
        roof = {
            vec3(338.54, -583.88, 74.17),
        },
        main = {
            vec3(298.62, -599.66, 43.29),
        },
        stash = {
            {
                name = 'ambulanceStash',
                label = 'Personal stash',
                weight = 100000,
                slots = 30,
                groups = { ambulance = 0 },
                owner = true, -- Set to false for group stash
                location = vec3(1135.39, -1540.72, 35.38)
            }
        },

        ---@class Bed
        ---@field coords vector4
        ---@field model number

        ---@type table<string, {coords: vector3, checkIn?: vector3|vector3[], beds: Bed[]}>
        hospitals = {
            pillbox = {
                coords = vec3(350, -580, 43),
                checkIn = vec3(1128.7, -1577.36, 35.38),
                beds = {
                    {coords = vec4(1132.81, -1580.04, 35.3, 356.61), model = 1631638868},
                    {coords = vec4(1126.27, -1580.59, 35.3, 268.76), model = 1631638868},
                    {coords = vec4(354.12, -593.12, 43.1, 336.32), model = 2117668672},
                    {coords = vec4(350.79, -591.8, 43.1, 336.32), model = 2117668672},
                    {coords = vec4(346.99, -590.48, 43.1, 336.32), model = 2117668672},
                    {coords = vec4(360.32, -587.19, 43.02, 152.08), model = -1091386327},
                    {coords = vec4(349.82, -583.33, 43.02, 152.08), model = -1091386327},
                    {coords = vec4(326.98, -576.17, 43.02, 152.08), model = -1091386327},
                },
            },
            paleto = {
                coords = vec3(-250, 6315, 32),
                checkIn = vec3(-254.54, 6331.78, 32.43),
                beds = {
                    {coords = vec4(-252.43, 6312.25, 32.34, 313.48), model = 2117668672},
                    {coords = vec4(-247.04, 6317.95, 32.34, 134.64), model = 2117668672},
                    {coords = vec4(-255.98, 6315.67, 32.34, 313.91), model = 2117668672},
                },
            },
            jail = {
                coords = vec3(1761, 2600, 46),
                beds = {
                    {coords = vec4(1761.96, 2597.74, 45.66, 270.14), model = 2117668672},
                    {coords = vec4(1761.96, 2591.51, 45.66, 269.8), model = 2117668672},
                    {coords = vec4(1771.8, 2598.02, 45.66, 89.05), model = 2117668672},
                    {coords = vec4(1771.85, 2591.85, 45.66, 91.51), model = 2117668672},
                },
            },
        },

        stations = {
            {label = 'Pillbox Hospital', coords = vec4(1139.76, -1542.22, 35.38, 253.92)},
        }
    },
}