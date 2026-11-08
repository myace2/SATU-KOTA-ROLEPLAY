# NSR HUD Ultimate — Optional Integrations & Dependency Matrix

The base HUD does **not** require any third-party resource. Every integration is wrapped in resource-state checks (`GetResourceState`) and `pcall` guards inside `bridge/*.lua`.

## 1. Complete Integration Matrix

| Category | Supported Resource | Built-in or Optional | Detection Method (`auto`) | Functionality Added | Fallback if Missing | Config Switch |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Framework** | `qbx_core` | Optional | `GetResourceState('qbx_core')` | Cash, Bank, Job, Needs, CitizenID persistence | Falls back to `qb-core` / `esx` / `standalone` | `Config.Framework = 'qbox'` |
| **Framework** | `qb-core` | Optional | `GetResourceState('qb-core')` | Cash, Bank, Job, Metadata Needs, CitizenID | Falls back to `standalone` | `Config.Framework = 'qbcore'` |
| **Framework** | `es_extended` | Optional | `GetResourceState('es_extended')` | Cash, Bank, Job, `esx_status`, ESX Identifier | Falls back to `standalone` | `Config.Framework = 'esx'` |
| **Database** | `oxmysql` | Optional | `GetResourceState('oxmysql')` | Stores player profiles in MySQL `nsr_hud_profiles` | Server JSON file (`data/player_profiles.json`) + KVP | `Config.Persistence.Provider = 'oxmysql'` |
| **Voice** | `pma-voice` | Optional | `GetResourceState('pma-voice')` | Proximity mode (`Whisper`/`Normal`/`Shout`), Radio channel & active TX | Native `NetworkIsPlayerTalking` | `Config.Integrations.Voice = 'pma-voice'` |
| **Voice** | `saltychat` | Optional | `GetResourceState('saltychat')` | Talk state, voice range index, radio traffic state | Native `NetworkIsPlayerTalking` | `Config.Integrations.Voice = 'saltychat'` |
| **Voice** | `mumble-voip` | Optional | `GetResourceState('mumble-voip')` | Native Mumble talking state & proximity | Native `NetworkIsPlayerTalking` | `Config.Integrations.Voice = 'mumble-voip'` |
| **Fuel** | `ox_fuel` | Optional | `GetResourceState('ox_fuel')` | Reads `Entity(veh).state.fuel` | Native `GetVehicleFuelLevel(veh)` | `Config.Integrations.Fuel = 'ox_fuel'` |
| **Fuel** | `LegacyFuel` | Optional | `GetResourceState('LegacyFuel')` | Calls `exports['LegacyFuel']:GetFuel(veh)` | Native `GetVehicleFuelLevel(veh)` | `Config.Integrations.Fuel = 'LegacyFuel'` |
| **Fuel** | `cdn-fuel` | Optional | `GetResourceState('cdn-fuel')` | Calls `exports['cdn-fuel']:GetFuel(veh)` | Native `GetVehicleFuelLevel(veh)` | `Config.Integrations.Fuel = 'cdn-fuel'` |
| **Fuel** | `ps-fuel` | Optional | `GetResourceState('ps-fuel')` | Calls `exports['ps-fuel']:GetFuel(veh)` | Native `GetVehicleFuelLevel(veh)` | `Config.Integrations.Fuel = 'ps-fuel'` |
| **Fuel** | `qb-fuel` | Optional | `GetResourceState('qb-fuel')` | Calls `exports['qb-fuel']:GetFuel(veh)` | Native `GetVehicleFuelLevel(veh)` | `Config.Integrations.Fuel = 'qb-fuel'` |
| **Seatbelt** | Built-in / `qbx_seatbelt` / `qb-smallresources` | Built-in + Optional | `GetResourceState` + `LocalPlayer.state.seatbelt` | Buckled status, exit block when buckled, windshield ejection protection | Uses built-in seatbelt physics (`bridge/seatbelt.lua`) | `Config.Integrations.Seatbelt = 'auto'` |
| **Nitro** | Entity Statebag / `qb-mechanicjob` | Optional | `Entity(veh).state.nitro` / `hud:client:UpdateNitrous` | Displays nitro percentage bar & active boost state | Nitro bar automatically hidden | `Config.Integrations.Nitro = 'auto'` |
| **Vehicle Keys** | `qbx_vehiclekeys` / `qb-vehiclekeys` / `qs-vehiclekeys` / `wasabi_carlock` | Built-in + Optional | `GetResourceState` + `GetVehicleDoorLockStatus` | Reads lock status & toggles central lock in CarPlay | Uses native `SetVehicleDoorsLocked` | `Config.Integrations.VehicleKeys = 'auto'` |

## 2. Adding Custom Integrations

See [`integrations/README.md`](../integrations/README.md) and the ready-to-use templates in [`integrations/examples/`](../integrations/examples/) for registering custom framework, fuel, or status providers without modifying core HUD files.
