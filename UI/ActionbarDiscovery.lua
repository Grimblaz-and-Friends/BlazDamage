-- UI/ActionbarDiscovery.lua
-- Discovers actionbar buttons and attaches overlays. UI layer — WoW API permitted.

local _, BD = ...
if type(BD) ~= "table" then BD = {} end

local ActionbarDiscovery = {}

local PREFIX = BD.PREFIX
local initialized = false

-- Bars 11 and 12 are the ElvUI pet bar and stance bar; player stats don't apply to pet or stance abilities.
local ELVUI_BAR_IDS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13, 14, 15}

local function scanDefaultButtons()
    local names = {
        "ActionButton",
        "MultiBarBottomLeftButton",
        "MultiBarBottomRightButton",
        "MultiBarRightButton",
        "MultiBarLeftButton",
    }
    local defaultFound = 0
    for _, prefix in ipairs(names) do
        for i = 1, 12 do
            local button = _G[prefix .. i]
            if button then
                pcall(BD.OverlayRenderer.attachOverlay, button)  -- per-button; degrade gracefully on individual failure
                defaultFound = defaultFound + 1
            end
        end
    end
    if defaultFound == 0 then
        print(PREFIX .. " No default actionbar buttons found. UI may not have loaded yet.")
    end
end

local function scanElvUIButtons()
    if not ElvUI then return end
    local buttonCount = 0
    for _, id in ipairs(ELVUI_BAR_IDS) do
        for slot = 1, 12 do
            local button = _G["ElvUI_Bar" .. id .. "Button" .. slot]
            if button then
                pcall(BD.OverlayRenderer.attachOverlay, button)  -- per-button; degrade gracefully on individual failure
                buttonCount = buttonCount + 1
            end
        end
    end
    if buttonCount == 0 then
        print(PREFIX .. " ElvUI detected but no buttons found. Ensure the ElvUI ActionBar module is enabled in /ec.")
    end
end

-- Scan all known button sources at init time (handles already-registered buttons at PLAYER_ENTERING_WORLD).
local function scanAll()
    scanDefaultButtons()
    scanElvUIButtons()
end

local function initAuto()
    local ok = pcall(hooksecurefunc, ActionBarButtonEventsFrame, "RegisterFrame", function(_, button)
        pcall(BD.OverlayRenderer.attachOverlay, button)
    end)
    if not ok then
        print(PREFIX .. " Auto discovery failed. Try /bd discovery update and /reload")
    end
    scanAll()
end

local function initUpdate()
    local ok = pcall(hooksecurefunc, "ActionButton_Update", function(button)
        pcall(BD.OverlayRenderer.attachOverlay, button)
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
