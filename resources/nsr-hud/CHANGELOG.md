# Changelog — NSR HUD Ultimate (`nsr-hud`)

## [1.0.0] — 2026-10-21 (Initial Commercial Release)

### Added
- **Multi-Framework Architecture (`bridge/framework.lua`)**: Complete support and automatic detection for Qbox (`qbx_core`), QBCore (`qb-core`), ESX Legacy (`es_extended`), and Standalone mode, plus `NSRFramework.RegisterAdapter` for custom frameworks.
- **Configuration-Only Localization (`shared/locale.lua`, `locales/*.lua`, `html/js/localization.js`)**: 239 localized strings across 8 languages (`en`, `ar`, `fr`, `de`, `es`, `pt`, `tr`, `it`) with automatic English fallback and full Right-to-Left (RTL) layout when `Config.Locale = 'ar'`.
- **Modular Player HUD (`client/player_hud.lua`, `html/js/player-hud.js`)**: 15 independently configurable widgets (`health`, `armor`, `hunger`, `thirst`, `stamina`, `oxygen`, `stress`, `voice`, `playerid`, `cash`, `bank`, `job`, `compass`, `location`, `clock`) with 5 visual styles (`ring`, `bar`, `pill`, `hex`, `minimal`).
- **Advanced Vehicle HUD (`client/vehicle_hud.lua`, `html/js/vehicle-hud.js`)**: 4 dashboard presets (`cyber_digital`, `analog_classic`, `sport_gt`, `minimal_strip`) and category-adaptive telemetry for Cars, Motorcycles, Bicycles, Boats, Helicopters, and Airplanes.
- **Vehicle Integration Bridges (`bridge/*.lua`)**: Safe, `pcall`-isolated adapters for `ox_fuel`, `LegacyFuel`, `cdn-fuel`, `ps-fuel`, `qb-fuel`, `pma-voice`, `saltychat`, `mumble-voip`, `qbx_seatbelt`, `qb-smallresources`, `qbx_vehiclekeys`, `qb-vehiclekeys`, `qs-vehiclekeys`, `wasabi_carlock`, and statebag nitro systems.
- **NSR CarPlay Infotainment System (`client/carplay.lua`, `html/js/carplay.js`)**: 6 in-vehicle applications (Home, Radio, GPS Waypoint Navigation, Vehicle Diagnostics, Cabin/Exterior Controls with server-side driver seat verification, and Display Settings).
- **Drag-and-Drop HUD Studio (`client/hud_editor.lua`, `html/js/editor.js`)**: Interactive widget dragging, X/Y center snap guides, live property inspector, 6 themes (`midnight`, `neon`, `minimal`, `sport`, `luxury`, `tactical`), and up to 5 named personal layout presets.
- **Persistence Engine (`server/persistence.lua`, `database/nsr_hud.sql`)**: Support for `oxmysql`, server-side JSON storage, and client ResourceKvp backup with per-player rate limiting and strict payload sanitization.
