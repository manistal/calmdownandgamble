
CalmDownandGamble = LibStub("AceAddon-3.0"):NewAddon("CalmDownandGamble", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "AceSerializer-3.0")
local CalmDownandGamble	= LibStub("AceAddon-3.0"):GetAddon("CalmDownandGamble")
local AceGUI = LibStub("AceGUI-3.0")


-- Initializer 
-- =============
function CalmDownandGamble:OnInitialize()
	self:PrintDebug("On Initialize")

	-- Member Initializers
	local defaults = {
	    global = {
			rankings = { },
			ban_list = { },
			chat_index = 1,
			custom_channel_index = nil,
			game_mode_index = 1, 
			game_stage_index = 1,
			window_shown = false,
			ui = nil, 
			minimap = {
				hide = false,
			}
		}
	}
    self.db = LibStub("AceDB-3.0"):New("CalmDownandGambleDB", defaults)

	self.game = {
		mode_id = self.db.global.game_mode_index,
		mode = {}, 
		stage_id = 1, 
		stage = {}
	}

	-- If we're going to dynamically add private channels, we need to ensure we dont start with them
	chat_index = (self.db.global.chat_index <= 4) and self.db.global.chat_index or 1
	self.chat = {
		channel_id = chat_index,
		channel = {},
		CHANNEL_CONSTS = {
			{ label = "Raid"  , const = "RAID"  , addon_const = "RAID", callback = "CHAT_MSG_RAID"  , callback_leader = "CHAT_MSG_RAID_LEADER"  }, -- Index 1
			{ label = "Party" , const = "PARTY" , addon_const = "PARTY", callback = "CHAT_MSG_PARTY" , callback_leader = "CHAT_MSG_PARTY_LEADER" }, -- Index 2
			{ label = "Guild" , const = "GUILD" , addon_const = "GUILD", callback = "CHAT_MSG_GUILD" , callback_leader = nil },                     -- Index 3
			{ label = "Say"   , const = "SAY"   , addon_const = "GUILD", callback = "CHAT_MSG_SAY"   , callback_leader = nil },                     -- Index 4
		}
	}	

	-- AceGUI Table Constructor
	self:ConstructUI()

	-- Register with the minimap icon frame
	self:ConstructMiniMapIcon()

	-- Register the slash commands
	self:RegisterSlashCommands()

	-- Initialize Game States	
	self:SetChatChannel()
	self:SetGameMode()
	self:SetGameStage()
	
	self:PrintDebug("Load Complete!")
end

-- Chat Channels
-- =================
function CalmDownandGamble:SetChatChannel() 
	self.chat.channel = self.chat.CHANNEL_CONSTS[self.chat.channel_id]
	self.chat.num_channels = table.getn(self.chat.CHANNEL_CONSTS)
	self.ui.chat_channel:SetText(self.chat.channel.label)
	
	self:PrintDebug(self.chat.channel.label)
end

function CalmDownandGamble:ChatChannelToggle()
	self.chat.channel_id = self.chat.channel_id + 1
	if self.chat.channel_id > self.chat.num_channels then self.chat.channel_id = 1 end
	self.db.global.chat_index = self.chat.channel_id
	self:SetChatChannel()
end

function CalmDownandGamble:MessageChat(msg)
	if (self.db.global.custom_channel_index and (self.chat.channel.const == "CHANNEL")) then 
		SendChatMessage(msg, self.chat.channel.const, nil, self.db.global.custom_channel_index)
	else 
		SendChatMessage(msg, self.chat.channel.const)
	end
end

function CalmDownandGamble:MessageAddon(event, msg)
	self:SendCommMessage(event, msg, self.chat.channel.addon_const)
end

function CalmDownandGamble:RegisterChatEvents()

	self:RegisterEvent("CHAT_MSG_SYSTEM", function(...) self:RollCallback(...) end)
	self:RegisterEvent(self.chat.channel.callback, function(...) self:ChatChannelCallback(...) end)
	if (self.chat.channel.callback_leader) then
		self:RegisterEvent(self.chat.channel.callback_leader, function(...) self:ChatChannelCallback(...) end)
	end
end

function CalmDownandGamble:UnregisterChatEvents()
	self:CancelAllTimers()
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
	self:UnregisterEvent(self.chat.channel.callback)
	if (self.chat.channel.callback_leader) then
		self:UnregisterEvent(self.chat.channel.callback_leader)
	end
end

-- Game Modes
-- ================
function CalmDownandGamble:SetGameMode() 
	-- Loaded from external File
	GAME_MODES = { CDG_HILO, CDG_INVERSE, CDG_BIGTWOS, CDG_YAHTZEE }
	self.game.mode = GAME_MODES[self.game.mode_id]
	self.game.num_modes = table.getn(GAME_MODES)
	self.ui.game_mode:SetText(self.game.mode.label)

end


function CalmDownandGamble:ToggleGameMode()
	self.game.mode_id = self.game.mode_id + 1
	if self.game.mode_id > self.game.num_modes then self.game.mode_id = 1 end
	self.db.global.game_mode_index = self.game.mode_id
	self:SetGameMode()
end


-- Game Stages
-- =====================
function CalmDownandGamble:SetGameStage() 
	GAME_STAGES = {
			{ label = "New Game",  callback = function() self:StartGame() end }, -- Index 1
			{ label = "Last Call!",   callback = function() self:LastCall() end }, -- Index 2
			{ label = "Start Rolls!", callback = function() self:StartRolls() end }, -- Index 3
			{ label = "Roll Status", callback = function() self:RollStatus() end }, -- Index 4
	}	
	
	self.game.stage = GAME_STAGES[self.game.stage_id]
	self.game.num_stages = table.getn(GAME_STAGES)
	self.ui.game_stage:SetText(self.game.stage.label)
	
	self:PrintDebug(self.game.stage.label)
end

function CalmDownandGamble:ResetGameStage()
	self.game.stage_id = 1
	self:SetGameStage()
end


function CalmDownandGamble:ToggleGameStage()
	self.game.stage.callback()
	if self.game.stage_id < self.game.num_stages then 
		self.game.stage_id = self.game.stage_id + 1 
		self:SetGameStage()
	end
end

-- Stage Callbacks
-- (stage_id = 1) Game will always start here in start game
function CalmDownandGamble:StartGame()
	-- Reset & Init Current GAME
	self.game.data = {
		accepting_players = true,
		accepting_rolls = false,
		high_tiebreaker = false,
		low_tiebreaker = false,
		winner = nil,
		loser = nil,
		winning_roll = nil,
		losing_roll = nil,
		high_roller_playoff = {},
		low_roller_playoff = {},
		player_rolls = {}
	}
	self:SetGoldAmount()
	self:RegisterChatEvents()
	self.game.mode.init_game(self.game)
	self:PrintDebug("Initialized Current GAME")

	-- In case of custom channel, we need to let the guild know! 
	if (self.db.global.custom_channel_index and (self.chat.channel.const == "CHANNEL")) then 
	    channel_name = self:GetCustomChannelName()
		SendChatMessage("Just started a Gambling Round in a custom channel! To join in use /cdg joinChat or /join "..channel_name, "GUILD")
	end

	-- Welcome Message!
	local welcome_msg = "CDG is now in session! Mode: "..self.game.mode.label..", Bet: "..self.game.data.gold_amount.." gold"
	self:MessageChat(welcome_msg)
	self:MessageChat("Press 1 to Join!")
	
	-- Notify Clients of New GAME
	local start_args = self.game.data.roll_lower.." "..self.game.data.roll_upper.." "..self.game.data.gold_amount.." "..self.chat.channel.const
	self:MessageAddon("CDG_NEW_GAME", start_args)
	self:PrintDebug(start_args)
end

-- (stage_id = 2) Count Down to Game Start
function CalmDownandGamble:LastCall()
	self:MessageChat("Last call! 10 seconds left!")
	self:ScheduleTimer("TimedStart", 10)
end

-- (stage_id = 3) After accepting entries via chat callbacks, start the rolls
function CalmDownandGamble:StartRolls()
	-- Cancel the countdown to start if its there
	self:CancelAllTimers()
	
	
	-- Make sure we have enough players
	self:PrintDebug(self:TableLength(self.game.data.player_rolls))
	if (self:TableLength(self.game.data.player_rolls) <= 1) then
		self:MessageChat("Can't start a game with less than 2 players")
		self.game.stage_id = self.game.stage_id - 1
		self:SetGameStage()
		return 
	end

	-- Allow roll callbacks
	self.game.data.accepting_rolls = true
	self.game.data.accepting_players = false
	
	-- Tell Tiebreakers Who Has to Roll
	local roll_msg = ""
	if self.game.data.high_tiebreaker then 
		self:MessageChat("The Winners Bracket! High Tiebreaker:")
		self:PrintTieBreakerPlayers(self.game.data.player_rolls)
	elseif self.game.data.low_tiebreaker then 
		self:MessageChat("The Losers! Low Tiebreaker:")
		self:PrintTieBreakerPlayers(self.game.data.player_rolls)
	end
	
	-- Off to the races!
	self:MessageChat(roll_msg)
	self:MessageChat("Time to roll! Good Luck! Command:   /roll "..self.game.data.roll_range)
end

function CalmDownandGamble:PrintTieBreakerPlayers(players)


	tiebreaker_list = ""
	for player, roll in pairs(players) do
		-- TODO - Figure out how to use this for Yahtzee self.game.mode.fmt_score(roll)
		tiebreaker_list = tiebreaker_list..player.." vs "
	end
	tiebreaker_list = tiebreaker_list:sub(1, -5)
	self:MessageChat(tiebreaker_list)
end

-- (stage_id =4) Poll for Roll Status
function CalmDownandGamble:RollStatus()
	self:CheckRollsComplete(true)
end

function CalmDownandGamble:CheckRollsComplete(print_players)

	local rolls_complete = true
	
	self:PrintDebug("CheckRollsComplete() Called")

	for player, roll in pairs(self.game.data.player_rolls) do
		if (roll == -1) then
			rolls_complete = false
			if print_players then
				self:MessageChat("Player: "..player.." still needs to roll") 
			end
		end
	end
	
	if (rolls_complete) then
		self.game.accepting_rolls = false
		self:GameLoop()
	end
	
end

function CalmDownandGamble:GameLoop() 
	if (CalmDownandGamble:EvaluateScores()) then
		self.game.mode.payout(self.game)
		self:MessageChat(self.game.data.loser.." owes "..self.game.data.winner.." "..self.game.data.cash_winnings.." gold!")
		self:LogResults()
		self:EndGame()
	end
end


function CalmDownandGamble:EndGame()
	-- Tell  the clients and UI were done
	local end_args = self.game.data.winner.." "..self.game.data.loser.." "..self.game.data.cash_winnings
	self:MessageAddon("CDG_END_GAME", end_args)
	self.ui.CDG_Frame:SetStatusText(self.game.data.cash_winnings.."g  "..self.game.data.loser.." => "..self.game.data.winner)
	
	-- Reset Game Hooks and Data
	self:UnregisterChatEvents()
	self:ResetGameStage()
	self.game.data = nil
end

function CalmDownandGamble:ResetGame()
	self:UnregisterChatEvents()
	self.game.data = nil
	self:ResetGameStage()
	self:MessageChat("Game has been reset.")
end

-- Utils
-- ========
function CalmDownandGamble:GameResultsCallback(...)
	local callback = select(1, ...)
	local message = select(2, ...)
	local chat = select(3, ...)
	local sender = select(4, ...)

	-- Parse the message
	message = self:SplitString(message, "%S+")	
    winner = message[1]
	loser = message[2]
    cash_winnings = message[3]
	
	-- Don't record what we're sending out
	local name, realm = UnitName("player")
	if (sender == name) then
		return
	end
	
	-- Log results
	if (self.db.global.rankings[winner] ~= nil) then
		self.db.global.rankings[winner] = self.db.global.rankings[winner] + cash_winnings
	else
		self.db.global.rankings[winner] = (1*cash_winnings)
	end
	
	if (self.db.global.rankings[loser] ~= nil) then
		self.db.global.rankings[loser] = self.db.global.rankings[loser] - cash_winnings
	else
		self.db.global.rankings[loser] = (-1*cash_winnings)
	end
end

function CalmDownandGamble:LogResults() 
	self:PrintDebug("Winner: "..self.game.data.winner)
	self:PrintDebug("Loser: "..self.game.data.loser)
	self:PrintDebug("CASH: "..self.game.data.cash_winnings)
	
	if (self.db.global.rankings[self.game.data.winner] ~= nil) then
		self.db.global.rankings[self.game.data.winner] = self.db.global.rankings[self.game.data.winner] + self.game.data.cash_winnings
	else
		self.db.global.rankings[self.game.data.winner] = (1*self.game.data.cash_winnings)
	end
	
	if (self.db.global.rankings[self.game.data.loser] ~= nil) then
		self.db.global.rankings[self.game.data.loser] = self.db.global.rankings[self.game.data.loser] - self.game.data.cash_winnings
	else
		self.db.global.rankings[self.game.data.loser] = (-1*self.game.data.cash_winnings)
	end
end

function CalmDownandGamble:SetGoldAmount() 

	local text_box = self.ui.gold_amount_entry:GetText()
	local text_box_valid = (not string.match(text_box, "[^%d]")) and (text_box ~= '')
	if ( text_box_valid ) then
		self.game.data.gold_amount = text_box
	else
		self.game.data.gold_amount = 100
	end

end

-- SCORING FUNCTION
-- ===================
-- Sorts the rolls base on the game mode sorting function
-- The game mode sorting fucntion accepts rolls and returns a sorted table
-- based on scores where the winner is always first, and the loser last
function CalmDownandGamble:EvaluateScores()
	self:PrintDebug("Evaluating Scores")
	
	local winning_roll, losing_roll, high_roller_playoff, low_roller_playoff = nil, nil, {}, {}
	local winner, loser = nil, nil
	
    -- Loop over the players and look for highest/lowest/etc
	local roll_index, total_rolls = 0, table.getn(self.game.data.player_rolls)
	for player, roll in self:sortedpairs(self.game.data.player_rolls, self.game.mode.sort_rolls) do
		
		-- Loop Incrementer
		roll_index = roll_index + 1
		player_score = self.game.mode.roll_to_score(roll)
		self:PrintDebug("    "..player.." "..player_score)
		
		-- Roll Index == 1 -> Winner 
		if (roll_index == 1) then 
			winning_roll = player_score
			high_roller_playoff[player] = -1
			winner = player
		
		-- Score == Winner -> Tiebreaker
		elseif (player_score == winning_roll) then
			high_roller_playoff[player] = -1
		
		-- Score != Winner -> First Loser
		elseif (losing_roll == nil) then      
			losing_roll = player_score
			low_roller_playoff[player] = -1
			loser = player
			
		-- Score != Loser and Index != End -> New Loser
		elseif (player_score ~= losing_roll) then   
			low_roller_playoff = {}
			losing_roll = player_score
			low_roller_playoff[player] = -1
			loser = player
		
		-- Score == Loser -> Tiebreaker
		elseif (player_score == losing_roll)  then  -- also the worst
			low_roller_playoff[player] = -1
		
		else
		end
		
		
	end
	
	local high_roller_count = self:TableLength(high_roller_playoff)
	local low_roller_count = self:TableLength(low_roller_playoff)
	
	local found_winner = (high_roller_count == 1) 
	local found_loser = (low_roller_count == 1) 
	
	-- High Tiebreaker -- 
	if self.game.data.high_tiebreaker then 
		if found_winner then 
			self.game.data.winner = winner
			self.game.data.winning_roll = winning_roll
			self.game.data.high_tiebreaker = false
			self.game.data.high_roller_playoff = {}
		-- TODO handle the case where we pick off losers
		--elseif ((self.game.data.loser == nil) and (not self.game.data.low_tiebreaker) and found_loser) then
			-- Handle the case where the first loser in high tiebreaker is the actual loser
			--self.game.data.loser = loser
			--self.game.data.losing_roll = losing_roll
			--self.game.data.low_tiebreaker = false
			--self.game.data.low_roller_playoff = {}
		else
			self.game.data.player_rolls = self:CopyTable(high_roller_playoff)
			self.game.data.high_tiebreaker = true
			self:StartRolls()
			self:PrintDebug("High Tie Breaker #2")
			return false
		end
	-- Low Tiebreaker -- 
	elseif self.game.data.low_tiebreaker then 

		
		-- if total_players == high_rollers
		if (high_roller_count == self:TableLength(self.game.data.player_rolls)) then
			
		end
	
		if found_loser then 
			self.game.data.loser = loser
			self.game.data.losing_roll = losing_roll
			self.game.data.low_tiebreaker = false
			self.game.data.low_roller_playoff = {}
		elseif (high_roller_count == self:TableLength(self.game.data.player_rolls)) then
		-- all low tied again? will show up in "high_roller_playoff"
			self.game.data.player_rolls = self:CopyTable(high_roller_playoff)
			self.game.data.low_tiebreaker = true
			self:StartRolls()
			self:PrintDebug("Low Tiebreaker #4")
			return false
		else
			self.game.data.player_rolls = self:CopyTable(low_roller_playoff)
			self.game.data.low_tiebreaker = true
			self:StartRolls()
			self:PrintDebug("Low Tiebreaker #2")
			return false
		end
	-- No Tiebreaker -- 
	else
		if found_winner then 
			self.game.data.winner = winner
			self.game.data.winning_roll = winning_roll
			self.game.data.high_tiebreaker = false
			self.game.data.high_roller_playoff = {}
		else 
			self.game.data.high_roller_playoff = self:CopyTable(high_roller_playoff)
		end
		
		if found_loser then 
			self.game.data.loser = loser
			self.game.data.losing_roll = losing_roll
			self.game.data.low_tiebreaker = false
			self.game.data.low_roller_playoff = {}
		else
			self.game.data.low_roller_playoff = self:CopyTable(low_roller_playoff)
		end

	end
	
	
	if (self:TableLength(self.game.data.low_roller_playoff) > 1) then 
		self:PrintDebug("Low Tiebreaker #1")
		-- start low tiebreaker -- 
		self.game.data.low_tiebreaker = true
		self.game.data.player_rolls = self:CopyTable(self.game.data.low_roller_playoff)
		self:StartRolls()
		return false
	elseif (self:TableLength(self.game.data.high_roller_playoff) > 1) then 
		self:PrintDebug("High Tiebreaker #1")
		self.game.data.high_tiebreaker = true
		self.game.data.player_rolls = self:CopyTable(self.game.data.high_roller_playoff)
		self:StartRolls()
		return false
	elseif (self.game.data.loser == nil) and (not found_loser) then  -- special case, everyone was a high roller
		self:PrintDebug("Low Tiebreaker #3")
		self.game.data.low_tiebreaker = true
		self.game.data.player_rolls = self:CopyTable(low_roller_playoff)
		self:StartRolls()
		return false
	elseif (self.game.data.loser == nil) and found_loser then  -- special case, everyone was a high roller, 1v1
		self.game.data.loser = loser
		self.game.data.losing_roll = losing_roll
		return true
	else
		return true
	end
		
end

-- ChatFrame Interaction Callbacks (Entry and Rolls)
-- ==================================================== 
function CalmDownandGamble:RollCallback(...)
	if (self.game.data == nil) then return end

	-- Parse the input Args 
	local channel = select(1, ...)
	local roll_text = select(2, ...)
	local message = self:SplitString(roll_text, "%S+")
	local player, roll, roll_range = message[1], message[3], message[4]
	if (roll_range == nil) then return end  -- If rollrange is nil its not a roll
	
	self:PrintDebug("Checking Roll for Range: "..self.game.data.roll_range)
	self:PrintDebug("Player: "..player.." Roll: "..roll)
	-- Check that the roll is valid ( also that the message is for us)
	local valid_roll = (self.game.data.roll_range == roll_range) and self.game.data.accepting_rolls

	if valid_roll then 
		if (self.game.data.player_rolls[player] == -1) then
			self:PrintDebug("Player: "..player.." Roll: "..roll.." RollRange: "..roll_range)
			-- TODO: Only in NONGROUP channels if channel == "CDG_ROLL_DICE" then SendSystemMessage(roll_text) end
			self.game.data.player_rolls[player] = tonumber(roll)
			self:CheckRollsComplete(false)
		end
	end
	
end

function CalmDownandGamble:ChatChannelCallback(...)
	if (self.game.data == nil) then return end

	local message = select(2, ...)
	local sender = select(3, ...)
	
	message = message:gsub("%s+", "") -- trim whitespace
	sender = Ambiguate(sender, "short")

	local player_join = (
		(self.game.data.player_rolls[sender] == nil) 
		and (self.game.data.accepting_players) 
		and (message == "1")
        and (not self.db.global.ban_list[sender])
	)
	
	if (player_join) then
		self.game.data.player_rolls[sender] = -1
		self:PrintDebug(sender.." joined the game")
	end

end

-- Button Interaction Callbacks (State and Settings)
-- ==================================================== 
function CalmDownandGamble:PrintBanlist()
	self:MessageChat("Hall of GTFO:")
	for player, _ in pairs(self.db.global.ban_list) do
		self:MessageChat(player)
    end
end

function CalmDownandGamble:PrintRanklist()

	self:MessageChat("Hall of Fame: ")
	local index = 1
	local sort_descending = function(t,a,b) return t[b] < t[a] end
	for player, gold in self:sortedpairs(self.db.global.rankings, sort_descending) do
		if gold <= 0 then break end
		
		local msg = string.format("%d. %s won %d gold.", index, player, gold)
		self:MessageChat(msg)
		index = index + 1
	end
	
	self:MessageChat("~~~~~~")
	
	self:MessageChat("Hall of Shame: ")
	index = 1
	local sort_ascending = function(t,a,b) return t[b] > t[a] end
	for player, gold in self:sortedpairs(self.db.global.rankings, sort_ascending) do
		if gold >= 0 then break end
	
		local msg = string.format("%d. %s lost %d gold.", index, player, math.abs(gold))
		self:MessageChat(msg)
		index = index + 1
	end
	
end

function CalmDownandGamble:RollForMe()
	if self.game.data == nil then 
		SendSystemMessage("You need an active game for me to roll for you!")
		return
	end
	RandomRoll(self.game.data.roll_lower, self.game.data.roll_upper)
end

function CalmDownandGamble:EnterForMe()
	self:MessageChat("1")
end

function CalmDownandGamble:TimedStart() 
	if (self.game.data ~= nil) then
		if not self.game.data.accepting_rolls then 
			self.game.stage_id = 4 -- 4 is the final stage
			self:SetGameStage()
			self:StartRolls()
		end
	end
end

-- UI ELEMENTS 
-- ======================================================
function CalmDownandGamble:ShowUI()
	self.ui.CDG_Frame:Show()
	self.db.global.window_shown = true
end

function CalmDownandGamble:HideUI()
	self.ui.CDG_Frame:Hide()
	self.db.global.window_shown = false
	self:SaveFrameState()
end

function CalmDownandGamble:SaveFrameState()
	self.db.global.ui = self:CopyTable(self.ui.CDG_Frame.status)
end

function CalmDownandGamble:ConstructUI()
	
	-- Settings to be used -- 
	local cdg_ui_elements = {
		-- Main Box Frame -- 
		main_frame = {
			width = 443,
			height = 145	
		},
		
		-- Order in which the buttons are layed out -- 
		button_index = {
			"game_stage",
			"enter_for_me",
			"roll_for_me",
			"chat_channel",
			"game_mode",
			"print_stats_table",
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
				click_callback = function() self:ToggleGameMode() end
			},
			print_ban_list = {
				width = 100,
				label = "Print bans",
				click_callback = function() self:PrintBanlist() end
			},
			print_stats_table = {
				width = 100,
				label = "Print stats",
				click_callback = function() self:PrintRanklist() end
			},
			reset_game = {
				width = 100,
				label = "Reset",
				click_callback = function() self:ResetGame() end
			},
			enter_for_me = {
				width = 100,
				label = "Enter me",
				click_callback = function() self:EnterForMe() end
			},			
			roll_for_me = {
				width = 100,
				label = "Roll!",
				click_callback = function() self:RollForMe() end
			},
			start_gambling = {
				width = 100,
				label = "Start roll",
				click_callback = function() self:StartRolls() end
			},
			last_call = {
				width = 100,
				label = "Last call!",
				click_callback = function() self:LastCall() end
			},
			game_stage = {
				width = 100,
				label = "New game",
				click_callback = function() self:ToggleGameStage() end

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
	self.ui.CDG_Frame:EnableResize(false)
	self.ui.CDG_Frame:SetCallback("OnClose", function() self:HideUI() end)
	self.ui.CDG_Frame.frame:SetUserPlaced(true)
	
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
	
	if (self.db.global.ui ~= nil) then
		self.ui.CDG_Frame:SetStatusTable(self.db.global.ui)
	end
	
	if not self.db.global.window_shown then
		self.ui.CDG_Frame:Hide()
	end
	
	-- Register for UI Events
	self:RegisterEvent("PLAYER_LEAVING_WORLD", function(...) self:SaveFrameState(...) end)
end