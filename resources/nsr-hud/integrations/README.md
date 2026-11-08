# NSR HUD Ultimate — Custom Integration Developer Guide

`nsr-hud` is architected so developers can add support for custom frameworks, custom fuel resources, or custom status systems without modifying the core HUD logic.

## 1. Registering a Custom Framework Adapter

Use `NSRFramework.RegisterAdapter(name, definition)` in a shared or client/server script loaded before `client/main.lua`:

- See [`examples/custom_framework_adapter.lua`](examples/custom_framework_adapter.lua) for a complete working template.

## 2. Registering a Custom Fuel Adapter

Use `NSRFuel.RegisterAdapter(name, checkFn, getterFn)` on the client:

- See [`examples/custom_fuel_adapter.lua`](examples/custom_fuel_adapter.lua) for a complete working template.

## 3. Feeding Custom Status Data in Standalone Mode

In `standalone` mode, any script can populate `hunger`, `thirst`, `stress`, `cash`, or `bank` by setting player statebags:

- See [`examples/custom_status_integration.lua`](examples/custom_status_integration.lua) for a complete working template.
