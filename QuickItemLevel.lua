local addonName, addonTable = ...
local QuickItemLevel = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")

-- Default configuration values
local defaults = {
  global = {
    cacheSize = 2500,
  },
}

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
local GameTooltip_SetTooltipWaitingForData = GameTooltip_SetTooltipWaitingForData

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

local QuickItemLevelDebug = false
local throttleTime = 0.1 -- Throttle time for inspections (in seconds)
local cacheExpireTime = 600 -- Cache expiration time (in seconds)

local printDebug = QuickItemLevelDebug and print or function() end

-- LRU cache implementation
local InspectCache = {}
local InspectCacheOrder = {} -- LRU order

local function UpdateCacheOrder(key)
    local order = InspectCacheOrder[key]
    if order then
        table.remove(InspectCacheOrder, order)
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
    args = {
      cacheSize = {
        order = 1,
        type = "range",
        name = "Cache Size",
        desc = "Set the maximum number of player inspections to keep in the cache.",
        min = 100,
        max = 5000,
        step = 100,
        get = function() return self.db.global.cacheSize end,
        set = function(_, value) self.db.global.cacheSize = value; TrimCache() end,
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
        if time() - data.timestamp >= cacheExpireTime then
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

local lastInspectTime = 0
local inspectQueue = {}

local function ProcessInspectQueue()
    if #inspectQueue > 0 then
        local guid = table.remove(inspectQueue, 1)
        local unit = "mouseover"
        if UnitGUID(unit) == guid and CanInspect(unit, true) then
            NotifyInspect(unit)
            printDebug("Inspecting " .. UnitName(unit))
        else
            printDebug("Cannot inspect, skipping")
        end
    end
end

local function UpdateMouseoverTooltip(self)
    if not UnitIsPlayer("mouseover") then
        return
    end

    local guid = UnitGUID("mouseover")
    local data = InspectCache[guid]

    if data then
        GameTooltip_SetTooltipWaitingForData(self, false)

        local addLine = true

        for i = self:NumLines(), 1, -1 do
            local line = _G[self:GetName().."TextLeft"..i]:GetText()
            if (strsub(line, 1, 16) == "Quick Item Level") then
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
        GameTooltip:AddLine("Quick Item Level", 1, 0.85, 0, 1)
        GameTooltip:AddLine(tostring(specName) .. " (" .. data.ilevel ..")", specColor.r, specColor.g, specColor.b, 1)
        GameTooltip:Show()
    else
        GameTooltip_SetTooltipWaitingForData(self, true)
    end
end

function QuickItemLevel:OnEnable()
  self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
  self:RegisterEvent("INSPECT_READY")

  GameTooltip:HookScript("OnUpdate", function(self)
    if not UnitIsPlayer("mouseover") then
      return
    end

    local guid = UnitGUID("mouseover")
    local data = InspectCache[guid]

    if data then
      UpdateMouseoverTooltip(self)
    else
      GameTooltip_SetTooltipWaitingForData(self, true)
    end
  end)
end

function QuickItemLevel:UPDATE_MOUSEOVER_UNIT()
  printDebug("UPDATE_MOUSEOVER_UNIT")
  local unit = "mouseover"
  if UnitIsPlayer(unit) then
    local guid = UnitGUID(unit)
    local data = GetInspectData(guid)

    if not data or (time() - data.timestamp >= cacheExpireTime) then
      if CanInspect(unit, true) then
        table.insert(inspectQueue, 1, guid)
        printDebug("Queued mouseover inspect for " .. UnitName(unit))
        ProcessInspectQueue()
      else
        printDebug("Cannot inspect " .. UnitName(unit) .. ", skipping")
      end
    else
      printDebug("Using cached data for " .. UnitName(unit) .. ", last updated " .. (time() - data.timestamp) .. " seconds ago")
      UpdateMouseoverTooltip(GameTooltip)
    end
  end
end

function QuickItemLevel:INSPECT_READY(_, guid)
  if guid then
    local class, _, classId = UnitClass("mouseover")
    local spec = GetInspectSpecialization("mouseover")
    local specName = GetSpecNameByID(spec)
    local ilevel = C_PaperDollInfo.GetInspectItemLevel("mouseover")

    if ilevel ~= 0 then
      local data = {
        class = class,
        spec = spec,
        specName = specName,
        ilevel = ilevel,
        timestamp = time()
      }

      SetInspectData(guid, data)
      printDebug("InspectUnit: " .. guid .. " " .. class .. " " .. spec .. " " .. ilevel)

      if UnitGUID("mouseover") == guid then
        printDebug("Refreshing mouseover tooltip for " .. UnitName("mouseover"))
        UpdateMouseoverTooltip(GameTooltip)
      end
    end
  end
end
