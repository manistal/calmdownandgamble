
SendSystemMessage("LOADING CDGHILO")

CDG_HILO = {
	-- String for game name
	label = "HiLo",
	
	init_game = function(game)
		game.data.roll_lower = 1
		game.data.roll_upper = game.data.gold_amount
		game.data.roll_range = "(1-"..game.data.gold_amount..")"
	end,
	
	sort_scores = function(scores, playera, playerb) 
		-- Sort from Highest to Lowest
		return scores[playerb] < scores[playera]
	end,
	
	payout = function(game)
		game.data.cash_winnings = game.data.winning_roll - self.game.data.losing_roll
	end,
}

-- GAME MODE INITS 
-- =========================


-- Yahtzee Init -- Yahtzee is different because fun. 
function CalmDownandGamble:YahtzeeInit() 
	self:SetGoldAmount()
	self.game.data.roll_range = "(11111-99999)"
	self.game.data.roll_upper = 99999
	self.game.data.roll_lower = 11111
end

-- Twos Init -- Yahtzee is different because fun. 
function CalmDownandGamble:TwosInit() 
	self:SetGoldAmount()
	self.game.data.roll_range = "(1-2)"
	self.game.data.roll_upper = 2
	self.game.data.roll_lower = 1
end


-- Game mode: Twos
-- =================================================
function CalmDownandGamble:Twos()
	if (CalmDownandGamble:EvaluateScores()) then
		self.game.data.cash_winnings = self.game.data.gold_amount
		self:MessageChat(self.game.data.loser.." owes "..self.game.data.winner.." "..self.game.data.cash_winnings.." gold!")
	
		-- Log Results -- All game modes must call these two explicitly
		self:LogResults()
		self:EndGame()
	end
end


-- Game mode: Inverse
-- =================================================
function CalmDownandGamble:Inverse()
	if (CalmDownandGamble:EvaluateScores()) then
		
		self.game.data.cash_winnings = self.game.data.winning_roll - self.game.data.losing_roll
		self.game.data.winner, self.game.data.loser = self.game.data.loser, self.game.data.winner
		self:MessageChat(self.game.data.loser.." owes "..self.game.data.winner.." "..self.game.data.cash_winnings.." gold!")
	
		-- Log Results -- All game modes must call these two explicitly
		self:LogResults()
		self:EndGame()
	end
end


-- Game mode: Yahtzee
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
		if CDG_DEBUG then self:Print(digit.." #"..count) end
		score = score + (count * digit)
    end
	
	return score
end

function CalmDownandGamble:Yahtzee()

	local player_scores = {}
	for player, roll in pairs(self.game.data.player_rolls) do
		local score = self:ScoreYahtzee(roll)
		player_scores[player] = score
	end
	
	local sort_by_score = function(t,a,b) return t[b] < t[a] end
	for player, score in self:sortedpairs(player_scores, sort_by_score) do
		self:MessageChat(player.." Roll: "..format_yahtzee_roll(self.game.data.player_rolls[player]).." Score: "..score)
	end

	self.game.data.player_rolls = {}
	self.game.data.player_rolls = self:CopyTable(player_scores)
	
	if (self:EvaluateScores()) then 
		self.game.data.cash_winnings = self.game.data.gold_amount
		self:MessageChat(self.game.data.loser.." owes "..self.game.data.winner.." "..self.game.data.cash_winnings.." gold!")
	
		-- Log Results -- All game modes must call these two explicitly
		self:LogResults()
		self:EndGame()
	end
	
end

-- Game mode: MiddleMan
-- =================================================
function CalmDownandGamble:Median()
	
	local sort_by_score = function(t,a,b) return t[b] < t[a] end
	local high_player, median_player, low_player = "", "", ""
	local high_score, median_score, low_score = 0, 0, 0
	
	local total_players = self:TableLength(self.game.data.player_rolls)
	local last_number = total_players
	local median_number = math.floor((total_players + 1) / 2)

	local player_index = 1
	for player, roll in self:sortedpairs(self.game.data.player_rolls, sort_by_score) do
		if CDG_DEBUG then self:Print(player.." "..roll) end
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

	if median_player == "" then
		self:MessageChat("You need at least 3 players!!")
		median_player = high_player
	end
	self.game.data.winner = median_player
	

	self.game.data.loser = high_player
	self.game.data.cash_winnings = math.abs(median_score - high_score)
	self:MessageChat(self.game.data.loser.." owes "..self.game.data.winner.." "..self.game.data.cash_winnings.." gold!")
	self:LogResults()
	
	self.game.data.loser = low_player
	self.game.data.cash_winnings = math.abs(median_score - low_score)
	self:MessageChat(self.game.data.loser.." owes "..self.game.data.winner.." "..self.game.data.cash_winnings.." gold!")
	self:LogResults()
	
	self:EndGame()
end
