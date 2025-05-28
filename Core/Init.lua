-- AuctionMaster Init
local addonName, AM = ...
local L = AM.L

-- Main initialization function
function AM:Initialize()
    -- Initialize modules
    self:InitializeModules()
    
    -- Set up minimap button
    self:SetupMinimapButton()
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "AuctionMaster initialized")
end

-- Initialize all modules
function AM:InitializeModules()
    -- Initialize API
    if self.API then
        self.API:Initialize()
    end
    
    -- Initialize Scanner when auction house is opened
    self.Events:AddCallback("AUCTION_HOUSE_SHOW", function()
        if not self.Scanner then
            self:LoadScannerModule()
        end
    end)
    
    -- Initialize Tooltip
    if not self.Tooltip then
        self:LoadTooltipModule()
    end
    
    -- Initialize other modules as needed
end

-- Load Scanner module
function AM:LoadScannerModule()
    -- Create Scanner module if it doesn't exist
    if not self.Scanner then
        self.Scanner = {}
        
        -- Load the module
        if Modules and Modules.Scanner then
            Modules.Scanner:Initialize(self)
        else
            -- Fallback if module loading fails
            self.Scanner = {
                Initialize = function() end,
                StartScan = function() 
                    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, "Scanner module not loaded properly")
                    return false
                end,
                Search = function(searchTerm)
                    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.ERROR, "Scanner module not loaded properly")
                    return false
                end
            }
        end
    end
end

-- Load Tooltip module
function AM:LoadTooltipModule()
    -- Create Tooltip module if it doesn't exist
    if not self.Tooltip then
        self.Tooltip = {}
        
        -- Load the module
        if Modules and Modules.Tooltip then
            Modules.Tooltip:Initialize(self)
        else
            -- Fallback if module loading fails
            self.Tooltip = {
                Initialize = function() end,
                OnTooltipSetItem = function() end
            }
        end
    end
end

-- Set up minimap button
function AM:SetupMinimapButton()
    -- Check if minimap button is enabled
    if self.DB:GetSetting("general.minimap.hide", false) then
        return
    end
    
    -- Create LDB launcher
    local ldb = LibStub("LibDataBroker-1.1", true)
    if not ldb then return end
    
    local minimapLauncher = ldb:NewDataObject("AuctionMaster", {
        type = "launcher",
        icon = "Interface\\AddOns\\AuctionMaster\\Media\\icon",
        OnClick = function(_, button)
            if button == "LeftButton" then
                -- Toggle main frame if auction house is open
                if AuctionFrame and AuctionFrame:IsVisible() then
                    if self.UI and self.UI.MainFrame then
                        self.UI.MainFrame:Toggle()
                    end
                else
                    -- Show settings if auction house is closed
                    if self.Settings then
                        self.Settings:Show()
                    end
                end
            elseif button == "RightButton" then
                -- Show settings
                if self.Settings then
                    self.Settings:Show()
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("AuctionMaster")
            tooltip:AddLine(L:Get("LOADED_MESSAGE", AM.Constants.VERSION), 1, 1, 1)
            tooltip:AddLine(" ")
            tooltip:AddLine(L:Get("LEFT_CLICK_TO_OPEN"), 0, 1, 0)
            tooltip:AddLine(L:Get("RIGHT_CLICK_FOR_OPTIONS"), 0, 1, 0)
        end,
    })
    
    -- Add minimap icon using LibDBIcon if available
    local icon = LibStub("LibDBIcon-1.0", true)
    if icon then
        icon:Register("AuctionMaster", minimapLauncher, self.DB.global.settings.general.minimap)
    end
end

-- Events module initializes first
AM.Events:Initialize()
