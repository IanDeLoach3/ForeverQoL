local ADDON_NAME, ns = ...

-- ===== Death & travel =====
ns.RegisterModule({
    key = "autoRelease",
    category = "Death & Travel",
    label = "Auto-release when you die",
    tooltip = "Releases to the graveyard immediately on death. Off by default and worth leaving off in group content -- releasing gives up any chance of being resurrected where you fell.",
    default = false,
})

ns.RegisterModule({
    key = "autoAcceptRes",
    category = "Death & Travel",
    label = "Auto-accept resurrections",
    tooltip = "Accepts a resurrection offer automatically. Off by default -- sometimes you want to wait for a safer moment before taking one.",
    default = false,
})

ns.RegisterModule({
    key = "autoAcceptSummon",
    category = "Death & Travel",
    label = "Auto-accept summons",
    tooltip = "Accepts warlock/meeting-stone summons automatically. Off by default, since a summon can yank you out of whatever you were doing.",
    default = false,
})

-- ===== Interface =====
ns.RegisterModule({
    key = "maxCameraDistance",
    category = "Interface",
    label = "Maximum camera zoom-out distance",
    tooltip = "Raises the camera distance cap so you can zoom out further than the default. Purely a CVar change -- takes effect immediately.",
    default = true,
    OnLoad = function()
        if ns.IsEnabled("maxCameraDistance") and SetCVar then
            SetCVar("cameraDistanceMaxZoomFactor", 2.6)
        end
    end,
    OnToggle = function(enabled)
        if SetCVar then
            SetCVar("cameraDistanceMaxZoomFactor", enabled and 2.6 or 1.9)
        end
    end,
})

ns.RegisterModule({
    key = "screenshotLevelUp",
    category = "Interface",
    label = "Screenshot on level up",
    tooltip = "Takes a screenshot a moment after you level, so you end up with a record of the run.",
    default = false,
})

-- ===== Behaviour =====
local function ConfirmSummonCompat()
    if C_SummonInfo and C_SummonInfo.ConfirmSummon then
        C_SummonInfo.ConfirmSummon()
    elseif _G.ConfirmSummon then
        _G.ConfirmSummon()
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_DEAD")
f:RegisterEvent("RESURRECT_REQUEST")
f:RegisterEvent("CONFIRM_SUMMON")
f:RegisterEvent("PLAYER_LEVEL_UP")

f:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_DEAD" then
        if ns.IsEnabled("autoRelease") then
            -- Never auto-release in a battleground-style res queue or when
            -- already a ghost; RepopMe would just error.
            if not UnitIsGhost("player") then
                pcall(RepopMe)
            end
        end

    elseif event == "RESURRECT_REQUEST" then
        if ns.IsEnabled("autoAcceptRes") then
            AcceptResurrect()
            StaticPopup_Hide("RESURRECT")
            StaticPopup_Hide("RESURRECT_NO_SICKNESS")
            StaticPopup_Hide("RESURRECT_NO_TIMER")
        end

    elseif event == "CONFIRM_SUMMON" then
        if ns.IsEnabled("autoAcceptSummon") then
            ConfirmSummonCompat()
            StaticPopup_Hide("CONFIRM_SUMMON")
        end

    elseif event == "PLAYER_LEVEL_UP" then
        if ns.IsEnabled("screenshotLevelUp") then
            C_Timer.After(1.5, function()
                pcall(Screenshot)
            end)
        end
    end
end)
