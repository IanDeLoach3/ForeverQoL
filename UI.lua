local ADDON_NAME, ns = ...

-- ===== Theme =====
local WHITE = "Interface\\Buttons\\WHITE8x8"
local ACCENT = { 0.20, 0.60, 0.85 }
local PANEL_BG = { 0.07, 0.07, 0.08, 0.97 }
local ROW_BG = { 0.12, 0.12, 0.13, 1 }
local BORDER = { 0.28, 0.28, 0.30 }

-- ===== Main window =====
local main = CreateFrame("Frame", "ForeverQoLFrame", UIParent, "BackdropTemplate")
main:SetSize(480, 560)
main:SetPoint("CENTER")
main:SetMovable(true)
main:EnableMouse(true)
main:SetClampedToScreen(true)
main:RegisterForDrag("LeftButton")
main:SetScript("OnDragStart", main.StartMoving)
main:SetScript("OnDragStop", main.StopMovingOrSizing)
main:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
main:SetBackdropColor(unpack(PANEL_BG))
main:SetBackdropBorderColor(unpack(ACCENT))
main:SetFrameStrata("DIALOG")
main:Hide()
tinsert(UISpecialFrames, "ForeverQoLFrame") -- Escape closes it

local titleBar = main:CreateTexture(nil, "ARTWORK")
titleBar:SetPoint("TOPLEFT", 1, -1)
titleBar:SetPoint("TOPRIGHT", -1, -1)
titleBar:SetHeight(30)
titleBar:SetColorTexture(0.10, 0.10, 0.11, 1)

local title = main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
title:SetText("|cff33ccffForever|rQoL")

local closeBtn = CreateFrame("Button", nil, main)
closeBtn:SetSize(24, 24)
closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -4, 0)
local closeLabel = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
closeLabel:SetPoint("CENTER")
closeLabel:SetText("x")
closeLabel:SetTextColor(0.6, 0.6, 0.6)
closeBtn:SetScript("OnEnter", function()
    closeLabel:SetTextColor(1, 0.35, 0.35)
end)
closeBtn:SetScript("OnLeave", function()
    closeLabel:SetTextColor(0.6, 0.6, 0.6)
end)
closeBtn:SetScript("OnClick", function()
    main:Hide()
end)

local subtitle = main:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
subtitle:SetPoint("TOPLEFT", 14, -38)
subtitle:SetPoint("RIGHT", -14, 0)
subtitle:SetJustifyH("LEFT")
subtitle:SetText("Everything is off unless you turn it on. Hover any option for details.")

-- ===== Scrolling content area =====
local scroll = CreateFrame("ScrollFrame", nil, main)
scroll:SetPoint("TOPLEFT", 14, -58)
scroll:SetPoint("BOTTOMRIGHT", -18, 14)

local content = CreateFrame("Frame", nil, scroll)
content:SetSize(1, 1)
scroll:SetScrollChild(content)

-- Slim scrollbar: a 4px track with an accent thumb, no arrow buttons.
local track = main:CreateTexture(nil, "ARTWORK")
track:SetPoint("TOPRIGHT", -10, -58)
track:SetPoint("BOTTOMRIGHT", -10, 14)
track:SetWidth(4)
track:SetColorTexture(1, 1, 1, 0.06)

local thumb = main:CreateTexture(nil, "OVERLAY")
thumb:SetWidth(4)
thumb:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.8)
thumb:SetPoint("TOPRIGHT", track, "TOPRIGHT", 0, 0)
thumb:SetHeight(40)

local function UpdateScrollbar()
    local viewH = scroll:GetHeight()
    local contentH = content:GetHeight()
    local maxScroll = math.max(contentH - viewH, 0)
    if maxScroll <= 0 then
        track:Hide()
        thumb:Hide()
        return
    end
    track:Show()
    thumb:Show()
    local ratio = viewH / contentH
    local thumbH = math.max(viewH * ratio, 24)
    thumb:SetHeight(thumbH)
    local offset = scroll:GetVerticalScroll()
    local travel = viewH - thumbH
    thumb:ClearAllPoints()
    thumb:SetPoint("TOPRIGHT", track, "TOPRIGHT", 0, -((offset / maxScroll) * travel))
end

scroll:EnableMouseWheel(true)
scroll:SetScript("OnMouseWheel", function(self, delta)
    local maxScroll = math.max(content:GetHeight() - self:GetHeight(), 0)
    local new = self:GetVerticalScroll() - (delta * 30)
    if new < 0 then
        new = 0
    elseif new > maxScroll then
        new = maxScroll
    end
    self:SetVerticalScroll(new)
    UpdateScrollbar()
end)

-- ===== Widgets =====
local function ShowTip(owner, titleText, bodyText)
    if not bodyText or bodyText == "" then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine(titleText, 1, 1, 1)
    GameTooltip:AddLine(bodyText, 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
end

local function CreateCheckbox(parent, def, width)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(22)
    row:SetWidth(width)

    local box = CreateFrame("Frame", nil, row, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 2, 0)
    box:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    box:SetBackdropColor(unpack(ROW_BG))
    box:SetBackdropBorderColor(unpack(BORDER))

    local fill = box:CreateTexture(nil, "OVERLAY")
    fill:SetPoint("TOPLEFT", 3, -3)
    fill:SetPoint("BOTTOMRIGHT", -3, 3)
    fill:SetColorTexture(unpack(ACCENT))

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", box, "RIGHT", 8, 0)
    label:SetPoint("RIGHT", -4, 0)
    label:SetJustifyH("LEFT")
    label:SetText(def.label or def.key)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.04)

    function row:Refresh()
        if ns.IsEnabled(def.key) then
            fill:Show()
            label:SetTextColor(1, 1, 1)
        else
            fill:Hide()
            label:SetTextColor(0.55, 0.55, 0.55)
        end
    end

    row:SetScript("OnClick", function()
        ns.SetEnabled(def.key, not ns.IsEnabled(def.key))
        row:Refresh()
        if def.OnToggle then
            pcall(def.OnToggle, ns.IsEnabled(def.key))
        end
        if ns.RefreshSettings then
            ns.RefreshSettings()
        end
    end)
    row:SetScript("OnEnter", function()
        ShowTip(row, def.label or def.key, def.tooltip)
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return row
end

local function CreateOptionBox(parent, def, width)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(width, 22)
    box:SetAutoFocus(false)
    box:SetFontObject(GameFontHighlight)
    box:SetTextInsets(6, 6, 0, 0)
    box:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    box:SetBackdropColor(unpack(ROW_BG))
    box:SetBackdropBorderColor(unpack(BORDER))
    box:SetText(tostring(ns.GetOption(def.optionKey, def.optionDefault or "")))
    box:SetScript("OnEscapePressed", box.ClearFocus)
    box:SetScript("OnEnterPressed", function(self)
        ns.SetOption(def.optionKey, self:GetText())
        self:ClearFocus()
        ns.Print(def.optionLabel and (def.optionLabel .. " set to: " .. self:GetText()) or "Saved.")
    end)
    return box
end

-- ===== Build the panel from the registry =====
local rows = {}

local function BuildPanel()
    local width = scroll:GetWidth() - 8
    local y = 0

    for _, category in ipairs(ns.categoryOrder) do
        local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOPLEFT", 0, -y)
        header:SetText("|cff33ccff" .. category .. "|r")
        y = y + 22

        for _, def in ipairs(ns.modules[category]) do
            local cb = CreateCheckbox(content, def, width)
            cb:SetPoint("TOPLEFT", 6, -y)
            table.insert(rows, cb)
            y = y + 22

            if def.optionKey then
                local ob = CreateOptionBox(content, def, 180)
                ob:SetPoint("TOPLEFT", 30, -y)
                local hint = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                hint:SetPoint("LEFT", ob, "RIGHT", 8, 0)
                hint:SetText(def.optionHint or "press Enter to save")
                y = y + 26
            end
        end
        y = y + 10
    end

    content:SetSize(width, math.max(y, 1))
    UpdateScrollbar()
end

function ns.RefreshSettings()
    for _, row in ipairs(rows) do
        row:Refresh()
    end
end

function ns.ToggleSettings()
    if main:IsShown() then
        main:Hide()
        return
    end
    if #rows == 0 then
        BuildPanel()
    end
    ns.RefreshSettings()
    main:Show()
    UpdateScrollbar()
end

-- ===== Minimap button =====
-- Registered here rather than in a module file because it needs
-- ToggleSettings, and the settings panel builds lazily on first open, so
-- registering at this point still lands before the panel is constructed.
local minimapBtn

ns.RegisterModule({
    key = "minimapButton",
    category = "Interface",
    label = "Show minimap button",
    tooltip = "Adds a button beside the minimap that opens this window. Drag it around the minimap edge to reposition. Turn off if you use /fqol instead.",
    default = true,
    OnToggle = function(enabled)
        if minimapBtn then
            minimapBtn:SetShown(enabled)
        end
    end,
})

-- Lua 5.1 (what WoW runs) has math.atan2; guard anyway in case a future
-- client drops it the way 5.3 did.
local atan2 = math.atan2 or math.atan

local function UpdateMinimapPosition()
    if not minimapBtn then
        return
    end
    local angle = math.rad(tonumber(ns.GetOption("minimapAngle", 200)) or 200)
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(angle), 80 * math.sin(angle))
end

local function BuildMinimapButton()
    if minimapBtn or not Minimap then
        return
    end

    local btn = CreateFrame("Button", "ForeverQoLMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetMovable(true)

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    btn:SetScript("OnClick", function()
        ns.ToggleSettings()
    end)

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            cx, cy = cx / scale, cy / scale
            ns.SetOption("minimapAngle", math.deg(atan2(cy - my, cx - mx)))
            UpdateMinimapPosition()
        end)
    end)
    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("ForeverQoL", 1, 1, 1)
        GameTooltip:AddLine("Click to open settings.", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag to move around the minimap.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    minimapBtn = btn
    UpdateMinimapPosition()
    btn:SetShown(ns.IsEnabled("minimapButton"))
end

-- ns.db doesn't exist until ADDON_LOADED, so the button is built after
-- saved variables are available rather than at file-load time.
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function()
    BuildMinimapButton()
end)
