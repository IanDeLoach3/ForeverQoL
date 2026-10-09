local ADDON_NAME, ns = ...

ns.RegisterModule({
    key = "chatCopy",
    category = "Chat",
    label = "Chat copy window (/fqol copy)",
    tooltip = "Opens a window containing your recent chat as selectable text, so you can Ctrl+A / Ctrl+C it out of the game. WoW has no native way to copy chat.",
    default = true,
})

ns.RegisterModule({
    key = "chatFilterDupes",
    category = "Chat",
    label = "Filter repeated channel messages",
    tooltip = "Hides the same message posted repeatedly in a public channel within a short window -- kills most trade/LFG spam without blocking the channel entirely. Only affects public channels, never whispers, guild or party.",
    default = false,
})

-- ===== Copy window =====
local WHITE = "Interface\\Buttons\\WHITE8x8"
local copyFrame

local function CleanLine(msg)
    if not msg then
        return ""
    end
    -- Strip colour codes and inline textures, and unwrap hyperlinks down to
    -- their visible text -- otherwise pasting this anywhere outside WoW is
    -- an unreadable mess of escape codes.
    msg = msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    msg = msg:gsub("|H.-|h(.-)|h", "%1")
    msg = msg:gsub("|T.-|t", "")
    msg = msg:gsub("|A.-|a", "")
    return msg
end

local function BuildCopyFrame()
    local f = CreateFrame("Frame", "ForeverQoLCopyFrame", UIParent, "BackdropTemplate")
    f:SetSize(620, 440)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    f:SetBackdropColor(0.07, 0.07, 0.08, 0.97)
    f:SetBackdropBorderColor(0.20, 0.60, 0.85)
    f:Hide()
    tinsert(UISpecialFrames, "ForeverQoLCopyFrame")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Copy Chat")

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOP", title, "BOTTOM", 0, -4)
    hint:SetText("Ctrl+A to select all, Ctrl+C to copy, Escape to close.")

    local scroll = CreateFrame("ScrollFrame", "ForeverQoLCopyScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -52)
    scroll:SetPoint("BOTTOMRIGHT", -34, 16)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(ChatFontNormal)
    edit:SetAutoFocus(false)
    edit:SetWidth(560)
    edit:SetScript("OnEscapePressed", function()
        f:Hide()
    end)
    scroll:SetScrollChild(edit)

    f.edit = edit
    return f
end

function ns.ShowChatCopy()
    if not ns.IsEnabled("chatCopy") then
        ns.Print("The chat copy window is disabled -- enable it in /fqol.")
        return
    end
    if not copyFrame then
        copyFrame = BuildCopyFrame()
    end

    local frame = SELECTED_DOCK_FRAME or ChatFrame1
    local lines = {}
    for i = 1, frame:GetNumMessages() do
        local msg = frame:GetMessageInfo(i)
        if msg then
            table.insert(lines, CleanLine(msg))
        end
    end

    copyFrame.edit:SetText(table.concat(lines, "\n"))
    copyFrame:Show()
    copyFrame.edit:SetFocus()
    copyFrame.edit:HighlightText()
end

-- ===== Duplicate spam filter =====
-- Public channels only. Whispers, guild, party and raid are deliberately
-- never filtered -- losing a real message is far worse than seeing spam.
local recent = {}
local WINDOW = 25

local function DupeFilter(_, _, message, sender)
    if not ns.IsEnabled("chatFilterDupes") then
        return false
    end
    local key = (sender or "?") .. "::" .. (message or "")
    local now = GetTime()
    local last = recent[key]
    recent[key] = now
    if last and (now - last) < WINDOW then
        return true -- suppress
    end
    -- Opportunistic cleanup so the table can't grow without bound.
    if math.random() < 0.05 then
        for k, t in pairs(recent) do
            if (now - t) > WINDOW * 2 then
                recent[k] = nil
            end
        end
    end
    return false
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", DupeFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", DupeFilter)
