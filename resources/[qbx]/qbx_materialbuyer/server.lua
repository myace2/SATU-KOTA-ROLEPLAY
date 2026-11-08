local config = require 'config'

local GOVERNMENT_STASH = 'govermentstash'

local function isNearBuyer(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local playerCoords = GetEntityCoords(ped)
    return #(playerCoords - config.location.coords) <= 5.0
end

RegisterNetEvent('qbx_materialbuyer:server:sellItem', function(itemName, amount)
    local src = source

    if type(itemName) ~= 'string' or type(amount) ~= 'number'
        or math.type(amount) ~= 'integer'
        or amount < 1 or amount > config.maxSellAmount then
        return
    end

    local unitPrice = config.prices[itemName]
    if not unitPrice or unitPrice < 1 then return end

    if not isNearBuyer(src) then
        print(('[qbx_materialbuyer] Blocked out-of-range sale from player %s'):format(src))
        return
    end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    -- Remove the material from the player first.
    local removed = exports.ox_inventory:RemoveItem(src, itemName, amount)
    if not removed then
        exports.qbx_core:Notify(src, 'Material tidak cukup di inventory.', 'error')
        return
    end

    -- Store the sold material in the existing Government stash.
    local stored, response = exports.ox_inventory:AddItem(GOVERNMENT_STASH, itemName, amount)

    if not stored then
        -- Refund the material if the Government stash cannot accept it.
        local refunded = exports.ox_inventory:AddItem(src, itemName, amount)

        print(('[qbx_materialbuyer] Failed to store %sx %s in %s for player %s. Stash response: %s. Refunded: %s')
            :format(amount, itemName, GOVERNMENT_STASH, src, tostring(response), tostring(refunded)))

        exports.qbx_core:Notify(
            src,
            refunded and 'Stash Government penuh/tidak tersedia. Material dikembalikan, transaksi dibatalkan.'
                or 'Stash Government gagal menerima material dan pengembalian inventory juga gagal. Hubungi staff.',
            'error'
        )
        return
    end

    -- Pay the player only after the material is safely stored.
    local totalPrice = unitPrice * amount
    player.Functions.AddMoney('cash', totalPrice, 'material-buyer-sale')

    local itemData = exports.ox_inventory:Items(itemName)
    local itemLabel = itemData and itemData.label or itemName

    exports.qbx_core:Notify(
        src,
        ('Berhasil menjual %sx %s. Kamu menerima $%s cash. Material masuk ke Stash Government.'):format(
            amount, itemLabel, totalPrice
        ),
        'success'
    )
end)
