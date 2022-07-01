
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
			game_mode_index = 1, 
			game_stage_index = 1,
			window_shown = false,
			ui_frame = nil, 
			custom_channel = {
				index = nil,
				name = "",
			}, 
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
	
	self.previous_gameData = nil

	-- If we're going to dynamically add private channels, we need to ensure we dont start with them
	self.chat = {
		channel_id = self.db.global.chat_index,
		channel = {},
		CHANNEL_CONSTS = { 
			{ label = "Raid"  ,   const = "RAID"  ,  addon_const = "RAID",  callback = "CHAT_MSG_RAID"  ,  callback_leader = "CHAT_MSG_RAID_LEADER"  }, -- Index 1
			{ label = "Party" ,   const = "PARTY" ,  addon_const = "PARTY", callback = "CHAT_MSG_PARTY" ,  callback_leader = "CHAT_MSG_PARTY_LEADER" }, -- Index 2
			{ label = "Guild" ,   const = "GUILD" ,  addon_const = "GUILD", callback = "CHAT_MSG_GUILD"     },                     -- Index 3
			{ label = "Say"   ,   const = "SAY"   ,  addon_const = "GUILD", callback = "CHAT_MSG_SAY"       },                     -- Index 4
    		{ label = "CDG", const = "CHANNEL", addon_const = "CHANNEL", callback = "CHAT_MSG_CHANNEL" },                     -- Index 5
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
	SendChatMessage(msg, self.chat.channel.const, nil, self.db.global.custom_channel.index)
end

function CalmDownandGamble:MessageAddon(event, msg)
	self:SendCommMessage(event, msg, self.chat.channel.addon_const, tostring(self.db.global.custom_channel.index))
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
	GAME_MODES = { CDG_HILO, CDG_INVERSE, CDG_ROULETTE, CDG_BIGTWOS, CDG_LILONES, CDG_YAHTZEE, CDG_CURLING }
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
			{ label = "NewGame",  callback = function() self:StartGame() end }, -- Index 1
			{ label = "LastCall",   callback = function() self:LastCall() end }, -- Index 2
			{ label = "StartRoll", callback = function() self:StartRolls() end }, -- Index 3
			{ label = "Status", callback = function() self:RollStatus() end }, -- Index 4
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
		high_tiebreak = nil,
		low_tiebreak = nil,
		winner = nil,
		loser = nil,
		round = "initial",
		first_round = true,
		winning_score = nil,
		losing_score = nil,
		high_score_playoff = {},
		low_score_playoff = {},
		player_rolls = {}
	}
	self.previous_gameData = self.game.data
	self:SetGoldAmount()
	self:RegisterChatEvents()
	self.game.mode.init_game(self.game)
	self:PrintDebug("Initialized Current GAME")

	-- In case of custom channel, we need to let the guild know! 
	if ((self.chat.channel.const == "CHANNEL") and (self.db.global.custom_channel.index == nil)) then 
		self:JoinCustomChannel(nil)
		SendChatMessage("Just started a Gambling Round in a custom channel! To join in use /cdg joinChat or /join "..self.db.global.custom_channel.name, "GUILD")
	end

	-- Welcome Message!
	local welcome_msg = "CDG is now in session! Mode: "..self.game.mode.label..", Bet: "..self.game.data.gold_amount.." gold"
	self:MessageChat(welcome_msg)
	if (self.game.mode.custom_intro ~= nil) then self:MessageChat(self.game.mode.custom_intro()) end
	self:MessageChat("Press 1 to Join!")

	-- TODO: Why is this BS different?
	if (self.chat.channel.const == "CHANNEL") then 
		self:MessageChat("Tell your friends to join the channel by /cdg join or /join "..self.db.global.custom_channel.name) 
	end
	
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
	if self.game.data.round == "losers" then 
		self:MessageChat("The Losers Bracket! Low Tiebreaker:")
		self:PrintTieBreakerPlayers(self.game.data.player_rolls)
	elseif self.game.data.round == "winners" then
		self:MessageChat("The Winners Bracket! High Tiebreaker:")
		self:PrintTieBreakerPlayers(self.game.data.player_rolls)
	elseif self.game.data.round == "initial" and not self.game.data.first_round then
		self:MessageChat("Tie! Reroll:")
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
	else
		self.game.data.first_round = false
		self:StartRolls()
	end
end


function CalmDownandGamble:EndGame()
	-- Tell  the clients and UI were done
	local end_args = self.game.data.winner.." "..self.game.data.loser.." "..self.game.data.cash_winnings
	self:MessageAddon("CDG_END_GAME", end_args)
	self.ui.CDG_Frame:SetStatusText(self.game.data.cash_winnings.."g  "..self.game.data.loser.." => "..self.game.data.winner)
	
	-- Clear the Roll Status UI
	self.ui.CDG_RollFrame:ReleaseChildren()
	self.ui.CDG_RollFrame:Release()
	self.ui.CDG_RollFrame = nil

	-- Reset Game Hooks and Data
	self:UnregisterChatEvents()
	self:ResetGameStage()
	self.previous_gameData = self:deepcopy(self.game.data)
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

	local winner, loser = nil, nil
	local winning_score, losing_score = nil, nil
	local high_score_playoff, low_score_playoff = {}, {}
	
	-- score all player rolls --
	local player_scores = {}
	for player, roll in self.game.data.player_rolls do
		player_scores[player] = self.game.mode.roll_to_score(roll)
	end
    -- Loop over the players scores and sort winners/losers
	for player, score in self:sortedpairs(player_scores, self.game.mode.sort_scores) do
		
		self:PrintDebug("    "..player.." "..score)
		
		-- First Entry -> Winner 
		if winner == nil then
			winning_score = score
			high_score_playoff[player] = -1
			winner = player
		
		-- Score == Winner -> Tiebreaker
		elseif (score == winning_score) then
			high_score_playoff[player] = -1
		
		-- Score != Winner -> First Loser
		elseif (losing_score == nil) then      
			losing_score = score
			low_score_playoff[player] = -1
			loser = player
			
		-- Score != Loser and Index != End -> New Loser
		elseif (score ~= losing_score) then   
			low_score_playoff = {}
			losing_score = score
			low_score_playoff[player] = -1
			loser = player
		
		-- Score == Loser -> Tiebreaker
		elseif (score == losing_score)  then  -- also the worst
			low_score_playoff[player] = -1
		else
		end
	end

	-- Determine Tiebreaker State
	local high_score_count = self:TableLength(high_score_playoff)
	local low_score_count = self:TableLength(low_score_playoff)
	local single_winner = (high_score_count == 1)
	local single_loser = (low_score_count == 1)

	-- Evaluate Round --

	local is_game_over = false

	-- Initial Round --
	if self.game.data.round == "initial" then

		-- Save original rolls for payouts
		self.game.data.winning_score = winning_score	
		self.game.data.losing_score = losing_score

		-- Winner and loser found. GG --
		if single_winner and single_loser then
			self.game.data.winner = winner
			self.game.data.loser = loser
			is_game_over = true

		-- Winner found, start losers round --
		elseif single_winner then
			self.game.data.winner = winner
			self.game.data.low_tiebreak = self:CopyTable(low_score_playoff)
			self.game.data.player_rolls = self.game.data.low_tiebreak
			self.game.data.round = "losers"
			if self.game.data.low_tiebreak_callback then
				self.game.data.low_tiebreak_callback(self.game)
			end

		-- Loser found, start winners round --
		elseif single_loser then
			self.game.data.loser = loser
			self.game.data.high_tiebreak = self:CopyTable(high_score_playoff)
			self.game.data.player_rolls = self.game.data.high_tiebreak
			self.game.data.round = "winners"
			if self.game.data.high_tiebreak_callback then
				self.game.data.high_tiebreak_callback(self.game)
			end

		-- Only low rolls, reroll --
		elseif high_score_count == 0 then
			self.game.data.low_tiebreak = self:CopyTable(low_score_playoff)
			self.game.data.player_rolls = self.game.data.low_tiebreak
			self.game.data.round = "initial"
			if self.game.data.only_losers_callback then
				self.game.data.only_losers_callback(self.game)
			end

		-- Only high rolls, reroll --
		elseif low_score_count == 0 then
			self.game.data.high_tiebreak = self:CopyTable(high_score_playoff)
			self.game.data.player_rolls = self.game.data.high_tiebreak
			self.game.data.round = "initial"
			if self.game.data.high_tiebreak_callback then
				self.game.data.high_tiebreak_callback(self.game)
			end

		-- Low roll ties and high roll ties, start with loser round --
		else
			self.game.data.high_tiebreak = self:CopyTable(high_score_playoff)
			self.game.data.low_tiebreak = self:CopyTable(low_score_playoff)
			self.game.data.player_rolls = self.game.data.low_tiebreak
			self.game.data.round = "losers"
			if self.game.data.low_tiebreak_callback then
				self.game.data.low_tiebreak_callback(self.game)
			end
		end

	-- Loser's Round --
	elseif self.game.data.round == "losers" then

		-- Loser found -- 
		if single_loser then
			self.game.data.loser = loser

			-- If winner also found, end game --
			if self.game.data.winner then
				is_game_over = true

			-- If no winner, start winners round --
			else
				self.game.data.player_rolls = self.game.data.high_tiebreak
				self.game.data.round = "winners"
				if self.game.data.high_tiebreak_callback then
					self.game.data.high_tiebreak_callback(self.game)
				end
			end

		-- No single loser found, roll again --
		else

			-- If there were no losers, play everyone again --
			if low_score_count == 0 then
				self.game.data.low_tiebreak = self:CopyTable(high_score_playoff)
				if self.game.data.low_tiebreak_callback then
					self.game.data.low_tiebreak_callback(self.game)
				end

			-- Only losers, reroll --
			elseif high_score_count == 0 then
				self.game.data.low_tiebreak = self:CopyTable(low_score_playoff)
				if self.game.data.only_losers_callback then
					self.game.data.only_losers_callback(self.game)
				end

			-- Many losers, play losers --
			else
				self.game.data.low_tiebreak = self:CopyTable(low_score_playoff)
				if self.game.data.low_tiebreak_callback then
					self.game.data.low_tiebreak_callback(self.game)
				end
			end
			self.game.data.player_rolls = self.game.data.low_tiebreak

		end

	-- Winner's Round --
	elseif self.game.data.round == "winners" then

		-- Winner found --
		if single_winner then
			self.game.data.winner = winner

			-- If loser also found, end game --
			if self.game.data.loser then
				is_game_over = true

			-- If no loser found, start losers round --
			else
				self.game.data.player_rolls = self.game.data.low_tiebreak
				self.game.data.round = "losers"
				if self.game.data.low_tiebreak_callback then
					self.game.data.low_tiebreak_callback(self.game)
				end
			end

		-- No winner found --
		else

			-- If high rollers exist --
			if high_score_count > 0 then
				self.game.data.high_tiebreak = self:CopyTable(high_score_playoff)
				self.game.data.player_rolls = self.game.data.high_tiebreak
				self.game.data.round = "winners"
				if self.game.data.high_tiebreak_callback then
					self.game.data.high_tiebreak_callback(self.game)
				end

			-- If only low rollers, reroll --
			elseif low_score_count > 0 then
				self.game.data.high_tiebreak = self:CopyTable(low_score_playoff)
				self.game.data.player_rolls = self.game.data.high_tiebreak
				self.game.data.round = "winners"
				if self.game.data.only_losers_callback then
					self.game.data.only_losers_callback(self.game)
				end

			-- Shouldn't be reached --
			else
				self:PrintDebug("Multiple winners else condition reached: high_score_count = "..high_score_count.." low_score_count = "..low_score_count)
			end
		end

	-- Shouldn't be reached --
	else
		self:PrintDebug("Unreachable Else: game.data.round not set properly")
	end
	return is_game_over	
end

-- ChatFrame Interaction Callbacks (Entry and Rolls)
-- ==================================================== 

function CalmDownandGamble:UpdateRollStatusUI()
	if ((self.ui ~= nil) and (self.game.data ~= nil)) then

		if (self.ui.CDG_RollFrame == nil) then

			-- Create the Rolling Frame and attach it to the casino frame
			-- *THIS IS STUPID DO IT IN XML TODODODODO*TODO -- 
			self.ui.CDG_RollFrame = AceGUI:Create("Frame")
			self.ui.CDG_RollFrame:SetWidth(200)
			self.ui.CDG_RollFrame:SetHeight(self.ui.CDG_Frame.frame:GetHeight() * 2)
			self.ui.CDG_RollFrame:ClearAllPoints()
			self.ui.CDG_RollFrame:SetPoint("BOTTOMLEFT", self.ui.CDG_Frame.frame, "BOTTOMRIGHT", 0, 0)
			self.ui.CDG_RollFrame:SetTitle("Roll Status")
			

			-- Boiler plat code for a container object
			self.ui.CDG_RollFrameScrollcontainer = AceGUI:Create("SimpleGroup") 
			self.ui.CDG_RollFrameScrollcontainer:SetFullWidth(true)
			self.ui.CDG_RollFrameScrollcontainer:SetHeight(self.ui.CDG_RollFrame.frame:GetHeight() - 75)
			self.ui.CDG_RollFrameScrollcontainer:SetLayout("Fill") 
			self.ui.CDG_RollFrame:AddChild(self.ui.CDG_RollFrameScrollcontainer)

			-- Attach a scrollbar to the container 
			self.ui.CDG_RollFrameScroll = AceGUI:Create("ScrollFrame")
			self.ui.CDG_RollFrameScroll:SetLayout("Flow") 
			self.ui.CDG_RollFrameScrollcontainer:AddChild(self.ui.CDG_RollFrameScroll)

		end

		-- Refresh the list of players and their rolls
		self.ui.CDG_RollFrameScroll:ReleaseChildren()	
		for player, roll in self:sortedpairs(self.game.data.player_rolls, self.game.mode.sort_rolls) do

			label = AceGUI:Create("Label")
			if (roll ~= tonumber(-1)) then 
				label:SetText(roll.." : "..player)
			else 
				label:SetText(" - : "..player)
			end
			label:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE, MONOCHROME")
			label:SetColor(255, 255, 0)
			self.ui.CDG_RollFrameScroll:AddChild(label)
		end
	
	end
end


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

			-- Update Game State Data 
			-- TODO: Only in NONGROUP channels if channel == "CDG_ROLL_DICE" then SendSystemMessage(roll_text) end
			self.game.data.player_rolls[player] = tonumber(roll)

			-- Update the UI and Check for the game end 
			self:UpdateRollStatusUI()			
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

-- NEEDS TO BE COMMON WITH CDGCLIENT! TODO!
function CalmDownandGamble:OpenTradeWinner()		
	if (self.game.data and self.game.data.winner) then
		if (TradeFrame:IsVisible()) then
			local copper = self.game.data.cash_winnings * 100 * 100 
			SetTradeMoney(copper)
			MoneyInputFrame_SetCopper(TradePlayerInputMoneyFrame, copper)
		else 
			InitiateTrade(self.game.data.winner)
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
	self.db.global.ui_frame = self:CopyTable(self.ui.CDG_Frame.status)
end

function CalmDownandGamble:ConstructUI()
	
	-- Settings to be used -- 
	local cdg_ui_elements = {
		-- Main Box Frame -- 
		main_frame = {
			width = 475,
			height = 130	
		},

		casino_subframe = {
			width = 475,
			height = 72	
		},
		
		-- Order in which the buttons are layed out in the Casino Subgroup
		casino_button_index = {
			"game_stage",
			"game_mode",
			"chat_channel",
			"reset_game"
		},

		-- Order in which the buttons are layed out In the play subgroup
		play_button_index = {
			"enter_for_me",
			"roll_for_me", 
			"open_trade"
		},
		
		-- Button Definitions -- 
		buttons = {
			chat_channel = {
				width = 80,
				label = "Raid",
				click_callback = function() self:ChatChannelToggle() end
			},
			game_mode = {
				width = 80,
				label = "(Classic)",
				click_callback = function() self:ToggleGameMode() end
			},
			reset_game = {
				width = 80,
				label = "Reset",
				click_callback = function() self:ResetGame() end
			},
			game_stage = {
				width = 95,
				label = "Start!",
				click_callback = function() self:ToggleGameStage() end

			},
			enter_for_me = {
				width = 100,
				label = "Enter",
				click_callback = function() self:EnterForMe() end
			},			
			roll_for_me = {
				width = 100,
				label = "Roll!",
				click_callback = function() self:RollForMe() end
			},
			-- TODO : Make this common with CDGClient
			open_trade = {
				width = 100,
				label = "Payout",
				click_callback = function() self:OpenTradeWinner() end
			}
		}
	};
	
	-- ui - represents the Top level of the storage hierarchy for the UI
	self.ui = {}
	
	-- CDG_Frame - Represents the window frame of the addon
	self.ui.CDG_Frame = AceGUI:Create("Frame")
	self.ui.CDG_Frame:SetTitle("Calm Down Gambling")
	self.ui.CDG_Frame:SetStatusText("")
	self.ui.CDG_Frame:SetLayout("Flow")
	self.ui.CDG_Frame:SetStatusTable(cdg_ui_elements.main_frame)
	self.ui.CDG_Frame:EnableResize(false)
	self.ui.CDG_Frame:SetCallback("OnClose", function() self:HideUI() end)
	self.ui.CDG_Frame.frame:EnableMouse(true)
	self.ui.CDG_Frame.frame:SetUserPlaced(true)

	-- Mouse callbacks 
	on_mouse_down = function(w, button) 
		if (button == "RightButton") then 
			self:ToggleCasino() 
		end 
	end
	self.ui.CDG_Frame.frame:SetScript("OnMouseDown", on_mouse_down)
	
	-- CDG_PlayerFrame - groups the player  Controls
	-- =====================================================
	-- TODO : Switch the UI code into XML, because this is stupid
	-- Pad the top layer of buttons to be centered 
	padding = AceGUI:Create("Button")
	padding:SetWidth(70) -- Duno why, looked the best
	padding.frame:SetAlpha(0)
	self.ui.CDG_Frame:AddChild(padding)

	-- play_button_index - Controls for playing
	for _, button_name in pairs(cdg_ui_elements.play_button_index) do
		local button_settings = cdg_ui_elements.buttons[button_name]
	
		self.ui[button_name] = AceGUI:Create("Button")
		self.ui[button_name]:SetText(button_settings.label)
		self.ui[button_name]:SetWidth(button_settings.width)
		self.ui[button_name]:SetCallback("OnClick", button_settings.click_callback)
		
		self.ui.CDG_Frame:AddChild(self.ui[button_name])
	end
	
	-- CDG_CasinoFrame - Groups the casino controls
	-- ====================================================
	self.ui.CDG_CasinoFrame = AceGUI:Create("SimpleGroup")
	self.ui.CDG_CasinoFrame:SetLayout("Flow")
	self.ui.CDG_CasinoFrame.frame:SetWidth(cdg_ui_elements.main_frame.width)

	-- gold_amount_entry - Text box for gold entry
	self.ui.gold_amount_entry = AceGUI:Create("EditBox")
	self.ui.gold_amount_entry:SetWidth(95)
	self.ui.CDG_CasinoFrame:AddChild(self.ui.gold_amount_entry)
	
	-- casino_button_index - Buttons to run the game
	for _, button_name in pairs(cdg_ui_elements.casino_button_index) do
		local button_settings = cdg_ui_elements.buttons[button_name]
	
		self.ui[button_name] = AceGUI:Create("Button")
		self.ui[button_name]:SetText(button_settings.label)
		self.ui[button_name]:SetWidth(button_settings.width)
		self.ui[button_name]:SetCallback("OnClick", button_settings.click_callback)
		
		self.ui.CDG_CasinoFrame:AddChild(self.ui[button_name])
	end
	self.ui.CDG_Frame:AddChild(self.ui.CDG_CasinoFrame)


	
	if (self.db.global.ui_frame ~= nil) then
		self.ui.CDG_Frame:SetStatusTable(self.db.global.ui_frame)
	end
	
	if not self.db.global.window_shown then
		self.ui.CDG_Frame:Hide()
	end
	
	-- Register for UI Events
	self:RegisterEvent("PLAYER_LEAVING_WORLD", function(...) self:SaveFrameState(...) end)
end