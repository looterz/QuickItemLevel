-- Localization for performance improvement
local _G = _G
local pairs = pairs
local time = time
local tostring = tostring
local strsub = strsub
local UnitGUID = UnitGUID
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local GetInspectSpecialization = GetInspectSpecialization
local GetSpecializationInfoByID = GetSpecializationInfoByID
local C_PaperDollInfo = C_PaperDollInfo
local C_Timer = C_Timer
local GameTooltip_SetTooltipWaitingForData = GameTooltip_SetTooltipWaitingForData
local InspectData = {}

local RAID_CLASS_COLORS = {
    ["DEATH KNIGHT"] = { r = 0.77, g = 0.12, b = 0.23 },
    ["DEMON HUNTER"] = { r = 0.64, g = 0.19, b = 0.79 },
    ["DRUID"] = { r = 1.00, g = 0.49, b = 0.04 },
    ["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45 },
    ["MAGE"] = { r = 0.25, g = 0.78, b = 0.92 },
    ["MONK"] = { r = 0.00, g = 1.00, b = 0.59 },
    ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
    ["PRIEST"] = { r = 1.00, g = 1.00, b = 1.00 },
    ["ROGUE"] = { r = 1.00, g = 0.96, b = 0.41 },
    ["SHAMAN"] = { r = 0.00, g = 0.44, b = 0.87 },
    ["WARLOCK"] = { r = 0.53, g = 0.53, b = 0.93 },
    ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 },
    ["EVOKER"] = { r = 0.2, g = 0.576, b = 0.498 }
}

local SimpleItemLevelDebug = false
local inspectDelay = 0.25 -- The delay in seconds before an inspection is initiated
local maxRetries = 10
local retryDelay = 0.25

local function printDebug(msg)
    if SimpleItemLevelDebug then
        print(msg)
    end
end

local function GetSpecNameByID(specID)
    local specId = GetInspectSpecialization("mouseover")
    local specName = select(2, GetSpecializationInfoByID(specId))
    if specName == nil then
        specName = "N/A"
    end
    return specName
end

local function InspectMouseoverUnit()
    if not UnitIsPlayer("mouseover") then
        return
    end

    local class, _, classId = UnitClass("mouseover")
    local _, spec = GetSpecializationInfoByID(GetInspectSpecialization("mouseover"))
    local specName = GetSpecNameByID(spec)
    local ilevel = C_PaperDollInfo.GetInspectItemLevel("mouseover")
    local tag = UnitGUID("mouseover")

    if spec == nil then
        spec = "N/A"
    end

    -- For whatever reason, we failed to inspect the unit
    if ilevel == 0 then
        return
    end

    InspectData[tag] = {
        class = class,
        spec = spec,
        specName = specName,
        ilevel = ilevel,
        timestamp = time()
    }

    printDebug("InspectMouseoverUnit: " .. tag .. " " .. class .. " " .. spec .. " " .. ilevel)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("INSPECT_READY")
frame:RegisterEvent("VARIABLES_LOADED")

local function cleanCache()
    for k, data in pairs(InspectData) do
        if data ~= nil then
            if (time() - data.timestamp >= 300 or data.ilevel == 0 or data.specName == "N/A") then
                InspectData[k] = nil
            end
        end
    end
end

local function RegisterMouseoverLoop()
    C_Timer.After(3, function()
        frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
        RegisterMouseoverLoop()
    end )
end

local function RegisterCacheCleanupLoop()
    C_Timer.After(60, function()
        cleanCache()
        RegisterCacheCleanupLoop()
    end)
end

local function retryNotifyInspect(retriesLeft)
    if (retriesLeft <= 0 or hasInspected or not UnitIsPlayer("mouseover")) then 
        printDebug("retryNotifyInspect: " .. tostring(retriesLeft) .. " " .. tostring(hasInspected) .. " " .. tostring(UnitIsPlayer("mouseover")))
        return 
    end

    C_Timer.After(retryDelay, function()
        if not hasInspected then
            printDebug("retryNotifyInspect: " .. tostring(retriesLeft))

            if CanInspect("mouseover", true) then
                NotifyInspect("mouseover")
            end

            retryNotifyInspect(retriesLeft - 1)
        end
    end)
end

local inspectTimer

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "VARIABLES_LOADED" then
        printDebug("VARIABLES_LOADED")

        frame:UnregisterEvent("VARIABLES_LOADED")
        frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

        RegisterMouseoverLoop()
        RegisterCacheCleanupLoop()
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        printDebug("UPDATE_MOUSEOVER_UNIT")

        local data = InspectData[UnitGUID("mouseover")]

        if data == nil then
            if inspectTimer then
                inspectTimer:Cancel()
            end

            inspectTimer = C_Timer.NewTimer(inspectDelay, function()
                frame:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
                frame:RegisterEvent("INSPECT_READY")
                if CanInspect("mouseover", true) then
                    NotifyInspect("mouseover")
                    hasInspected = false
                end
                retryNotifyInspect(maxRetries)
            end)
        end
    elseif event == "INSPECT_READY" then
        printDebug("INSPECT_READY")

        if inspectTimer then
            inspectTimer:Cancel()
        end

        hasInspected = true
        InspectMouseoverUnit()
        frame:UnregisterEvent("INSPECT_READY")
        frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    end
end)

local function UpdateMouseoverTooltip(self, elapsed)
    if not UnitIsPlayer("mouseover") then
        return
    end
    
    local data = InspectData[UnitGUID("mouseover")]

    if data ~= nil then
        GameTooltip_SetTooltipWaitingForData(self, false)

        local addLine = true

        for i = self:NumLines(), 1, -1 do
            local line = _G[self:GetName().."TextLeft"..i]:GetText()
            if (strsub(line, 1, 17) == "Simple Item Level") then
                addLine = false
                break
            end
        end

        if not addLine then return end

        local specName = data.specName
        local specColor = RAID_CLASS_COLORS[string.upper(data.class)]

        if specColor == nil then
            printDebug("ERROR: specColor is nil for " .. data.class)
            specColor = RAID_CLASS_COLORS["PRIEST"]
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Simple Item Level", 1, 0.85, 0, 1)
        GameTooltip:AddLine(tostring(specName) .. " (" .. data.ilevel ..")", specColor.r, specColor.g, specColor.b, 1)
        GameTooltip:Show()
    else
        GameTooltip_SetTooltipWaitingForData(self, true)
    end
end
GameTooltip:HookScript("OnUpdate", UpdateMouseoverTooltip)
