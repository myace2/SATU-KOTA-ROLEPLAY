return {
    cityhalls = {
        {
            coords = vec3(-553.62, -192.43, 38.22),
            showBlip = true,
            blip = {
                label = 'Goverment',
                shortRange = true,
                sprite = 487,
                display = 4,
                scale = 0.85,
                colour = 3,
            },
            licenses = {
                ['id'] = {
                    item = 'id_card',
                    label = 'ID',
                    cost = 50,
                },
            },
        },
    },

    employment = {
        enabled = false, -- Set to false to disable the employment menu
        jobs = {
            unemployed = 'Unemployed',
            trucker = 'Trucker',
            taxi = 'Taxi',
            tow = 'Tow Truck',
            reporter = 'News Reporter',
            garbage = 'Garbage Collector',
            bus = 'Bus Driver',
        },
    },
}
