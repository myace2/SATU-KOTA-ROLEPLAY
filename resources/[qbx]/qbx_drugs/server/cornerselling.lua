local config = require 'config.server'
local cornerOffers = {}
local stolenItems = {}
local cornerLocks = {}

-- Semua gang boleh melakukan corner selling, tetapi player tanpa gang tidak boleh.
local function isGangMember(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end

    local gangName = player.PlayerData.gang and player.PlayerData.gang.name
    return type(gangName) == 'string' and gangName ~= '' and gangName:lower() ~= 'none'
end

local function notifyGangRequired(source)
    exports.qbx_core:Notify(source, 'Corner Selling hanya dapat digunakan oleh anggota gang.', 'error')
end

local function getAvailableDrugs(source)
    local availableDrugs = {}
    local player = exports.qbx_core:GetPlayer(source)

    if not player then return nil end

    for i = 1, #config.cornerSellingDrugsList do
        local itemName = config.cornerSellingDrugsList[i]
        local itemCount = exports.ox_inventory:Search(source, 'count', itemName)
        if itemCount > 0 then
            availableDrugs[#availableDrugs + 1] = {
                item = itemName,
                amount = itemCount,
                label = exports.ox_inventory:Items()[itemName].label
            }
        end
    end
    return table.type(availableDrugs) ~= 'empty' and availableDrugs or nil
end

lib.callback.register('qb-drugs:server:getDrugOffer', function(source)
    if not isGangMember(source) then
        notifyGangRequired(source)
        return nil
    end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then return nil end
    local availableDrugs = getAvailableDrugs(player.PlayerData.source)
    if availableDrugs == nil then return nil end

    local randomDrug = math.random(1, #availableDrugs)
    local chosenDrug = availableDrugs[randomDrug]
    local offeredAmount = math.random(1, chosenDrug.amount > 15 and 15 or chosenDrug.amount)
    local basePrice = math.random(config.cornerSellingDrugsPrice[chosenDrug.item].min, config.cornerSellingDrugsPrice[chosenDrug.item].max)
    local totalPrice = config.scamChance >= math.random(1, 100) and basePrice * offeredAmount or math.random(3, 10) * offeredAmount

    cornerOffers[source] = {
        item = chosenDrug.item,
        amount = offeredAmount,
        total = totalPrice,
        expiresAt = os.time() + 60,
    }

    return { chosen = chosenDrug, idx = randomDrug, amount = offeredAmount, total = totalPrice }
end)

RegisterNetEvent('qb-drugs:server:giveStealItems', function()
    local src = source
    if not isGangMember(src) then
        stolenItems[src] = nil
        notifyGangRequired(src)
        return
    end

    local stolen = stolenItems[src]
    stolenItems[src] = nil
    if not stolen or stolen.expiresAt < os.time() then return end

    exports.ox_inventory:AddItem(src, stolen.item, stolen.amount)
end)

RegisterNetEvent('qb-drugs:server:sellCornerDrugs', function()
    local src = source
    if not isGangMember(src) then
        cornerOffers[src] = nil
        notifyGangRequired(src)
        return
    end
    if cornerLocks[src] then return end
    cornerLocks[src] = true

    local player = exports.qbx_core:GetPlayer(src)
    local offer = cornerOffers[src]
    cornerOffers[src] = nil
    if player and offer and offer.expiresAt >= os.time()
        and exports.ox_inventory:GetItemCount(src, offer.item) >= offer.amount
        and exports.ox_inventory:RemoveItem(src, offer.item, offer.amount) then
        if exports.ox_inventory:AddItem(src, 'black_money', offer.total) then
            exports.qbx_core:Notify(src, locale('success.offer_accepted'), 'success')
            if config.policeCallChance >= math.random(1, 100) then
                TriggerEvent('police:server:policeAlert', locale('info.possible_drug_dealing'), nil, src)
            end
        else
            exports.ox_inventory:AddItem(src, offer.item, offer.amount)
            exports.qbx_core:Notify(src, locale('error.item_unavailable'), 'error')
        end
    elseif player then
        TriggerClientEvent('qb-drugs:client:cornerselling', src)
    end

    cornerLocks[src] = nil
end)

RegisterNetEvent('qb-drugs:server:robCornerDrugs', function()
    local src = source
    if not isGangMember(src) then
        cornerOffers[src] = nil
        notifyGangRequired(src)
        return
    end
    if cornerLocks[src] then return end
    cornerLocks[src] = true

    local player = exports.qbx_core:GetPlayer(src)
    local offer = cornerOffers[src]
    cornerOffers[src] = nil
    if player and offer and offer.expiresAt >= os.time()
        and exports.ox_inventory:RemoveItem(src, offer.item, offer.amount) then
        stolenItems[src] = {
            item = offer.item,
            amount = offer.amount,
            expiresAt = os.time() + 600,
        }
    end

    cornerLocks[src] = nil
end)

AddEventHandler('playerDropped', function()
    cornerOffers[source] = nil
    stolenItems[source] = nil
    cornerLocks[source] = nil
end)
