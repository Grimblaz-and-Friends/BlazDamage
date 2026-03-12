-- UI/EventHandler.lua
-- Event registration and throttled stat refresh. UI layer — TOC-loaded only.

local _, BD = ...

local EventHandler = {}
BD.EventHandler = EventHandler

local frame    = CreateFrame("Frame")
local dirty    = false
local THROTTLE = 0.1  -- seconds
local elapsed  = 0    -- throttle accumulator

local function onUpdate(self, dt)
    elapsed = elapsed + dt
    if elapsed >= THROTTLE and dirty then
        BD.StatCollector.refresh()
        BD.OverlayRenderer.refreshAll()
        dirty = false
        elapsed = 0
        frame:SetScript("OnUpdate", nil)  -- unregister when not dirty
    end
end

local function setDirty()
    if not dirty then
        dirty = true
        elapsed = 0
        frame:SetScript("OnUpdate", onUpdate)
    end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterUnitEvent("UNIT_AURA", "player")
frame:RegisterEvent("COMBAT_RATING_UPDATE")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        BD.ActionbarDiscovery.init()
        setDirty()
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        local slot = ...
        if slot == 0 then
            BD.OverlayRenderer.refreshAll()
        else
            BD.OverlayRenderer.refreshSlot(slot)
        end
    else
        setDirty()
    end
end)
