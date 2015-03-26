

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
			game_mode_index = 1, 
			window_shown = false
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


-- Initialization Helper Functions
-- ===========================================
function CalmDownandGamble:InitState()
	-- Chat Context -- 
	self.chat = {}
	self.game = {}
	self:SetChannelSettings()
	self:SetGameMode()
	
end

function CalmDownandGamble:SetChannelSettings() 

	self.chat.options = {
			{ label = "Raid"  , const = "RAID"  , callback = "CHAT_MSG_RAID"  , callback_leader = "CHAT_MSG_RAID_LEADER"  }, -- Index 1
			{ label = "Party" , const = "PARTY" , callback = "CHAT_MSG_PARTY" , callback_leader = "CHAT_MSG_PARTY_LEADER" }, -- Index 2
			{ label = "Guild" , const = "GUILD" , callback = "CHAT_MSG_GUILD" , callback_leader = nil },                     -- Index 3
			{ label = "Say"   , const = "SAY"   , callback = "CHAT_MSG_SAY"   , callback_leader = nil },                     -- Index 4
	}	
	self.chat.channel_const = "RAID"   -- What the WoW API is looking for, CHANNEL for numeric channels
	
	if DEBUG then self:Print(self.chat.options[self.db.global.chat_index].label) end
	
	self.chat.channel_const = self.chat.options[self.db.global.chat_index].const
	self.ui.chat_channel:SetText(self.chat.options[self.db.global.chat_index].label)
	self.chat.channel_callback = self.chat.options[self.db.global.chat_index].callback
	self.chat.channel_callback_leader = self.chat.options[self.db.global.chat_index].callback_leader

end

function CalmDownandGamble:SetGameMode() 

	self.game.options = {
			{ label = "High-Low",  evaluate = function() self:HighLowWrap() end, init = function() self:DefaultGameInit() end }, -- Index 1
			{ label = "Inverse",   evaluate = function() self:Inverse() end,     init = function() self:DefaultGameInit() end }, -- Index 2
			{ label = "MiddleMan", evaluate = function() self:Median() end,      init = function() self:DefaultGameInit() end }, -- Index 3
			{ label = "Yahtzee",   evaluate = function() self:Yahtzee() end,     init = function() self:YahtzeeInit() end },     -- Index 4
			{ label = "BigTWOS",   evaluate = function() self:HighLowWrap() end,     init = function() self:TwosInit() end },     -- Index 5
	}	
	
	if DEBUG then self:Print(self.game.options[self.db.global.game_mode_index].label) end
	self.ui.game_mode:SetText(self.game.options[self.db.global.game_mode_index].label)

end

-- Slash Command Setup and Calls
-- =========================================================
function CalmDownandGamble:RegisterCallbacks()
	-- Register Some Slash Commands
	self:RegisterChatCommand("cdgshow", "ShowUI")
	self:RegisterChatCommand("cdghide", "HideUI")
	self:RegisterChatCommand("cdgreset", "ResetStats")
	self:RegisterChatCommand("cdgdebug", "SetDebug")
	
	
	-- self:RegisterComm("CDG_NEW_GAME", "NewGameCallback")
    -- self:RegisterComm("CDG_NEW_ROLL", "NewRollsCallback")
    -- self:RegisterComm("CDG_END_GAME", "GameResultsCallback")
end

function CalmDownandGamble:SetDebug()
	DEBUG = not DEBUG
end

function CalmDownandGamble:ShowUI()
	self.ui.CDG_Frame:Show()
	self.db.global.window_shown = true
end

function CalmDownandGamble:HideUI()
	self.ui.CDG_Frame:Hide()
	self.db.global.window_shown = false
end

function CalmDownandGamble:ResetStats()
	self.db.global.rankings = {}
end


-- Game State Machine 
-- ================================================

-- (1) Game will always start here in start game
function CalmDownandGamble:StartGame()
	-- Init our game
	self.current_game = {}
	self.current_game.accepting_rolls = false
	self.current_game.accepting_players = true
	self.current_game.high_roller_playoff = nil
	self.current_game.low_roller_playoff = nil
	self.current_game.player_rolls = {}
	
	self.game.options[self.db.global.game_mode_index].init()
	
	-- Register game callbacks
	self:RegisterComm("CDG_ROLL_DICE", "RollCallback")
	self:RegisterEvent("CHAT_MSG_SYSTEM", function(...) self:RollCallback(...) end)
	self:RegisterEvent(self.chat.channel_callback, function(...) self:ChatChannelCallback(...) end)
	if (self.chat.channel_callback_leader) then
		self:RegisterEvent(self.chat.channel_callback_leader, function(...) self:ChatChannelCallback(...) end)
	end
	
	if DEBUG then self:Print("Init'd game state and registered callbacks") end
	
	local welcome_msg = "CDG is now in session! Mode: "..self.game.options[self.db.global.game_mode_index].label..", Bet: "..self.current_game.gold_amount.." gold"
	SendChatMessage(welcome_msg, self.chat.channel_const)
	SendChatMessage("Press 1 to Join!", self.chat.channel_const)

	
	
	local start_args = self.current_game.roll_lower.." "..self.current_game.roll_upper.." "..self.current_game.gold_amount
	self:SendCommMessage("CDG_NEW_GAME", start_args, self.chat.channel_const)
	if DEBUG then self:Print(start_args) end
end

-- (2) After accepting entries via chat callbacks, start the rolls
function CalmDownandGamble:StartRolls()

	local roll_msg = ""
	if (self.current_game.high_roller_playoff) then
		self.current_game.player_rolls = CopyTable(self.current_game.high_roller_playoff)
		roll_msg = "High Roller TieBreaker! "..format_player_names(self.current_game.high_roller_playoff)
	elseif (self.current_game.low_roller_playoff) then
		self.current_game.player_rolls = CopyTable(self.current_game.low_roller_playoff)
		roll_msg = "Low Roller TieBreaker! "..format_player_names(self.current_game.low_roller_playoff)
	else
		roll_msg = "Time to roll! Good Luck! Command:   /roll "..self.current_game.roll_range
	end
	SendChatMessage(roll_msg, self.chat.channel_const)
	
	self.current_game.accepting_rolls = true
	self.current_game.accepting_players = false
end

    -- Helper func for StartRolls
function format_player_names(players)
	local return_str = ""
	for player, _ in pairs(players) do
		return_str = return_str..player.." vs "
	end
	return_str = return_str.."!!"
	return string.gsub(return_str, " vs !", "")
end

-- (3) Called from game mode evaluate function, will log values of
-- current_winner/current_loser - can be called twice like in middleman
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

-- (4) Resets the game state machine, called from game mode evaluate after game
-- is done and all tiebreakers have been resolved
function CalmDownandGamble:EndGame()
	-- Show me the results
	local end_args = self.current_game.winner.." "..self.current_game.loser.." "..self.current_game.cash_winnings
	self:SendCommMessage("CDG_END_GAME", end_args, self.chat.channel_const)
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


-- Game Utililties -- Needed by game for basic common actions
-- =============================================================
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
		self.game.options[self.db.global.game_mode_index].evaluate()
	end
	
end


-- Game Modes -- Each Game Mode must define an init (or use default) and an
-- evaluate function, init sets roll_range and gold value, eval sets 
-- cashwinnings winner and loser
-- ============================================================================

-- DEFAULT INIT -- Used by almost everything
function CalmDownandGamble:DefaultGameInit() 
	self:SetGoldAmount()
	self.current_game.roll_upper = self.current_game.gold_amount
	self.current_game.roll_lower = 1
	self.current_game.roll_range = "(1-"..self.current_game.gold_amount..")"
end

-- Yahtzee Init -- Yahtzee is different because fun. 
function CalmDownandGamble:YahtzeeInit() 
	self:SetGoldAmount()
	self.current_game.roll_range = "(11111-99999)"
	self.current_game.roll_upper = 99999
	self.current_game.roll_lower = 11111
end

-- Twos Init -- Yahtzee is different because fun. 
function CalmDownandGamble:TwosInit() 
	self:SetGoldAmount()
	self.current_game.roll_range = "(1-2)"
	self.current_game.roll_upper = 2
	self.current_game.roll_lower = 1
end

-- Basic scoring function, will pick out highest and lowest from the list
-- of rolls, can be overloaded (such as in inverse and yahtzee)
function CalmDownandGamble:HighLow()
	
	if DEBUG then self:Print("Evaluating High Low") end
	
	local high_player, low_player = "", ""
	local high_score, low_score = 0, 999999
	
	local high_player_playoff = {}
	local low_player_playoff = {}
	
	for player, roll in pairs(self.current_game.player_rolls) do
	
		player_score = tonumber(roll)
		if DEBUG then self:Print(player.." "..player_score) end
		
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
	
	-- Currently a play off -- 
	local high_playoff = (TableLength(high_player_playoff) ~= 0)
	local low_playoff = (TableLength(low_player_playoff) ~= 0)

	local first_rolls = (self.current_game.high_roller_playoff == nil) and (self.current_game.low_roller_playoff == nil)
	local prev_high_playoff = (self.current_game.high_roller_playoff ~= nil)

	if first_rolls then
		if high_playoff then
			self.current_game.high_roller_playoff = CopyTable(high_player_playoff)
		else
			self.current_game.winner = high_player
		end
		
		if low_playoff then
			self.current_game.low_roller_playoff = CopyTable(low_player_playoff)
		else
			self.current_game.loser = low_player
		end
		
	elseif prev_high_playoff then
		if high_playoff then
			self.current_game.high_roller_playoff = CopyTable(high_player_playoff)
		else
			self.current_game.winner = high_player
			self.current_game.high_roller_playoff = nil
		end
	else
		if low_playoff then
			self.current_game.low_roller_playoff = CopyTable(low_player_playoff)
		else
			self.current_game.loser = low_player
		end
	end
	
	local found_winner = (self.current_game.winner ~= nil)
	local found_loser =  (self.current_game.loser ~= nil)

	if not (found_winner and found_loser) then
		self:StartRolls()
		return
	end
	
	self.current_game.cash_winnings = high_score - low_score

end

-- Game mode: Yahtze 
-- =================================================
function format_yahtzee_roll(roll)
	local ret_string = ""
	for digit in string.gmatch(roll, "%d") do
		ret_string = ret_string..digit.."-"
    end
	ret_string = ret_string.."!!"
	return string.gsub(ret_string, "-!!", "")
end

function CalmDownandGamble:ScoreYahtzee(roll)

	local score = 0
	for digit in string.gmatch(roll, "%d") do
		local _, count = string.gsub(roll, digit, "")
		if DEBUG then self:Print(digit.." #"..count) end
		score = score + (count * digit)
    end
	
	return score
end


function CalmDownandGamble:Yahtzee()

	local player_scores = {}
	for player, roll in pairs(self.current_game.player_rolls) do
		local score = self:ScoreYahtzee(roll)
		player_scores[player] = score
	end
	
	local sort_by_score = function(t,a,b) return t[b] < t[a] end
	for player, score in sortedpairs(player_scores, sort_by_score) do
		SendChatMessage(player.." Roll: "..format_yahtzee_roll(self.current_game.player_rolls[player]).." Score: "..score, self.chat.channel_const)
	end

	self.current_game.player_rolls = {}
	self.current_game.player_rolls = CopyTable(player_scores)
	self:HighLow()
	self.current_game.cash_winnings = self.current_game.gold_amount
	
	SendChatMessage(self.current_game.loser.." owes "..self.current_game.winner.." "..self.current_game.cash_winnings.." gold!", self.chat.channel_const)
	
	-- Log Results -- All game modes must call these two explicitly
	self:LogResults()
	self:EndGame()
	
end

-- Game mode: MiddleMan
-- =================================================
function CalmDownandGamble:Median()
	
	local sort_by_score = function(t,a,b) return t[b] < t[a] end
	local high_player, median_player, low_player = "", "", ""
	local high_score, median_score, low_score = 0, 0, 0
	
	local total_players = TableLength(self.current_game.player_rolls)
	local last_number = total_players
	local median_number = math.floor((total_players + 1) / 2)

	local player_index = 1
	for player, roll in sortedpairs(self.current_game.player_rolls, sort_by_score) do
		self:Print(player.." "..roll)
		if player_index == 1 then 
			high_player = player
			high_score = roll
		elseif player_index == median_number then
			median_player = player
			median_score = roll
		elseif player_index == last_number then
			low_player = player
			low_score = roll
		else 
		end
		player_index = player_index + 1
	end

	self.current_game.winner = median_player
	

	self.current_game.loser = high_player
	self.current_game.cash_winnings = math.abs(median_score - high_score)
	SendChatMessage(self.current_game.loser.." owes "..self.current_game.winner.." "..self.current_game.cash_winnings.." gold!", self.chat.channel_const)
	self:LogResults()
	
	self.current_game.loser = low_player
	self.current_game.cash_winnings = math.abs(median_score - low_score)
	SendChatMessage(self.current_game.loser.." owes "..self.current_game.winner.." "..self.current_game.cash_winnings.." gold!", self.chat.channel_const)
	self:LogResults()
	
	self:EndGame()
end

-- Game mode: High Low
-- =================================================
function CalmDownandGamble:HighLowWrap()
	CalmDownandGamble:HighLow()
	
	SendChatMessage(self.current_game.loser.." owes "..self.current_game.winner.." "..self.current_game.cash_winnings.." gold!", self.chat.channel_const)
	
	-- Log Results -- All game modes must call these two explicitly
	self:LogResults()
	self:EndGame()
end

-- Game mode: Inverse
-- =================================================
function CalmDownandGamble:Inverse()
	CalmDownandGamble:HighLow()
	
	self.current_game.winner, self.current_game.loser = self.current_game.loser, self.current_game.winner
	
	SendChatMessage(self.current_game.loser.." owes "..self.current_game.winner.." "..self.current_game.cash_winnings.." gold!", self.chat.channel_const)
	
	-- Log Results -- All game modes must call these two explicitly
	self:LogResults()
	self:EndGame()
end



-- ChatFrame Interaction Callbacks (Entry and Rolls)
-- ==================================================== 
function CalmDownandGamble:RollCallback(...)
	-- Parse the input Args 
	local channel = select(1, ...)
	local roll_text = select(2, ...)
	local message = SplitString(roll_text, "%S+")
	local player, roll, roll_range = message[1], message[3], message[4]
	
	-- Check that the roll is valid ( also that the message is for us)
	local valid_roll = (self.current_game.roll_range == roll_range) and self.current_game.accepting_rolls

	if valid_roll then 
		if (self.current_game.player_rolls[player] == -1) then
			if DEBUG then self:Print("Player: "..player.." Roll: "..roll.." RollRange: "..roll_range) end
			if channel == "CDG_ROLL_DICE" then SendSystemMessage(roll_text) end
			self.current_game.player_rolls[player] = tonumber(roll)
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


-- Button Interaction Callbacks (State and Settings)
-- ==================================================== 
function CalmDownandGamble:PrintBanlist()
    -- Todo implement bans -- 
end

function CalmDownandGamble:PrintRanklist()

	sort_by_score = function(t,a,b) return t[b] < t[a] end
	index = 1
	SendChatMessage("Hall of Fame: ", self.chat.channel_const)
	for player, gold in sortedpairs(self.db.global.rankings, sort_by_score) do
		if gold <= 0 then break end
		
		local msg = string.format("%d. %s won %d gold.", index, player, gold)
		SendChatMessage(msg, self.chat.channel_const)
		index = index + 1
	end
	
	SendChatMessage("~~~~~~", self.chat.channel_const)
	
	sort_by_score = function(t,a,b) return t[b] > t[a] end
	index = 1
	SendChatMessage("Hall of Shame: ", self.chat.channel_const)
	for player, gold in sortedpairs(self.db.global.rankings, sort_by_score) do
		if gold >= 0 then break end
	
		local msg = string.format("%d. %s lost %d gold.", index, player, math.abs(gold))
		SendChatMessage(msg, self.chat.channel_const)
		index = index + 1
	end
	
end

function CalmDownandGamble:RollForMe()
	RandomRoll(1, self.current_game.gold_amount)
end

function CalmDownandGamble:EnterForMe()
	SendChatMessage("1", self.chat.channel_const)
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
	SendChatMessage("Game has been reset.", self.chat.channel_const)
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
			"last_call",
			"start_gambling",
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
				click_callback = function() self:ResetGame() end
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
				label = "Start Rolls!",
				click_callback = function() self:StartRolls() end
			},
			last_call = {
				width = 100,
				label = "Last Call!",
				click_callback = function() self:LastCall() end
			},
			new_game = {
				width = 100,
				label = "New Game",
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
	self.ui.CDG_Frame:SetCallback("OnClose", function() self:HideUI() end)
	
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
	
	if not self.db.global.window_shown then
		self.ui.CDG_Frame:Hide()
	end
	
end


-- Util Functions -- Lua doesnt provide alot of basic functionality
-- =======================================================================
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










