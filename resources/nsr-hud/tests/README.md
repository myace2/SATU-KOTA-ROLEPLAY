# NSR HUD Ultimate — Automated Validation & Testing Guide

This directory contains automated static and behavioral verification suites for `nsr-hud`, as well as the live FiveM server acceptance checklist.

## 1. Automated Tests Executed Offline

1. **Static & Architectural Validator (`tests/validate_resource.py`)**:
   - Run with: `python3 tests/validate_resource.py`
   - Verifies that all 50+ files declared in `fxmanifest.lua` exist on disk and are non-empty.
   - Verifies balanced Lua blocks (`function`/`if`/`do` vs `end`), parentheses, and braces across all 27 `.lua` files.
   - Verifies 100% localization key parity across all 8 language files (`en`, `ar`, `fr`, `de`, `es`, `pt`, `tr`, `it` — 239 keys each) and ensures every `data-i18n` attribute in `html/index.html` maps to a registered key.
   - Verifies that zero language selectors exist in the NUI (`Config.Locale` is the single source of truth).
   - Verifies zero external CDN/font/image URLs exist in `html/`.
   - Verifies that framework exports (`qbx_core`, `qb-core`, `es_extended`) are strictly isolated inside `bridge/framework.lua`.

2. **JavaScript Syntax & Runtime Behavioral Suite (`tests/test_nui_runtime.js`)**:
   - Run with: `node tests/test_nui_runtime.js`
   - Verifies `node --check` syntax across all 8 NUI JavaScript modules.
   - Tests `NSRLocaleUI.init()` for both English (`dir="ltr"`) and Arabic (`dir="rtl"`, `.rtl-layout` class, parameter interpolation, currency formatting).
   - Tests `NSRPersistenceUI.sanitizeProfile()` against out-of-bounds coordinates, invalid scales, unknown widget styles, and malformed color strings.

## 2. Live FiveM Server Acceptance Checklist

When deploying onto a live FiveM FXServer instance, verify the following runtime interactions:

- [ ] **Startup Banner**: Confirm `[NSR-HUD] NSR HUD Ultimate v1.0.0 initialized` prints in server console with expected Framework, Locale, and Persistence provider.
- [ ] **Player HUD Transitions**: Confirm Health, Armor, Stamina, Oxygen (when underwater), Voice talking ring, Street/Zone, Compass, and Clock update smoothly.
- [ ] **Vehicle Entry & Categories**: Enter a Car, Motorcycle, Bicycle, Boat, Helicopter, and Plane to verify category-adaptive Vehicle HUD rendering and smooth hide on exit.
- [ ] **NSR CarPlay (`/carplay` or `U`)**: Verify Radio station switching, GPS Waypoint setting on the pause map, and driver-only authority enforcement when a passenger clicks door/engine controls.
- [ ] **HUD Studio (`/hud` or `F7`)**: Drag widgets, test center X/Y snap guides, save a named preset, and reconnect or `restart nsr-hud` to confirm layout persistence.
