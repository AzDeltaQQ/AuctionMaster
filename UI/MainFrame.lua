-- AuctionMaster Main UI Frame
local addonName, AM = ...
local L = AM.L -- For future localization

AM.UI = AM.UI or {} -- Ensure AM.UI table exists
local MainFrame = {}
AM.UI.MainFrame = MainFrame

local frame = nil

function MainFrame:Initialize()
    if frame then return end -- Already initialized

    frame = CreateFrame("Frame", "AuctionMasterMainFrame", UIParent)
    frame:SetWidth(700)
    frame:SetHeight(500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0.1, 0.1, 0.1, 0.9) -- Dark semi-transparent background

    -- Title
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("AuctionMaster Main Window")

    -- Close Button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -2, -2)
    closeButton:SetScript("OnClick", function() MainFrame:Hide() end)
    
    AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "AuctionMaster MainFrame initialized.")
end

function MainFrame:Show()
    if not frame then
        self:Initialize() -- Initialize if not already done
    end
    if frame then
        frame:Show()
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "AuctionMaster MainFrame shown.")
    end
end

function MainFrame:Hide()
    if frame then
        frame:Hide()
        AM.Util.Debug(AM.Constants.DEBUG_LEVEL.INFO, "AuctionMaster MainFrame hidden.")
    end
end

function MainFrame:Toggle()
    if not frame or not frame:IsShown() then
        self:Show()
    else
        self:Hide()
    end
end

function MainFrame:IsShown()
    return frame and frame:IsShown()
end