--[[
    NSR HUD Ultimate — Voice & Radio Integration Bridge (bridge/voice.lua)
    Supports: 'auto', 'pma-voice', 'saltychat', 'mumble-voip', 'native'
]]

NSRVoice = {
    ActiveProvider = 'native',
    State = {
        talking = false,
        radioActive = false,
        radioChannel = 0,
        modeIndex = 2,      -- 1 = Whisper (33%), 2 = Normal (66%), 3 = Shout (100%)
        rangePercent = 66
    }
}

local modePercentages = {
    [1] = 33,
    [2] = 66,
    [3] = 100
}

function NSRVoice.Initialize()
    local configured = (Config and Config.Integrations and Config.Integrations.Voice) or 'auto'
    if configured == 'auto' then
        if NSRUtils.IsResourceStarted('pma-voice') then
            NSRVoice.ActiveProvider = 'pma-voice'
        elseif NSRUtils.IsResourceStarted('saltychat') then
            NSRVoice.ActiveProvider = 'saltychat'
        elseif NSRUtils.IsResourceStarted('mumble-voip') then
            NSRVoice.ActiveProvider = 'mumble-voip'
        else
            NSRVoice.ActiveProvider = 'native'
        end
    else
        NSRVoice.ActiveProvider = configured
    end

    -- pma-voice event listeners
    AddEventHandler('pma-voice:setTalkingMode', function(newMode)
        local idx = tonumber(newMode) or 2
        NSRVoice.State.modeIndex = NSRUtils.Clamp(idx, 1, 3)
        NSRVoice.State.rangePercent = modePercentages[NSRVoice.State.modeIndex] or 66
    end)

    AddEventHandler('pma-voice:radioActive', function(isRadioTalking)
        NSRVoice.State.radioActive = isRadioTalking == true
    end)

    -- saltychat event listeners
    AddEventHandler('SaltyChat_TalkStateChanged', function(isTalking)
        NSRVoice.State.talking = isTalking == true
    end)

    AddEventHandler('SaltyChat_VoiceRangeChanged', function(voiceRange, index)
        local idx = tonumber(index) and (tonumber(index) + 1) or 2
        NSRVoice.State.modeIndex = NSRUtils.Clamp(idx, 1, 3)
        NSRVoice.State.rangePercent = modePercentages[NSRVoice.State.modeIndex] or 66
    end)

    AddEventHandler('SaltyChat_RadioTrafficStateChanged', function(_, isSending)
        NSRVoice.State.radioActive = isSending == true
    end)

    NSRUtils.Debug(('Voice integration initialized: %s'):format(NSRVoice.ActiveProvider))
end

function NSRVoice.GetStatus()
    local playerId = PlayerId()
    local isTalking = NetworkIsPlayerTalking(playerId) == 1 or NetworkIsPlayerTalking(playerId) == true

    if LocalPlayer and LocalPlayer.state then
        local st = LocalPlayer.state
        if type(st.proximity) == 'table' and tonumber(st.proximity.index) then
            local idx = NSRUtils.Clamp(tonumber(st.proximity.index), 1, 3)
            NSRVoice.State.modeIndex = idx
            NSRVoice.State.rangePercent = modePercentages[idx] or 66
        end
        if tonumber(st.radioChannel) then
            NSRVoice.State.radioChannel = tonumber(st.radioChannel)
        end
    end

    return {
        provider = NSRVoice.ActiveProvider,
        talking = isTalking or NSRVoice.State.radioActive,
        radioActive = NSRVoice.State.radioActive,
        radioChannel = NSRVoice.State.radioChannel or 0,
        modeIndex = NSRVoice.State.modeIndex,
        rangePercent = NSRVoice.State.rangePercent
    }
end
