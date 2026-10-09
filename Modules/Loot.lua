local ADDON_NAME, ns = ...

ns.RegisterModule({
    key = "fastLoot",
    category = "Looting",
    label = "Faster auto-loot",
    tooltip = "Grabs everything the instant the loot window opens instead of waiting for the default animation. Respects your normal auto-loot setting and modifier key.",
    default = true,
})

ns.RegisterModule({
    key = "autoConfirmBoP",
    category = "Looting",
    label = "Skip \"this will bind to you\" prompts",
    tooltip = "Auto-confirms the soulbound warning when looting bind-on-pickup items, instead of making you click through it every time.",
    default = false,
})

ns.RegisterModule({
    key = "autoConfirmDisenchant",
    category = "Looting",
    label = "Skip disenchant roll confirmations",
    tooltip = "Auto-confirms the \"are you sure you want to roll disenchant\" prompt.",
    default = false,
})

local f = CreateFrame("Frame")
f:RegisterEvent("LOOT_READY")
f:RegisterEvent("LOOT_BIND_CONFIRM")
f:RegisterEvent("CONFIRM_DISENCHANT_ROLL")

f:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "LOOT_READY" then
        if not ns.IsEnabled("fastLoot") then
            return
        end
        -- Mirrors the game's own rule: auto-loot is on when the CVar says so,
        -- inverted while the modifier is held. This keeps the feature honest
        -- to whatever the player already configured rather than overriding it.
        local autoLoot = GetCVarBool and GetCVarBool("autoLootDefault")
        if autoLoot ~= IsModifierKeyDown() then
            for i = GetNumLootItems(), 1, -1 do
                LootSlot(i)
            end
        end

    elseif event == "LOOT_BIND_CONFIRM" then
        if ns.IsEnabled("autoConfirmBoP") and arg1 then
            ConfirmLootSlot(arg1)
            StaticPopup_Hide("LOOT_BIND")
        end

    elseif event == "CONFIRM_DISENCHANT_ROLL" then
        if ns.IsEnabled("autoConfirmDisenchant") and arg1 then
            ConfirmLootRoll(arg1, arg2)
            StaticPopup_Hide("CONFIRM_LOOT_ROLL")
        end
    end
end)
