local function isValidStressAmount(amount)
    return type(amount) == 'number' and amount == amount and amount > 0 and amount <= 100
end

local function updateStress(source, amount, increase)
    if not isValidStressAmount(amount) then return end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local stress = tonumber(player.PlayerData.metadata.stress) or 0
    stress = math.max(0, math.min(100, stress + (increase and amount or -amount)))

    player.Functions.SetMetaData('stress', stress)
    Player(source).state:set('stress', stress, true)
    TriggerClientEvent('hud:client:UpdateStress', source, stress)
end

RegisterNetEvent('hud:server:GainStress', function(amount)
    updateStress(source, amount, true)
end)

RegisterNetEvent('hud:server:RelieveStress', function(amount)
    updateStress(source, amount, false)
end)
