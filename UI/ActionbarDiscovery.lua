-- UI/ActionbarDiscovery.lua
-- Discovers actionbar buttons and attaches overlays. UI layer — WoW API permitted.

local _, BD = ...
if type(BD) ~= "table" then BD = {} end

local ActionbarDiscovery = {}

local PREFIX = "|cFFFFFF00BlazDamage:|r"
local initialized = false

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

local function initAuto()
    local ok = pcall(hooksecurefunc, "ActionBarButtonEventsFrame_RegisterFrame", function(button)
        BD.OverlayRenderer.attachOverlay(button)
    end)
    if not ok then
        print(PREFIX .. " Auto discovery failed. Try /bd discovery update and /reload")
    end
    -- Also scan known buttons immediately (handles already-registered buttons at PLAYER_ENTERING_WORLD)
    scanDefaultButtons()
end

local function initUpdate()
    local ok = pcall(hooksecurefunc, "ActionButton_Update", function(button)
        BD.OverlayRenderer.attachOverlay(button)
    end)
    if not ok then
        print(PREFIX .. " Update discovery failed. Try /bd discovery auto and /reload")
    end
    scanDefaultButtons()
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
