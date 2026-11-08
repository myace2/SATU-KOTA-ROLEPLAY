# NSR HUD Ultimate — Complete Feature & Compatibility Matrix

## 1. Subsystem Support Across Environments

| Subsystem / Feature | QBCore (`qb-core`) | Qbox (`qbx_core`) | ESX Legacy (`es_extended`) | Standalone (`standalone`) | Implementation Status |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Health, Armor, Stamina, Oxygen** | Full | Full | Full | Full | Implemented (`client/modules/health.lua`) |
| **Hunger & Thirst** | Full | Full | Full (`esx_status`) | Optional via StateBag | Implemented (`bridge/framework.lua`) |
| **Stress Indicator** | Full | Full | Full (`esx_status`) | Optional via StateBag | Implemented (`client/modules/status.lua`) |
| **Voice Proximity & Radio** | Full | Full | Full | Full | Implemented (`bridge/voice.lua`) |
| **Cash & Bank Balances** | Full | Full | Full | Optional via StateBag | Implemented (`client/modules/money.lua`) |
| **Job & Grade Display** | Full | Full | Full | Auto-Hidden | Implemented (`client/modules/job.lua`) |
| **Compass, Street, Zone, Clock** | Full | Full | Full | Full | Implemented (`client/player_hud.lua`) |
| **Vehicle HUD (4 Presets)** | Full | Full | Full | Full | Implemented (`html/js/vehicle-hud.js`) |
| **Vehicle Categories (Car/Bike/Boat/Air)** | Full | Full | Full | Full | Implemented (`client/modules/vehicle.lua`) |
| **Seatbelt System & Ejection Guard** | Full | Full | Full | Full | Implemented (`bridge/seatbelt.lua`) |
| **Cruise Control Speed Limiter** | Full | Full | Full | Full | Implemented (`client/vehicle_hud.lua`) |
| **NSR CarPlay (6 Apps)** | Full | Full | Full | Full | Implemented (`client/carplay.lua`, `html/js/carplay.js`) |
| **Drag-and-Drop HUD Studio (`/hud`)** | Full | Full | Full | Full | Implemented (`client/hud_editor.lua`, `html/js/editor.js`) |
| **6 Original Theme Presets** | Full | Full | Full | Full | Implemented (`html/css/themes.css`) |
| **8 Languages + Arabic RTL** | Full | Full | Full | Full | Implemented (`locales/*.lua`, `shared/locale.lua`) |
| **MySQL (`oxmysql`) Persistence** | Full | Full | Full | Full | Implemented (`server/persistence.lua`) |
| **JSON & KVP Fallback Persistence** | Full | Full | Full | Full | Implemented (`server/persistence.lua`, `client/main.lua`) |

## 2. Security & Validation Boundaries

| Operation | Client Validation | Server Authority Check | Rate-Limited |
| :--- | :---: | :---: | :---: |
| Save HUD Profile & Presets | `NSRPersistenceUI.sanitizeProfile` | `NSRValidation.SanitizeProfile` + Server Identifier Lookup | Yes (`2000ms` cooldown) |
| Reset HUD Profile | `NSRPersistenceUI` | `NSRPersistence.ResetPlayerProfile` | Yes (`2000ms` cooldown) |
| CarPlay Mechanical / Door / Lock Controls | `isDriver` seat check | `GetPedInVehicleSeat(veh, -1) == GetPlayerPed(src)` | Yes (Event validation) |
| CarPlay Radio & GPS Waypoint | Native GTA V Client API | Client-only (non-sensitive local state) | N/A |
