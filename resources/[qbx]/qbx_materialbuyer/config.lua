return {
    -- Default location: scrapyard area. Change coords to move the buyer.
    location = {
        coords = vec3(2351.5, 3132.96, 48.2),
        size = vec3(2.0, 2.0, 2.0),
        rotation = 0.0,
        distance = 2.0,
        debug = false,
    },

    -- Prices are paid per item in cash. Adjust these values as desired.
    prices = {
        metalscrap = 8,
        iron = 12,
        steel = 18,
        copper = 15,
        aluminum = 10,
        plastic = 5,
        rubber = 6,
        glass = 4,
    },

    maxSellAmount = 1000,

    blip = {
        enabled = true,
        coords = vec3(2351.5, 3132.96, 48.2),
        sprite = 365,
        color = 5,
        scale = 0.75,
        label = 'Material Buyer',
    },
}
