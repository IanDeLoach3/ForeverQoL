local ADDON_NAME, ns = ...

ns.RegisterModule({
    key = "mailTakeAllButton",
    category = "Mail",
    label = "Add a \"Take All\" button to the mailbox",
    tooltip = "Puts a button on the inbox that collects gold and attachments from every message. Cash-on-delivery mail is always skipped so it can never charge you.",
    default = true,
})

ns.RegisterModule({
    key = "mailAutoGold",
    category = "Mail",
    label = "Auto-collect gold when opening the mailbox",
    tooltip = "Automatically takes gold-only messages (no attachments, no CoD) the moment you open the mailbox.",
    default = false,
})

-- Mail actions are server-rate-limited -- firing them all in one frame
-- silently drops most of them. Everything below processes one message per
-- tick and reschedules itself instead.
local TICK = 0.35
local MAX_STEPS = 200 -- hard stop so a permanently-failing item can't loop forever

local running = false

local function Finish(reason)
    running = false
    if reason then
        ns.Print(reason)
    end
end

local function TakeNextStep(steps, tookAny)
    if steps > MAX_STEPS then
        Finish("Stopped after " .. MAX_STEPS .. " steps -- bags may be full.")
        return
    end

    local num = GetInboxNumItems and GetInboxNumItems() or 0
    if num == 0 then
        Finish(tookAny and "Mailbox emptied." or "Nothing to take.")
        return
    end

    -- Walk backwards: taking a message renumbers everything after it.
    for i = num, 1, -1 do
        local _, _, _, _, money, cod, _, itemCount = GetInboxHeaderInfo(i)
        local isCOD = cod and cod > 0
        local hasGold = money and money > 0
        local hasItems = itemCount and itemCount > 0

        if not isCOD and (hasGold or hasItems) then
            if hasGold then
                TakeInboxMoney(i)
            end
            if hasItems then
                AutoLootMailItem(i)
            end
            C_Timer.After(TICK, function()
                TakeNextStep(steps + 1, true)
            end)
            return
        end
    end

    Finish(tookAny and "Mailbox emptied (CoD mail left alone)." or "Nothing to take (only CoD or empty mail).")
end

local function TakeAll()
    if running then
        return
    end
    running = true
    TakeNextStep(1, false)
end

-- ===== Gold-only auto-collect =====
local function AutoCollectGold()
    if not ns.IsEnabled("mailAutoGold") then
        return
    end
    local num = GetInboxNumItems and GetInboxNumItems() or 0
    for i = num, 1, -1 do
        local _, _, _, _, money, cod, _, itemCount = GetInboxHeaderInfo(i)
        if money and money > 0 and (not cod or cod == 0) and (not itemCount or itemCount == 0) then
            TakeInboxMoney(i)
        end
    end
end

-- ===== Take All button =====
local button

local function EnsureButton()
    if button or not InboxFrame then
        return
    end
    button = CreateFrame("Button", nil, InboxFrame, "UIPanelButtonTemplate")
    button:SetSize(110, 22)
    button:SetText("Take All")
    button:SetPoint("BOTTOMLEFT", InboxFrame, "BOTTOMLEFT", 60, 88)
    button:SetScript("OnClick", TakeAll)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Take All", 1, 1, 1)
        GameTooltip:AddLine("Collects gold and attachments from every message. CoD mail is skipped.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("MAIL_SHOW")
f:RegisterEvent("MAIL_CLOSED")
f:SetScript("OnEvent", function(_, event)
    if event == "MAIL_CLOSED" then
        running = false
        return
    end
    EnsureButton()
    if button then
        button:SetShown(ns.IsEnabled("mailTakeAllButton"))
    end
    AutoCollectGold()
end)
