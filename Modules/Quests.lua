local ADDON_NAME, ns = ...

-- Holding Shift suppresses every automation in this file -- the standard
-- escape hatch so you can always read a quest or pick a reward by hand.
local function Suppressed()
    return IsShiftKeyDown()
end

ns.RegisterModule({
    key = "autoAcceptQuests",
    category = "Quests",
    label = "Auto-accept quests",
    tooltip = "Accepts quests as soon as the quest window opens. Hold Shift while talking to an NPC to read it manually instead.",
    default = false,
})

ns.RegisterModule({
    key = "autoTurnInQuests",
    category = "Quests",
    label = "Auto-turn-in completed quests",
    tooltip = "Hands in finished quests automatically -- but ONLY when the quest has no reward choice. Anything with a choice of rewards always waits for you, so it can never pick wrong. Hold Shift to skip.",
    default = false,
})

ns.RegisterModule({
    key = "autoGossipSkip",
    category = "Quests",
    label = "Skip single-option NPC dialogue",
    tooltip = "When an NPC has exactly one dialogue option and no quests, picks it for you. Off by default -- it can skip flavour text you may want to read.",
    default = false,
})

-- ===== Accept / turn in =====
local f = CreateFrame("Frame")
f:RegisterEvent("QUEST_DETAIL")
f:RegisterEvent("QUEST_PROGRESS")
f:RegisterEvent("QUEST_COMPLETE")
f:RegisterEvent("GOSSIP_SHOW")

f:SetScript("OnEvent", function(_, event)
    if Suppressed() then
        return
    end

    if event == "QUEST_DETAIL" then
        if ns.IsEnabled("autoAcceptQuests") then
            AcceptQuest()
        end

    elseif event == "QUEST_PROGRESS" then
        if ns.IsEnabled("autoTurnInQuests") and IsQuestCompletable and IsQuestCompletable() then
            CompleteQuest()
        end

    elseif event == "QUEST_COMPLETE" then
        if ns.IsEnabled("autoTurnInQuests") then
            local choices = GetNumQuestChoices and GetNumQuestChoices() or 0
            -- Only ever auto-hand-in when there is genuinely nothing to
            -- choose. Picking a reward for you is irreversible, so a quest
            -- with any choice at all is always left for the player.
            if choices == 0 then
                pcall(GetQuestReward, 1)
            end
        end

    elseif event == "GOSSIP_SHOW" then
        if not ns.IsEnabled("autoGossipSkip") then
            return
        end
        -- Retail moved all of this into C_GossipInfo and changed
        -- SelectOption to take an option ID rather than an index, so both
        -- paths are handled separately rather than pretending they match.
        if C_GossipInfo and C_GossipInfo.GetOptions then
            local ok = pcall(function()
                local opts = C_GossipInfo.GetOptions()
                local numAvail = C_GossipInfo.GetNumAvailableQuests and C_GossipInfo.GetNumAvailableQuests() or 0
                local numActive = C_GossipInfo.GetNumActiveQuests and C_GossipInfo.GetNumActiveQuests() or 0
                if opts and #opts == 1 and numAvail == 0 and numActive == 0 then
                    local id = opts[1].gossipOptionID or opts[1].orderIndex
                    if id then
                        C_GossipInfo.SelectOption(id)
                    end
                end
            end)
            if not ok then
                return
            end
        elseif _G.GetGossipOptions then
            local opts = { _G.GetGossipOptions() }
            local numAvail = _G.GetNumGossipAvailableQuests and _G.GetNumGossipAvailableQuests() or 0
            local numActive = _G.GetNumGossipActiveQuests and _G.GetNumGossipActiveQuests() or 0
            -- Classic returns pairs of (text, type), so one option == 2 values.
            if #opts == 2 and numAvail == 0 and numActive == 0 then
                pcall(_G.SelectGossipOption, 1)
            end
        end
    end
end)
