-- AuctionMaster Tooltip Module
local addonName, AM = ...
local L = AM.L

-- Create module namespace
AM.Tooltip = {}
local Tooltip = AM.Tooltip

-- Local variables
local tooltipHooks = {}
local tooltipEnabled = true
local modifierKey = "none" -- none, shift, alt, ctrl

-- Initialize the tooltip module
function Tooltip:Initialize()
    -- Load settings
    tooltipEnabled = AM.DB:GetSetting("tooltips.enable", true)
    modifierKey = AM.DB:GetSetting("tooltips.modifierKey", "none")
    
    -- Set up tooltip hooks
    self:SetupTooltipHooks()
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Tooltip module initialized")
end

-- Set up tooltip hooks
function Tooltip:SetupTooltipHooks()
    -- Get LibExtraTip
    local LibExtraTip = LibStub("LibExtraTip-1.0", true)
    if not LibExtraTip then
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, "LibExtraTip not found, tooltip functionality limited")
        -- Fall back to basic tooltip hooks
        self:SetupBasicTooltipHooks()
        return
    end
    
    -- Register tooltips with LibExtraTip
    LibExtraTip:RegisterTooltip(GameTooltip)
    LibExtraTip:RegisterTooltip(ItemRefTooltip)
    
    -- Add callback for item tooltips
    LibExtraTip:AddCallback({
        type = "item",
        callback = function(tooltip, itemLink, quantity)
            self:OnTooltipSetItem(tooltip, itemLink, quantity)
        end
    })
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "LibExtraTip hooks established")
end

-- Set up basic tooltip hooks if LibExtraTip is not available
function Tooltip:SetupBasicTooltipHooks()
    -- Hook GameTooltip SetItem
    if not tooltipHooks.GameTooltip_SetItem then
        tooltipHooks.GameTooltip_SetItem = GameTooltip.SetItem
        GameTooltip.SetItem = function(self, item)
            tooltipHooks.GameTooltip_SetItem(self, item)
            Tooltip:OnTooltipSetItem(self, item)
        end
    end
    
    -- Hook GameTooltip SetHyperlink
    if not tooltipHooks.GameTooltip_SetHyperlink then
        tooltipHooks.GameTooltip_SetHyperlink = GameTooltip.SetHyperlink
        GameTooltip.SetHyperlink = function(self, link)
            tooltipHooks.GameTooltip_SetHyperlink(self, link)
            Tooltip:OnTooltipSetItem(self, link)
        end
    end
    
    -- Hook ItemRefTooltip SetHyperlink
    if not tooltipHooks.ItemRefTooltip_SetHyperlink then
        tooltipHooks.ItemRefTooltip_SetHyperlink = ItemRefTooltip.SetHyperlink
        ItemRefTooltip.SetHyperlink = function(self, link)
            tooltipHooks.ItemRefTooltip_SetHyperlink(self, link)
            Tooltip:OnTooltipSetItem(self, link)
        end
    end
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Basic tooltip hooks established")
end

-- Handle tooltip item display
function Tooltip:OnTooltipSetItem(tooltip, itemLink, quantity)
    -- Check if tooltips are enabled
    if not tooltipEnabled then return end
    
    -- Check for modifier key requirement
    if modifierKey ~= "none" then
        local isShiftDown = IsShiftKeyDown()
        local isAltDown = IsAltKeyDown()
        local isControlDown = IsControlKeyDown()
        
        if (modifierKey == "shift" and not isShiftDown) or
           (modifierKey == "alt" and not isAltDown) or
           (modifierKey == "ctrl" and not isControlDown) then
            return
        end
    end
    
    -- Extract item link if not provided directly
    if not itemLink then
        local name, link = tooltip:GetItem()
        if link then
            itemLink = link
        else
            return
        end
    end
    
    -- Get item key
    local itemKey = AM.Util.GetItemKey(itemLink)
    if not itemKey then return end
    
    -- Add price information to tooltip
    self:AddPriceInfo(tooltip, itemKey, itemLink, quantity or 1)
end

-- Add price information to tooltip
function Tooltip:AddPriceInfo(tooltip, itemKey, itemLink, quantity)
    -- Get settings for which prices to show
    local showMarketValue = AM.DB:GetSetting("tooltips.showMarketValue", true)
    local showHistorical = AM.DB:GetSetting("tooltips.showHistorical", true)
    local showMinBuyout = AM.DB:GetSetting("tooltips.showMinBuyout", true)
    
    -- Get price data
    local marketValue = nil
    local historicalValue = nil
    local minBuyout = nil
    
    if showMarketValue then
        marketValue = AM.DB:GetItemPrice(itemKey, AM.Constants.PRICE_TYPE_MARKET)
    end
    
    if showHistorical then
        historicalValue = AM.DB:GetItemPrice(itemKey, AM.Constants.PRICE_TYPE_HISTORICAL)
    end
    
    if showMinBuyout then
        minBuyout = AM.DB:GetItemPrice(itemKey, AM.Constants.PRICE_TYPE_MINIMUM)
    end
    
    -- Check if we have any price data
    if not marketValue and not historicalValue and not minBuyout then
        -- No price data available
        if AM.DB:GetSetting("tooltips.showNoData", true) then
            -- Add header
            self:AddLine(tooltip, L:Get("ADDON_NAME"), AM.Constants.COLORS.BLUE)
            
            -- Add no data message
            self:AddLine(tooltip, L:Get("NO_PRICE_DATA"), AM.Constants.COLORS.GRAY)
        end
        return
    end
    
    -- Add header
    self:AddLine(tooltip, L:Get("ADDON_NAME"), AM.Constants.COLORS.BLUE)
    
    -- Add market value
    if marketValue and marketValue > 0 then
        local marketValueText = AM.Util.FormatMoney(marketValue, true)
        if quantity > 1 then
            local totalValue = marketValue * quantity
            marketValueText = marketValueText .. " (" .. AM.Util.FormatMoney(totalValue, true) .. " " .. L:Get("TOTAL") .. ")"
        end
        self:AddLine(tooltip, L:Get("MARKET_VALUE") .. ": " .. marketValueText)
    end
    
    -- Add historical value
    if historicalValue and historicalValue > 0 then
        local historicalValueText = AM.Util.FormatMoney(historicalValue, true)
        self:AddLine(tooltip, L:Get("HISTORICAL_VALUE") .. ": " .. historicalValueText)
    end
    
    -- Add minimum buyout
    if minBuyout and minBuyout > 0 then
        local minBuyoutText = AM.Util.FormatMoney(minBuyout, true)
        if quantity > 1 then
            local totalValue = minBuyout * quantity
            minBuyoutText = minBuyoutText .. " (" .. AM.Util.FormatMoney(totalValue, true) .. " " .. L:Get("TOTAL") .. ")"
        end
        self:AddLine(tooltip, L:Get("MIN_BUYOUT") .. ": " .. minBuyoutText)
    end
    
    -- Add vendor sell price comparison if available
    local itemInfo = AM.DB:GetItemInfo(itemLink)
    if itemInfo and itemInfo.vendorSell and itemInfo.vendorSell > 0 then
        local vendorSellText = AM.Util.FormatMoney(itemInfo.vendorSell, true)
        if quantity > 1 then
            local totalValue = itemInfo.vendorSell * quantity
            vendorSellText = vendorSellText .. " (" .. AM.Util.FormatMoney(totalValue, true) .. " " .. L:Get("TOTAL") .. ")"
        end
        self:AddLine(tooltip, L:Get("VENDOR_SELL_PRICE") .. ": " .. vendorSellText)
        
        -- Add profit/loss vs vendor if we have auction data
        if minBuyout and minBuyout > 0 then
            local profit = minBuyout - itemInfo.vendorSell
            local profitText = AM.Util.FormatMoney(profit, true)
            local color = (profit > 0) and AM.Constants.COLORS.GREEN or AM.Constants.COLORS.RED
            self:AddLine(tooltip, L:Get("PROFIT_VS_VENDOR") .. ": " .. profitText, color)
        end
    end
    
    -- Add last scan time
    local lastScan = AM.DB.realm.lastScan
    if lastScan and lastScan > 0 then
        local timeText = AM.Util.GetTimeDifference(lastScan)
        self:AddLine(tooltip, L:Get("LAST_SCAN") .. ": " .. timeText, AM.Constants.COLORS.GRAY)
    end
end

-- Add a line to the tooltip
function Tooltip:AddLine(tooltip, text, color)
    -- Get LibExtraTip
    local LibExtraTip = LibStub("LibExtraTip-1.0", true)
    
    if LibExtraTip then
        -- Use LibExtraTip to add the line
        if color then
            LibExtraTip:AddLine(tooltip, text, color.r, color.g, color.b)
        else
            LibExtraTip:AddLine(tooltip, text, 1, 1, 1)
        end
    else
        -- Fall back to basic tooltip method
        if color then
            tooltip:AddLine(text, color.r, color.g, color.b)
        else
            tooltip:AddLine(text, 1, 1, 1)
        end
    end
end

-- Enable or disable tooltips
function Tooltip:SetEnabled(enabled)
    tooltipEnabled = enabled
    AM.DB:SetSetting("tooltips.enable", enabled)
end

-- Set modifier key requirement
function Tooltip:SetModifierKey(key)
    modifierKey = key
    AM.DB:SetSetting("tooltips.modifierKey", key)
end
