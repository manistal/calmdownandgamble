
-- High/Low 
-- ==================
CDG_HILO = {
	-- String for game name
	label = "HiLo",
	
	init_game = function(game)
		game.data.roll_lower = 1
		game.data.roll_upper = game.data.gold_amount
		game.data.roll_range = "(1-"..game.data.gold_amount..")"
	end,

	sort_rolls = function(rolls)
		high_to_low = function(scores, playera, playerb) return scores[playerb] < scores[playera] end
		return CalmDownandGamble:sortedpairs(rolls, high_to_low)
	end,
	
	payout = function(game)
		game.data.cash_winnings = game.data.winning_roll - game.data.losing_roll
	end,
}

-- BigTwos 
-- ==============
CDG_BIGTWOS = {
	label = "BigTwos",
	
	init_game = function(game)
		game.data.roll_lower = 1
		game.data.roll_upper = 2
		game.data.roll_range = "(1-2)"
	end,
	
	sort_rolls = function(rolls)
		high_to_low = function(scores, playera, playerb) return scores[playerb] < scores[playera] end
		return CalmDownandGamble:sortedpairs(rolls, high_to_low)
	end,
	
	payout = function(game)
		game.data.cash_winnings = game.data.gold_amount
	end,

}

-- Inverse
-- ===========
CDG_INVERSE = {
	label = "Inverse",
	
	init_game = function(game)
		game.data.roll_lower = 1
		game.data.roll_upper = game.data.gold_amount
		game.data.roll_range = "(1-"..game.data.gold_amount..")"
	end,
	
	sort_rolls = function(rolls)
		low_to_high = function(scores, playera, playerb) return scores[playerb] > scores[playera] end
		return CalmDownandGamble:sortedpairs(rolls, low_to_high)
	end,
	
	payout = function(game)
		game.data.cash_winnings = game.data.losing_roll - game.data.winning_roll
	end,

}

-- Russian Roullette
-- ===================
CDG_ROULETTE= {
	label = "Roullette",
	
	init_game = function(game)
		game.data.roll_lower = 1
		game.data.roll_upper = 6
		game.data.roll_range = "(1-6)"
	end,
	
	sort_rolls = function(rolls)
		high_to_low = function(scores, playera, playerb) return scores[playerb] < scores[playera] end
		
		-- Adjust the scores for roulette, you roll 1 you lose. 
		for player, roll in CalmDownandGamble:sortedpairs(rolls, high_to_low) do
			if (tonumber(roll) == 1) then
				rolls[player] = 0 -- They LOSE
			else
				rolls[player] = 1
			end
		end
		
		return CalmDownandGamble:sortedpairs(rolls, high_to_low)
	end,
	
	payout = function(game)
		game.data.cash_winnings = game.data.gold_amount
	end,

}


-- Yahtzee
-- ============
local function ScoreYahtzee(roll)
	-- Get the total of this dice, common score
	total = 0
	for digit in string.gmatch(roll, "%d") do
		total = total + digit
	end
	
	hand, score, highroll = "", 0, 0
	
	-- Evaluate best possible hand
	for digit in string.gmatch(roll, "%d") do
	
		-- If you hit these your other numbers wont be better
		local _, count = string.gsub(roll, digit, "")
		if (count == 5) then
			return "YAHTZEE!", 50
		end
		
		if (count == 4) then
			return "Four of a Kind!", total
		end
		
		if (count == 3) then
			-- Check for Full House
			for digit in string.gmatch(roll, "%d") do
				local _, other_count = string.gsub(roll, digit, "")
				if (other_count == 2) then
					return "Full House!", 25
				end
			end
			
			return "Three of a Kind!", total
		end
		
		
		-- Doubles, could get better
		if (count == 2) then
			-- Check for full house
			for digit in string.gmatch(roll, "%d") do
				local _, other_count = string.gsub(roll, digit, "")
				if (other_count == 2) then
					return "Full House!", 25
				end
			end
			
			hand, score = "Doubles!",  digit*2
		end
		
		-- Singles UGH
		if (count == 1) then
			if (digit > highroll) then
				highroll = digit
			end
		end
		
	end	
	
	-- Singles Bummer
	if (score == 0) then
		hand, score = "OUCH - Single Roll", highroll
	end

	return hand, score
end

local function FormatYahtzee(roll)
	local ret_string = ""
	for digit in string.gmatch(roll, "%d") do
		ret_string = ret_string..digit.."-"
    end
	ret_string = ret_string.."!!"
	return string.gsub(ret_string, "-!!", "")
end


CDG_YAHTZEE = {
	label = "Yahtzee",
	
	init_game = function(game)
		game.data.roll_range = "(11111-99999)"
		game.data.roll_upper = 99999
		game.data.roll_lower = 11111
	end,
	
	sort_rolls = function(scores, playera, playerb) 
		local _, scoreA = ScoreYahtzee(scores[playera])
		local _, scoreB = ScoreYahtzee(scores[playerb])
		-- Sort from Highest to Lowest
		return scoreB < scoreA
	end,
	
	sort_rolls = function(rolls)
		yahtzee_high_to_low = function(scores, playera, playerb) 
			local _, scoreA = ScoreYahtzee(scores[playera])
			local _, scoreB = ScoreYahtzee(scores[playerb])
			-- Sort from Highest to Lowest
			return scoreB < scoreA
		end
		
		return CalmDownandGamble:sortedpairs(rolls, yahtzee_high_to_low)
	end,
	
	
	payout = function(game)
		for player, roll in CalmDownandGamble:sortedpairs(player_scores, game.mode.sort_rolls) do
			local hand, score = ScoreYahtzee(roll)
			CalmDownandGamble:MessageChat(player.." Roll: "..FormatYahtzee(roll).." Score: "..score.." "..hand)
		end
		game.data.cash_winnings = game.data.gold_amount
	end,

}
