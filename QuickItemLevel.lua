local addonName, addonTable = ...
local QuickItemLevel = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

-- Default configuration values
local defaults = {
    global = {
        cacheSize = 2500,
        shiftKeyRequired = false,
        inspectDelay = 0.025,
        cacheExpireTime = 600,
        showSpec = true,
        showItemLevel = true,
        tooltipStyle = "inline",
        showHeader = false,
    }
}

-- Localization for performance improvement
local _G = _G
local time = time
local tostring = tostring
local strsub = strsub
local UnitGUID = UnitGUID
local UnitIsPlayer = UnitIsPlayer
local UnitClass = UnitClass
local GetInspectSpecialization = GetInspectSpecialization
local GetSpecializationInfoByID = GetSpecializationInfoByID
local C_PaperDollInfo = C_PaperDollInfo
local GameTooltip_SetTooltipWaitingForData = GameTooltip_SetTooltipWaitingForData

local QuickItemLevelDebug = false

local printDebug = QuickItemLevelDebug and print or function()
end

-- LRU cache implementation
local InspectCache = {}
local InspectCacheOrder = {} -- LRU order

local function UpdateCacheOrder(key)
    for i, k in ipairs(InspectCacheOrder) do
        if k == key then
            table.remove(InspectCacheOrder, i)
            break
        end
    end
    table.insert(InspectCacheOrder, key)
end

local function TrimCache()
    while #InspectCacheOrder > QuickItemLevel.db.global.cacheSize do
        local key = table.remove(InspectCacheOrder, 1)
        InspectCache[key] = nil
        printDebug("Removed cache entry for " .. key .. " due to cache size limit")
    end
end

function QuickItemLevel:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("QuickItemLevelDB", defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self:GetOptions())
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, "Quick Item Level")

    self:RegisterChatCommand("qil", "ChatCommand")
    self:RegisterChatCommand("quickitemlevel", "ChatCommand")
end

function QuickItemLevel:GetOptions()
    return {
        type = "group",
        childGroups = "tab",
        args = {
            settings = {
                type = "group",
                name = "Settings",
                order = 1,
                args = {
                    cacheSize = {
                        order = 1,
                        type = "range",
                        name = "Cache Size",
                        desc = "Set the maximum number of player inspections to keep in the cache.",
                        min = 100,
                        max = 5000,
                        step = 100,
                        get = function()
                            return self.db.global.cacheSize
                        end,
                        set = function(_, value)
                            self.db.global.cacheSize = value;
                            TrimCache()
                        end
                    },
                    inspectDelay = {
                        order = 2,
                        type = "range",
                        name = "Inspection Delay",
                        desc = "Set the delay (in seconds) before performing an inspection.",
                        min = 0,
                        max = 1,
                        step = 0.01,
                        get = function()
                            return self.db.global.inspectDelay
                        end,
                        set = function(_, value)
                            self.db.global.inspectDelay = value
                        end
                    },
                    cacheExpireTime = {
                        order = 3,
                        type = "range",
                        name = "Cache Expiration",
                        desc = "Time in seconds before cached inspection data expires.",
                        min = 60,
                        max = 3600,
                        step = 60,
                        get = function()
                            return self.db.global.cacheExpireTime
                        end,
                        set = function(_, value)
                            self.db.global.cacheExpireTime = value
                        end
                    },
                    spacer = {
                        order = 4,
                        type = "description",
                        name = "",
                    },
                    shiftKeyRequired = {
                        order = 5,
                        type = "toggle",
                        name = "Require Shift Key",
                        desc = "Only perform inspections when the Shift key is held down.",
                        get = function()
                            return self.db.global.shiftKeyRequired
                        end,
                        set = function(_, value)
                            self.db.global.shiftKeyRequired = value
                        end
                    },
                    showSpec = {
                        order = 6,
                        type = "toggle",
                        name = "Show Specialization",
                        desc = "Display the player's specialization in the tooltip.",
                        get = function()
                            return self.db.global.showSpec
                        end,
                        set = function(_, value)
                            self.db.global.showSpec = value
                        end
                    },
                    showItemLevel = {
                        order = 7,
                        type = "toggle",
                        name = "Show Item Level",
                        desc = "Display the player's item level in the tooltip.",
                        get = function()
                            return self.db.global.showItemLevel
                        end,
                        set = function(_, value)
                            self.db.global.showItemLevel = value
                        end
                    },
                    showHeader = {
                        order = 8,
                        type = "toggle",
                        name = "Show Header",
                        desc = "Display the 'Quick Item Level' header above the spec and item level info.",
                        get = function()
                            return self.db.global.showHeader
                        end,
                        set = function(_, value)
                            self.db.global.showHeader = value
                        end
                    },
                    tooltipStyle = {
                        order = 9,
                        type = "select",
                        name = "Tooltip Style",
                        desc = "Choose how spec and item level are displayed in the tooltip.",
                        values = {
                            ["inline"] = "Inline Colors",
                            ["sidebyside"] = "Side by Side",
                            ["stacked"] = "Stacked Lines",
                        },
                        get = function()
                            return self.db.global.tooltipStyle
                        end,
                        set = function(_, value)
                            self.db.global.tooltipStyle = value
                        end
                    },
                },
            },
        },
    }
end

function QuickItemLevel:ChatCommand(input)
    if input == "" then
        LibStub("AceConfigDialog-3.0"):Open(addonName)
    end
end

local function GetSpecNameByID(specID)
    local specName = select(2, GetSpecializationInfoByID(specID))
    return specName or "N/A"
end

local function GetInspectData(guid)
    local data = InspectCache[guid]
    if data then
        if time() - data.timestamp >= QuickItemLevel.db.global.cacheExpireTime then
            InspectCache[guid] = nil
            printDebug("Removed cache entry for " .. guid .. " due to expiration")
            return nil
        else
            UpdateCacheOrder(guid)
        end
    end
    return data
end

local function SetInspectData(guid, data)
    if not InspectCache[guid] then
        if #InspectCacheOrder >= QuickItemLevel.db.global.cacheSize then
            TrimCache()
        end
        UpdateCacheOrder(guid)
    end
    InspectCache[guid] = data
end

local inspectQueue = {}
local qilWaitingForData = false
local pendingInspectGuid = nil
local pendingInspectUnit = nil


local function ProcessInspectQueue()
    if #inspectQueue > 0 then
        local entry = table.remove(inspectQueue, 1)
        local guid, unit = entry[1], entry[2]
        if UnitGUID(unit) == guid and CanInspect(unit, true) then
            pendingInspectGuid = guid
            pendingInspectUnit = unit
            NotifyInspect(unit)
            printDebug("Inspecting " .. (UnitName(unit) or "unknown"))
        else
            printDebug("Cannot inspect, skipping")
        end
    end
end

local function UpdateUnitTooltip(tooltip, unit)
    if not unit or not UnitIsPlayer(unit) then
        return
    end

    local guid = UnitGUID(unit)
    local data = InspectCache[guid]

    if data then
        GameTooltip_SetTooltipWaitingForData(tooltip, false)
        qilWaitingForData = false

        if tooltip.qilGuid == guid then
            return
        end
        tooltip.qilGuid = guid

        if not data.class then return end

        local specColor = RAID_CLASS_COLORS[data.class]

        if specColor == nil then
            printDebug("ERROR: specColor is nil for " .. tostring(data.class))
            specColor = RAID_CLASS_COLORS["PRIEST"]
        end

        local showSpec = QuickItemLevel.db.global.showSpec
        local showIlvl = QuickItemLevel.db.global.showItemLevel
        local style = QuickItemLevel.db.global.tooltipStyle

        if not showSpec and not showIlvl then return end

        local specName = tostring(data.specName)
        local classHex = string.format("|cFF%02x%02x%02x", specColor.r * 255, specColor.g * 255, specColor.b * 255)
        local goldHex = "|cFFFFD900"
        local goldR, goldG, goldB = 1, 0.85, 0

        tooltip:AddLine(" ")
        if QuickItemLevel.db.global.showHeader then
            tooltip:AddLine("Quick Item Level", goldR, goldG, goldB, 1)
        end

        if style == "sidebyside" then
            if showSpec and showIlvl then
                tooltip:AddDoubleLine(specName, data.ilevel, specColor.r, specColor.g, specColor.b, goldR, goldG, goldB)
            elseif showSpec then
                tooltip:AddLine(specName, specColor.r, specColor.g, specColor.b, 1)
            else
                tooltip:AddLine("iLvl " .. data.ilevel, goldR, goldG, goldB, 1)
            end
        elseif style == "stacked" then
            if showSpec then
                tooltip:AddLine(specName, specColor.r, specColor.g, specColor.b, 1)
            end
            if showIlvl then
                tooltip:AddLine("Item Level " .. data.ilevel, goldR, goldG, goldB, 1)
            end
        else -- inline
            if showSpec and showIlvl then
                tooltip:AddLine(classHex .. specName .. " " .. goldHex .. "(" .. data.ilevel .. ")|r")
            elseif showSpec then
                tooltip:AddLine(specName, specColor.r, specColor.g, specColor.b, 1)
            else
                tooltip:AddLine("iLvl " .. data.ilevel, goldR, goldG, goldB, 1)
            end
        end

        tooltip:Show()
    else
        GameTooltip_SetTooltipWaitingForData(tooltip, true)
    end
end

function QuickItemLevel:OnShiftKeyDown()
    if not self.db.global.shiftKeyRequired then
        return
    end

    local unit = "mouseover"
    if UnitIsPlayer(unit) then
        self:UPDATE_MOUSEOVER_UNIT()
    end
end

function QuickItemLevel:OnEnable()
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    self:RegisterEvent("INSPECT_READY")

    GameTooltip:HookScript("OnTooltipCleared", function(self)
        self.qilGuid = nil
        self.qilInspectGuid = nil
    end)

    GameTooltip:HookScript("OnUpdate", function(self)
        local ok, _, unit = pcall(self.GetUnit, self)
        if not ok then return end

        local isPlayer = false
        if unit then
            local ok2, result = pcall(UnitIsPlayer, unit)
            if ok2 then isPlayer = result end
        end

        if not unit or not isPlayer then
            if qilWaitingForData then
                GameTooltip_SetTooltipWaitingForData(self, false)
                qilWaitingForData = false
            end
            self.qilGuid = nil
            return
        end

        local guid = UnitGUID(unit)
        local data = InspectCache[guid]

        if data then
            UpdateUnitTooltip(self, unit)
            qilWaitingForData = false
        else
            GameTooltip_SetTooltipWaitingForData(self, true)
            qilWaitingForData = true

            -- Initiate inspection for non-mouseover units (mouseover handled by UPDATE_MOUSEOVER_UNIT)
            if unit ~= "mouseover" and not self.qilInspectGuid then
                self.qilInspectGuid = guid
                local shiftKeyDown = IsShiftKeyDown()
                if (not QuickItemLevel.db.global.shiftKeyRequired or shiftKeyDown) and CanInspect(unit, true) then
                    local capturedUnit = unit
                    C_Timer.After(QuickItemLevel.db.global.inspectDelay, function()
                        if UnitGUID(capturedUnit) == guid then
                            table.insert(inspectQueue, 1, {guid, capturedUnit})
                            printDebug("Queued tooltip inspect for " .. (UnitName(capturedUnit) or "unknown"))
                            ProcessInspectQueue()
                        end
                    end)
                end
            end
        end
    end)

    -- Register the Shift key press event
    self:RegisterEvent("MODIFIER_STATE_CHANGED")
end

function QuickItemLevel:MODIFIER_STATE_CHANGED(_, key, state)
    if key == "LSHIFT" and state == 1 then
        self:OnShiftKeyDown()
    end
end

function QuickItemLevel:UPDATE_MOUSEOVER_UNIT()
    printDebug("UPDATE_MOUSEOVER_UNIT")
    local unit = "mouseover"
    if UnitIsPlayer(unit) then
        local guid = UnitGUID(unit)
        -- pcall guards against tainted guid from other addons' event dispatch chains
        local ok, data = pcall(GetInspectData, guid)
        if not ok then return end
        local shiftKeyDown = IsShiftKeyDown()

        if not data or (time() - data.timestamp >= self.db.global.cacheExpireTime) then
            if (not self.db.global.shiftKeyRequired or shiftKeyDown) and CanInspect(unit, true) then
                C_Timer.After(self.db.global.inspectDelay, function()
                    local ok, match = pcall(function() return UnitGUID("mouseover") == guid end)
                    if ok and match then
                        table.insert(inspectQueue, 1, {guid, "mouseover"})
                        printDebug("Queued mouseover inspect for " .. (UnitName(unit) or "unknown"))
                        ProcessInspectQueue()
                    end
                end)
            else
                printDebug("Cannot inspect " .. (UnitName(unit) or "unknown") .. ", skipping")
            end
        else
            printDebug("Using cached data for " .. (UnitName(unit) or "unknown") .. ", last updated " .. (time() - data.timestamp) ..
                           " seconds ago")
            UpdateUnitTooltip(GameTooltip, unit)
        end
    end
end

function QuickItemLevel:INSPECT_READY()
    if not pendingInspectGuid or not pendingInspectUnit then
        return
    end

    local unit = pendingInspectUnit
    local unitGuid = UnitGUID(unit)

    if unitGuid and unitGuid == pendingInspectGuid then
        pendingInspectGuid = nil
        pendingInspectUnit = nil

        local className, classFile, classId = UnitClass(unit)
        local spec = GetInspectSpecialization(unit)
        local specName = GetSpecNameByID(spec)
        local ilevel = C_PaperDollInfo.GetInspectItemLevel(unit)

        if ilevel ~= 0 then
            local data = {
                class = classFile,
                spec = spec,
                specName = specName,
                ilevel = ilevel,
                timestamp = time()
            }

            SetInspectData(unitGuid, data)
            printDebug("InspectUnit: " .. unitGuid .. " " .. classFile .. " " .. spec .. " " .. ilevel)
            UpdateUnitTooltip(GameTooltip, unit)
        end
    end
end
