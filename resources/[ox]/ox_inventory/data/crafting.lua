return {
	{
        name = 'debug_crafting',

		groups = {
            ['lostmc'] = 0,
            ['ballas'] = 0,
            ['vagos'] = 0,
            ['cartel'] = 0,
            ['families'] = 0,
            ['triads'] = 0,
        },


		items = {
			{
				name = 'lockpick',
				ingredients = {
					metalscrap = 5,
					iron = 10
				},
				duration = 5000,
				count = 2,
			},
		},
		points = {
			vec3(3813.04, 4446.35, 3.32),
		    vec3(3813.04, 4446.35, 3.32)
		},
		zones = {
			{
				coords = vec3(3813.04, 4446.35, 3.32),
				size = vec3(3.8, 1.05, 0.15),
				distance = 1.5,
				rotation = 0,
			},
		},
	},
	{
    name = 'vest_crafting',

    groups = {
        ['lostmc'] = 0,
        ['ballas'] = 0,
        ['vagos'] = 0,
        ['cartel'] = 0,
        ['families'] = 0,
        ['triads'] = 0,
    },

    items = {
        {
            name = 'armour',
            ingredients = {
                metalscrap = 10,
                steel = 5,
                plastic = 5,
            },
            duration = 10000,
            count = 1,
        },
    },

    points = {
        vec3(154.26, -3210.98, 5.92),
    },

    zones = {
        {
            coords = vec3(154.26, -3210.98, 5.92),
            size = vec3(3.0, 3.0, 2.0),
            distance = 2.0,
            rotation = 0.0,

            groups = {
                ['lostmc'] = 0,
                ['ballas'] = 0,
                ['vagos'] = 0,
                ['cartel'] = 0,
                ['families'] = 0,
                ['triads'] = 0,
            },
        },
    },
},
{
    name = 'drug_processing',
    label = 'Drug Processing',
    groups = {
        lostmc = 0,
        ballas = 0,
        vagos = 0,
        cartel = 0,
        families = 0,
        triads = 0,
    },
    items = {
        {
            name = 'joint',
            ingredients = {
                ['weed'] = 1,
                rolling_paper = 1,
            },
            duration = 5000,
            count = 1,
        },
        {
            name = 'meth',
            ingredients = {
                meth_raw = 1,
            },
            duration = 5000,
            count = 1,
        },
        {
            name = 'cokebaggy',
            ingredients = {
                coca_leaf = 5,
            },
            duration = 5000,
            count = 1,
        },
    },
    points = {
        vec3(2192.75, 5595.72, 53.52),
    },
    zones = {
        {
            coords = vec3(2192.75, 5595.72, 53.52),
            size = vec3(2.0, 2.0, 2.0),
            distance = 2.0,
            rotation = 0.0,
            groups = {
                lostmc = 0,
                ballas = 0,
                vagos = 0,
                cartel = 0,
                families = 0,
                triads = 0,
            },
        },
    },
},
}
