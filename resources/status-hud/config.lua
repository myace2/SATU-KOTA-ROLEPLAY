Config = {}

Config.Framework = 'qb-core' -- Options: 'esx', 'qb-core'
Config.UpdateInterval = 200  -- Update interval in milliseconds

Config.MinimapUpdateInterval = 1000
Config.MinimapPadding = 12

-- Display options
Config.HideDefaultHudBars = true -- Hide GTA default minimap health/armor bars
Config.HideDefaultHudBarsInterval = 250 -- ms between refreshes after initial burst (lower = less flicker, higher = less CPU)
Config.HideDefaultHudBarsBurstFrames = 60 -- frames to run at full speed when radar becomes visible / after changes
Config.ShowPlayerId = true   -- Show/hide player ID
Config.ShowLocation = true   -- Show/hide location
Config.ServerName = 'SATU KOTA'

Config.Stress = {
	Enabled = true,
	ShootingChance = 10,
	SpeedingThreshold = 130,
	UnbuckledSpeedingThreshold = 100,
	SpeedingInterval = 10000,
}

Config.SpeedometerUnit = 'KM/H'
Config.SpeedometerMaxSpeed = 300