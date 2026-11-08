return {
	{
		coords = vec3(452.3, -991.4, 30.7),
		target = {
			loc = vec3(451.25, -994.28, 30.69),
			length = 1.2,
			width = 5.6,
			heading = 0,
			minZ = 29.49,
			maxZ = 32.09,
			label = 'Open personal locker'
		},
		name = 'policelocker',
		label = 'Personal locker',
		owner = true,
		slots = 70,
		weight = 70000,
		groups = shared.police
	},

	{
		coords = vec3(301.3, -600.23, 43.28),
		target = {
			loc = vec3(301.82, -600.99, 43.29),
			length = 0.6,
			width = 1.8,
			heading = 340,
			minZ = 43.34,
			maxZ = 44.74,
			label = 'Open personal locker'
		},
		name = 'emslocker',
		label = 'Personal Locker',
		owner = true,
		slots = 70,
		weight = 70000,
		groups = {['ambulance'] = 0}
	},
	{
		coords = vec3(-516.6, -210.98, 37.17),
		target = {
			loc = vec3(-515.6, -210.98, 38.17),
			length = 0.6,
			width = 1.8,
			heading = 360,
			minZ = 43.34,
			maxZ = 44.74,
			label = 'Open Goverment Stash'
		},
		name = 'govermentstash',
		label = 'Open Goverment Stash',
		owner = false,
		slots = 250,
		weight = 999000000,
		groups = {['goverment'] = 0}
	},
}
