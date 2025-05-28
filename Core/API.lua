-- AuctionMaster API
local addonName, AM = ...
local L = AM.L

-- Initialize the API module
AM.API = {}
local API = AM.API

-- Initialize API
function API:Initialize()
    -- Set up public API functions
    AUCTIONMASTER_API = {}
    
    -- Get item price
    AUCTIONMASTER_API.GetItemPrice = function(itemLink, priceType)
        local itemKey = AM.Util.GetItemKey(itemLink)
        if not itemKey then return nil end
        
        return AM.DB:GetItemPrice(itemKey, priceType)
    end
    
    -- Get market value
    AUCTIONMASTER_API.GetMarketValue = function(itemLink)
        return AUCTIONMASTER_API.GetItemPrice(itemLink, AM.Constants.PRICE_TYPE_MARKET)
    end
    
    -- Get historical value
    AUCTIONMASTER_API.GetHistoricalValue = function(itemLink)
        return AUCTIONMASTER_API.GetItemPrice(itemLink, AM.Constants.PRICE_TYPE_HISTORICAL)
    end
    
    -- Get minimum buyout
    AUCTIONMASTER_API.GetMinBuyout = function(itemLink)
        return AUCTIONMASTER_API.GetItemPrice(itemLink, AM.Constants.PRICE_TYPE_MINIMUM)
    end
    
    -- Format money value
    AUCTIONMASTER_API.FormatMoney = function(copper, colorize)
        return AM.Util.FormatMoney(copper, colorize)
    end
    
    -- Register for price updates
    AUCTIONMASTER_API.RegisterPriceCallback = function(callback)
        AM.Events:AddCallback(AM.Constants.EVENTS.PRICE_UPDATE, callback)
    end
    
    -- Unregister from price updates
    AUCTIONMASTER_API.UnregisterPriceCallback = function(callback)
        AM.Events:RemoveCallback(AM.Constants.EVENTS.PRICE_UPDATE, callback)
    end
    
    -- Start a scan
    AUCTIONMASTER_API.StartScan = function()
        if AM.Scanner then
            return AM.Scanner:StartScan()
        end
        return false
    end
    
    -- Search for an item
    AUCTIONMASTER_API.Search = function(searchTerm)
        if AM.Scanner then
            return AM.Scanner:Search(searchTerm)
        end
        return false
    end
    
    -- Get addon version
    AUCTIONMASTER_API.GetVersion = function()
        return AM.Constants.VERSION
    end
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "API initialized")
end
