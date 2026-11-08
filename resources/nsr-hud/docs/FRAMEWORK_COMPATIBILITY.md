# NSR HUD Ultimate — Framework Compatibility Guide

`nsr-hud` isolates all framework-specific code inside [`bridge/framework.lua`](../bridge/framework.lua). No framework exports or events are scattered across the HUD rendering or NUI scripts.

## 1. Automatic Detection Order (`Config.Framework = 'auto'`)

When `Config.Framework = 'auto'`, `NSRFramework.Initialize()` inspects running resources in the following order:

1. **Qbox (`qbx_core`)**: Checked **first** because `qbx_core` frequently provides a backwards-compatible `qb-core` bridge. Checking `qbx_core` first ensures native Qbox exports and statebags are used.
2. **QBCore (`qb-core`)**: Checked second via `GetResourceState('qb-core')`.
3. **ESX Legacy (`es_extended`)**: Checked third via `GetResourceState('es_extended')`.
4. **Standalone (`standalone`)**: Activated automatically if no framework is started or if an invalid framework name is configured.

## 2. Widget Behavior by Framework

| Widget ID | QBCore (`qb-core`) | Qbox (`qbx_core`) | ESX Legacy (`es_extended`) | Standalone (`standalone`) |
| :--- | :--- | :--- | :--- | :--- |
| `health` | Native GTA Ped Health | Native GTA Ped Health | Native GTA Ped Health | Native GTA Ped Health |
| `armor` | Native GTA Ped Armor | Native GTA Ped Armor | Native GTA Ped Armor | Native GTA Ped Armor |
| `stamina` | Native Sprint Stamina | Native Sprint Stamina | Native Sprint Stamina | Native Sprint Stamina |
| `oxygen` | Native Underwater Time | Native Underwater Time | Native Underwater Time | Native Underwater Time |
| `voice` | `bridge/voice.lua` | `bridge/voice.lua` | `bridge/voice.lua` | `bridge/voice.lua` |
| `playerid` | `GetPlayerServerId` | `GetPlayerServerId` | `GetPlayerServerId` | `GetPlayerServerId` |
| `compass` | Native Heading | Native Heading | Native Heading | Native Heading |
| `location` | Native Street & Zone | Native Street & Zone | Native Street & Zone | Native Street & Zone |
| `clock` | Game or Local Clock | Game or Local Clock | Game or Local Clock | Game or Local Clock |
| `hunger` | `metadata.hunger` / `UpdateNeeds` | `LocalPlayer.state.hunger` / `metadata` | `esx_status:onTick` (`hunger`) | Hidden unless set on `LocalPlayer.state.hunger` |
| `thirst` | `metadata.thirst` / `UpdateNeeds` | `LocalPlayer.state.thirst` / `metadata` | `esx_status:onTick` (`thirst`) | Hidden unless set on `LocalPlayer.state.thirst` |
| `stress` | `metadata.stress` / `UpdateStress` | `LocalPlayer.state.stress` / `metadata` | `esx_status:onTick` (`stress`) | Hidden unless set on `LocalPlayer.state.stress` |
| `cash` | `PlayerData.money.cash` | `PlayerData.money.cash` | Account `money` | Hidden unless set on `LocalPlayer.state.cash` |
| `bank` | `PlayerData.money.bank` | `PlayerData.money.bank` | Account `bank` | Hidden unless set on `LocalPlayer.state.bank` |
| `job` | `PlayerData.job.label` + `grade.name` | `PlayerData.job.label` + `grade.name` | `xPlayer.job.label` + `grade_label` | Hidden automatically (no fake job shown) |

## 3. Standalone Mode Guarantee

In `standalone` mode, `nsr-hud` never fabricates player balances, jobs, or hunger/thirst percentages. Widgets whose underlying framework data is `nil` return `available = false` and are automatically hidden during gameplay (while still remaining visible in `/hud` Studio if the server owner or player wishes to position them).
