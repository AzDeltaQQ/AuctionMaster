-- AuctionMaster Scanner Module
local addonName, AM = ...
local L = AM.L

-- Create module namespace
AM.Scanner = {}
local Scanner = AM.Scanner

-- Local variables
local scanInProgress = false
local scanType = nil
local scanStartTime = 0
local scanResults = {}
local currentQuery = {}
local currentPage = 0
local totalPages = 0
local scanThrottle = 100 -- ms between queries, will be loaded from settings
local lastScanTime = 0
local searchCache = {}

-- Initialize the scanner module
function Scanner:Initialize()
    -- Load settings
    scanThrottle = AM.DB:GetSetting("scanning.scanThrottle", 100)
    
    -- Register for events
    AM.Events:AddCallback("AUCTION_ITEM_LIST_UPDATE", function() self:OnAuctionUpdate() end)
    AM.Events:AddCallback("AUCTION_HOUSE_CLOSED", function() self:OnAuctionHouseClosed() end)
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Scanner module initialized")
end

-- Start a full auction house scan
function Scanner:StartScan(scanParams)
    -- Check if auction house is open
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, L:Get("ERROR_AH_CLOSED"))
        return false
    end
    
    -- Check if a scan is already in progress
    if scanInProgress then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.WARNING, L:Get("ERROR_SCAN_IN_PROGRESS"))
        return false
    end
    
    -- Initialize scan parameters
    scanParams = scanParams or {}
    scanType = scanParams.type or AM.Constants.SCAN_TYPE_FULL
    
    -- Reset scan data
    scanResults = {}
    currentPage = 0
    totalPages = 0
    scanStartTime = GetTime()
    scanInProgress = true
    
    -- Fire scan start event
    AM.Events:FireEvent(AM.Constants.EVENTS.SCAN_START, scanType)
    
    -- Start the scan
    self:ScanNextPage()
    
    return true
end

-- Search for specific items
function Scanner:Search(searchTerm, exact)
    -- Check if auction house is open
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, L:Get("ERROR_AH_CLOSED"))
        return false
    end
    
    -- Check if a scan is already in progress
    if scanInProgress then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.WARNING, L:Get("ERROR_SCAN_IN_PROGRESS"))
        return false
    end
    
    -- Initialize search parameters
    local searchParams = {
        type = AM.Constants.SCAN_TYPE_TARGETED,
        searchTerm = searchTerm,
        exact = exact or false
    }
    
    -- Check search cache for recent results
    local cacheKey = searchTerm:lower()
    if searchCache[cacheKey] and (GetTime() - searchCache[cacheKey].time < 60) then
        -- Use cached results if less than 60 seconds old
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Using cached search results for: " .. searchTerm)
        return searchCache[cacheKey].results
    end
    
    -- Start the search scan
    return self:StartScan(searchParams)
end

-- Scan the next page of auction results
function Scanner:ScanNextPage()
    -- Check if auction house is still open
    if not AuctionFrame or not AuctionFrame:IsVisible() then
        self:EndScan("ERROR_AH_CLOSED")
        return
    end
    
    -- Increment page counter
    currentPage = currentPage + 1
    
    -- Prepare query based on scan type
    if scanType == AM.Constants.SCAN_TYPE_FULL then
        -- Full scan - query all items
        currentQuery = {
            name = "",
            minLevel = 0,
            maxLevel = 0,
            invTypeIndex = 0,
            classIndex = 0,
            subclassIndex = 0,
            page = currentPage - 1,
            isUsable = false,
            qualityIndex = 0,
            getAll = AM.DB:GetSetting("scanning.getAll", false)
        }
    elseif scanType == AM.Constants.SCAN_TYPE_TARGETED then
        -- Targeted scan - search for specific items
        currentQuery = {
            name = currentQuery.searchTerm or "",
            minLevel = 0,
            maxLevel = 0,
            invTypeIndex = 0,
            classIndex = 0,
            subclassIndex = 0,
            page = currentPage - 1,
            isUsable = false,
            qualityIndex = 0,
            getAll = false
        }
    elseif scanType == AM.Constants.SCAN_TYPE_SNIPER then
        -- Sniper scan - look for newly posted items
        currentQuery = {
            name = "",
            minLevel = 0,
            maxLevel = 0,
            invTypeIndex = 0,
            classIndex = 0,
            subclassIndex = 0,
            page = 0,
            isUsable = false,
            qualityIndex = 0,
            getAll = false
        }
    end
    
    -- Update progress
    local progress = 0
    if totalPages > 0 then
        progress = math.floor((currentPage / totalPages) * 100)
    end
    AM.Events:FireEvent(AM.Constants.EVENTS.SCAN_PROGRESS, progress, currentPage, totalPages)
    
    -- Execute the query with throttling
    local timeSinceLastScan = GetTime() - lastScanTime
    if timeSinceLastScan < (scanThrottle / 1000) then
        -- Wait before sending next query
        C_Timer.After((scanThrottle / 1000) - timeSinceLastScan, function()
            self:ExecuteQuery()
        end)
    else
        -- Execute immediately
        self:ExecuteQuery()
    end
end

-- Execute the current query
function Scanner:ExecuteQuery()
    -- Record query time
    lastScanTime = GetTime()
    
    -- Send the query to the auction house
    QueryAuctionItems(
        currentQuery.name,
        currentQuery.minLevel,
        currentQuery.maxLevel,
        currentQuery.invTypeIndex,
        currentQuery.classIndex,
        currentQuery.subclassIndex,
        currentQuery.page,
        currentQuery.isUsable,
        currentQuery.qualityIndex,
        currentQuery.getAll
    )
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Querying page " .. (currentQuery.page + 1))
end

-- Handle auction data updates
function Scanner:OnAuctionUpdate()
    -- Ignore if no scan in progress
    if not scanInProgress then return end
    
    -- Process the current page of results
    self:ProcessCurrentPage()
    
    -- Check if we need to scan more pages
    if currentPage == 1 then
        -- First page - determine total pages
        local numBatchAuctions, totalAuctions = GetNumAuctionItems("list")
        totalPages = math.ceil(totalAuctions / numBatchAuctions)
        
        if totalPages == 0 then
            totalPages = 1 -- At least one page even if empty
        end
        
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Found " .. totalAuctions .. " auctions across " .. totalPages .. " pages")
    end
    
    -- Continue scanning or finish
    if currentPage < totalPages then
        -- Scan next page
        self:ScanNextPage()
    else
        -- Scan complete
        self:EndScan()
    end
end

-- Process the current page of auction results
function Scanner:ProcessCurrentPage()
    local numBatchAuctions = GetNumAuctionItems("list")
    
    -- Process each auction
    for i = 1, numBatchAuctions do
        local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, 
              bidAmount, highBidder, owner, saleStatus = GetAuctionItemInfo("list", i)
        
        -- Skip if no name (shouldn't happen, but just in case)
        if name then
            local itemLink = GetAuctionItemLink("list", i)
            local timeLeft = GetAuctionItemTimeLeft("list", i)
            
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
                    owner = owner,
                    timeLeft = timeLeft,
                    itemLink = itemLink,
                    timestamp = GetTime()
                }
                
                -- Add to results
                if not scanResults[itemKey] then
                    scanResults[itemKey] = {}
                end
                
                table.insert(scanResults[itemKey], auction)
            end
        end
    end
end

-- End the current scan
function Scanner:EndScan(errorMsg)
    -- Check if scan was in progress
    if not scanInProgress then return end
    
    -- Calculate scan duration
    local scanDuration = GetTime() - scanStartTime
    
    -- Update scan status
    scanInProgress = false
    
    -- Process results
    if not errorMsg then
        -- Count total items scanned
        local totalItems = 0
        for itemKey, auctions in pairs(scanResults) do
            totalItems = totalItems + #auctions
            
            -- Save auction data to database
            AM.DB:SaveAuctionData(itemKey, auctions)
        end
        
        -- Update scan statistics
        local realmData = AM.DB.realm
        realmData.scanStats.totalScans = (realmData.scanStats.totalScans or 0) + 1
        realmData.scanStats.lastFullScan = GetTime()
        
        -- Update average scan time
        if realmData.scanStats.averageScanTime and realmData.scanStats.averageScanTime > 0 then
            realmData.scanStats.averageScanTime = (realmData.scanStats.averageScanTime * 0.8) + (scanDuration * 0.2)
        else
            realmData.scanStats.averageScanTime = scanDuration
        end
        
        -- Update last scan time
        realmData.lastScan = GetTime()
        
        -- Cache search results if this was a search
        if scanType == AM.Constants.SCAN_TYPE_TARGETED and currentQuery.searchTerm then
            local cacheKey = currentQuery.searchTerm:lower()
            searchCache[cacheKey] = {
                time = GetTime(),
                results = scanResults
            }
        end
        
        -- Fire scan complete event
        AM.Events:FireEvent(AM.Constants.EVENTS.SCAN_COMPLETE, scanResults, totalItems, scanDuration)
        
        -- Print completion message
        print("|cFF00CCFF" .. L:Get("SCAN_COMPLETE", totalItems) .. "|r")
    else
        -- Fire scan failed event
        AM.Events:FireEvent(AM.Constants.EVENTS.SCAN_FAILED, errorMsg)
        
        -- Print error message
        print("|cFFFF0000" .. L:Get(errorMsg) .. "|r")
    end
    
    -- Clear scan data
    scanResults = {}
    currentQuery = {}
    currentPage = 0
    totalPages = 0
end

-- Handle auction house closed
function Scanner:OnAuctionHouseClosed()
    -- End any in-progress scan
    if scanInProgress then
        self:EndScan("ERROR_AH_CLOSED")
    end
end

-- Check if a scan is in progress
function Scanner:IsScanning()
    return scanInProgress
end

-- Get the current scan progress
function Scanner:GetScanProgress()
    if not scanInProgress then
        return 100
    end
    
    if totalPages == 0 then
        return 0
    end
    
    return math.floor((currentPage / totalPages) * 100)
end

-- Get the last scan results
function Scanner:GetLastScanResults()
    return scanResults
end
