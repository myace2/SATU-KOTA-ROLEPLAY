local function notify(source, message, notificationType)
    if source == 0 then
        print(('[givecar] %s'):format(message))
        return
    end

    exports.qbx_core:Notify(source, message, notificationType)
end

lib.addCommand('givecar', {
    help = 'Berikan kendaraan permanen kepada pemain',
    restricted = 'group.admin',
    params = {
        { name = 'id', type = 'number', help = 'Server ID pemain' },
        { name = 'model', type = 'string', help = 'Spawn code kendaraan' },
    },
}, function(source, args)
    local targetId = math.floor(args.id)
    local target = exports.qbx_core:GetPlayer(targetId)
    if not target then
        return notify(source, 'Pemain tidak ditemukan atau sedang offline.', 'error')
    end

    local model = args.model:lower()
    local vehiclesByHash = exports.qbx_core:GetVehiclesByHash()
    if not vehiclesByHash[joaat(model)] then
        return notify(source, 'Spawn code belum terdaftar di katalog kendaraan Qbox.', 'error')
    end

    local vehicleId, err = exports.qbx_vehicles:CreatePlayerVehicle({
        model = model,
        citizenid = target.PlayerData.citizenid,
        garage = 'garasikota',
    })

    if not vehicleId then
        return notify(source, err and err.message or 'Gagal menyimpan kendaraan.', 'error')
    end

    notify(source, ('Kendaraan %s berhasil diberikan kepada ID %s.'):format(model, targetId), 'success')
    notify(targetId, ('Kendaraan %s sudah tersedia di Garasi Kota.'):format(model), 'success')
end)    