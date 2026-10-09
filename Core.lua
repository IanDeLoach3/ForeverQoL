local ADDON_NAME, ns = ...

ns.ADDON_NAME = ADDON_NAME
ns.ACCENT_CHAT = "|cff33ccff"

function ns.Print(msg)
    print(ns.ACCENT_CHAT .. "[FQoL]|r " .. msg)
end

-- ===== Module registry =====
-- Every feature registers itself here with a key, a category, and a default.
-- UI.lua loads LAST and builds the entire settings panel from whatever
-- registered, so adding a feature means writing one module file and touching
-- no UI code at all.
--
-- Modules keep their event handlers registered permanently and check
-- ns.IsEnabled(key) when the event actually fires, rather than
-- registering/unregistering on toggle. Fewer moving parts, and toggling a
-- setting takes effect instantly with no enable/disable bookkeeping.
ns.modules = {}        -- category -> { def, def, ... }
ns.categoryOrder = {}  -- categories in registration order

function ns.RegisterModule(def)
    if not def or not def.key or not def.category then
        error("ForeverQoL: RegisterModule needs at least { key, category }")
    end
    if not ns.modules[def.category] then
        ns.modules[def.category] = {}
        table.insert(ns.categoryOrder, def.category)
    end
    table.insert(ns.modules[def.category], def)
    return def
end

function ns.IsEnabled(key)
    return ns.db and ns.db.settings and ns.db.settings[key] == true
end

function ns.SetEnabled(key, value)
    if not (ns.db and ns.db.settings) then
        return
    end
    ns.db.settings[key] = value and true or false
end

-- Optional per-module setting that isn't a simple on/off (e.g. the invite
-- keyword). Stored alongside the toggles but keyed separately so a module
-- can keep arbitrary config without needing its own SavedVariables entry.
function ns.GetOption(key, fallback)
    if not (ns.db and ns.db.options) then
        return fallback
    end
    local v = ns.db.options[key]
    if v == nil then
        return fallback
    end
    return v
end

function ns.SetOption(key, value)
    if ns.db and ns.db.options then
        ns.db.options[key] = value
    end
end

-- ===== Saved variables =====
local function ApplyDefaults()
    ns.db.settings = ns.db.settings or {}
    ns.db.options = ns.db.options or {}
    for _, category in ipairs(ns.categoryOrder) do
        for _, def in ipairs(ns.modules[category]) do
            if ns.db.settings[def.key] == nil then
                ns.db.settings[def.key] = def.default and true or false
            end
            if def.optionKey and def.optionDefault ~= nil and ns.db.options[def.optionKey] == nil then
                ns.db.options[def.optionKey] = def.optionDefault
            end
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        ForeverQoLDB = ForeverQoLDB or {}
        ns.db = ForeverQoLDB
        ApplyDefaults()
        -- Modules that need to do something once at load (set a CVar, etc.)
        for _, category in ipairs(ns.categoryOrder) do
            for _, def in ipairs(ns.modules[category]) do
                if def.OnLoad then
                    local ok, err = pcall(def.OnLoad)
                    if not ok then
                        ns.Print("|cffff5555Error loading " .. def.key .. ":|r " .. tostring(err))
                    end
                end
            end
        end
    elseif event == "PLAYER_LOGIN" then
        local count = 0
        for _, category in ipairs(ns.categoryOrder) do
            for _, def in ipairs(ns.modules[category]) do
                if ns.IsEnabled(def.key) then
                    count = count + 1
                end
            end
        end
        ns.Print("loaded -- " .. count .. " feature(s) active. Type |cffffff00/fqol|r to configure.")
    end
end)

SLASH_FOREVERQOL1 = "/fqol"
SLASH_FOREVERQOL2 = "/foreverqol"
SlashCmdList["FOREVERQOL"] = function(msg)
    local cmd = (msg or ""):gsub("^%s*(.-)%s*$", "%1"):lower()

    if cmd == "copy" then
        if ns.ShowChatCopy then
            ns.ShowChatCopy()
        end
    elseif cmd == "help" then
        ns.Print("|cffffff00/fqol|r - open settings")
        ns.Print("|cffffff00/fqol copy|r - open the chat copy window")
    else
        if ns.ToggleSettings then
            ns.ToggleSettings()
        end
    end
end
