
local menuOpen = false

RegisterNetEvent('qbx_customs:client:openNui', function(vehicleName)
    if menuOpen then return end

    menuOpen = true

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        vehicle = vehicleName or 'Vehicle'
    })
end)

RegisterNUICallback('close', function(_, cb)
    menuOpen = false

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'close'
    })

    cb({ success = true })
end)

RegisterNUICallback('selectCategory', function(data, cb)
    if not menuOpen then
        cb({ success = false })
        return
    end

    local allowed = {
        performance = true,
        parts = true,
        colors = true,
        extras = true,
        repair = true
    }

    if not allowed[data.category] then
        cb({ success = false })
        return
    end

    -- Tahap berikutnya:
    -- Hubungkan kategori ke fungsi menu modifikasi lama.

    print('[qbx_customs] Selected category: ' .. data.category)

    cb({ success = true })
end)
