# NSR HUD Ultimate — Complete Configuration Reference (`config.lua`)

All normal customization of `nsr-hud` is performed inside `config.lua` without editing any frontend HTML, CSS, or JavaScript files.

## 1. Core Settings

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `Config.Framework` | `string` | `'auto'` | Framework selection: `'auto'`, `'qbcore'`, `'qbox'`, `'esx'`, or `'standalone'`. |
| `Config.Locale` | `string` | `'en'` | Language code: `'en'`, `'ar'`, `'fr'`, `'de'`, `'es'`, `'pt'`, `'tr'`, or `'it'`. Single source of truth for localization. |
| `Config.Debug` | `boolean` | `false` | Enables verbose diagnostic messages in client F8 and server console. |
| `Config.DefaultTheme` | `string` | `'midnight'` | Default theme preset for new players (`'midnight'`, `'neon'`, `'minimal'`, `'sport'`, `'luxury'`, `'tactical'`). |

## 2. Persistence Settings (`Config.Persistence`)

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `Provider` | `string` | `'auto'` | `'auto'`, `'oxmysql'`, `'json'`, or `'kvp'`. |
| `TableName` | `string` | `'nsr_hud_profiles'` | MySQL table name used when `oxmysql` is active. |
| `AutoCreateTable` | `boolean` | `true` | Runs `CREATE TABLE IF NOT EXISTS` automatically on startup. |
| `JsonFilePath` | `string` | `'data/player_profiles.json'` | Relative file path inside `nsr-hud` for JSON persistence. |
| `SaveCooldownMs` | `number` | `2000` | Minimum time in milliseconds between save requests from the same player. |
| `MaxPersonalPresets` | `number` | `5` | Maximum named layout presets each player can store. |

## 3. Player HUD Settings (`Config.PlayerHUD`)

- `Enabled` (`true`): Master switch for the Player HUD.
- `HideRadarOnFoot` (`false`): When `true`, hides the GTA V minimap while on foot and enables it when entering a vehicle.
- `HideNativeComponents` (`true`): Suppresses default GTA V cash, street name, area name, and vehicle name HUD elements every frame.
- `TimeSource` (`'game'`): `'game'` displays in-game GTA clock (`GetClockHours`/`GetClockMinutes`); `'real'` displays local real-world time.
- `CurrencySymbol` (`'$'`) & `CurrencyPosition` (`'prefix'` or `'suffix'`): Controls how Cash and Bank balances are formatted.
- `Widgets.<id>`: Configures default `enabled`, `style` (`'ring'`, `'bar'`, `'pill'`, `'hex'`, `'minimal'`), `x`, `y`, `scale`, `opacity`, `color`, `showIcon`, `showLabel`, `showValue`, and `autoHideAbove`/`autoHideBelow` for all 15 widgets.

## 4. Vehicle HUD Settings (`Config.Vehicle`)

- `Enabled` (`true`): Master switch for the Vehicle HUD.
- `AlwaysVisibleOnFoot` (`false`): Keep `false` so the Vehicle HUD only renders when the player is inside a vehicle.
- `SpeedUnit` (`'kmh'`): Default speed unit (`'kmh'` or `'mph'`).
- `DefaultPreset` (`'cyber_digital'`): Default dashboard style (`'cyber_digital'`, `'analog_classic'`, `'sport_gt'`, `'minimal_strip'`).
- `RedlineThreshold` (`0.82`): Normalized RPM value (`0.0`–`1.0`) where the redline shift indicator flashes.
- `Seatbelt`: Configures built-in seatbelt physics (`Enabled`, `PreventExitWhenBuckled`, `EjectSpeedThresholdKmh`, `MinDecelerationForEject`).
- `CruiseControl`: Configures built-in cruise control speed limiter (`Enabled`, `MinSpeedKmh`, `MaxSpeedKmh`).

## 5. CarPlay Settings (`Config.CarPlay` & `Config.NavigationLocations`)

- `Enabled` (`true`): Enables or disables the NSR CarPlay tablet (`/carplay` / `U`).
- `AllowPassengerAccess` (`true`): Allows passengers to open CarPlay to view telemetry, change radio stations, or set waypoints.
- `DriverOnlyControls` (`true`): Enforces driver-seat authority on both client and server for ignition, doors, locks, lights, hazards, and neon underglow.
- `Apps`: Individual booleans (`home`, `radio`, `navigation`, `telemetry`, `controls`, `settings`) allowing server owners to disable specific CarPlay applications.
- `Config.NavigationLocations`: Array of quick GPS destination presets (`id`, `labelKey`, `x`, `y`, `category`).

## 6. Performance Settings (`Config.Performance`)

- `AdaptiveUpdates` (`true`): Slows down player telemetry polling to `PlayerIdleInterval` (`800ms`) when player stats are unchanged.
- `PlayerUpdateInterval` (`250ms`): Active player HUD check interval.
- `VehicleUpdateInterval` (`60ms`): Active vehicle dashboard telemetry interval (sleeps at `650ms` when on foot).
- `VehicleSlowUpdateInterval` (`500ms`): Low-frequency checks for door angles, window states, tire bursts, locks, and license plate.
- `LocationUpdateInterval` (`600ms`): Street name, zone, compass, and clock refresh interval.
- `DeltaThreshold` (`0.5`): Minimum numeric delta required before sending a new NUI message payload.
