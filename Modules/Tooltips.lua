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
        if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then
            return
        end
        local _, link = tooltip:GetItem()
        AddLines(tooltip, link)
    end)
elseif GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        local _, link = tooltip:GetItem()
        AddLines(tooltip, link)
    end)
end
