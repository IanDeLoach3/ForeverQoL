local ADDON_NAME, ns = ...

-- Bug report / suggestion window. An addon can't send anything over the
-- internet, so this builds a ready-to-paste report (your description plus
-- automatically gathered technical details) and shows the GitHub issues link
-- to paste it into. No character name, realm, or account info is ever included.

local WHITE = "Interface\\Buttons\\WHITE8x8"
local ISSUES_URL = "https://github.com/IanDeLoach3/ForeverQoL/issues/new"

local frame
local currentKind

local function AddonVersion()
    local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return (getMeta and getMeta(ADDON_NAME, "Version")) or "unknown"
end

local function BuildReportText(kind, description)
    local lines = {}
    lines[#lines + 1] = (kind == "bug" and "BUG REPORT" or "SUGGESTION") .. " -- ForeverQoL v" .. AddonVersion()
    lines[#lines + 1] = ""
    lines[#lines + 1] = (kind == "bug") and "What happened (and what I expected):" or "My idea:"
    lines[#lines + 1] = (description ~= "" and description) or "(write your description in the box above)"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "-- Added automatically (no character info) --"

    local version, build, _, toc = GetBuildInfo()
    lines[#lines + 1] = "Game: " .. tostring(version) .. " (build " .. tostring(build) .. ", interface " .. tostring(toc) .. ")"
    lines[#lines + 1] = "Locale: " .. tostring(GetLocale())

    local enabled, total = {}, 0
    for _, category in ipairs(ns.categoryOrder) do
        for _, def in ipairs(ns.modules[category]) do
            total = total + 1
            if ns.IsEnabled(def.key) then
                enabled[#enabled + 1] = def.key
            end
        end
    end
    lines[#lines + 1] = "Features on (" .. #enabled .. "/" .. total .. "): " .. (#enabled > 0 and table.concat(enabled, ", ") or "none")

    if kind == "bug" then
        local errs = ns.recentErrors or {}
        if #errs == 0 then
            lines[#lines + 1] = "Recent ForeverQoL errors: none caught this session"
        else
            lines[#lines + 1] = "Recent ForeverQoL errors:"
            for _, e in ipairs(errs) do
                lines[#lines + 1] = "  " .. e
            end
        end
    end
    return table.concat(lines, "\n")
end

-- A bordered, scrollable multi-line text box. Returns the outer frame and the EditBox.
local function MakeTextBox(parent, x, y, w, h)
    local bg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", x, y)
    bg:SetSize(w, h)
    bg:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    bg:SetBackdropColor(0.12, 0.12, 0.13, 1)
    bg:SetBackdropBorderColor(0.28, 0.28, 0.30)

    local scroll = CreateFrame("ScrollFrame", nil, bg, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -4)
    scroll:SetPoint("BOTTOMRIGHT", -26, 4)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(ChatFontNormal)
    edit:SetAutoFocus(false)
    edit:SetWidth(w - 36)
    edit:SetScript("OnEscapePressed", edit.ClearFocus)
    -- Keep the text cursor in view while typing in a long box.
    edit:SetScript("OnCursorChanged", function(self, _, y2, _, h2)
        local top = -y2
        local viewTop = scroll:GetVerticalScroll()
        local viewH = scroll:GetHeight()
        if top < viewTop then
            scroll:SetVerticalScroll(top)
        elseif top + h2 > viewTop + viewH then
            scroll:SetVerticalScroll(top + h2 - viewH)
        end
    end)
    scroll:SetScrollChild(edit)
    return bg, edit
end

local function MakeLabel(parent, x, y, text, template)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    return fs
end

local function Regenerate()
    if frame and currentKind then
        frame.output:SetText(BuildReportText(currentKind, frame.input:GetText()))
    end
end

local function BuildFrame()
    local f = CreateFrame("Frame", "ForeverQoLReportFrame", UIParent, "BackdropTemplate")
    f:SetSize(560, 496)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    f:SetBackdropColor(0.07, 0.07, 0.08, 0.97)
    f:SetBackdropBorderColor(0.20, 0.60, 0.85)
    f:Hide()
    tinsert(UISpecialFrames, "ForeverQoLReportFrame")

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOPLEFT", 16, -14)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    f.hint = MakeLabel(f, 16, -42, "", "GameFontDisableSmall")
    f.hint:SetWidth(528)

    f.inputLabel = MakeLabel(f, 16, -72, "")
    local _, input = MakeTextBox(f, 16, -92, 528, 104)
    f.input = input
    input:SetScript("OnTextChanged", Regenerate)

    MakeLabel(f, 16, -208, "Your report (this is what you paste):")
    local _, output = MakeTextBox(f, 16, -228, 528, 150)
    f.output = output
    -- The report is generated, not typed: if someone edits it directly, rebuild it.
    output:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            Regenerate()
        end
    end)

    MakeLabel(f, 16, -390, "Paste it into a new issue here (copy this link into your browser):")
    local linkBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
    linkBg:SetPoint("TOPLEFT", 16, -410)
    linkBg:SetSize(528, 24)
    linkBg:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    linkBg:SetBackdropColor(0.12, 0.12, 0.13, 1)
    linkBg:SetBackdropBorderColor(0.28, 0.28, 0.30)
    local link = CreateFrame("EditBox", nil, linkBg)
    link:SetPoint("TOPLEFT", 6, 0)
    link:SetPoint("BOTTOMRIGHT", -6, 0)
    link:SetFontObject(ChatFontNormal)
    link:SetAutoFocus(false)
    link:SetText(ISSUES_URL)
    link:SetScript("OnEscapePressed", link.ClearFocus)
    link:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            self:SetText(ISSUES_URL)
            self:HighlightText()
        end
    end)
    f.link = link

    local copyReport = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    copyReport:SetSize(150, 24)
    copyReport:SetPoint("TOPLEFT", 16, -448)
    copyReport:SetText("Select report text")
    copyReport:SetScript("OnClick", function()
        f.output:SetFocus()
        f.output:HighlightText()
    end)

    local copyLink = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    copyLink:SetSize(120, 24)
    copyLink:SetPoint("LEFT", copyReport, "RIGHT", 8, 0)
    copyLink:SetText("Select link")
    copyLink:SetScript("OnClick", function()
        f.link:SetFocus()
        f.link:HighlightText()
    end)

    local copyTip = MakeLabel(f, 0, 0, "then Ctrl+C", "GameFontDisableSmall")
    copyTip:ClearAllPoints()
    copyTip:SetPoint("LEFT", copyLink, "RIGHT", 10, 0)

    return f
end

-- kind: "bug" or "suggest"
function ns.ShowReport(kind)
    kind = (kind == "suggest") and "suggest" or "bug"
    if not frame then
        frame = BuildFrame()
    end
    if currentKind ~= kind then
        currentKind = kind
        frame.input:SetText("")
    end
    if kind == "bug" then
        frame.title:SetText("Report a bug")
        frame.hint:SetText("Describe what went wrong and what you were doing. The report below adds your game version, enabled features, and any recent ForeverQoL errors for you.")
        frame.inputLabel:SetText("What happened, and what did you expect?")
    else
        frame.title:SetText("Suggest a feature")
        frame.hint:SetText("Tell me what you'd like added or changed. The report below adds your game version for context.")
        frame.inputLabel:SetText("What's your idea?")
    end
    Regenerate()
    frame:Show()
    frame.input:SetFocus()
end
