-- AuctionMaster Events
local addonName, AM = ...
local L = AM.L

-- Initialize the events module
AM.Events = {}
local Events = AM.Events

-- Event frame
local eventFrame = CreateFrame("Frame")

-- Registered events
local registeredEvents = {}

-- Event callbacks
local eventCallbacks = {}

-- Initialize events
function Events:Initialize()
    -- Register for addon loaded event
    eventFrame:RegisterEvent("ADDON_LOADED")
    
    -- Set up event handler
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        Events:OnEvent(event, ...)
    end)
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Events system initialized")
end

-- Handle events
function Events:OnEvent(event, ...)
    -- Handle addon loading
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            self:OnAddonLoaded()
        end
        return
    end
    
    -- Process registered events
    if registeredEvents[event] then
        -- Call all registered callbacks for this event
        for _, callback in ipairs(eventCallbacks[event] or {}) do
            callback(...)
        end
    end
end

-- Handle addon loaded event
function Events:OnAddonLoaded()
    -- Initialize database
    AM.DB:Initialize()
    
    -- Register for other events
    self:RegisterEvent("AUCTION_HOUSE_SHOW")
    self:RegisterEvent("AUCTION_HOUSE_CLOSED")
    self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
    self:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
    self:RegisterEvent("AUCTION_BIDDER_LIST_UPDATE")
    self:RegisterEvent("PLAYER_LOGOUT")
    
    -- Register slash commands
    self:RegisterSlashCommands()
    
    -- Print loaded message
    print("|cFF00CCFF" .. L:Get("LOADED_MESSAGE", AM.Constants.VERSION) .. "|r")
    
    -- Initialize other modules
    AM:Initialize()
end

-- Register for an event
function Events:RegisterEvent(event)
    if not registeredEvents[event] then
        eventFrame:RegisterEvent(event)
        registeredEvents[event] = true
        eventCallbacks[event] = {}
    end
end

-- Unregister from an event
function Events:UnregisterEvent(event)
    if registeredEvents[event] then
        eventFrame:UnregisterEvent(event)
        registeredEvents[event] = nil
        eventCallbacks[event] = nil
    end
end

-- Add a callback for an event
function Events:AddCallback(event, callback)
    if not registeredEvents[event] then
        self:RegisterEvent(event)
    end
    
    if not eventCallbacks[event] then
        eventCallbacks[event] = {}
    end
    
    table.insert(eventCallbacks[event], callback)
end

-- Remove a callback for an event
function Events:RemoveCallback(event, callback)
    if not eventCallbacks[event] then return end
    
    for i, cb in ipairs(eventCallbacks[event]) do
        if cb == callback then
            table.remove(eventCallbacks[event], i)
            break
        end
    end
    
    -- Unregister event if no more callbacks
    if #eventCallbacks[event] == 0 then
        self:UnregisterEvent(event)
    end
end

-- Fire a custom event
function Events:FireEvent(event, ...)
    if eventCallbacks[event] then
        for _, callback in ipairs(eventCallbacks[event]) do
            callback(...)
        end
    end
end

-- Register slash commands
function Events:RegisterSlashCommands()
    -- Main slash command
    SLASH_AUCTIONMASTER1 = "/auctionmaster"
    SLASH_AUCTIONMASTER2 = "/am"
    
    SlashCmdList["AUCTIONMASTER"] = function(msg)
        local command, args = strsplit(" ", msg, 2)
        command = command:lower()
        
        if command == "scan" then
            -- Start a scan
            if AM.Scanner then
                AM.Scanner:StartScan()
            else
                print("|cFFFF0000" .. L:Get("ERROR_AH_CLOSED") .. "|r")
            end
        elseif command == "search" and args then
            -- Search for an item
            if AM.Scanner then
                AM.Scanner:Search(args)
            else
                print("|cFFFF0000" .. L:Get("ERROR_AH_CLOSED") .. "|r")
            end
        elseif command == "sniper" then
            -- Toggle sniper mode
            if AM.Sniper then
                AM.Sniper:Toggle()
            else
                print("|cFFFF0000" .. L:Get("ERROR_AH_CLOSED") .. "|r")
            end
        elseif command == "reset" then
            -- Reset settings
            AM.DB:ResetSettings()
            print("|cFF00CCFF" .. L:Get("SETTINGS_RESET") .. "|r")
        elseif command == "options" or command == "config" then
            -- Open options panel
            if AM.Settings then
                AM.Settings:Show()
            end
        else
            -- Show help
            print("|cFF00CCFF" .. L:Get("HELP_TITLE") .. "|r")
            print(L:Get("HELP_COMMANDS"))
            print("  " .. L:Get("HELP_SCAN"))
            print("  " .. L:Get("HELP_SEARCH"))
            print("  " .. L:Get("HELP_SNIPER"))
            print("  " .. L:Get("HELP_RESET"))
            print("  " .. L:Get("HELP_OPTIONS"))
        end
    end
end
