local config = require 'config'

local GOVERNMENT_STASH = 'govermentstash'
local MAX_STASH_ITEM_COUNT = 10000
local HISTORY_TABLE = 'qbx_materialbuyer_history'
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

local function createHistoryTable()
    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            `player_id` INT NOT NULL,
            `citizenid` VARCHAR(50) NOT NULL,
            `player_name` VARCHAR(100) NOT NULL,
            `item_name` VARCHAR(100) NOT NULL,
            `item_label` VARCHAR(100) NOT NULL,
            `amount` INT UNSIGNED NOT NULL,
            `unit_price` INT UNSIGNED NOT NULL,
            `total_price` BIGINT UNSIGNED NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_created_at` (`created_at`),
            INDEX `idx_citizenid` (`citizenid`),
            INDEX `idx_item_name` (`item_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]):format(HISTORY_TABLE))
end

CreateThread(function()
    local ok, err = pcall(createHistoryTable)
    if not ok then
        print(('[qbx_materialbuyer] Failed to create transaction history table: %s'):format(tostring(err)))
    else
        print(('[qbx_materialbuyer] Transaction history table %s is ready.'):format(HISTORY_TABLE))
    end
end)

local function saveTransaction(src, player, itemName, itemLabel, amount, unitPrice, totalPrice)
    local charinfo = player.PlayerData.charinfo or {}
    local firstName = charinfo.firstname or ''
    local lastName = charinfo.lastname or ''
    local characterName = (firstName .. ' ' .. lastName):gsub('^%s*(.-)%s*$', '%1')

    if characterName == '' then
        characterName = GetPlayerName(src) or ('Player %s'):format(src)
    end

    local ok, result = pcall(function()
        return MySQL.insert.await(
            ('INSERT INTO `%s` (player_id, citizenid, player_name, item_name, item_label, amount, unit_price, total_price) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'):format(HISTORY_TABLE),
            {
                src,
                player.PlayerData.citizenid or 'unknown',
                characterName,
                itemName,
                itemLabel,
                amount,
                unitPrice,
                totalPrice,
            }
        )
    end)

    if not ok then
        print(('[qbx_materialbuyer] Could not save transaction history for player %s: %s'):format(src, tostring(result)))
    end
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
        saveTransaction(src, player, itemName, itemLabel, amount, unitPrice, totalPrice)

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

-- Admin-only command. Access is controlled by the group.admin ACE principal.
lib.addCommand('materialhistory', {
    help = 'Lihat 25 transaksi Material Buyer terbaru',
    restricted = 'group.admin',
}, function(source)
    local rows = MySQL.query.await(
        ('SELECT id, player_id, citizenid, player_name, item_name, item_label, amount, unit_price, total_price, DATE_FORMAT(created_at, "%%d-%%m-%%Y %%H:%%i:%%s") AS created_at FROM `%s` ORDER BY id DESC LIMIT 25'):format(HISTORY_TABLE)
    ) or {}

    if source == 0 then
        print(('[qbx_materialbuyer] Found %s recent transactions.'):format(#rows))
        for i = 1, #rows do
            local row = rows[i]
            print(('#%s | %s (ID %s) | %sx %s | $%s | %s'):format(
                row.id, row.player_name, row.player_id, row.amount, row.item_label, row.total_price, row.created_at
            ))
        end
        return
    end

    TriggerClientEvent('qbx_materialbuyer:client:showHistory', source, rows)
end)
