

-- Declare the new addon and load the libraries we want to use 
CalmDownandGamble = LibStub("AceAddon-3.0"):NewAddon("CalmDownandGamble", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "AceSerializer-3.0")
local CalmDownandGamble	= LibStub("AceAddon-3.0"):GetAddon("CalmDownandGamble")
local AceGUI = LibStub("AceGUI-3.0")

-- Basic Adddon Initialization stuff, virtually inherited functions 
-- ================================================================ 

-- CONSTRUCTOR 
function CalmDownandGamble:OnInitialize()
	self:Print("Load Begin")

	-- Set up Infrastructure
    self.db = LibStub("AceDB-3.0"):New("CalmDownandGambleDB")
	self:ConstructUI()
	self:RegisterCallbacks()

	self:Print("Load Complete!!")
end

-- INIT FOR ENABLE  
function CalmDownandGamble:OnEnable()
end

-- DESTRUCTOR  
function CalmDownandGamble:OnDisable()
end

function CalmDownandGamble:RegisterCallbacks()
	-- Register Some Slash Commands
	self:RegisterChatCommand("cdgshow", "ShowUI")
	self:RegisterChatCommand("cdghide", "HideUI")
	
	-- Regsiter Chat Callbacks
	self:RegisterEvent("CHAT_MSG_SYSTEM", function(...) self:RollCallback(...) end)
end

-- Util Functions cuz EW LUA STRINGS 
-- =============================================
function SplitString(str)
	local ret_list = {}
	local index = 1
	for token in string.gmatch(str, "%S+") do
		ret_list[index] = token
		index = index + 1
	end
	return ret_list
end


-- CALLBACK FUNCTIONS 
-- ==================================================== 

-- SLASH COMMANDS -- 
function CalmDownandGamble:ShowUI()
	self.ui.CDG_Frame:Show()
end
function CalmDownandGamble:HideUI()
	self.ui.CDG_Frame:Hide()
end

-- BUTTONS -- 
function CalmDownandGamble:ButtonCallback()
	self:Print("DID IT WORK")
end

function CalmDownandGamble:RollForMeCallback()
	RandomRoll(1, 100)
end

function CalmDownandGamble:StartRolls()
end

function CalmDownandGamble:LastCall()
	for player, roll in pairs(self.current_game.player_rolls) do
		self:Print(player)
		self:Print(roll)
	end

end

function CalmDownandGamble:ResetGame()
	self.current_game = nil
end

function CalmDownandGamble:AcceptRegisters()
	-- SendChatMessage("text" [, "chatType" [, languageIndex [, "channel"]]])
	SendChatMessage("Pres 1 to Join!!")
	self.current_game = {}
	self.current_game.player_rolls = {}
end

-- CHAT CALLBACKS -- 
function CalmDownandGamble:RollCallback(...)
	local message = select(2, ...)
	message = SplitString(message)
	local player, roll, roll_range = message[1], message[3], message[4]
	
	if self.current_game then 
		-- TODO if self.current_game.roll_range != roll_range then
		if not (self.current_game.player_rolls[player]) then
			self.current_game.player_rolls[player] = roll
		end
	end
	
end


-- UI ELEMENTS 
-- ======================================================
function CalmDownandGamble:ConstructUI()
	
	-- Settings to be used -- 
	local cdg_ui_elements = {
		-- Main Box Frame -- 
		main_frame = {
			width = 440,
			height = 170
		},
		
		-- Order in which the buttons are layed out -- 
		button_index = {
			"accept_entries",
			"start_gambling",
			"last_call",
			"roll_for_me",
			"enter_for_me",
			"print_stats_table",
			"print_ban_list",
			"chat_channel",
			"game_mode",
			"reset_game"
		},
		
		-- Button Definitions -- 
		buttons = {
			chat_channel = {
				width = 100,
				label = "(Raid)",
				click_callback = function() self:ButtonCallback() end
			},
			game_mode = {
				width = 100,
				label = "(Classic)",
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
				click_callback = function() self:RollForMeCallback() end
			},
			enter_for_me = {
				width = 100,
				label = "Enter Me",
				click_callback = function() self:ButtonCallback() end
			},
			start_gambling = {
				width = 100,
				label = "StartRolls!",
				click_callback = function() self:StartRolls() end
			},
			last_call = {
				width = 100,
				label = "LastCall!",
				click_callback = function() self:LastCall() end
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
				click_callback = function() self:AcceptRegisters() end
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
	self.ui.CDG_Frame:SetStatusTable(cdg_ui_elements.main_frame)
	
	-- Set up edit box for gold -- 
	self.ui.gold_amount_entry = AceGUI:Create("EditBox")
	self.ui.gold_amount_entry:SetLabel("Gold Amount")
	self.ui.gold_amount_entry:SetWidth(100)
	self.ui.CDG_Frame:AddChild(self.ui.gold_amount_entry)
	
	-- Set up Buttons Above Text Box-- 
	for _, button_name in pairs(cdg_ui_elements.button_index) do
		local button_settings = cdg_ui_elements.buttons[button_name]
	
		self.ui[button_name] = AceGUI:Create("Button")
		self.ui[button_name]:SetText(button_settings.label)
		self.ui[button_name]:SetWidth(button_settings.width)
		self.ui[button_name]:SetCallback("OnClick", button_settings.click_callback)
		
		self.ui.CDG_Frame:AddChild(self.ui[button_name])
	end
	
	
	
	
end












