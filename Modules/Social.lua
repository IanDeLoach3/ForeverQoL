local ADDON_NAME, ns = ...

-- Retail moved InviteUnit into C_PartyInfo; Classic still has the bare
-- global. Same dual-path approach used throughout this addon.
local function Invite(name)
    if C_PartyInfo and C_PartyInfo.InviteUnit then
        C_PartyInfo.InviteUnit(name)
    elseif _G.InviteUnit then
        _G.InviteUnit(name)
    end
end

local function StripRealm(name)
    return name and (name:match("^[^-]+") or name) or nil
end

local function IsGuildmate(name)
    if not IsInGuild() then
        return false
    end
    local target = StripRealm(name):lower()
    for i = 1, (GetNumGuildMembers() or 0) do
        local memberName = GetGuildRosterInfo(i)
        if memberName and StripRealm(memberName):lower() == target then
            return true
        end
    end
    return false
end

local function IsFriend(name)
    local target = StripRealm(name):lower()
    if C_FriendList and C_FriendList.GetNumFriends then
        for i = 1, (C_FriendList.GetNumFriends() or 0) do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and info.name and StripRealm(info.name):lower() == target then
                return true
            end
        end
    elseif _G.GetNumFriends then
        for i = 1, (_G.GetNumFriends() or 0) do
            local fname = _G.GetFriendInfo(i)
            if fname and StripRealm(fname):lower() == target then
                return true
            end
        end
    end
    return false
end

-- ===== Modules =====
ns.RegisterModule({
    key = "autoInviteWhisper",
    category = "Social",
    label = "Auto-invite players who whisper a keyword",
    tooltip = "Anyone who whispers you exactly this word gets a group invite. Handy when you're advertising in chat -- you can keep questing while people join. Only fires when you're not in a group or you're the leader.",
    default = false,
    optionKey = "inviteKeyword",
    optionDefault = "inv",
    optionLabel = "Invite keyword",
    optionHint = "keyword to listen for (Enter to save)",
})

ns.RegisterModule({
    key = "autoDeclineDuels",
    category = "Social",
    label = "Auto-decline duels",
    tooltip = "Silently declines duel requests and hides the popup.",
    default = false,
})

ns.RegisterModule({
    key = "autoAcceptGuildInvites",
    category = "Social",
    label = "Auto-accept group invites from guild & friends",
    tooltip = "Accepts party invites automatically, but only from people in your guild or on your friends list. Invites from strangers still prompt you as normal.",
    default = false,
})

-- ===== Behaviour =====
-- Short per-player cooldown so a spammed keyword can't fire a burst of
-- invites at the same person.
local lastInvite = {}
local INVITE_COOLDOWN = 20

local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_WHISPER")
f:RegisterEvent("DUEL_REQUESTED")
f:RegisterEvent("PARTY_INVITE_REQUEST")

f:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "CHAT_MSG_WHISPER" then
        if not ns.IsEnabled("autoInviteWhisper") then
            return
        end
        local message, sender = arg1, arg2
        if not message or not sender then
            return
        end

        local keyword = tostring(ns.GetOption("inviteKeyword", "inv")):lower()
        local trimmed = message:gsub("^%s*(.-)%s*$", "%1"):lower()
        if keyword == "" or trimmed ~= keyword then
            return
        end

        -- Don't try to invite into someone else's group.
        if IsInGroup() and not UnitIsGroupLeader("player") then
            return
        end

        local now = GetTime()
        if lastInvite[sender] and (now - lastInvite[sender]) < INVITE_COOLDOWN then
            return
        end
        lastInvite[sender] = now

        Invite(sender)
        ns.Print("Invited " .. StripRealm(sender) .. " (whispered \"" .. keyword .. "\").")

    elseif event == "DUEL_REQUESTED" then
        if ns.IsEnabled("autoDeclineDuels") then
            CancelDuel()
            StaticPopup_Hide("DUEL_REQUESTED")
        end

    elseif event == "PARTY_INVITE_REQUEST" then
        if not ns.IsEnabled("autoAcceptGuildInvites") then
            return
        end
        local inviter = arg1
        if inviter and (IsGuildmate(inviter) or IsFriend(inviter)) then
            AcceptGroup()
            StaticPopup_Hide("PARTY_INVITE")
            ns.Print("Accepted invite from " .. StripRealm(inviter) .. ".")
        end
    end
end)
