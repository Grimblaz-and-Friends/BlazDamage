-- UI/ActionbarDiscovery.lua
-- Discovers actionbar buttons and attaches overlays. UI layer — WoW API permitted.

local _, BD = ...
if type(BD) ~= "table" then BD = {} end

local ActionbarDiscovery = {}

local PREFIX = BD.PREFIX
local initialized = false

-- Bars 11 and 12 are the ElvUI pet bar and stance bar; no offensive spell actions there.
local ELVUI_BAR_IDS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13, 14, 15}

local function scanDefaultButtons()
    local names = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
    }
    for _, prefix in ipairs(names) do
        for i = 1, 12 do
            local button = _G[prefix .. i]
            if button then
                BD.OverlayRenderer.attachOverlay(button)
            end
        end
    end
end

local function scanElvUIButtons()
    if not ElvUI then return end
    local found = 0
    for _, id in ipairs(ELVUI_BAR_IDS) do
        for slot = 1, 12 do
            local button = _G["ElvUI_Bar" .. id .. "Button" .. slot]
            if button then
                BD.OverlayRenderer.attachOverlay(button)
                found = found + 1
            end
        end
    end
    if found == 0 then
        print(PREFIX .. " ElvUI detected but no buttons found. Ensure the ElvUI ActionBar module is enabled in /ec.")
    end
end

-- Scan all known button sources at init time (handles already-registered buttons at PLAYER_ENTERING_WORLD).
local function scanAll()
    scanDefaultButtons()
    scanElvUIButtons()
end

local function initAuto()
    local ok = pcall(hooksecurefunc, "ActionBarButtonEventsFrame_RegisterFrame", function(button)
        BD.OverlayRenderer.attachOverlay(button)
    end)
    if not ok then
        print(PREFIX .. " Auto discovery failed. Try /bd discovery update and /reload")
    end
    scanAll()
end

local function initUpdate()
    local ok = pcall(hooksecurefunc, "ActionButton_Update", function(button)
        BD.OverlayRenderer.attachOverlay(button)
    end)
    if not ok then
        print(PREFIX .. " Update discovery failed. Try /bd discovery auto and /reload")
    end
    scanAll()
end

function ActionbarDiscovery.init()
    if initialized then return end
    local mode = BD.config and BD.config.discoveryMode or BD.defaults.discoveryMode
    if mode == "update" then
        initUpdate()
    else
        initAuto()
    end
    initialized = true
end

BD.ActionbarDiscovery = ActionbarDiscovery
