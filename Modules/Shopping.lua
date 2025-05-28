-- AuctionMaster Shopping Module
local addonName, AM = ...
local L = AM.L

-- Create module namespace
AM.Shopping = {}
local Shopping = AM.Shopping

-- Local variables
local shoppingLists = {}
local sniperRunning = false
local sniperTimer = nil
local sniperInterval = 2.5 -- seconds, will be loaded from settings

-- Initialize the shopping module
function Shopping:Initialize()
    -- Load settings
    sniperInterval = AM.DB:GetSetting("shopping.sniperInterval", 2.5)
    
    -- Load shopping lists from database
    self:LoadShoppingLists()
    
    -- Register for events
    AM.Events:AddCallback("AUCTION_HOUSE_CLOSED", function() self:StopSniper() end)
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Shopping module initialized")
end

-- Load shopping lists from database
function Shopping:LoadShoppingLists()
    -- Get character data
    local charData = AM.DB.char
    
    -- Initialize shopping lists if needed
    if not charData.shopping then
        charData.shopping = {
            lists = {
                ["Default"] = {
                    items = {},
                    lastSearch = 0,
                }
            },
            history = {}
        }
    end
    
    -- Load lists
    shoppingLists = charData.shopping.lists
end

-- Get all shopping lists
function Shopping:GetLists()
    return shoppingLists
end

-- Get a specific shopping list
function Shopping:GetList(listName)
    return shoppingLists[listName]
end

-- Create a new shopping list
function Shopping:CreateList(listName)
    if not listName or listName == "" or shoppingLists[listName] then
        return false
    end
    
    shoppingLists[listName] = {
        items = {},
        lastSearch = 0
    }
    
    return true
end

-- Rename a shopping list
function Shopping:RenameList(oldName, newName)
    if not oldName or not newName or newName == "" or not shoppingLists[oldName] or shoppingLists[newName] then
        return false
    end
    
    shoppingLists[newName] = shoppingLists[oldName]
    shoppingLists[oldName] = nil
    
    return true
end

-- Delete a shopping list
function Shopping:DeleteList(listName)
    if not listName or not shoppingLists[listName] or listName == "Default" then
        return false
    end
    
    shoppingLists[listName] = nil
    
    return true
end

-- Add item to shopping list
function Shopping:AddItem(listName, itemLink, maxPrice, notes)
    if not listName or not shoppingLists[listName] or not itemLink then
        return false
    end
    
    -- Get item key and info
    local itemKey = AM.Util.GetItemKey(itemLink)
    if not itemKey then
        return false
    end
    
    local itemID = tonumber(string.match(itemKey, "^(%d+):"))
    local itemInfo = AM.DB:GetItemInfo(itemID)
    
    if not itemInfo then
        return false
    end
    
    -- Add to list
    shoppingLists[listName].items[itemKey] = {
        itemID = itemID,
        name = itemInfo.name,
        link = itemInfo.link,
        maxPrice = maxPrice or 0,
        notes = notes or "",
        addedAt = time()
    }
    
    return true
end

-- Remove item from shopping list
function Shopping:RemoveItem(listName, itemKey)
    if not listName or not shoppingLists[listName] or not itemKey then
        return false
    end
    
    if not shoppingLists[listName].items[itemKey] then
        return false
    end
    
    shoppingLists[listName].items[itemKey] = nil
    
    return true
end

-- Update item in shopping list
function Shopping:UpdateItem(listName, itemKey, maxPrice, notes)
    if not listName or not shoppingLists[listName] or not itemKey then
        return false
    end
    
    local item = shoppingLists[listName].items[itemKey]
    if not item then
        return false
    end
    
    if maxPrice ~= nil then
        item.maxPrice = maxPrice
    end
    
    if notes ~= nil then
        item.notes = notes
    end
    
    return true
end

-- Search for items in a shopping list
function Shopping:SearchList(listName)
    if not listName or not shoppingLists[listName] then
        return false
    end
    
    local list = shoppingLists[listName]
    
    -- Check if auction house is open
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, L:Get("ERROR_AH_CLOSED"))
        return false
    end
    
    -- Check if scanner is available
    if not AM.Scanner then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, "Scanner module not available")
        return false
    end
    
    -- Update last search time
    list.lastSearch = time()
    
    -- Get all item names from the list
    local itemNames = {}
    for _, item in pairs(list.items) do
        table.insert(itemNames, item.name)
    end
    
    -- No items to search
    if #itemNames == 0 then
        return false
    end
    
    -- Start search for first item
    local currentItem = 1
    
    local function searchNextItem()
        if currentItem <= #itemNames then
            local itemName = itemNames[currentItem]
            AM.Scanner:Search(itemName)
            currentItem = currentItem + 1
            
            -- Schedule next search
            C_Timer.After(1, searchNextItem)
        end
    end
    
    -- Start the search chain
    searchNextItem()
    
    return true
end

-- Start sniper mode
function Shopping:StartSniper()
    -- Check if auction house is open
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, L:Get("ERROR_AH_CLOSED"))
        return false
    end
    
    -- Check if scanner is available
    if not AM.Scanner then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, "Scanner module not available")
        return false
    end
    
    -- Already running
    if sniperRunning then
        return true
    end
    
    -- Start sniper
    sniperRunning = true
    
    -- Create timer for repeated scans
    local function sniperScan()
        if not sniperRunning then
            return
        end
        
        -- Check if auction house is still open
        if not AuctionFrame or not AuctionFrame:IsVisible() then
            self:StopSniper()
            return
        end
        
        -- Start a sniper scan
        AM.Scanner:StartScan({type = AM.Constants.SCAN_TYPE_SNIPER})
        
        -- Schedule next scan
        sniperTimer = C_Timer.After(sniperInterval, sniperScan)
    end
    
    -- Start first scan
    sniperScan()
    
    -- Register for scan complete event to process results
    AM.Events:AddCallback(AM.Constants.EVENTS.SCAN_COMPLETE, function(results) self:ProcessSniperResults(results) end)
    
    print("|cFF00CCFF" .. L:Get("SNIPER_RUNNING") .. "|r")
    
    return true
end

-- Stop sniper mode
function Shopping:StopSniper()
    if not sniperRunning then
        return
    end
    
    sniperRunning = false
    
    -- Cancel timer if active
    if sniperTimer then
        sniperTimer:Cancel()
        sniperTimer = nil
    end
    
    -- Unregister from scan complete event
    AM.Events:RemoveCallback(AM.Constants.EVENTS.SCAN_COMPLETE, self.ProcessSniperResults)
    
    print("|cFF00CCFF" .. L:Get("SNIPER_STOPPED") .. "|r")
end

-- Toggle sniper mode
function Shopping:ToggleSniper()
    if sniperRunning then
        self:StopSniper()
    else
        self:StartSniper()
    end
end

-- Process sniper scan results
function Shopping:ProcessSniperResults(results)
    if not sniperRunning or not results then
        return
    end
    
    -- Check each item for deals
    for itemKey, auctions in pairs(results) do
        for _, auction in ipairs(auctions) do
            -- Calculate price per item
            local pricePerItem = auction.buyout / auction.count
            
            -- Get market value
            local marketValue = AM.Pricing:CalculateMarketValue(itemKey)
            
            if marketValue then
                -- Calculate deal score
                local dealScore = AM.Pricing:CalculateDealScore(itemKey, pricePerItem)
                
                -- Check if this is a good deal (score > 20%)
                if dealScore and dealScore > 20 then
                    -- Fire deal found event
                    AM.Events:FireEvent(AM.Constants.EVENTS.DEAL_FOUND, auction, dealScore)
                    
                    -- Notify user if enabled
                    if AM.DB:GetSetting("shopping.dealNotification", true) then
                        local message = string.format("%s: %s - %s (%d%% off)", 
                            L:Get("DEAL_FOUND"),
                            auction.name,
                            AM.Util.FormatMoney(pricePerItem, true),
                            dealScore)
                        
                        print("|cFF00FF00" .. message .. "|r")
                        
                        -- Play sound if enabled
                        if AM.DB:GetSetting("sound.enableAlerts", true) then
                            local volume = AM.DB:GetSetting("sound.volume", 0.5)
                            PlaySoundFile("Interface\\AddOns\\AuctionMaster\\Media\\deal.mp3", "Master", volume)
                        end
                    end
                end
            end
        end
    end
end

-- Record purchase in history
function Shopping:RecordPurchase(itemLink, quantity, price, seller)
    if not itemLink or not quantity or not price then
        return false
    end
    
    -- Get character data
    local charData = AM.DB.char
    
    -- Initialize history if needed
    if not charData.shopping.history then
        charData.shopping.history = {}
    end
    
    -- Add purchase to history
    table.insert(charData.shopping.history, {
        itemLink = itemLink,
        quantity = quantity,
        price = price,
        seller = seller or "Unknown",
        timestamp = time()
    })
    
    return true
end

-- Get purchase history
function Shopping:GetPurchaseHistory(limit)
    limit = limit or 50
    
    -- Get character data
    local charData = AM.DB.char
    
    -- No history
    if not charData.shopping.history then
        return {}
    end
    
    -- Sort by timestamp (newest first)
    local history = {}
    for _, purchase in ipairs(charData.shopping.history) do
        table.insert(history, purchase)
    end
    
    table.sort(history, function(a, b)
        return (a.timestamp or 0) > (b.timestamp or 0)
    end)
    
    -- Limit results
    if #history > limit then
        local limitedHistory = {}
        for i = 1, limit do
            table.insert(limitedHistory, history[i])
        end
        history = limitedHistory
    end
    
    return history
end

-- Check if sniper is running
function Shopping:IsSniperRunning()
    return sniperRunning
end
