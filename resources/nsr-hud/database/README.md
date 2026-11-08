# NSR HUD Ultimate — Database & Persistence Guide

`nsr-hud` supports three persistence modes configured via `Config.Persistence.Provider` in `config.lua`:

## 1. Provider Comparison & Trade-Offs

| Provider | Config Value | External Dependency | Storage Location | Advantages & Trade-Offs |
| :--- | :--- | :--- | :--- | :--- |
| **Auto (Default)** | `'auto'` | None (uses `oxmysql` if started) | SQL table or JSON fallback | Automatically selects `oxmysql` when present and falls back to server JSON storage if `oxmysql` is absent or offline. |
| **MySQL (`oxmysql`)** | `'oxmysql'` | `oxmysql` | MySQL table `nsr_hud_profiles` | **Recommended for production roleplay servers.** Scales to thousands of players, supports centralized database backups, and survives server migrations. |
| **Server JSON** | `'json'` | None | `nsr-hud/data/player_profiles.json` | **Zero-dependency server storage.** Ideal for Standalone servers without MySQL. Cached in memory and flushed periodically (every 15s when dirty and on `onResourceStop`). |
| **Client KVP** | `'kvp'` | None | Client CitizenFX `ResourceKvp` | Stored locally on each player's machine (`nsr_hud_profile_v1`) and validated by the server. Zero server disk usage, though layouts do not roam if a player switches PCs. |

## 2. SQL Schema Setup (`oxmysql`)

When `Config.Persistence.AutoCreateTable = true` (default), `server/persistence.lua` automatically executes `CREATE TABLE IF NOT EXISTS nsr_hud_profiles` on startup.

If your MySQL user does not have `CREATE TABLE` privileges, import [`database/nsr_hud.sql`](nsr_hud.sql) manually:

```sql
CREATE TABLE IF NOT EXISTS `nsr_hud_profiles` (
    `identifier` VARCHAR(96) NOT NULL,
    `profile_json` LONGTEXT NOT NULL,
    `schema_version` INT NOT NULL DEFAULT 1,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`),
    INDEX `idx_nsr_hud_updated` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## 3. Security & Rate-Limiting

- **Server-Resolved Identifiers**: The server resolves player identifiers using framework CitizenID/Identifier (`citizenid:...` or `esx:...`) or hardware/account license (`license2:`, `license:`, `fivem:`, `steam:`). Client-supplied identifiers are never accepted.
- **Anti-Spam Cooldown**: Save requests are rate-limited per player source (`Config.Persistence.SaveCooldownMs = 2000` ms).
- **Schema Validation**: Every saved profile passes through `NSRValidation.SanitizeProfile()` on both client and server before storage, clamping coordinates (`0`–`96%`), scale (`0.5`–`2.0`), opacity (`0.1`–`1.0`), and stripping unknown fields.
