# NSR HUD Ultimate (`nsr-hud`) — v1.0.0

**Premium All-in-One FiveM Player HUD, Vehicle Dashboard, CarPlay & Drag-and-Drop Customization System**  
*Commercial Distribution Package — NSR Store (Tebex)*

## 1. Overview

**NSR HUD Ultimate** (`nsr-hud`) is a modular, full-stack FiveM HUD ecosystem engineered for QBCore, Qbox (`qbx_core`), ESX Legacy (`es_extended`), and Standalone FiveM servers. Every component—from the 15-widget Player HUD and 4-preset Vehicle Telemetry Cluster to the interactive **NSR CarPlay** infotainment system and **NSR HUD Studio** drag-and-drop editor—runs completely offline without external CDN, font server, or third-party runtime dependencies.

## 2. Key Highlights

- **Multi-Framework Adapter Architecture**: Automatic detection or explicit selection for `qbox`, `qbcore`, `esx`, and `standalone` via `Config.Framework` in `config.lua`.
- **Configuration-Driven 8-Language Localization (`Config.Locale`)**: Full translations for English (`en`), Arabic (`ar` with automatic Right-to-Left layout), French (`fr`), German (`de`), Spanish (`es`), Portuguese (`pt`), Turkish (`tr`), and Italian (`it`). Language is controlled strictly via `config.lua` with zero language selectors in the NUI.
- **15 Modular Player HUD Widgets**: Health, Armor, Hunger, Thirst, Stamina, Oxygen, Stress, Voice/Radio, Server ID, Cash, Bank, Job/Grade, Compass, Street/Zone Location, and Clock—each supporting 5 visual styles (`ring`, `bar`, `pill`, `hex`, `minimal`), custom colors, scale, opacity, and auto-hide thresholds.
- **Category-Adaptive Vehicle HUD**: 4 original dashboard presets (`cyber_digital`, `analog_classic`, `sport_gt`, `minimal_strip`) that adapt automatically to Cars, Motorcycles, Bicycles, Boats, Helicopters, and Airplanes.
- **NSR CarPlay Infotainment Tablet**: 6 built-in applications (Home, Native FM/Digital Radio, GPS Waypoint Navigation, Real-Time Vehicle Diagnostics, Cabin/Door/Window/Seat Controls with server-side driver authority checks, and Display Settings).
- **Drag-and-Drop HUD Studio (`/hud`)**: Interactive canvas dragging with X/Y center snap guides, per-widget property inspector, live Vehicle HUD preview, 6 global themes (`midnight`, `neon`, `minimal`, `sport`, `luxury`, `tactical`), and up to 5 named personal presets per player.
- **Multi-Tier Persistence**: Supports `oxmysql` (with auto-schema creation and import-ready `database/nsr_hud.sql`), server-side JSON storage (`data/player_profiles.json`), and client ResourceKvp backup.

## 3. Quick Start

1. Copy the `nsr-hud` folder into your server's `resources/` directory.
2. (Optional) If using `oxmysql`, import `database/nsr_hud.sql` or leave `Config.Persistence.AutoCreateTable = true` in `config.lua`.
3. Review `config.lua` to set `Config.Framework` (`'auto'`, `'qbcore'`, `'qbox'`, `'esx'`, or `'standalone'`) and `Config.Locale` (`'en'`, `'ar'`, `'fr'`, `'de'`, `'es'`, `'pt'`, `'tr'`, or `'it'`).
4. Add `ensure nsr-hud` to your `server.cfg` **after** your framework, database, voice, and fuel resources.

## 4. Default Commands & Keybinds

| Command | Default Key | Description |
| :--- | :--- | :--- |
| `/hud` | `F7` | Opens or closes the Drag-and-Drop NSR HUD Studio editor |
| `/togglehud` | *(Unbound)* | Toggles master HUD visibility on or off |
| `/vehiclehud` | *(Unbound)* | Opens the HUD Studio directly to the Vehicle HUD customization tab |
| `/carplay` | `U` | Opens or closes the NSR CarPlay infotainment system inside a vehicle |
| `/seatbelt` | `B` | Buckles or unbuckles the vehicle seatbelt |
| `/cruise` | `Y` | Locks or disengages the vehicle cruise-control speed limiter (Driver only) |
| `/resethud` | *(Unbound)* | Restores the player's HUD layout and colors to server defaults |
| `nsrhud_status` | *(Server Console)* | Prints active framework, locale, persistence provider, and cached profile count |

## 5. Documentation Index

- [Installation Guide](INSTALLATION.md) (`docs/INSTALLATION.md`)
- [Configuration Guide](docs/CONFIGURATION.md)
- [Framework Compatibility Guide](docs/FRAMEWORK_COMPATIBILITY.md)
- [Optional Integrations & Dependency Matrix](docs/INTEGRATIONS.md)
- [Localization & RTL Guide](docs/LOCALIZATION.md)
- [Troubleshooting & Performance Profiling](docs/TROUBLESHOOTING.md)
- [Feature & Compatibility Matrix](docs/COMPATIBILITY_MATRIX.md)
- [Database & Persistence Guide](database/README.md)
- [Custom Adapter Developer Guide](integrations/README.md)
