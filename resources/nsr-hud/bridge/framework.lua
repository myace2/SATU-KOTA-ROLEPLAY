--[[
    NSR HUD Ultimate — Extensible Framework Bridge (bridge/framework.lua)
    Supports: 'auto', 'qbox' (qbx_core), 'qbcore' (qb-core), 'esx' (es_extended), and 'standalone'.
    All framework-specific exports and events are isolated in this file.
]]

NSRFramework = {
    ActiveName = 'standalone',
    Adapters = {},
    ClientCache = {
        loaded = false,
        cash = nil,
        bank = nil,
        job = nil,
        hunger = nil,
        thirst = nil,
        stress = nil
    },
    Listeners = {}
}

local isServer = IsDuplicityVersion and IsDuplicityVersion() or false

function NSRFramework.RegisterAdapter(name, definition)
    if type(name) ~= 'string' or type(definition) ~= 'table' then return false end
    NSRFramework.Adapters[name:lower()] = definition
    return true
end

function NSRFramework.OnDataChanged(cb)
    if type(cb) == 'function' then
        NSRFramework.Listeners[#NSRFramework.Listeners + 1] = cb
    end
end

local function notifyListeners(reason)
    for i = 1, #NSRFramework.Listeners do
        pcall(NSRFramework.Listeners[i], reason, NSRFramework.ClientCache)
    end
end

-- ============================================================================
-- 1. QBOX (qbx_core) ADAPTER
-- ============================================================================
NSRFramework.RegisterAdapter('qbox', {
    IsAvailable = function()
        return NSRUtils.IsResourceStarted('qbx_core')
    end,
    InitClient = function()
        local function refreshFromPlayerData(pData)
            if type(pData) ~= 'table' then
                local ok, exported = pcall(function()
                    return exports.qbx_core:GetPlayerData()
                end)
                if ok and type(exported) == 'table' then
                    pData = exported
                elseif QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData then
                    pData = QBCore.Functions.GetPlayerData()
                end
            end
            if type(pData) ~= 'table' or not pData.citizenid then
                return
            end
            NSRFramework.ClientCache.loaded = true
            local money = pData.money or {}
            NSRFramework.ClientCache.cash = tonumber(money.cash)
            NSRFramework.ClientCache.bank = tonumber(money.bank)

            if type(pData.job) == 'table' then
                local gradeLabel = (type(pData.job.grade) == 'table' and pData.job.grade.name) or pData.job.grade_label or ''
                NSRFramework.ClientCache.job = {
                    name = pData.job.name or 'unemployed',
                    label = pData.job.label or pData.job.name or '',
                    gradeLabel = gradeLabel,
                    onDuty = pData.job.onduty ~= false
                }
            end

            local meta = pData.metadata or {}
            local state = LocalPlayer and LocalPlayer.state or {}
            NSRFramework.ClientCache.hunger = tonumber(state.hunger or meta.hunger)
            NSRFramework.ClientCache.thirst = tonumber(state.thirst or meta.thirst)
            NSRFramework.ClientCache.stress = tonumber(state.stress or meta.stress)
            notifyListeners('qbox_refresh')
        end

        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
            refreshFromPlayerData()
        end)
        RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
            NSRFramework.ClientCache.loaded = false
            notifyListeners('unload')
        end)
        RegisterNetEvent('QBX:PlayerLoggedOut', function()
            NSRFramework.ClientCache.loaded = false
            notifyListeners('unload')
        end)
        RegisterNetEvent('QBCore:Player:SetPlayerData', function(pData)
            refreshFromPlayerData(pData)
        end)
        RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
            if type(jobInfo) == 'table' then
                local gradeLabel = (type(jobInfo.grade) == 'table' and jobInfo.grade.name) or ''
                NSRFramework.ClientCache.job = {
                    name = jobInfo.name or 'unemployed',
                    label = jobInfo.label or jobInfo.name or '',
                    gradeLabel = gradeLabel,
                    onDuty = jobInfo.onduty ~= false
                }
                notifyListeners('job')
            end
        end)
        RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
            if tonumber(newHunger) then NSRFramework.ClientCache.hunger = tonumber(newHunger) end
            if tonumber(newThirst) then NSRFramework.ClientCache.thirst = tonumber(newThirst) end
            notifyListeners('needs')
        end)
        RegisterNetEvent('hud:client:UpdateStress', function(newStress)
            if tonumber(newStress) then NSRFramework.ClientCache.stress = tonumber(newStress) end
            notifyListeners('stress')
        end)

        if type(AddStateBagChangeHandler) == 'function' then
            for _, bagKey in ipairs({ 'hunger', 'thirst', 'stress' }) do
                AddStateBagChangeHandler(bagKey, nil, function(bagName, _, value)
                    if LocalPlayer and bagName == ('player:%s'):format(GetPlayerServerId(PlayerId())) then
                        NSRFramework.ClientCache[bagKey] = tonumber(value)
                        notifyListeners(bagKey)
                    end
                end)
            end
        end

        refreshFromPlayerData()
    end,
    GetServerIdentifier = function(src)
        local ok, player = pcall(function()
            return exports.qbx_core:GetPlayer(src)
        end)
        if ok and player and player.PlayerData and player.PlayerData.citizenid then
            return 'citizenid:' .. tostring(player.PlayerData.citizenid)
        end
        return nil
    end
})

-- ============================================================================
-- 2. QBCORE (qb-core) ADAPTER
-- ============================================================================
NSRFramework.RegisterAdapter('qbcore', {
    IsAvailable = function()
        return NSRUtils.IsResourceStarted('qb-core') and not NSRUtils.IsResourceStarted('qbx_core')
    end,
    InitClient = function()
        local QBCoreObj = nil
        local ok, obj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok then QBCoreObj = obj end

        local function refreshFromPlayerData(pData)
            if type(pData) ~= 'table' and QBCoreObj and QBCoreObj.Functions then
                local okData, d = pcall(QBCoreObj.Functions.GetPlayerData)
                if okData then pData = d end
            end
            if type(pData) ~= 'table' or not pData.citizenid then return end

            NSRFramework.ClientCache.loaded = true
            local money = pData.money or {}
            NSRFramework.ClientCache.cash = tonumber(money.cash)
            NSRFramework.ClientCache.bank = tonumber(money.bank)

            if type(pData.job) == 'table' then
                local gradeLabel = (type(pData.job.grade) == 'table' and pData.job.grade.name) or ''
                NSRFramework.ClientCache.job = {
                    name = pData.job.name or 'unemployed',
                    label = pData.job.label or pData.job.name or '',
                    gradeLabel = gradeLabel,
                    onDuty = pData.job.onduty ~= false
                }
            end

            local meta = pData.metadata or {}
            NSRFramework.ClientCache.hunger = tonumber(meta.hunger)
            NSRFramework.ClientCache.thirst = tonumber(meta.thirst)
            NSRFramework.ClientCache.stress = tonumber(meta.stress)
            notifyListeners('qbcore_refresh')
        end

        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
            refreshFromPlayerData()
        end)
        RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
            NSRFramework.ClientCache.loaded = false
            notifyListeners('unload')
        end)
        RegisterNetEvent('QBCore:Player:SetPlayerData', function(pData)
            refreshFromPlayerData(pData)
        end)
        RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
            if type(jobInfo) == 'table' then
                local gradeLabel = (type(jobInfo.grade) == 'table' and jobInfo.grade.name) or ''
                NSRFramework.ClientCache.job = {
                    name = jobInfo.name or 'unemployed',
                    label = jobInfo.label or jobInfo.name or '',
                    gradeLabel = gradeLabel,
                    onDuty = jobInfo.onduty ~= false
                }
                notifyListeners('job')
            end
        end)
        RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
            if tonumber(newHunger) then NSRFramework.ClientCache.hunger = tonumber(newHunger) end
            if tonumber(newThirst) then NSRFramework.ClientCache.thirst = tonumber(newThirst) end
            notifyListeners('needs')
        end)
        RegisterNetEvent('hud:client:UpdateStress', function(newStress)
            if tonumber(newStress) then NSRFramework.ClientCache.stress = tonumber(newStress) end
            notifyListeners('stress')
        end)

        refreshFromPlayerData()
    end,
    GetServerIdentifier = function(src)
        local ok, QBCoreObj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok and QBCoreObj and QBCoreObj.Functions then
            local player = QBCoreObj.Functions.GetPlayer(src)
            if player and player.PlayerData and player.PlayerData.citizenid then
                return 'citizenid:' .. tostring(player.PlayerData.citizenid)
            end
        end
        return nil
    end
})

-- ============================================================================
-- 3. ESX LEGACY (es_extended) ADAPTER
-- ============================================================================
NSRFramework.RegisterAdapter('esx', {
    IsAvailable = function()
        return NSRUtils.IsResourceStarted('es_extended')
    end,
    InitClient = function()
        local ESXObj = nil
        local ok, obj = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if ok then ESXObj = obj end

        local function applyEsxPlayerData(pData)
            if type(pData) ~= 'table' and ESXObj and ESXObj.GetPlayerData then
                local okD, d = pcall(ESXObj.GetPlayerData)
                if okD then pData = d end
            end
            if type(pData) ~= 'table' then return end

            NSRFramework.ClientCache.loaded = true
            if type(pData.accounts) == 'table' then
                for i = 1, #pData.accounts do
                    local acc = pData.accounts[i]
                    if acc and acc.name == 'money' then
                        NSRFramework.ClientCache.cash = tonumber(acc.money)
                    elseif acc and acc.name == 'bank' then
                        NSRFramework.ClientCache.bank = tonumber(acc.money)
                    end
                end
            end
            if type(pData.job) == 'table' then
                NSRFramework.ClientCache.job = {
                    name = pData.job.name or 'unemployed',
                    label = pData.job.label or pData.job.name or '',
                    gradeLabel = pData.job.grade_label or pData.job.grade_name or '',
                    onDuty = true
                }
            end
            notifyListeners('esx_refresh')
        end

        RegisterNetEvent('esx:playerLoaded', function(xPlayer)
            applyEsxPlayerData(xPlayer)
        end)
        RegisterNetEvent('esx:onPlayerLogout', function()
            NSRFramework.ClientCache.loaded = false
            notifyListeners('unload')
        end)
        RegisterNetEvent('esx:setJob', function(job)
            if type(job) == 'table' then
                NSRFramework.ClientCache.job = {
                    name = job.name or 'unemployed',
                    label = job.label or job.name or '',
                    gradeLabel = job.grade_label or job.grade_name or '',
                    onDuty = true
                }
                notifyListeners('job')
            end
        end)
        RegisterNetEvent('esx:setAccountMoney', function(account)
            if type(account) == 'table' then
                if account.name == 'money' then
                    NSRFramework.ClientCache.cash = tonumber(account.money)
                elseif account.name == 'bank' then
                    NSRFramework.ClientCache.bank = tonumber(account.money)
                end
                notifyListeners('money')
            end
        end)
        AddEventHandler('esx_status:onTick', function(statusList)
            if type(statusList) ~= 'table' then return end
            for i = 1, #statusList do
                local st = statusList[i]
                if type(st) == 'table' then
                    local pct = tonumber(st.percent)
                    if not pct and tonumber(st.val) then
                        pct = tonumber(st.val) / 10000.0
                    end
                    if st.name == 'hunger' and pct then
                        NSRFramework.ClientCache.hunger = NSRUtils.Clamp(pct, 0, 100)
                    elseif st.name == 'thirst' and pct then
                        NSRFramework.ClientCache.thirst = NSRUtils.Clamp(pct, 0, 100)
                    elseif st.name == 'stress' and pct then
                        NSRFramework.ClientCache.stress = NSRUtils.Clamp(pct, 0, 100)
                    end
                end
            end
            notifyListeners('esx_status')
        end)

        applyEsxPlayerData()
    end,
    GetServerIdentifier = function(src)
        local ok, ESXObj = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if ok and ESXObj and ESXObj.GetPlayerFromId then
            local xPlayer = ESXObj.GetPlayerFromId(src)
            if xPlayer and xPlayer.identifier then
                return 'esx:' .. tostring(xPlayer.identifier)
            end
        end
        return nil
    end
})

-- ============================================================================
-- 4. STANDALONE ADAPTER
-- ============================================================================
NSRFramework.RegisterAdapter('standalone', {
    IsAvailable = function()
        return true
    end,
    InitClient = function()
        NSRFramework.ClientCache.loaded = true
        -- In standalone mode, never fabricate cash, bank, job, hunger, or thirst.
        -- However, if another standalone script sets LocalPlayer.state.hunger/thirst/stress, read it safely.
        if type(AddStateBagChangeHandler) == 'function' then
            for _, bagKey in ipairs({ 'hunger', 'thirst', 'stress', 'cash', 'bank' }) do
                AddStateBagChangeHandler(bagKey, nil, function(bagName, _, value)
                    if LocalPlayer and bagName == ('player:%s'):format(GetPlayerServerId(PlayerId())) then
                        NSRFramework.ClientCache[bagKey] = tonumber(value)
                        notifyListeners(bagKey)
                    end
                end)
            end
        end
        notifyListeners('standalone_init')
    end,
    GetServerIdentifier = function(_)
        return nil
    end
})

-- ============================================================================
-- INITIALIZATION & PUBLIC API
-- ============================================================================

function NSRFramework.Initialize()
    local configured = (Config and type(Config.Framework) == 'string') and Config.Framework:lower() or 'auto'
    if not NSRConstants.SupportedFrameworks[configured] and not NSRFramework.Adapters[configured] then
        NSRUtils.Warn(('Unsupported Config.Framework "%s". Falling back to "standalone".'):format(configured))
        configured = 'standalone'
    end

    if configured == 'auto' then
        -- Priority order: qbox -> qbcore -> esx -> standalone
        local priority = { 'qbox', 'qbcore', 'esx', 'standalone' }
        for i = 1, #priority do
            local candidate = priority[i]
            local adapter = NSRFramework.Adapters[candidate]
            if adapter and adapter.IsAvailable and adapter.IsAvailable() then
                NSRFramework.ActiveName = candidate
                break
            end
        end
    else
        local adapter = NSRFramework.Adapters[configured]
        if adapter and (configured == 'standalone' or (adapter.IsAvailable and adapter.IsAvailable())) then
            NSRFramework.ActiveName = configured
        else
            NSRUtils.Warn(('Forced framework "%s" is not started. Falling back to "standalone" mode.'):format(configured))
            NSRFramework.ActiveName = 'standalone'
        end
    end

    NSRUtils.Debug(('Framework initialized: %s (configured: %s)'):format(NSRFramework.ActiveName, configured))

    local activeAdapter = NSRFramework.Adapters[NSRFramework.ActiveName]
    if not isServer and activeAdapter and activeAdapter.InitClient then
        local ok, err = pcall(activeAdapter.InitClient)
        if not ok then
            NSRUtils.Warn(('Framework client init error (%s): %s'):format(NSRFramework.ActiveName, tostring(err)))
        end
    end
end

function NSRFramework.GetActiveFramework()
    return NSRFramework.ActiveName
end

function NSRFramework.GetPlayerStatus()
    local c = NSRFramework.ClientCache
    local state = LocalPlayer and LocalPlayer.state or {}
    local hunger = c.hunger ~= nil and c.hunger or tonumber(state.hunger)
    local thirst = c.thirst ~= nil and c.thirst or tonumber(state.thirst)
    local stress = c.stress ~= nil and c.stress or tonumber(state.stress)

    return {
        framework = NSRFramework.ActiveName,
        hasNeeds = (hunger ~= nil or thirst ~= nil),
        hunger = hunger and NSRUtils.Round(NSRUtils.Clamp(hunger, 0, 100), 0) or nil,
        thirst = thirst and NSRUtils.Round(NSRUtils.Clamp(thirst, 0, 100), 0) or nil,
        stress = stress and NSRUtils.Round(NSRUtils.Clamp(stress, 0, 100), 0) or nil,
        cash = c.cash,
        bank = c.bank,
        job = c.job
    }
end

function NSRFramework.GetPlayerIdentifier(src)
    if not isServer then return nil end
    local adapter = NSRFramework.Adapters[NSRFramework.ActiveName]
    if adapter and adapter.GetServerIdentifier then
        local ok, fwId = pcall(adapter.GetServerIdentifier, src)
        if ok and type(fwId) == 'string' and #fwId > 0 then
            return fwId
        end
    end

    -- Fallback to FiveM hardware/account identifiers (license2 -> license -> fivem -> steam)
    if type(GetPlayerIdentifierByType) == 'function' then
        for _, idType in ipairs({ 'license2', 'license', 'fivem', 'steam', 'discord' }) do
            local idVal = GetPlayerIdentifierByType(src, idType)
            if type(idVal) == 'string' and #idVal > 0 then
                return idVal
            end
        end
    end
    if type(GetPlayerIdentifiers) == 'function' then
        local ids = GetPlayerIdentifiers(src) or {}
        if #ids > 0 then
            return ids[1]
        end
    end
    return ('src:%s'):format(tostring(src))
end
