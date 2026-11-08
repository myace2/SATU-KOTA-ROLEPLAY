# NSR HUD Ultimate — Installation & Upgrade Guide

## 1. Folder Placement

1. Extract the `nsr-hud` directory into your FiveM server's `resources/` directory (for example, `resources/[nsr]/nsr-hud`).
2. Ensure the folder is named **`nsr-hud`** (matching the resource prefix and NUI callback origin).

## 2. Server Configuration (`server.cfg`)

Place `ensure nsr-hud` in your `server.cfg` **after** optional core dependencies so automatic detection can identify active resources on startup:

```cfg
# Core & Database (Optional — only if used by your server)
ensure oxmysql
ensure qb-core      # or qbx_core / es_extended

# Voice & Vehicle Systems (Optional)
ensure pma-voice
ensure LegacyFuel   # or ox_fuel / cdn-fuel / ps-fuel / qb-fuel

# NSR HUD Ultimate
ensure nsr-hud
```

> **Note:** Never install an optional dependency unless your server actually uses it. `nsr-hud` runs out-of-the-box on a pure Standalone server with zero external resources.

## 3. Framework Setup (`Config.Framework`)

Open `config.lua` and configure `Config.Framework`:

```lua
Config.Framework = 'auto' -- 'auto' | 'qbcore' | 'qbox' | 'esx' | 'standalone'
```

| Environment | Recommended Setting | Setup Notes |
| :--- | :--- | :--- |
| **QBCore (`qb-core`)** | `'auto'` or `'qbcore'` | Automatically reads cash, bank, job, grade, hunger, thirst, and stress from `QBCore.Functions.GetPlayerData()`. Disable `qb-hud` in `server.cfg` to prevent duplicate HUD overlays. |
| **Qbox (`qbx_core`)** | `'auto'` or `'qbox'` | Prioritizes `qbx_core` exports and player statebags (`LocalPlayer.state.hunger`, `thirst`, `stress`). Disable `qbx_hud` if installed. |
| **ESX Legacy (`es_extended`)** | `'auto'` or `'esx'` | Reads `money` and `bank` accounts, job/grade labels, and listens to `esx_status:onTick` for hunger, thirst, and stress. Disable `esx_hud` if installed. |
| **Standalone** | `'auto'` or `'standalone'` | Uses native GTA V/FiveM natives for Health, Armor, Stamina, Oxygen, Voice, Server ID, Street/Zone, Compass, Clock, Vehicle HUD, and CarPlay. Framework-only widgets (Cash, Bank, Job, Hunger, Thirst) are hidden automatically unless populated via statebags. |

## 4. Language Selection (`Config.Locale`)

Language is controlled **exclusively** through `config.lua`:

```lua
Config.Locale = 'en' -- 'en' | 'ar' | 'fr' | 'de' | 'es' | 'pt' | 'tr' | 'it'
```

- Setting `Config.Locale = 'ar'` switches all server notifications and NUI text to Arabic and automatically enables Right-to-Left (`dir="rtl"`) layout alignment.
- Players cannot override the server language in-game; there is no language selector in the NUI.

## 5. Persistence & SQL Setup (`Config.Persistence`)

Open `config.lua` and review `Config.Persistence`:

```lua
Config.Persistence = {
    Provider = 'auto', -- 'auto' | 'oxmysql' | 'json' | 'kvp'
    TableName = 'nsr_hud_profiles',
    AutoCreateTable = true
}
```

- **With `oxmysql`**: When `Provider = 'auto'` or `'oxmysql'` and `oxmysql` is started, `nsr-hud` automatically creates the `nsr_hud_profiles` table if `AutoCreateTable = true`. You can also manually import `database/nsr_hud.sql` using HeidiSQL, phpMyAdmin, or the MySQL CLI.
- **Without `oxmysql` (JSON / KVP Fallback)**: If `oxmysql` is not installed, `nsr-hud` automatically stores player profiles in `data/player_profiles.json` on the server and caches a backup in client ResourceKvp (`nsr_hud_profile_v1`). No SQL database is required.

## 6. Verifying the Installation

1. Start or restart your server (`refresh` followed by `ensure nsr-hud`).
2. Check the server console for the startup confirmation banner:
   ```text
   [NSR-HUD] NSR HUD Ultimate v1.0.0 initialized | Framework: <detected> | Locale: <code (LTR/RTL)> | Persistence: <provider>
   ```
3. Run `nsrhud_status` in the server console at any time to inspect the active adapter state.
4. In-game, type `/hud` (or press `F7`) to verify the Drag-and-Drop HUD Studio opens and saves layouts cleanly.

## 7. Updating Without Losing Saved Player Layouts

1. If using `oxmysql`, your player profiles live safely in the `nsr_hud_profiles` database table. Replace the `nsr-hud` files and preserve your customized `config.lua`.
2. If using the `json` persistence provider, back up `nsr-hud/data/player_profiles.json` before replacing the resource folder, then copy `data/player_profiles.json` back into the updated folder.
3. `shared/validation.lua` automatically migrates saved layouts when new widgets or properties are introduced in future versions.
