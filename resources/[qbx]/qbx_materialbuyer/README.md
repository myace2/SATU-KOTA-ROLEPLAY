# QBX Material Buyer

Standalone material-selling point for Qbox + ox_inventory + ox_target.

## Dependencies

- qbx_core
- ox_lib
- ox_inventory
- ox_target

## Installation

1. Place this resource at `resources/[qbx]/qbx_materialbuyer`.
2. Ensure dependencies start before this resource.
3. Add `ensure qbx_materialbuyer` to server.cfg after ox_target and qbx_core.
4. Restart the server or run `refresh` then `ensure qbx_materialbuyer`.

## Configuration

Edit `config.lua`:

- `location.coords`: ox_target sale-zone position.
- `location.size`: interaction-zone size.
- `prices`: cash price per item.
- `maxSellAmount`: maximum items per transaction.
- `blip`: map marker settings.

Default location is the existing scrapyard delivery area: vec3(2351.5, 3132.96, 48.2).

Default sale prices:
- metalscrap: $8
- iron: $12
- steel: $18
- copper: $15
- aluminum: $10
- plastic: $5
- rubber: $6
- glass: $4

The server validates the item allowlist, integer quantity, maximum quantity, player proximity, and inventory removal before paying cash.
