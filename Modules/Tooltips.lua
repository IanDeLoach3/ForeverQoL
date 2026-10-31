local ADDON_NAME, ns = ...

-- GetItemInfo moved into C_Item (patch 10.2.6) and the bare global is gone
-- entirely on Forever -- same shim used across all of these addons.
local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo

ns.RegisterModule({
    key = "tooltipItemID",
    category = "Tooltips",
    label = "Show item ID in tooltips",
    tooltip = "Adds the numeric item ID to item tooltips. Handy for looking things up on a database site or reporting bugs.",
    default = false,
})

ns.RegisterModule({
    key = "tooltipStackValue",
    category = "Tooltips",
    label = "Show total stack vendor value",
    tooltip = "Adds the vendor value of the whole stack, not just one item -- so a stack of 20 shows what all 20 are worth.",
    default = false,
})

ns.RegisterModule({
    key = "tooltipStatValues",
    category = "Tooltips",
    label = "Show what item stats are worth",
    tooltip = "Adds what each primary stat on an item gives your character, e.g. \"+7 Agility (+7 AP, +0.54% Crit)\". Based on your class and level; crit numbers are close estimates.",
    default = true,
})

-- ===== Stat values =====
-- Classic conversion rates. The crit ratios are the level-60 values; below 60
-- each point is worth more, roughly in line with level, so we scale by that.
local STAT_KEYS = {
    [SPELL_STAT1_NAME or "Strength"] = "str",
    [SPELL_STAT2_NAME or "Agility"] = "agi",
    [SPELL_STAT3_NAME or "Stamina"] = "sta",
    [SPELL_STAT4_NAME or "Intellect"] = "int",
}
local STR_AP = { WARRIOR = 2, PALADIN = 2, SHAMAN = 2, DRUID = 2 } -- everyone else 1
local AGI_AP = { ROGUE = 1, HUNTER = 1 }                           -- everyone else 0
local AGI_PER_CRIT = { ROGUE = 29, HUNTER = 53 }                   -- everyone else 20
local INT_PER_CRIT = { MAGE = 59.5, PRIEST = 59.2, WARLOCK = 60.6, DRUID = 60, SHAMAN = 59.5, PALADIN = 54 }
local STAT_COLOR = "|cffdcd27a"

local function DescribeStat(key, n, class, scale)
    local parts = {}
    if key == "str" then
        parts[#parts + 1] = "+" .. n * (STR_AP[class] or 1) .. " AP"
    elseif key == "agi" then
        if AGI_AP[class] then
            parts[#parts + 1] = "+" .. n * AGI_AP[class] .. " AP"
        end
        if class == "HUNTER" then
            parts[#parts + 1] = "+" .. n * 2 .. " RAP"
        end
        parts[#parts + 1] = string.format("+%.2f%% Crit", n / ((AGI_PER_CRIT[class] or 20) * scale))
    elseif key == "sta" then
        parts[#parts + 1] = "+" .. n * 10 .. " HP"
    elseif key == "int" and class ~= "WARRIOR" and class ~= "ROGUE" then
        parts[#parts + 1] = "+" .. n * 15 .. " Mana"
        if INT_PER_CRIT[class] then
            parts[#parts + 1] = string.format("+%.2f%% Spell Crit", n / (INT_PER_CRIT[class] * scale))
        end
    end
    if #parts > 0 then
        return table.concat(parts, ", ")
    end
end

-- Only touch tooltips the player actually sees -- other addons scan items
-- with their own hidden tooltips and would choke on the extra text.
local function IsVisibleItemTooltip(tooltip)
    return tooltip == GameTooltip or tooltip == ItemRefTooltip
        or tooltip == _G.ShoppingTooltip1 or tooltip == _G.ShoppingTooltip2
end

local function AnnotateStats(tooltip)
    if not ns.IsEnabled("tooltipStatValues") or not IsVisibleItemTooltip(tooltip) then
        return
    end
    local name = tooltip:GetName()
    local _, class = UnitClass("player")
    local scale = math.max(UnitLevel("player") or 60, 10) / 60
    for i = 2, tooltip:NumLines() do
        local line = _G[name .. "TextLeft" .. i]
        local text = line and line:GetText()
        -- the "(" check stops a refreshed tooltip getting annotated twice
        if text and not text:find("(", 1, true) then
            local amount, stat = text:match("^%+(%d+) (%a+)$")
            local extra = stat and STAT_KEYS[stat] and DescribeStat(STAT_KEYS[stat], tonumber(amount), class, scale)
            if extra then
                line:SetText(text .. " " .. STAT_COLOR .. "(" .. extra .. ")|r")
            end
        end
    end
    tooltip:Show() -- re-fit the width to the longer lines
end

local function Money(copper)
    if GetCoinTextureString then
        return GetCoinTextureString(copper)
    end
    return tostring(math.floor((copper or 0) / 10000)) .. "g"
end

local function AddLines(tooltip, link)
    if not link then
        return
    end
    local _, _, _, _, _, _, _, stackMax, _, _, sellPrice = GetItemInfo(link)
    local itemID = link:match("item:(%d+)")

    if ns.IsEnabled("tooltipItemID") and itemID then
        tooltip:AddDoubleLine("Item ID", itemID, 0.6, 0.6, 0.6, 1, 1, 1)
    end

    if ns.IsEnabled("tooltipStackValue") and sellPrice and sellPrice > 0 then
        -- Work out how many are actually in the hovered stack where we can;
        -- fall back to a single item if the count isn't discoverable.
        local count = 1
        if tooltip.GetOwner then
            local owner = tooltip:GetOwner()
            if owner and owner.count and type(owner.count) == "number" and owner.count > 0 then
                count = owner.count
            end
        end
        if count > 1 then
            tooltip:AddDoubleLine("Stack value (" .. count .. ")", Money(sellPrice * count), 0.6, 0.6, 0.6, 1, 1, 1)
        end
    end

    tooltip:Show()
end

-- Retail rebuilt the tooltip system in 10.0 around TooltipDataProcessor;
-- Classic still uses the OnTooltipSetItem script. Forever is on the modern
-- one, but both paths are wired so this file works on either client.
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
        AnnotateStats(tooltip)
        if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then
            return
        end
        local _, link = tooltip:GetItem()
        AddLines(tooltip, link)
    end)
elseif GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        AnnotateStats(tooltip)
        local _, link = tooltip:GetItem()
        AddLines(tooltip, link)
    end)
    for _, tip in ipairs({ ItemRefTooltip, _G.ShoppingTooltip1, _G.ShoppingTooltip2 }) do
        if tip and tip.HookScript then
            tip:HookScript("OnTooltipSetItem", AnnotateStats)
        end
    end
end
