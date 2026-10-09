local ADDON_NAME, ns = ...

ns.RegisterModule({
    key = "hideErrorSpam",
    category = "Interface",
    label = "Hide combat error spam",
    tooltip = "Suppresses the red \"Out of range\", \"Not enough mana\", \"Ability is not ready\" style messages. Genuinely useful errors like a full inventory still come through.",
    default = false,
})

ns.RegisterModule({
    key = "durabilityWarning",
    category = "Interface",
    label = "Warn when gear drops below 20% durability",
    tooltip = "Prints a chat warning the first time your worst-worn item crosses 20%, so you find out before something breaks mid-pull.",
    default = true,
})

ns.RegisterModule({
    key = "autoFillDelete",
    category = "Interface",
    label = "Pre-fill the \"DELETE\" confirmation",
    tooltip = "When deleting a rare-or-better item, types the required confirmation word for you. Convenient, but it removes a deliberate safety step -- leave this off unless you're sure.",
    default = false,
})

-- ===== Error message filtering =====
-- Blocklist is built from Blizzard's own global strings so it matches the
-- client's language automatically, and nil-guarded because not every key
-- exists on every client version.
local BLOCK_KEYS = {
    "ERR_ABILITY_COOLDOWN", "ERR_SPELL_COOLDOWN",
    "ERR_OUT_OF_RAGE", "ERR_OUT_OF_MANA", "ERR_OUT_OF_ENERGY",
    "ERR_OUT_OF_FOCUS", "ERR_OUT_OF_RUNIC_POWER", "ERR_OUT_OF_POWER_DISPLAY",
    "ERR_BADATTACKPOS", "ERR_BADATTACKFACING",
    "SPELL_FAILED_UNIT_NOT_INFRONT", "SPELL_FAILED_OUT_OF_RANGE",
    "SPELL_FAILED_TOO_CLOSE", "SPELL_FAILED_BAD_TARGETS",
    "SPELL_FAILED_NOT_READY", "SPELL_FAILED_TARGETS_DEAD",
    "SPELL_FAILED_MOVING", "SPELL_FAILED_ITEM_NOT_READY",
}

local blocked = {}
for _, key in ipairs(BLOCK_KEYS) do
    local text = _G[key]
    if type(text) == "string" then
        blocked[text] = true
    end
end

if UIErrorsFrame and UIErrorsFrame.AddMessage then
    local original = UIErrorsFrame.AddMessage
    UIErrorsFrame.AddMessage = function(self, message, ...)
        if ns.IsEnabled("hideErrorSpam") and message and blocked[message] then
            return
        end
        return original(self, message, ...)
    end
end

-- ===== Durability warning =====
local DURABILITY_SLOTS = { 1, 3, 5, 6, 7, 8, 9, 10, 16, 17, 18 }
local warned = false

local function CheckDurability()
    if not ns.IsEnabled("durabilityWarning") or not GetInventoryItemDurability then
        return
    end
    local lowest = 101
    for _, slot in ipairs(DURABILITY_SLOTS) do
        local current, maximum = GetInventoryItemDurability(slot)
        if current and maximum and maximum > 0 then
            local pct = (current / maximum) * 100
            if pct < lowest then
                lowest = pct
            end
        end
    end

    if lowest <= 20 and not warned then
        warned = true
        ns.Print("|cffff8800Durability warning:|r your worst item is at " .. math.floor(lowest) .. "%.")
    elseif lowest > 35 then
        -- Reset well above the threshold so a repair re-arms the warning
        -- without it re-firing every point of damage around the boundary.
        warned = false
    end
end

-- ===== DELETE confirmation pre-fill =====
if _G.StaticPopup_Show then
    hooksecurefunc("StaticPopup_Show", function(which)
        if which ~= "DELETE_GOOD_ITEM" or not ns.IsEnabled("autoFillDelete") then
            return
        end
        for i = 1, (STATICPOPUP_NUMDIALOGS or 4) do
            local dialog = _G["StaticPopup" .. i]
            if dialog and dialog:IsShown() and dialog.which == "DELETE_GOOD_ITEM" then
                local editBox = _G["StaticPopup" .. i .. "EditBox"]
                if editBox then
                    editBox:SetText(DELETE_ITEM_CONFIRM_STRING or "DELETE")
                end
            end
        end
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", CheckDurability)
