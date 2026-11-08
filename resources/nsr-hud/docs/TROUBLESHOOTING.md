# NSR HUD Ultimate — Troubleshooting & Performance Profiling Guide

## 1. Checking Resource Performance with FiveM Profiler (`resmon`)

1. Open the FiveM client console (`F8`).
2. Type `resmon 1` to open the real-time Resource Monitor.
3. Locate `nsr-hud` in the list:
   - **On foot (idle)**: The Vehicle HUD loop sleeps at `650ms` and the Player HUD loop adapts between `250ms` and `800ms` using delta compression (`NSRUtils.HasChanged`), avoiding redundant `SendNUIMessage` calls when player stats are static.
   - **In vehicle**: The Vehicle HUD telemetry loop runs at `Config.Performance.VehicleUpdateInterval` (`60ms` default) while slow-changing properties (doors, windows, locks, lights, tires) are cached and polled only every `500ms` (`VehicleSlowUpdateInterval`).
4. To record a detailed CPU trace in FiveM:
   ```text
   profiler record 500
   profiler view
   ```

## 2. Diagnostic Commands & Debug Mode

- **Server Console Status Check**: Run `nsrhud_status` in the server console to display the active version, detected framework, active locale, active persistence provider, and number of cached player profiles.
- **Verbose Debug Logging**: Set `Config.Debug = true` in `config.lua` and restart `nsr-hud` to see adapter detection logs in F8 and the server console.

## 3. Common Issues & Solutions

### Issue: Default GTA V or Framework HUD is still visible alongside NSR HUD
- **Cause**: Your server is still running `qb-hud`, `qbx_hud`, or `esx_hud`.
- **Solution**: Comment out or remove `ensure qb-hud` / `ensure qbx_hud` / `ensure esx_hud` in your `server.cfg`, and verify `Config.PlayerHUD.HideNativeComponents = true` in `config.lua`.

### Issue: Hunger, Thirst, Cash, Bank, or Job widgets are hidden
- **Cause**: The server is running in `standalone` mode or the player has not completed character selection yet.
- **Solution**: Run `nsrhud_status` in the server console. If it reports `Framework: standalone` on a QBCore/Qbox/ESX server, ensure `ensure nsr-hud` is placed **after** your framework in `server.cfg`, or explicitly set `Config.Framework = 'qbcore'` (or `'qbox'` / `'esx'`) in `config.lua`.

### Issue: Player is stuck with mouse cursor on screen after resource restart
- **Cause**: Force-restarting a resource while a modal is open in older scripts can leave NUI focus active.
- **Solution**: `nsr-hud` includes an `onResourceStop` cleanup handler that automatically executes `SetNuiFocus(false, false)`. Players can also press `Escape` or run `/hud` to release focus cleanly.
