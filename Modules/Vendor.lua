local ADDON_NAME, ns = ...

-- ===== Container API shim =====
-- Retail (and therefore Forever) moved the bag functions into C_Container,
-- and GetContainerItemInfo changed shape at the same time: the modern one
-- returns a single table, the Classic one returns a long list of values.
-- Normalising both into one shape here keeps the rest of the file readable
-- and means Classic Era keeps working too.
local GetNumSlots = (C_Container and C_Container.GetContainerNumSlots) or _G.GetContainerNumSlots
local UseItem = (C_Container and C_Container.UseContainerItem) or _G.UseContainerItem

local function GetBagItem(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if not info then
            return nil
        end
        return { quality = info.quality, link = info.hyperlink, noValue = info.hasNoValue, count = info.stackCount }
    elseif _G.GetContainerItemInfo then
        local icon, count, _, quality, _, _, link, _, noValue = _G.GetContainerItemInfo(bag, slot)
        if not icon then
            return nil
        end
        return { quality = quality, link = link, noValue = noValue, count = count }
    end
    return nil
end

local function Money(copper)
    if GetCoinTextureString then
        return GetCoinTextureString(copper)
    end
    return tostring(math.floor((copper or 0) / 10000)) .. "g"
end

-- ===== Modules =====
ns.RegisterModule({
    key = "autoRepair",
    category = "Vendor",
    label = "Auto-repair at vendors",
    tooltip = "Repairs all your gear the moment you open a merchant that offers repairs.",
    default = true,
})

ns.RegisterModule({
    key = "autoRepairGuild",
    category = "Vendor",
    label = "Prefer guild funds for repairs",
    tooltip = "Tries guild bank funds first and falls back to your own gold. Requires repair privileges in your guild.",
    default = false,
})

ns.RegisterModule({
    key = "autoSellJunk",
    category = "Vendor",
    label = "Auto-sell grey items",
    tooltip = "Sells every Poor-quality (grey) item when you open a merchant. Never touches anything above grey.",
    default = true,
})

-- ===== Behaviour =====
local function DoRepair()
    if not ns.IsEnabled("autoRepair") then
        return
    end
    if not (CanMerchantRepair and CanMerchantRepair()) then
        return
    end
    local cost = GetRepairAllCost and GetRepairAllCost() or 0
    if not cost or cost <= 0 then
        return
    end

    -- Guild funds first if asked for and actually permitted, otherwise the
    -- player's own gold. RepairAllItems(true) silently does nothing when you
    -- lack guild repair rights, so the permission check matters.
    if ns.IsEnabled("autoRepairGuild") and CanGuildBankRepair and CanGuildBankRepair() then
        RepairAllItems(true)
        ns.Print("Repaired using guild funds (" .. Money(cost) .. ").")
        return
    end

    if GetMoney() >= cost then
        RepairAllItems(false)
        ns.Print("Repaired for " .. Money(cost) .. ".")
    else
        ns.Print("|cffff5555Not enough gold to repair|r (need " .. Money(cost) .. ").")
    end
end

local function DoSellJunk()
    if not ns.IsEnabled("autoSellJunk") then
        return
    end
    if not (GetNumSlots and UseItem) then
        return
    end

    local before = GetMoney()
    local sold = 0
    local maxBag = NUM_BAG_SLOTS or 4
    for bag = 0, maxBag do
        local slots = GetNumSlots(bag) or 0
        for slot = 1, slots do
            local item = GetBagItem(bag, slot)
            -- Quality 0 is Poor/grey. hasNoValue items can't be sold at all,
            -- so trying would just throw a vendor error.
            if item and item.quality == 0 and not item.noValue then
                UseItem(bag, slot)
                sold = sold + 1
            end
        end
    end

    if sold > 0 then
        -- Money updates a moment after the sell calls go through, so read it
        -- on the next frame rather than immediately.
        C_Timer.After(0.5, function()
            local earned = GetMoney() - before
            if earned > 0 then
                ns.Print("Sold " .. sold .. " grey item(s) for " .. Money(earned) .. ".")
            else
                ns.Print("Sold " .. sold .. " grey item(s).")
            end
        end)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("MERCHANT_SHOW")
f:SetScript("OnEvent", function()
    DoRepair()
    DoSellJunk()
end)
