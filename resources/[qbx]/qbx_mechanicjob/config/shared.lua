return {
    maxStatusValues = {
        engine = 1000.0,
        body = 1000.0,
        radiator = 100,
        axle = 100,
        brakes = 100,
        clutch = 100,
        fuel = 100,
    },
    repairCost = {
        body = 'plastic',
        radiator = 'plastic',
        axle = 'steel',
        brakes = 'iron',
        clutch = 'aluminum',
        fuel = 'plastic',
    },
    repairCostAmount = {
        engine = {
            item = 'metalscrap',
            costs = 2,
        },
        body = {
            item = 'plastic',
            costs = 3,
        },
        radiator = {
            item = 'steel',
            costs = 5,
        },
        axle = {
            item = 'aluminum',
            costs = 7,
        },
        brakes = {
            item = 'copper',
            costs = 5,
        },
        clutch = {
            item = 'copper',
            costs = 6,
        },
        fuel = {
            item = 'plastic',
            costs = 5,
        },
    },
    plates = {
        {
            coords = vec4(1122.51, -786.32, 56.6, 359.39),
            boxData = {
                heading = 340,
                length = 5,
                width = 2.5,
                debugPoly = false
            },
            AttachedVehicle = nil,
        },
        {
            coords = vec4(1157.15, -799.32, 56.6, 270.24),
            boxData = {
                heading = 249,
                length = 6.5,
                width = 5,
                debugPoly = false
            },
            AttachedVehicle = nil,
        },
    },
    locations = {
        exit = vec3(1150.05, -786.02, 56.6),
        duty = vec3(1160.68, -786.48, 56.6),
        stash = vec3(1131.59, -780.21, 56.6),
        vehicle = vec4(1159.09, -771.64, 56.47, 2.68),
    }
}