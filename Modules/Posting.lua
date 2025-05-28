-- AuctionMaster Posting Module
local addonName, AM = ...
local L = AM.L

-- Create module namespace
AM.Posting = {}
local Posting = AM.Posting

-- Local variables
local postingProfiles = {}
local currentAuctions = {}
local queuedItems = {}

-- Initialize the posting module
function Posting:Initialize()
    -- Load posting profiles from database
    self:LoadPostingProfiles()
    
    -- Register for events
    AM.Events:AddCallback("AUCTION_OWNED_LIST_UPDATE", function() self:UpdateCurrentAuctions() end)
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Posting module initialized")
end

-- Load posting profiles from database
function Posting:LoadPostingProfiles()
    -- Get character data
    local charData = AM.DB.char
    
    -- Initialize posting profiles if needed
    if not charData.posting then
        charData.posting = {
            profiles = {
                ["Default"] = {
                    undercut = 1,
                    duration = AM.Constants.AUCTION_DURATION_24,
                    stackSize = 1,
                    autoPost = false,
                }
            },
            itemSettings = {},
            history = {}
        }
    end
    
    -- Load profiles
    postingProfiles = charData.posting.profiles
end

-- Get all posting profiles
function Posting:GetProfiles()
    return postingProfiles
end

-- Get a specific posting profile
function Posting:GetProfile(profileName)
    return postingProfiles[profileName]
end

-- Create a new posting profile
function Posting:CreateProfile(profileName, settings)
    if not profileName or profileName == "" or postingProfiles[profileName] then
        return false
    end
    
    -- Create default settings if not provided
    settings = settings or {
        undercut = 1,
        duration = AM.Constants.AUCTION_DURATION_24,
        stackSize = 1,
        autoPost = false,
    }
    
    postingProfiles[profileName] = settings
    
    return true
end

-- Update a posting profile
function Posting:UpdateProfile(profileName, settings)
    if not profileName or not postingProfiles[profileName] then
        return false
    end
    
    -- Update settings
    for key, value in pairs(settings) do
        postingProfiles[profileName][key] = value
    end
    
    return true
end

-- Delete a posting profile
function Posting:DeleteProfile(profileName)
    if not profileName or not postingProfiles[profileName] or profileName == "Default" then
        return false
    end
    
    postingProfiles[profileName] = nil
    
    return true
end

-- Get item settings
function Posting:GetItemSettings(itemKey)
    -- Get character data
    local charData = AM.DB.char
    
    -- Return item settings if they exist
    if charData.posting.itemSettings[itemKey] then
        return charData.posting.itemSettings[itemKey]
    end
    
    -- Return nil if no settings found
    return nil
end

-- Set item settings
function Posting:SetItemSettings(itemKey, settings)
    if not itemKey or not settings then
        return false
    end
    
    -- Get character data
    local charData = AM.DB.char
    
    -- Initialize item settings if needed
    if not charData.posting.itemSettings[itemKey] then
        charData.posting.itemSettings[itemKey] = {}
    end
    
    -- Update settings
    for key, value in pairs(settings) do
        charData.posting.itemSettings[itemKey][key] = value
    end
    
    return true
end

-- Update current auctions
function Posting:UpdateCurrentAuctions()
    -- Check if auction house is open
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        return
    end
    
    -- Clear current auctions
    currentAuctions = {}
    
    -- Get owned auctions
    local numAuctions = GetNumAuctionItems("owner")
    
    -- Process each auction
    for i = 1, numAuctions do
        local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, 
              bidAmount, highBidder, owner, saleStatus = GetAuctionItemInfo("owner", i)
        
        -- Skip if no name (shouldn't happen, but just in case)
        if name then
            local itemLink = GetAuctionItemLink("owner", i)
            local timeLeft = GetAuctionItemTimeLeft("owner", i)
            
            -- Get item key
            local itemKey = AM.Util.GetItemKey(itemLink)
            
            if itemKey then
                -- Create auction data
                local auction = {
                    name = name,
                    texture = texture,
                    count = count,
                    quality = quality,
                    level = level,
                    minBid = minBid,
                    bidAmount = bidAmount,
                    buyout = buyoutPrice,
                    timeLeft = timeLeft,
                    itemLink = itemLink,
                    saleStatus = saleStatus
                }
                
                -- Add to current auctions
                if not currentAuctions[itemKey] then
                    currentAuctions[itemKey] = {}
                end
                
                table.insert(currentAuctions[itemKey], auction)
            end
        end
    end
    
    -- Fire event
    AM.Events:FireEvent(AM.Constants.EVENTS.OWNED_AUCTIONS_UPDATED, currentAuctions)
end

-- Get current auctions
function Posting:GetCurrentAuctions()
    return currentAuctions
end

-- Calculate posting price for an item
function Posting:CalculatePostingPrice(itemKey, profileName)
    if not itemKey then
        return nil
    end
    
    -- Get profile
    local profile = postingProfiles[profileName or "Default"]
    if not profile then
        return nil
    end
    
    -- Get item settings
    local itemSettings = self:GetItemSettings(itemKey)
    
    -- Determine pricing strategy
    local strategy = (itemSettings and itemSettings.pricingStrategy) or "undercut"
    
    -- Calculate price based on strategy
    return AM.Pricing:CalculatePostingPrice(itemKey, strategy)
end

-- Add item to posting queue
function Posting:QueueItem(itemLink, quantity, stackSize, price, duration, profileName)
    if not itemLink or not quantity or quantity <= 0 then
        return false
    end
    
    -- Get item key
    local itemKey = AM.Util.GetItemKey(itemLink)
    if not itemKey then
        return false
    end
    
    -- Get item info
    local itemID = tonumber(string.match(itemKey, "^(%d+):"))
    local itemInfo = AM.DB:GetItemInfo(itemID)
    
    if not itemInfo then
        return false
    end
    
    -- Get profile
    local profile = postingProfiles[profileName or "Default"]
    if not profile then
        return false
    end
    
    -- Use profile defaults if not specified
    stackSize = stackSize or profile.stackSize
    duration = duration or profile.duration
    
    -- Calculate price if not specified
    if not price or price <= 0 then
        price = self:CalculatePostingPrice(itemKey, profileName)
        
        -- If still no price, use fallback
        if not price or price <= 0 then
            -- Try to get vendor price as absolute minimum
            local vendorPrice = (itemInfo.vendorSell or 0) * 2
            price = math.max(1, vendorPrice)
        end
    end
    
    -- Add to queue
    table.insert(queuedItems, {
        itemKey = itemKey,
        itemID = itemID,
        name = itemInfo.name,
        link = itemInfo.link,
        quantity = quantity,
        stackSize = stackSize,
        price = price,
        duration = duration,
        profileName = profileName or "Default"
    })
    
    return true
end

-- Clear posting queue
function Posting:ClearQueue()
    queuedItems = {}
    return true
end

-- Get posting queue
function Posting:GetQueue()
    return queuedItems
end

-- Process posting queue
function Posting:ProcessQueue()
    -- Check if auction house is open
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, L:Get("ERROR_AH_CLOSED"))
        return false
    end
    
    -- No items in queue
    if #queuedItems == 0 then
        return true
    end
    
    -- Process first item in queue
    local item = table.remove(queuedItems, 1)
    
    -- Post the item
    self:PostItem(item.link, item.quantity, item.stackSize, item.price, item.duration)
    
    -- If more items in queue, schedule next post
    if #queuedItems > 0 then
        C_Timer.After(0.5, function() self:ProcessQueue() end)
    end
    
    return true
end

-- Post an item to the auction house
function Posting:PostItem(itemLink, quantity, stackSize, price, duration)
    if not itemLink or not quantity or quantity <= 0 or not stackSize or stackSize <= 0 or not price or price <= 0 or not duration then
        return false
    end
    
    -- Check if auction house is open
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, L:Get("ERROR_AH_CLOSED"))
        return false
    end
    
    -- Find the item in bags
    local bagID, slotID = self:FindItemInBags(itemLink)
    if not bagID or not slotID then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, L:Get("ERROR_ITEM_NOT_FOUND"))
        return false
    end
    
    -- Calculate number of stacks
    local numStacks = math.floor(quantity / stackSize)
    local remainder = quantity % stackSize
    
    -- Post full stacks
    for i = 1, numStacks do
        -- Click the item in bag
        PickupContainerItem(bagID, slotID)
        ClickAuctionSellItemButton()
        
        -- Set stack size
        AuctionFrameAuctions.duration = duration
        StartAuction(price, price, 12) -- 12 hours
        
        -- Wait for auction to be created
        C_Timer.After(0.5, function()
            -- Find the item again for next stack
            bagID, slotID = self:FindItemInBags(itemLink)
            if not bagID or not slotID then
                AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, L:Get("ERROR_ITEM_NOT_FOUND"))
                return
            end
        end)
    end
    
    -- Post remainder stack if any
    if remainder > 0 then
        -- Click the item in bag
        PickupContainerItem(bagID, slotID)
        ClickAuctionSellItemButton()
        
        -- Set stack size
        AuctionFrameAuctions.duration = duration
        StartAuction(price, price, 12) -- 12 hours
    end
    
    -- Record in posting history
    self:RecordPosting(itemLink, quantity, price, duration)
    
    return true
end

-- Find an item in bags
function Posting:FindItemInBags(itemLink)
    if not itemLink then
        return nil, nil
    end
    
    -- Get item key
    local targetItemKey = AM.Util.GetItemKey(itemLink)
    if not targetItemKey then
        return nil, nil
    end
    
    -- Search all bags
    for bagID = 0, 4 do
        local numSlots = GetContainerNumSlots(bagID)
        for slotID = 1, numSlots do
            local link = GetContainerItemLink(bagID, slotID)
            if link then
                local itemKey = AM.Util.GetItemKey(link)
                if itemKey and itemKey == targetItemKey then
                    return bagID, slotID
                end
            end
        end
    end
    
    return nil, nil
end

-- Record posting in history
function Posting:RecordPosting(itemLink, quantity, price, duration)
    if not itemLink or not quantity or not price then
        return false
    end
    
    -- Get character data
    local charData = AM.DB.char
    
    -- Initialize history if needed
    if not charData.posting.history then
        charData.posting.history = {}
    end
    
    -- Add posting to history
    table.insert(charData.posting.history, {
        itemLink = itemLink,
        quantity = quantity,
        price = price,
        duration = duration,
        timestamp = time()
    })
    
    return true
end

-- Get posting history
function Posting:GetPostingHistory(limit)
    limit = limit or 50
    
    -- Get character data
    local charData = AM.DB.char
    
    -- No history
    if not charData.posting.history then
        return {}
    end
    
    -- Sort by timestamp (newest first)
    local history = {}
    for _, posting in ipairs(charData.posting.history) do
        table.insert(history, posting)
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

-- Cancel an auction
function Posting:CancelAuction(index)
    -- Check if auction house is open
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, L:Get("ERROR_AH_CLOSED"))
        return false
    end
    
    -- Check if index is valid
    if not index or index < 1 or index > GetNumAuctionItems("owner") then
        return false
    end
    
    -- Cancel the auction
    CancelAuction(index)
    
    return true
end

-- Cancel all auctions matching criteria
function Posting:CancelAuctions(criteria)
    -- Check if auction house is open
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, L:Get("ERROR_AH_CLOSED"))
        return false
    end
    
    -- Get owned auctions
    local numAuctions = GetNumAuctionItems("owner")
    
    -- Track auctions to cancel
    local toCancel = {}
    
    -- Find auctions matching criteria
    for i = 1, numAuctions do
        local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, 
              bidAmount, highBidder, owner, saleStatus = GetAuctionItemInfo("owner", i)
        
        local itemLink = GetAuctionItemLink("owner", i)
        local timeLeft = GetAuctionItemTimeLeft("owner", i)
        
        -- Check if auction matches criteria
        local matches = true
        
        if criteria then
            if criteria.itemName and name:lower():find(criteria.itemName:lower()) == nil then
                matches = false
            end
            
            if criteria.itemLink and itemLink ~= criteria.itemLink then
                matches = false
            end
            
            if criteria.timeLeft and timeLeft ~= criteria.timeLeft then
                matches = false
            end
            
            if criteria.undercut and matches then
                -- Check if this auction is undercut
                local itemKey = AM.Util.GetItemKey(itemLink)
                if itemKey then
                    local minBuyout = AM.Pricing:CalculateMinBuyout(itemKey)
                    local pricePerItem = buyoutPrice / count
                    
                    if not minBuyout or pricePerItem <= minBuyout then
                        matches = false
                    end
                end
            end
        end
        
        -- Add to cancel list if matches
        if matches then
            table.insert(toCancel, i)
        end
    end
    
    -- Cancel matching auctions
    local cancelled = 0
    for _, index in ipairs(toCancel) do
        if self:CancelAuction(index) then
            cancelled = cancelled + 1
            
            -- Wait a bit between cancellations
            C_Timer.After(0.5 * cancelled, function()
                -- Continue cancelling
            end)
        end
    end
    
    return cancelled > 0
end
