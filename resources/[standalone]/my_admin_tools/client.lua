print('propinfo client loaded')

local function rotToDir(rot)
    local z, x = math.rad(rot.z), math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

RegisterCommand('propinfo', function()
    local camCoords = GetGameplayCamCoord()
    local dest = camCoords + rotToDir(GetGameplayCamRot(2)) * 20.0
    local ray = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, dest.x, dest.y, dest.z, 17, PlayerPedId(), 0)
    local _, hit, _, _, entity = GetShapeTestResult(ray)

    if hit == 1 and entity ~= 0 and DoesEntityExist(entity) then
        print(('Model: %s | Coords: %s | Heading: %s'):format(
            GetEntityModel(entity),
            GetEntityCoords(entity),
            GetEntityHeading(entity)
        ))
    else
        print('Tidak ada objek terdeteksi')
    end
end)