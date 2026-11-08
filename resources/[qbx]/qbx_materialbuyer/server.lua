local config = require 'config'

local GOVERNMENT_STASH = 'govermentstash'
local MAX_STASH_ITEM_COUNT = 10000
local itemLocks = {}

local function isNearBuyer(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local playerCoords = GetEntityCoords(ped)
    return #(playerCoords - config.location.coords) <= 5.0
end

local function getStashCount(itemName)
    return exports.ox_inventory:GetItemCount(GOVERNMENT_STASH, itemName) or 0
end

-- Client requests current Government stock when opening the buyer menu.
lib.callback.register('qbx_materialbuyer:server:getStock', function(src)
    if not isNearBuyer(src) then return nil end

    local stock = {}
    for itemName in pairs(config.prices) do
        local count = getStashCount(itemName)
        stock[itemName] = {
            count = count,
            remaining = math.max(0, MAX_STASH_ITEM_COUNT - count),
            limit = MAX_STASH_ITEM_COUNT,
        }
    end

    return stock
end)

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

    -- Serialize sales of the same material to prevent two players exceeding the cap.
    if itemLocks[itemName] then
        exports.qbx_core:Notify(src, 'Transaksi material ini sedang diproses. Coba lagi sebentar.', 'error')
        return
    end
    itemLocks[itemName] = true

    local ok, err = xpcall(function()
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return end

        local currentAmount = getStashCount(itemName)
        local remaining = math.max(0, MAX_STASH_ITEM_COUNT - currentAmount)
        if amount > remaining then
            local itemData = exports.ox_inventory:Items(itemName)
            local itemLabel = itemData and itemData.label or itemName

            exports.qbx_core:Notify(
                src,
                remaining > 0
                    and ('Sisa kapasitas %s di Stash Government hanya %s item.'):format(itemLabel, remaining)
                    or ('Stok %s di Stash Government sudah mencapai batas 10.000 item.'):format(itemLabel),
                'error'
            )
            return
        end

        local removed = exports.ox_inventory:RemoveItem(src, itemName, amount)
        if not removed then
            exports.qbx_core:Notify(src, 'Material tidak cukup di inventory.', 'error')
            return
        end

        local stored, response = exports.ox_inventory:AddItem(GOVERNMENT_STASH, itemName, amount)
        if not stored then
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
    end, debug.traceback)

    itemLocks[itemName] = nil

    if not ok then
        print(('[qbx_materialbuyer] Sale error for player %s, item %s: %s'):format(src, itemName, tostring(err)))
        exports.qbx_core:Notify(src, 'Terjadi kesalahan saat memproses transaksi. Hubungi staff jika material terpotong.', 'error')
    end
end)
