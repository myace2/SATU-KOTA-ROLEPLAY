local config = require 'config'
local buyerPed

local function openSellMenu()
    local stock = lib.callback.await('qbx_materialbuyer:server:getStock', false)
    if not stock then
        lib.notify({
            title = 'Material Buyer',
            description = 'Tidak dapat mengambil data stok Government. Pastikan kamu berada di dekat NPC.',
            type = 'error',
        })
        return
    end

    local inventory = exports.ox_inventory:GetPlayerItems()
    local options = {}

    for _, item in pairs(inventory or {}) do
        local price = config.prices[item.name]
        local count = item.count or item.amount or 0
        local itemStock = stock[item.name]

        if price and count > 0 and itemStock then
            local remaining = itemStock.remaining
            local sellLimit = math.min(count, config.maxSellAmount, remaining)
            local isFull = remaining <= 0

            options[#options + 1] = {
                title = item.label or item.name,
                description = ('Harga: $%s/unit | Stok Government: %s/%s%s'):format(
                    price,
                    itemStock.count,
                    itemStock.limit,
                    isFull and ' | PENUH' or (' | Sisa kapasitas: ' .. remaining)
                ),
                icon = isFull and 'ban' or 'sack-dollar',
                arrow = not isFull,
                disabled = isFull,
                onSelect = function()
                    local input = lib.inputDialog('Jual Material', {
                        {
                            type = 'number',
                            label = ('Jumlah (tersedia: %s)'):format(count),
                            description = ('Maksimal penjualan: %s | Total maksimal: $%s'):format(
                                sellLimit, sellLimit * price
                            ),
                            min = 1,
                            max = sellLimit,
                            required = true,
                        }
                    })

                    if not input or not input[1] then return end
                    TriggerServerEvent('qbx_materialbuyer:server:sellItem', item.name, input[1])
                end,
            }
        end
    end

    if #options == 0 then
        options[1] = {
            title = 'Tidak ada material',
            description = 'Kamu tidak memiliki material yang dapat dijual.',
            icon = 'ban',
            disabled = true,
        }
    end

    lib.registerContext({
        id = 'qbx_materialbuyer_menu',
        title = 'Material Buyer',
        options = options,
    })
    lib.showContext('qbx_materialbuyer_menu')
end

CreateThread(function()
    local model = joaat(config.location.pedModel)
    lib.requestModel(model)

    buyerPed = CreatePed(
        0,
        model,
        config.location.coords.x,
        config.location.coords.y,
        config.location.coords.z - 1.0,
        config.location.heading,
        false,
        true
    )

    SetEntityAsMissionEntity(buyerPed, true, true)
    SetEntityInvincible(buyerPed, true)
    FreezeEntityPosition(buyerPed, true)
    SetBlockingOfNonTemporaryEvents(buyerPed, true)
    SetModelAsNoLongerNeeded(model)

    exports.ox_target:addLocalEntity(buyerPed, {
        {
            name = 'qbx_materialbuyer_sell',
            icon = 'fa-solid fa-recycle',
            label = 'Jual Material',
            distance = 2.0,
            onSelect = openSellMenu,
        }
    })

    if config.blip.enabled then
        local blip = AddBlipForCoord(config.blip.coords.x, config.blip.coords.y, config.blip.coords.z)
        SetBlipSprite(blip, config.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, config.blip.scale)
        SetBlipColour(blip, config.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(config.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if buyerPed and DoesEntityExist(buyerPed) then
        exports.ox_target:removeLocalEntity(buyerPed, 'qbx_materialbuyer_sell')
        DeleteEntity(buyerPed)
    end
end)


RegisterNetEvent('qbx_materialbuyer:client:showHistory', function(rows)
    local options = {}

    for i = 1, #rows do
        local row = rows[i]
        options[#options + 1] = {
            title = ('#%s | %s'):format(row.id, row.item_label),
            description = ('Player: %s (ID %s) | Jumlah: %s | Harga/unit: $%s | Total: $%s | Waktu: %s | Citizen ID: %s'):format(
                row.player_name,
                row.player_id,
                row.amount,
                row.unit_price,
                row.total_price,
                row.created_at,
                row.citizenid
            ),
            icon = 'receipt',
            readOnly = true,
        }
    end

    if #options == 0 then
        options[1] = {
            title = 'Belum ada transaksi',
            description = 'Riwayat transaksi Material Buyer masih kosong.',
            icon = 'receipt',
            disabled = true,
        }
    end

    lib.registerContext({
        id = 'qbx_materialbuyer_history',
        title = 'Riwayat Material Buyer (25 Terbaru)',
        options = options,
    })

    lib.showContext('qbx_materialbuyer_history')
end)


RegisterNetEvent('qbx_materialbuyer:client:showDashboard', function(data)
    local options = {
        {
            title = 'Ringkasan Pembelian Hari Ini',
            description = ('Transaksi: %s | Material dibeli: %s item | Total pembayaran: $%s'):format(
                data.stats.transaction_count or 0,
                data.stats.total_items or 0,
                data.stats.total_spent or 0
            ),
            icon = 'chart-line',
            readOnly = true,
        },
        {
            title = 'Stok Government',
            description = 'Jumlah stok saat ini dibandingkan batas 10.000 item per material.',
            icon = 'warehouse',
            readOnly = true,
        },
    }

    for i = 1, #(data.stock or {}) do
        local item = data.stock[i]
        local full = item.remaining <= 0
        options[#options + 1] = {
            title = ('%s — %s/10.000'):format(item.label, item.count),
            description = full
                and 'STATUS: PENUH | Penjualan material ini ditolak.'
                or ('Sisa kapasitas: %s | Harga beli: $%s/unit'):format(item.remaining, item.unitPrice),
            icon = full and 'ban' or 'boxes-stacked',
            readOnly = true,
        }
    end

    options[#options + 1] = {
        title = 'Pembelian Hari Ini per Material',
        description = 'Rincian jumlah material yang dibeli Government hari ini.',
        icon = 'list',
        readOnly = true,
    }

    if #(data.byMaterial or {}) == 0 then
        options[#options + 1] = {
            title = 'Belum ada pembelian hari ini',
            description = 'Belum ada transaksi Material Buyer pada hari ini.',
            icon = 'receipt',
            disabled = true,
        }
    else
        for i = 1, #data.byMaterial do
            local row = data.byMaterial[i]
            options[#options + 1] = {
                title = row.item_label,
                description = ('Dibeli: %s item | Total dibayarkan: $%s'):format(row.amount, row.total_price),
                icon = 'receipt',
                readOnly = true,
            }
        end
    end

    lib.registerContext({
        id = 'qbx_materialbuyer_dashboard',
        title = 'Government Material Dashboard',
        options = options,
    })
    lib.showContext('qbx_materialbuyer_dashboard')
end)
