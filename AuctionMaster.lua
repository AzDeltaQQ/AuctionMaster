-- AuctionMaster Main File
local addonName, AM = ...

-- Main addon frame
local frame = CreateFrame("Frame")

-- Register for ADDON_LOADED event
frame:RegisterEvent("ADDON_LOADED")

-- Event handler
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        -- Initialize addon
        AM.Events:Initialize()
    end
end)

-- Main addon table
AuctionMaster = {
    -- Version information
    version = AM.Constants.VERSION,
    
    -- Public API functions
    GetMarketValue = function(itemLink)
        return AUCTIONMASTER_API and AUCTIONMASTER_API.GetMarketValue(itemLink) or nil
    end,
    
    GetHistoricalValue = function(itemLink)
        return AUCTIONMASTER_API and AUCTIONMASTER_API.GetHistoricalValue(itemLink) or nil
    end,
    
    GetMinBuyout = function(itemLink)
        return AUCTIONMASTER_API and AUCTIONMASTER_API.GetMinBuyout(itemLink) or nil
    end,
    
    FormatMoney = function(copper, colorize)
        return AM.Util and AM.Util.FormatMoney(copper, colorize) or copper
    end,
    
    StartScan = function()
        return AUCTIONMASTER_API and AUCTIONMASTER_API.StartScan() or false
    end,
    
    Search = function(searchTerm)
        return AUCTIONMASTER_API and AUCTIONMASTER_API.Search(searchTerm) or false
    end,
    
    ShowSettings = function()
        if AM.Settings then
            AM.Settings:Show()
            return true
        end
        return false
    end
}

-- Slash commands
SLASH_AUCTIONMASTER1 = "/auctionmaster"
SLASH_AUCTIONMASTER2 = "/am"
SlashCmdList["AUCTIONMASTER"] = function(msg)
    local command, args = strsplit(" ", msg, 2)
    command = command:lower()
    
    if command == "scan" then
        AuctionMaster.StartScan()
    elseif command == "search" and args then
        AuctionMaster.Search(args)
    elseif command == "settings" or command == "config" or command == "options" then
        AuctionMaster.ShowSettings()
    elseif command == "help" or command == "" then
        print("|cFF00CCFF=== AuctionMaster Help ===|r")
        print("/am scan - Start a full auction house scan")
        print("/am search [item] - Search for an item")
        print("/am settings - Open the settings panel")
        print("/am help - Show this help message")
    else
        print("|cFFFF0000Unknown command: " .. command .. "|r")
        print("Type /am help for a list of commands")
    end
end
