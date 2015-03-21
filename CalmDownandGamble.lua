

-- Declare the new addon and load the libraries we want to use 
CalmDownandGamble = LibStub("AceAddon-3.0"):NewAddon("CalmDownandGamble", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "AceSerializer-3.0")
local CalmDownandGamble	= LibStub("AceAddon-3.0"):GetAddon("CalmDownandGamble")
local AceGUI = LibStub("AceGUI-3.0")

-- Basic Adddon Initialization stuff, virtually inherited functions 
-- ================================================================ 

-- CONSTRUCTOR 
function CalmDownandGamble:OnInitialize()
    -- Set up a database so we can save results 
	self:Print("Load Begin")

	self:RegisterChatCommand("cdgwoo", "ShowUI")
	self:RegisterChatCommand("cdgroll", "GenerateRoll")
	self:RegisterChatCommand("cdgleave", "LeaveGame")
    self.db = LibStub("AceDB-3.0"):New("CalmDownandGambleDB")
	self:ConstructUI()

	self:Print("Load Complete!!")
end

-- INIT FOR ENABLE  
function CalmDownandGamble:OnEnable()
end

-- DESTRUCTOR  
function CalmDownandGamble:OnDisable()
end


-- CALLBACK FUNCTIONS 
-- ==================================================== 
function CalmDownandGamble:GenerateRoll()
end

function CalmDownandGamble:ShowUI()
	self:Print("HAHAH");
	self.ui.CDG_Frame:Hide()
end

function CalmDownandGamble:LeaveGame()
end

function CalmDownandGamble:ButtonCallback()
	self:Print("DID IT WORK")
end

-- UI ELEMENTS 
-- ======================================================
function CalmDownandGamble:ConstructUI()
	
	-- Settings to be used -- 
	local cdg_ui_elements = {
		-- Main Box Frame -- 
		main_frame = {
			width = 450,
			height = 150
		},
		
		-- Order in which the buttons are layed out -- 
		button_index = {
			"accept_entries",
			"start_gambling",
			"print_stats_table",
			"print_ban_list",
			"roll_for_me",
			"enter_for_me",
			"chat_channel",
			"reset_game"
		},
		
		-- Button Definitions -- 
		buttons = {
			chat_channel = {
				width = 100,
				label = "(Raid)",
				click_callback = function() self:ButtonCallback() end
			},
			reset_game = {
				width = 100,
				label = "Reset",
				click_callback = function() self:ButtonCallback() end
			},
			roll_for_me = {
				width = 100,
				label = "Roll For Me",
				click_callback = function() self:ButtonCallback() end
			},
			enter_for_me = {
				width = 100,
				label = "Enter Me",
				click_callback = function() self:ButtonCallback() end
			},
			start_gambling = {
				width = 100,
				label = "StartRolls!",
				click_callback = function() self:ButtonCallback() end
			},
			print_ban_list = {
				width = 100,
				label = "Print Bans",
				click_callback = function() self:ButtonCallback() end
			},
			print_stats_table = {
				width = 100,
				label = "Print Stats",
				click_callback = function() self:ButtonCallback() end
			},
			accept_entries = {
				width = 100,
				label = "CallEntries",
				click_callback = function() self:ButtonCallback() end
			}
		}
	};
	
	-- Give us a base UI Table to work with -- 
	self.ui = {}
	
	-- Constructor Calls -- 
	self.ui.CDG_Frame = AceGUI:Create("Frame")
	self.ui.CDG_Frame:SetTitle("Calm Down Gambling")
	self.ui.CDG_Frame:SetStatusText("")
	self.ui.CDG_Frame:SetLayout("Flow")
	self.ui.CDG_Frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	self.ui.CDG_Frame:SetStatusTable(cdg_ui_elements.main_frame)
	

	-- Set up Buttons -- 
	for _, button_name in pairs(cdg_ui_elements.button_index) do
		local button_settings = cdg_ui_elements.buttons[button_name]
	
		self.ui[button_name] = AceGUI:Create("Button")
		self.ui[button_name]:SetText(button_settings.label)
		self.ui[button_name]:SetWidth(button_settings.width)
		self.ui[button_name]:SetCallback("OnClick", button_settings.click_callback)
		
		self.ui.CDG_Frame:AddChild(self.ui[button_name])
	end
	
	
	--[[
	local editbox = AceGUI:Create("EditBox")
	editbox:SetLabel("Insert text:")
	editbox:SetWidth(200)
	CDG_Frame:AddChild(editbox)

	local button = AceGUI:Create("Button")
	button:SetText("Click Me!")
	button:SetWidth(200)
	CDG_Frame:AddChild(button)
	--]]
end












