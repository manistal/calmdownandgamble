

-- Declare the new addon and load the libraries we want to use 
CalmDownandGamble = LibStub("AceAddon-3.0"):NewAddon("CalmDownandGamble", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "AceSerializer-3.0")
local CalmDownandGamble	= LibStub("AceAddon-3.0"):GetAddon("CalmDownandGamble")
local AceGUI = LibStub("AceGUI-3.0")

local DEBUG = false

-- Basic Adddon Initialization stuff, virtually inherited functions 
-- ================================================================ 

-- CONSTRUCTOR 
function CalmDownandGamble:OnInitialize()
	if DEBUG then self:Print("Load Begin") end

	-- Set up Infrastructure
	local defaults = {
	    global = {
			rankings = { },
			chat_index = 1,
			game_mode_index = 1
		}
	}

    self.db = LibStub("AceDB-3.0"):New("CalmDownandGambleDB", defaults)
	self:ConstructUI()
	self:RegisterCallbacks()
	self:InitState()

	if DEBUG then self:Print("Load Complete!!") end
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
	
	if DEBUG then self:Print(self.chat.options[self.db.global.chat_index].label) end
	
	self.chat.channel_const = self.chat.options[self.db.global.chat_index].const
	self.ui.chat_channel:SetText(self.chat.options[self.db.global.chat_index].label)
	self.chat.channel_callback = self.chat.options[self.db.global.chat_index].callback
	self.chat.channel_callback_leader = self.chat.options[self.db.global.chat_index].callback_leader

end

function CalmDownandGamble:SetDebug()
	DEBUG = not DEBUG
end

function CalmDownandGamble:RegisterCallbacks()
	-- Register Some Slash Commands
	self:RegisterChatCommand("cdgshow", "ShowUI")
	self:RegisterChatCommand("cdghide", "HideUI")
	self:RegisterChatCommand("cdgreset", "ResetStats")
	self:RegisterChatCommand("cdgdebug", "SetDebug")
end

function CalmDownandGamble:StartGame()
	-- Init our game
	self.current_game = {}
	self.current_game.accepting_rolls = false
	self.current_game.accepting_players = true
	self.current_game.high_roller_playoff = nil
	self.current_game.low_roller_playoff = nil
	
	self.current_game.player_rolls = {}
	self:SetGoldAmount()
	
	-- Register game callbacks
	self:RegisterEvent("CHAT_MSG_SYSTEM", function(...) self:RollCallback(...) end)
	self:RegisterEvent(self.chat.channel_callback, function(...) self:ChatChannelCallback(...) end)
	if (self.chat.channel_callback_leader) then
		self:RegisterEvent(self.chat.channel_callback_leader, function(...) self:ChatChannelCallback(...) end)
	end
	
	
	local welcome_msg = "CDG Initialized. ~~ Mode: "..self.game.options[self.db.global.game_mode_index].label.." ~~ Bet:  "..self.current_game.gold_amount.." gold ~~ Press 1 to Join now."
	SendChatMessage(welcome_msg, self.chat.channel_const)
	
end

function CalmDownandGamble:EndGame()

	-- Show me the results
	self.ui.CDG_Frame:SetStatusText(self.current_game.cash_winnings.."g  "..self.current_game.loser.." => "..self.current_game.winner)

	-- Init our game
	self.current_game = nil
	
	-- Register game callbacks
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
	self:UnregisterEvent(self.chat.channel_callback)
	if (self.chat.channel_callback_leader) then
		self:UnregisterEvent(self.chat.channel_callback_leader)
	end
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

function CalmDownandGamble:CheckRollsComplete(print_players)

	local rolls_complete = true

	for player, roll in pairs(self.current_game.player_rolls) do
		if DEBUG then self:Print(" "..player.." "..roll.." ") end 
		if (roll == -1) then
			rolls_complete = false
			if print_players then
				SendChatMessage("Player: "..player.." still needs to roll", self.chat.channel_const) 
			end
		end
	end
	
	if (rolls_complete) then
		self.game.options[self.db.global.game_mode_index].func()
	end
	
end


function CalmDownandGamble:SetGameMode() 

	self.game.options = {
			{ label = "High-Low", func = function() self:HighLowWrap() end}, -- Index 1
			{ label = "Inverse", func = function() self:Inverse() end},   -- Index 2
			--{ label = "2s", func = function() self:twos() end},   -- Index 3
			--{ label = "Big Pot", func = function() self:BigPot() end},   -- Index 4
			
	}	
	
	if DEBUG then self:Print(self.game.options[self.db.global.game_mode_index].label) end
	self.ui.game_mode:SetText(self.game.options[self.db.global.game_mode_index].label)

end


function CalmDownandGamble:LogResults() 
	if (self.db.global.rankings[self.current_game.winner] ~= nil) then
		self.db.global.rankings[self.current_game.winner] = self.db.global.rankings[self.current_game.winner] + self.current_game.cash_winnings
	else
		self.db.global.rankings[self.current_game.winner] = self.current_game.cash_winnings
	end
	
	if (self.db.global.rankings[self.current_game.loser] ~= nil) then
		self.db.global.rankings[self.current_game.loser] = self.db.global.rankings[self.current_game.loser] - self.current_game.cash_winnings
	else
		self.db.global.rankings[self.current_game.loser] = (-1*self.current_game.cash_winnings)
	end
end


function CalmDownandGamble:HighLow()
	
	local high_player, low_player = "", ""
	local high_score, low_score = 0, (self.current_game.gold_amount + 1)
	
	local high_player_playoff = {}
	local low_player_playoff = {}
	
	for player, roll in pairs(self.current_game.player_rolls) do
	
		player_score = tonumber(roll)
		
		if (player_score > high_score) then
			high_player = player
			high_score = player_score
			high_player_playoff = {}
		elseif (player_score == high_score) then
			high_player_playoff[player] = -1
			high_player_playoff[high_player] = -1
		end
			
		if (player_score < low_score) then
			low_player = player
			low_score = player_score
			low_player_playoff = {}
		elseif (player_score == low_score) then
			low_player_playoff[player] = -1
			low_player_playoff[low_player] = -1
		end
		
	end
	
	local high_play = TableLength(high_player_playoff)
	local low_play = TableLength(low_player_playoff)
	local playoff = ((high_play ~= 0) or (low_play ~= 0))
	
	if (high_play > 1) and (low_play > 1) then
		self.current_game.high_roller_playoff = CopyTable(high_player_playoff)
		self.current_game.low_roller_playoff = CopyTable(low_player_playoff)
		self:StartRolls()
		return
	elseif (high_play > 1) then
		self.current_game.high_roller_playoff = CopyTable(high_player_playoff)
		self.current_game.loser = low_player
		self:StartRolls()
		return
	elseif (low_play > 1) then
		self.current_game.low_roller_playoff = CopyTable(low_player_playoff)
		self.current_game.winner = high_player
		self:StartRolls()
		return
	else
		-- Ternary operator -- A ? B : C ==> A AND B OR C cause fuck lua
		self.current_game.winner = (self.current_game.winner == nil) and high_player or self.current_game.winner
		self.current_game.loser = (self.current_game.loser == nil) and low_player or self.current_game.loser
	end


	self.current_game.cash_winnings = high_score - low_score

end


function CalmDownandGamble:HighLowWrap()
	CalmDownandGamble:HighLow()
	
	SendChatMessage("THE RESULTS: "..self.current_game.loser.." owes "..self.current_game.winner.." "..self.current_game.cash_winnings.." gold!", self.chat.channel_const)
	
	-- Log Results -- All game modes must call these two explicitly
	self:LogResults()
	self:EndGame()
end

function CalmDownandGamble:Inverse()
	CalmDownandGamble:HighLow()
	
	self.current_game.winner, self.current_game.loser = self.current_game.loser, self.current_game.winner
	
	SendChatMessage("THE RESULTS: "..self.current_game.loser.." owes "..self.current_game.winner.." "..self.current_game.cash_winnings.." gold!", self.chat.channel_const)
	
	-- Log Results -- All game modes must call these two explicitly
	self:LogResults()
	self:EndGame()
end


function CalmDownandGamble:twos()
	SendChatMessage("TWOS CHECK RESULTS!", self.chat.channel_const)
end

function CalmDownandGamble:BigPot()
	SendChatMessage("BIG POT RESULTS!!", self.chat.channel_const)
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

function CopyTable(T)
  local u = { }
  for k, v in pairs(T) do u[k] = v end
  return setmetatable(u, getmetatable(T))
end

function TableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function PrintTable(T)
	for k, v in pairs(T) do
		CalmDownandGamble:Print(k.."  "..v)
	end
end

function sortedpairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end
    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
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
			if DEBUG then self:Print("Player: "..player.." Roll: "..roll.." RollRange: "..roll_range) end
			self.current_game.player_rolls[player] = roll
			self:CheckRollsComplete(false)
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
		if DEBUG then self:Print("JOINED "..sender) end
	end

end

-- BUTTONS -- 
function CalmDownandGamble:PrintBanlist()

end

function CalmDownandGamble:ResetStats()
	self.db.global.rankings = {}
end

function CalmDownandGamble:PrintRanklist()

	sort_by_score = function(t,a,b) return t[b] < t[a] end
	index = 1
	SendChatMessage("The Winners Circle: ", self.chat.channel_const)
	SendChatMessage("======", self.chat.channel_const)
	for player, gold in sortedpairs(self.db.global.rankings, sort_by_score) do
		if gold <= 0 then break end
		
		local msg = string.format("%d.  %-20s %d gold.", index, player, gold)
		SendChatMessage(msg, self.chat.channel_const)
		index = index + 1
	end
	
	SendChatMessage("         ", self.chat.channel_const)
	
	sort_by_score = function(t,a,b) return t[b] > t[a] end
	index = 1
	SendChatMessage("The Wall Of Lost Gold Shame: ", self.chat.channel_const)
	SendChatMessage("======", self.chat.channel_const)
	for player, gold in sortedpairs(self.db.global.rankings, sort_by_score) do
		if gold >= 0 then break end
	
		local msg = string.format("%d.  %-20s     %d gold.", index, player, math.abs(gold))
		SendChatMessage(msg, self.chat.channel_const)
		index = index + 1
	end

	SendChatMessage("         ", self.chat.channel_const)
	
end

function CalmDownandGamble:RollForMe()
	RandomRoll(1, self.current_game.gold_amount)
end

function CalmDownandGamble:EnterForMe()
	SendChatMessage("1", self.chat.channel_const)
end

function format_player_names(players)
	local return_str = ""
	for player, _ in pairs(players) do
		return_str = return_str..player.." vs "
	end
	return_str = return_str.."!!"
	return return_str.gsub(return_str, " vs !", "")
end

function CalmDownandGamble:StartRolls()
	
	local roll_msg = ""
	if (self.current_game.high_roller_playoff) then
		self.current_game.player_rolls = CopyTable(self.current_game.high_roller_playoff)
		roll_msg = "High Roller TieBreaker! "..format_player_names(self.current_game.high_roller_playoff)
	elseif (self.current_game.low_roller_playoff) then
		self.current_game.player_rolls = CopyTable(self.current_game.low_roller_playoff)
		roll_msg = "Low Roller TieBreaker! "..format_player_names(self.current_game.low_roller_playoff)
	else
		roll_msg = "Time to roll! Good Luck! Command:   /roll "..self.current_game.gold_amount
	end
	SendChatMessage(roll_msg, self.chat.channel_const)
	
	self.current_game.accepting_rolls = true
	self.current_game.accepting_players = false
end

function CalmDownandGamble:LastCall()
	if (self.current_game.accepting_rolls) then
		self:CheckRollsComplete(true)
	elseif (self.current_game.accepting_players) then
		SendChatMessage("Last call! 10 seconds left!", self.chat.channel_const)
		self:ScheduleTimer("StartRolls", 10)
	end
end

function CalmDownandGamble:ResetGame()
	self.current_game = nil
end

function CalmDownandGamble:ChatChannelToggle()
	self.db.global.chat_index = self.db.global.chat_index + 1
	if self.db.global.chat_index > table.getn(self.chat.options) then self.db.global.chat_index = 1 end

	self:SetChannelSettings()
end

function CalmDownandGamble:ButtonGameMode()
	self.db.global.game_mode_index = self.db.global.game_mode_index + 1
	if self.db.global.game_mode_index > table.getn(self.game.options) then self.db.global.game_mode_index = 1 end

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
				click_callback = function() self:PrintBanlist() end
			},
			print_stats_table = {
				width = 100,
				label = "Print Stats",
				click_callback = function() self:PrintRanklist() end
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
				click_callback = function() self:EnterForMe() end
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
	
	
	self.ui.CDG_Frame:Hide()
	
end












