

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
	self:InitState()

	self:Print("Load Complete!!")
end

-- INIT FOR ENABLE  
function CalmDownandGamble:OnEnable()
end

-- DESTRUCTOR  
function CalmDownandGamble:OnDisable()
end

function CalmDownandGamble:InitState()
	-- Chat Context -- 
	self.chat = {}
	self.game = {}
	self.chat.channel_index = 1
	self.game.channel_index = 1
	self:SetChannelSettings()
	self:SetGameMode()
	
end

function CalmDownandGamble:SetChannelSettings() 

	self.chat.options = {
			{ label = "Raid", const = "RAID", callback = "CHAT_MSG_RAID", callback_leader = "CHAT_MSG_RAID_LEADER" }, -- Index 1
			{ label = "Say", const = "SAY", callback = "CHAT_MSG_SAY", callback_leader = nil},   -- Index 2
			{ label = "Party", const = "PARTY", callback = "CHAT_MSG_PARTY", callback_leader = "CHAT_MSG_PARTY_LEADER" },   -- Index 3
			{ label = "Guild", const = "GUILD", callback = "CHAT_MSG_GUILD", callback_leader = nil },   -- Index 4	
	}	
	self.chat.channel_const = "RAID"   -- What the WoW API is looking for, CHANNEL for numeric channels
	
	self:Print(self.chat.options[self.chat.channel_index].label)
	
	self.chat.channel_const = self.chat.options[self.chat.channel_index].const
	self.ui.chat_channel:SetText(self.chat.options[self.chat.channel_index].label)
	self.chat.channel_callback = self.chat.options[self.chat.channel_index].callback
	self.chat.channel_callback_leader = self.chat.options[self.chat.channel_index].callback_leader

end

function CalmDownandGamble:RegisterCallbacks()
	-- Register Some Slash Commands
	self:RegisterChatCommand("cdgshow", "ShowUI")
	self:RegisterChatCommand("cdghide", "HideUI")
end

function CalmDownandGamble:StartGame()
	-- Init our game
	self.current_game = {}
	self.current_game.accepting_rolls = false
	self.current_game.accepting_players = true

	self.current_game.player_rolls = {}
	self:SetGoldAmount()
	
	-- Register game callbacks
	self:RegisterEvent("CHAT_MSG_SYSTEM", function(...) self:RollCallback(...) end)
	self:RegisterEvent(self.chat.channel_callback, function(...) self:ChatChannelCallback(...) end)
	if (self.chat.channel_callback_leader) then
		self:RegisterEvent(self.chat.channel_callback_leader, function(...) self:ChatChannelCallback(...) end)
	end
	
	
	local welcome_msg = "CDG Initialized. Mode: "..self.game.options[self.game.channel_index].label.." Bet:"..self.current_game.gold_amount.." gold, Join now."
	local welcome_info = 
	SendChatMessage(welcome_msg, self.chat.channel_const)
	SendChatMessage(welcome_info, self.chat.channel_const)
	
end

function CalmDownandGamble:EndGame()
	-- Init our game
	self.current_game = nil
	
	-- Register game callbacks
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
	self:UnregisterEvent(self.chat.channel_const)

end

function CalmDownandGamble:SetGoldAmount() 

	local text_box = self.ui.gold_amount_entry:GetText()
	local text_box_valid = (not string.match(text_box, "[^%d]")) and (text_box ~= '')
	if ( text_box_valid ) then
		self.current_game.gold_amount = text_box
	else
		self.current_game.gold_amount = 100
	end

end

function CalmDownandGamble:SetGameMode() 

	self.game.options = {
			{ label = "High-Low", func = function() self:HighLow() end}, -- Index 1
			{ label = "2s", func = function() self:twos() end},   -- Index 2
			{ label = "Big Pot", func = function() self:BigPot() end},   -- Index 3
	
	}	
	
	self:Print(self.game.options[self.game.channel_index].label)
	self.ui.game_mode:SetText(self.game.options[self.game.channel_index].label)

end
function CalmDownandGamble:HighLow()

end

function CalmDownandGamble:twos()

end

function CalmDownandGamble:BigPot()

end

-- Util Functions cuz EW LUA STRINGS 
-- =============================================
function SplitString(str, pattern)
	local ret_list = {}
	local index = 1
	for token in string.gmatch(str, pattern) do
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

-- CHAT CALLBACKS -- 
function CalmDownandGamble:RollCallback(...)
	-- Parse the input Args 
	local message = select(2, ...)
	message = SplitString(message, "%S+")
	local player, roll, roll_range = message[1], message[3], message[4]
	
	-- Check that the roll is valid ( also that the message is for us)
	local roll_range_str = "(1-"..self.current_game.gold_amount..")"
	local valid_roll = (roll_range_str == roll_range) and self.current_game.accepting_rolls

	if self.current_game and valid_roll then 
		
		if (self.current_game.player_rolls[player] == -1) then
			self:Print("Player: "..player.." Roll: "..roll.." RollRange: "..roll_range)
			self.current_game.player_rolls[player] = roll
		end
		
	end
	
	
end

function CalmDownandGamble:ChatChannelCallback(...)
	local message = select(2, ...)
	local sender = select(3, ...)
	
	sender = SplitString(sender, "%w+")[1]
	
	local player_join = (
		(self.current_game.player_rolls[sender] == nil) 
		and (self.current_game.accepting_players) 
		and (message == "1")
	)
	
	if (player_join) then
		self.current_game.player_rolls[sender] = -1
		self:Print("JOINED "..sender)
	end

end

-- BUTTONS -- 
function CalmDownandGamble:ButtonCallback()
	--self:Print(self.chat.chanId)
	--self:Print(self.chat.chanName)
end

function CalmDownandGamble:RollForMe()
	RandomRoll(1, 100)
end

function CalmDownandGamble:EnterForMe()
	RandomRoll(1, 100)
end

function CalmDownandGamble:StartRolls()
	local roll_msg = "Time to roll!! /roll "..self.current_game.gold_amount
	SendChatMessage(roll_msg, self.chat.channel_const)
	self.current_game.accepting_rolls = true
	self.current_game.accepting_players = false
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


function CalmDownandGamble:ChatChannelToggle()
	self.chat.channel_index = self.chat.channel_index + 1
	if self.chat.channel_index > table.getn(self.chat.options) then self.chat.channel_index = 1 end

	self:SetChannelSettings()
	
end

function CalmDownandGamble:ButtonGameMode()
	self.game.channel_index = self.game.channel_index + 1
	if self.game.channel_index > table.getn(self.game.options) then self.game.channel_index = 1 end

	self:SetGameMode()
	
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
			"new_game",
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
				label = "Raid",
				click_callback = function() self:ChatChannelToggle() end
			},
			game_mode = {
				width = 100,
				label = "(Classic)",
				click_callback = function() self:ButtonGameMode() end
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
			reset_game = {
				width = 100,
				label = "Reset",
				click_callback = function() self:EndGame() end
			},
			roll_for_me = {
				width = 100,
				label = "Roll For Me",
				click_callback = function() self:RollForMe() end
			},
			enter_for_me = {
				width = 100,
				label = "Enter Me",
				click_callback = function() self:EnterGameForMe() end
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
			new_game = {
				width = 100,
				label = "NewGame",
				click_callback = function() self:StartGame() end
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












