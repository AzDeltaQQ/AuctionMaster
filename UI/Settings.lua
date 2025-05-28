-- AuctionMaster Settings Module
local addonName, AM = ...
local L = AM.L

-- Create module namespace
AM.Settings = {}
local Settings = AM.Settings

-- Local variables
local settingsFrame = nil
local categoryButtons = {}
local currentCategory = nil
local optionWidgets = {}

-- Initialize the settings module
function Settings:Initialize()
    -- Create settings frame
    self:CreateSettingsFrame()
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "Settings module initialized")
end

-- Create the main settings frame
function Settings:CreateSettingsFrame()
    -- Create main frame
    settingsFrame = CreateFrame("Frame", "AuctionMasterSettingsFrame", UIParent)
    settingsFrame:SetWidth(800)
    settingsFrame:SetHeight(600)
    settingsFrame:SetPoint("CENTER")
    settingsFrame:SetFrameStrata("HIGH")
    settingsFrame:SetMovable(true)
    settingsFrame:EnableMouse(true)
    settingsFrame:RegisterForDrag("LeftButton")
    settingsFrame:SetScript("OnDragStart", settingsFrame.StartMoving)
    settingsFrame:SetScript("OnDragStop", settingsFrame.StopMovingOrSizing)
    settingsFrame:Hide()
    
    -- Add background
    local bg = settingsFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.8)
    
    -- Add border
    local border = CreateFrame("Frame", nil, settingsFrame)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    border:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- Add title
    local title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L:Get("ADDON_NAME") .. " - " .. L:Get("SETTINGS"))
    
    -- Add close button
    local closeButton = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -2, -2)
    closeButton:SetScript("OnClick", function() settingsFrame:Hide() end)
    
    -- Create category panel
    local categoryPanel = CreateFrame("Frame", nil, settingsFrame)
    categoryPanel:SetPoint("TOPLEFT", 16, -50)
    categoryPanel:SetPoint("BOTTOMLEFT", 16, 16)
    categoryPanel:SetWidth(150)
    
    local categoryBg = categoryPanel:CreateTexture(nil, "BACKGROUND")
    categoryBg:SetAllPoints()
    categoryBg:SetTexture(0.1, 0.1, 0.1, 0.6)
    
    -- Create content panel
    local contentPanel = CreateFrame("Frame", nil, settingsFrame)
    contentPanel:SetPoint("TOPLEFT", categoryPanel, "TOPRIGHT", 16, 0)
    contentPanel:SetPoint("BOTTOMRIGHT", -16, 16)
    
    local contentBg = contentPanel:CreateTexture(nil, "BACKGROUND")
    contentBg:SetAllPoints()
    contentBg:SetTexture(0.1, 0.1, 0.1, 0.6)
    
    -- Create scroll frame for content
    local scrollFrame = CreateFrame("ScrollFrame", "AuctionMasterSettingsScrollFrame", contentPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 8)
    
    local scrollChild = CreateFrame("Frame")
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(contentPanel:GetWidth() - 38)
    scrollChild:SetHeight(1) -- Will be adjusted dynamically
    
    -- Store references
    settingsFrame.categoryPanel = categoryPanel
    settingsFrame.contentPanel = contentPanel
    settingsFrame.scrollFrame = scrollFrame
    settingsFrame.scrollChild = scrollChild
    
    -- Add category buttons
    self:AddCategoryButtons()
    
    -- Select first category by default
    if #categoryButtons > 0 then
        categoryButtons[1]:Click()
    end
end

-- Add category buttons to the settings frame
function Settings:AddCategoryButtons()
    local categories = {
        { name = "general", label = L:Get("GENERAL_SETTINGS") },
        { name = "appearance", label = L:Get("APPEARANCE_SETTINGS") },
        { name = "tooltips", label = L:Get("TOOLTIP_SETTINGS") },
        { name = "scanning", label = L:Get("SCAN_SETTINGS") },
        { name = "posting", label = L:Get("POSTING_SETTINGS") },
        { name = "shopping", label = L:Get("SHOPPING_SETTINGS") },
        { name = "sound", label = L:Get("SOUND_SETTINGS") },
        { name = "data", label = L:Get("DATA_SETTINGS") }
    }
    
    local buttonHeight = 24
    local spacing = 2
    local yOffset = -10
    
    for i, category in ipairs(categories) do
        local button = CreateFrame("Button", "AuctionMasterCategoryButton" .. i, settingsFrame.categoryPanel)
        button:SetHeight(buttonHeight)
        button:SetPoint("TOPLEFT", 10, yOffset)
        button:SetPoint("TOPRIGHT", -10, yOffset)
        
        local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        buttonText:SetPoint("LEFT", 10, 0)
        buttonText:SetText(category.label)
        button.text = buttonText
        
        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture(1, 1, 1, 0.2)
        
        local selected = button:CreateTexture(nil, "BACKGROUND")
        selected:SetAllPoints()
        selected:SetTexture(0.2, 0.6, 1, 0.4)
        selected:Hide()
        button.selected = selected
        
        button:SetScript("OnClick", function()
            self:SelectCategory(category.name)
            
            -- Update button visuals
            for _, btn in ipairs(categoryButtons) do
                btn.selected:Hide()
            end
            button.selected:Show()
        end)
        
        table.insert(categoryButtons, button)
        yOffset = yOffset - (buttonHeight + spacing)
    end
end

-- Select a category and show its options
function Settings:SelectCategory(categoryName)
    currentCategory = categoryName
    
    -- Clear existing options
    for _, widget in ipairs(optionWidgets) do
        widget:Hide()
    end
    optionWidgets = {}
    
    -- Add options for selected category
    if categoryName == "general" then
        self:AddGeneralOptions()
    elseif categoryName == "appearance" then
        self:AddAppearanceOptions()
    elseif categoryName == "tooltips" then
        self:AddTooltipOptions()
    elseif categoryName == "scanning" then
        self:AddScanningOptions()
    elseif categoryName == "posting" then
        self:AddPostingOptions()
    elseif categoryName == "shopping" then
        self:AddShoppingOptions()
    elseif categoryName == "sound" then
        self:AddSoundOptions()
    elseif categoryName == "data" then
        self:AddDataOptions()
    end
    
    -- Adjust scroll child height
    local height = 20 -- Initial padding
    for _, widget in ipairs(optionWidgets) do
        height = height + (widget.height or widget:GetHeight() or 30) + 10
    end
    settingsFrame.scrollChild:SetHeight(math.max(height, settingsFrame.scrollFrame:GetHeight()))
end

-- Add general options
function Settings:AddGeneralOptions()
    local yOffset = -20
    
    -- Minimap button option
    yOffset = self:AddCheckbox(
        "general.minimap.hide",
        L:Get("MINIMAP_BUTTON"),
        L:Get("MINIMAP_BUTTON_TOOLTIP"),
        yOffset,
        function(value)
            -- Update minimap button visibility
            local icon = LibStub("LibDBIcon-1.0", true)
            if icon then
                if value then
                    icon:Hide("AuctionMaster")
                else
                    icon:Show("AuctionMaster")
                end
            end
        end,
        true -- Invert value (hide vs show)
    )
    
    -- Debug level option
    yOffset = self:AddDropdown(
        "general.debugLevel",
        L:Get("DEBUG_LEVEL"),
        L:Get("DEBUG_LEVEL_TOOLTIP"),
        yOffset,
        {
            { value = AM.Constants.DEBUG_LEVEL.NONE, text = L:Get("NONE") },
            { value = AM.Constants.DEBUG_LEVEL.ERROR, text = L:Get("ERROR") },
            { value = AM.Constants.DEBUG_LEVEL.WARNING, text = L:Get("WARNING") },
            { value = AM.Constants.DEBUG_LEVEL.INFO, text = L:Get("INFO") },
            { value = AM.Constants.DEBUG_LEVEL.VERBOSE, text = L:Get("VERBOSE") }
        }
    )
    
    -- Add reset button
    yOffset = self:AddButton(
        L:Get("RESET_SETTINGS"),
        yOffset,
        function()
            -- Show confirmation dialog
            StaticPopupDialogs["AUCTIONMASTER_RESET_SETTINGS"] = {
                text = L:Get("RESET_SETTINGS_CONFIRM"),
                button1 = L:Get("YES"),
                button2 = L:Get("NO"),
                OnAccept = function()
                    AM.DB:ResetSettings()
                    ReloadUI()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }
            StaticPopup_Show("AUCTIONMASTER_RESET_SETTINGS")
        end
    )
end

-- Add appearance options
function Settings:AddAppearanceOptions()
    local yOffset = -20
    
    -- Theme option
    yOffset = self:AddDropdown(
        "appearance.theme",
        L:Get("THEME"),
        L:Get("THEME_TOOLTIP"),
        yOffset,
        {
            { value = "default", text = L:Get("DEFAULT") },
            { value = "dark", text = L:Get("DARK") },
            { value = "light", text = L:Get("LIGHT") }
        }
    )
    
    -- Scale option
    yOffset = self:AddSlider(
        "appearance.scale",
        L:Get("SCALE"),
        L:Get("SCALE_TOOLTIP"),
        yOffset,
        0.5, 2.0, 0.05
    )
    
    -- Font scale option
    yOffset = self:AddSlider(
        "appearance.fontScale",
        L:Get("FONT_SCALE"),
        L:Get("FONT_SCALE_TOOLTIP"),
        yOffset,
        0.5, 2.0, 0.05
    )
end

-- Add tooltip options
function Settings:AddTooltipOptions()
    local yOffset = -20
    
    -- Enable tooltips option
    yOffset = self:AddCheckbox(
        "tooltips.enable",
        L:Get("ENABLE_TOOLTIPS"),
        L:Get("ENABLE_TOOLTIPS_TOOLTIP"),
        yOffset,
        function(value)
            if AM.Tooltip then
                AM.Tooltip:SetEnabled(value)
            end
        end
    )
    
    -- Show historical prices option
    yOffset = self:AddCheckbox(
        "tooltips.showHistorical",
        L:Get("SHOW_HISTORICAL"),
        L:Get("SHOW_HISTORICAL_TOOLTIP"),
        yOffset
    )
    
    -- Show market value option
    yOffset = self:AddCheckbox(
        "tooltips.showMarketValue",
        L:Get("SHOW_MARKET_VALUE"),
        L:Get("SHOW_MARKET_VALUE_TOOLTIP"),
        yOffset
    )
    
    -- Show minimum buyout option
    yOffset = self:AddCheckbox(
        "tooltips.showMinBuyout",
        L:Get("SHOW_MIN_BUYOUT"),
        L:Get("SHOW_MIN_BUYOUT_TOOLTIP"),
        yOffset
    )
    
    -- Modifier key option
    yOffset = self:AddDropdown(
        "tooltips.modifierKey",
        L:Get("MODIFIER_KEY"),
        L:Get("MODIFIER_KEY_TOOLTIP"),
        yOffset,
        {
            { value = "none", text = L:Get("NONE") },
            { value = "shift", text = L:Get("SHIFT") },
            { value = "alt", text = L:Get("ALT") },
            { value = "ctrl", text = L:Get("CTRL") }
        },
        function(value)
            if AM.Tooltip then
                AM.Tooltip:SetModifierKey(value)
            end
        end
    )
end

-- Add scanning options
function Settings:AddScanningOptions()
    local yOffset = -20
    
    -- Auto scan option
    yOffset = self:AddCheckbox(
        "scanning.autoScan",
        L:Get("AUTO_SCAN"),
        L:Get("AUTO_SCAN_TOOLTIP"),
        yOffset
    )
    
    -- Scan interval option
    yOffset = self:AddSlider(
        "scanning.scanInterval",
        L:Get("SCAN_INTERVAL"),
        L:Get("SCAN_INTERVAL_TOOLTIP"),
        yOffset,
        5, 120, 5
    )
    
    -- GetAll scan option
    yOffset = self:AddCheckbox(
        "scanning.getAll",
        L:Get("GET_ALL"),
        L:Get("GET_ALL_TOOLTIP"),
        yOffset
    )
    
    -- Fast scan option
    yOffset = self:AddCheckbox(
        "scanning.fastScan",
        L:Get("FAST_SCAN"),
        L:Get("FAST_SCAN_TOOLTIP"),
        yOffset
    )
    
    -- Scan throttle option
    yOffset = self:AddSlider(
        "scanning.scanThrottle",
        L:Get("SCAN_THROTTLE"),
        L:Get("SCAN_THROTTLE_TOOLTIP"),
        yOffset,
        50, 500, 10
    )
end

-- Add posting options
function Settings:AddPostingOptions()
    local yOffset = -20
    
    -- Undercut amount option
    yOffset = self:AddEditBox(
        "posting.undercut",
        L:Get("UNDERCUT_AMOUNT"),
        L:Get("UNDERCUT_AMOUNT_TOOLTIP"),
        yOffset,
        function(text)
            return tonumber(text) or 1
        end
    )
    
    -- Default duration option
    yOffset = self:AddDropdown(
        "posting.defaultDuration",
        L:Get("DEFAULT_DURATION"),
        L:Get("DEFAULT_DURATION_TOOLTIP"),
        yOffset,
        {
            { value = AM.Constants.AUCTION_DURATION_12, text = L:Get("12_HOURS") },
            { value = AM.Constants.AUCTION_DURATION_24, text = L:Get("24_HOURS") },
            { value = AM.Constants.AUCTION_DURATION_48, text = L:Get("48_HOURS") }
        }
    )
    
    -- Default stack size option
    yOffset = self:AddSlider(
        "posting.defaultStackSize",
        L:Get("DEFAULT_STACK_SIZE"),
        L:Get("DEFAULT_STACK_SIZE_TOOLTIP"),
        yOffset,
        1, 20, 1
    )
    
    -- Auto post option
    yOffset = self:AddCheckbox(
        "posting.autoPost",
        L:Get("AUTO_POST"),
        L:Get("AUTO_POST_TOOLTIP"),
        yOffset
    )
end

-- Add shopping options
function Settings:AddShoppingOptions()
    local yOffset = -20
    
    -- Enable sniper option
    yOffset = self:AddCheckbox(
        "shopping.enableSniper",
        L:Get("ENABLE_SNIPER"),
        L:Get("ENABLE_SNIPER_TOOLTIP"),
        yOffset
    )
    
    -- Sniper interval option
    yOffset = self:AddSlider(
        "shopping.sniperInterval",
        L:Get("SNIPER_INTERVAL"),
        L:Get("SNIPER_INTERVAL_TOOLTIP"),
        yOffset,
        0.5, 10, 0.5
    )
    
    -- Deal notification option
    yOffset = self:AddCheckbox(
        "shopping.dealNotification",
        L:Get("DEAL_NOTIFICATION"),
        L:Get("DEAL_NOTIFICATION_TOOLTIP"),
        yOffset
    )
end

-- Add sound options
function Settings:AddSoundOptions()
    local yOffset = -20
    
    -- Enable sound alerts option
    yOffset = self:AddCheckbox(
        "sound.enableAlerts",
        L:Get("ENABLE_ALERTS"),
        L:Get("ENABLE_ALERTS_TOOLTIP"),
        yOffset
    )
    
    -- Volume option
    yOffset = self:AddSlider(
        "sound.volume",
        L:Get("VOLUME"),
        L:Get("VOLUME_TOOLTIP"),
        yOffset,
        0, 1, 0.05
    )
end

-- Add data options
function Settings:AddDataOptions()
    local yOffset = -20
    
    -- Data retention option
    yOffset = self:AddSlider(
        "general.dataRetention",
        L:Get("DATA_RETENTION"),
        L:Get("DATA_RETENTION_TOOLTIP"),
        yOffset,
        1, 90, 1
    )
    
    -- Prune data button
    yOffset = self:AddButton(
        L:Get("PRUNE_DATA"),
        yOffset,
        function()
            -- Show confirmation dialog
            StaticPopupDialogs["AUCTIONMASTER_PRUNE_DATA"] = {
                text = L:Get("PRUNE_DATA_CONFIRM"),
                button1 = L:Get("YES"),
                button2 = L:Get("NO"),
                OnAccept = function()
                    -- Prune data older than specified days
                    local days = AM.DB:GetSetting("general.dataRetention", 30)
                    local cutoff = time() - (days * 86400)
                    
                    -- Prune all items
                    if AM.DB.realm and AM.DB.realm.history then
                        for itemKey in pairs(AM.DB.realm.history) do
                            AM.DB:PruneHistoricalData(itemKey, cutoff)
                        end
                    end
                    
                    print("|cFF00CCFF" .. L:Get("DATA_PRUNED") .. "|r")
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3
            }
            StaticPopup_Show("AUCTIONMASTER_PRUNE_DATA")
        end
    )
    
    -- Reset database button
    yOffset = self:AddButton(
        L:Get("RESET_DATABASE"),
        yOffset,
        function()
            -- Show confirmation dialog
            StaticPopupDialogs["AUCTIONMASTER_RESET_DATABASE"] = {
                text = L:Get("RESET_DATABASE_CONFIRM"),
                button1 = L:Get("YES"),
                button2 = L:Get("NO"),
                OnAccept = function()
                    -- Reset realm data
                    AM.DB.realm = {
                        lastScan = 0,
                        scanStats = {
                            totalScans = 0,
                            lastFullScan = 0,
                            averageScanTime = 0,
                        },
                        auctions = {},
                        history = {},
                        marketStats = {},
                        itemCache = {},
                    }
                    
                    print("|cFF00CCFF" .. L:Get("DATABASE_RESET") .. "|r")
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3
            }
            StaticPopup_Show("AUCTIONMASTER_RESET_DATABASE")
        end
    )
end

-- Helper function to add a checkbox option
function Settings:AddCheckbox(settingPath, label, tooltip, yOffset, callback, invert)
    local checkbox = CreateFrame("CheckButton", "AuctionMasterCheckbox" .. #optionWidgets, settingsFrame.scrollChild, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 10, yOffset)
    checkbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        if invert then checked = not checked end
        AM.DB:SetSetting(settingPath, checked)
        if callback then callback(checked) end
    end)
    
    local text = _G[checkbox:GetName() .. "Text"]
    text:SetText(label)
    
    -- Set initial value
    local value = AM.DB:GetSetting(settingPath)
    if invert then value = not value end
    checkbox:SetChecked(value)
    
    -- Add tooltip
    if tooltip then
        checkbox.tooltipText = tooltip
        checkbox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        checkbox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    table.insert(optionWidgets, checkbox)
    return yOffset - 30
end

-- Helper function to add a dropdown option
function Settings:AddDropdown(settingPath, label, tooltip, yOffset, options, callback)
    local dropdown = CreateFrame("Frame", "AuctionMasterDropdown" .. #optionWidgets, settingsFrame.scrollChild, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", 10, yOffset)
    
    local labelText = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 0)
    labelText:SetText(label)
    
    -- Set up dropdown
    UIDropDownMenu_SetWidth(dropdown, 200)
    
    local currentValue = AM.DB:GetSetting(settingPath)
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()
        for _, option in ipairs(options) do
            info.text = option.text
            info.value = option.value
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                AM.DB:SetSetting(settingPath, self.value)
                if callback then callback(self.value) end
            end
            info.checked = (option.value == currentValue)
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    
    UIDropDownMenu_SetSelectedValue(dropdown, currentValue)
    
    -- Add tooltip
    if tooltip then
        dropdown.tooltipText = tooltip
        dropdown:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        dropdown:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    dropdown.height = 50
    table.insert(optionWidgets, dropdown)
    return yOffset - 60
end

-- Helper function to add a slider option
function Settings:AddSlider(settingPath, label, tooltip, yOffset, minValue, maxValue, step)
    local slider = CreateFrame("Slider", "AuctionMasterSlider" .. #optionWidgets, settingsFrame.scrollChild, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 10, yOffset)
    slider:SetWidth(200)
    slider:SetHeight(20)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    
    local labelText = _G[slider:GetName() .. "Text"]
    labelText:SetText(label)
    
    local lowText = _G[slider:GetName() .. "Low"]
    lowText:SetText(minValue)
    
    local highText = _G[slider:GetName() .. "High"]
    highText:SetText(maxValue)
    
    -- Create value text
    local valueText = slider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueText:SetPoint("TOP", slider, "BOTTOM", 0, 0)
    slider.valueText = valueText
    
    -- Set initial value
    local value = AM.DB:GetSetting(settingPath)
    slider:SetValue(value)
    valueText:SetText(value)
    
    -- Set up scripts
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step -- Round to nearest step
        self.valueText:SetText(value)
        AM.DB:SetSetting(settingPath, value)
    end)
    
    -- Add tooltip
    if tooltip then
        slider.tooltipText = tooltip
        slider:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        slider:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    slider.height = 50
    table.insert(optionWidgets, slider)
    return yOffset - 60
end

-- Helper function to add an edit box option
function Settings:AddEditBox(settingPath, label, tooltip, yOffset, validator)
    local editBox = CreateFrame("EditBox", "AuctionMasterEditBox" .. #optionWidgets, settingsFrame.scrollChild, "InputBoxTemplate")
    editBox:SetPoint("TOPLEFT", 10, yOffset)
    editBox:SetWidth(200)
    editBox:SetHeight(20)
    editBox:SetAutoFocus(false)
    
    local labelText = editBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT", 0, 0)
    labelText:SetText(label)
    
    -- Set initial value
    local value = AM.DB:GetSetting(settingPath)
    editBox:SetText(value)
    
    -- Set up scripts
    editBox:SetScript("OnEnterPressed", function(self)
        local value = self:GetText()
        if validator then
            value = validator(value)
        end
        AM.DB:SetSetting(settingPath, value)
        self:ClearFocus()
    end)
    
    editBox:SetScript("OnEscapePressed", function(self)
        self:SetText(AM.DB:GetSetting(settingPath))
        self:ClearFocus()
    end)
    
    -- Add tooltip
    if tooltip then
        editBox.tooltipText = tooltip
        editBox:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        editBox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    editBox.height = 40
    table.insert(optionWidgets, editBox)
    return yOffset - 50
end

-- Helper function to add a button
function Settings:AddButton(label, yOffset, callback)
    local button = CreateFrame("Button", "AuctionMasterButton" .. #optionWidgets, settingsFrame.scrollChild, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", 10, yOffset)
    button:SetWidth(200)
    button:SetHeight(24)
    button:SetText(label)
    button:SetScript("OnClick", callback)
    
    button.height = 30
    table.insert(optionWidgets, button)
    return yOffset - 40
end

-- Show the settings frame
function Settings:Show()
    settingsFrame:Show()
end

-- Hide the settings frame
function Settings:Hide()
    settingsFrame:Hide()
end

-- Toggle the settings frame
function Settings:Toggle()
    if settingsFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
