
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
	
	sort_rolls = function(scores, playera, playerb) 
		-- Sort from Highest to Lowest
		return scores[playerb] < scores[playera]
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
	
	sort_rolls = function(scores, playera, playerb) 
		-- Sort from Highest to Lowest
		return scores[playerb] < scores[playera]
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
	
	sort_rolls = function(scores, playera, playerb) 
		-- Sort from Lowest to Highest
		return scores[playerb] < scores[playera]
	end,
	
	payout = function(game)
		game.data.cash_winnings = game.data.losing_roll - game.data.winning_roll
	end,

}

-- Yahtzee
-- ============
local function ScoreYahtzee(roll)

	local score = 0
	for digit in string.gmatch(roll, "%d") do
		local _, count = string.gsub(roll, digit, "")
		score = score + (count * digit)
    end
	
	return score
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
		-- Sort from Highest to Lowest
		return ScoreYahtzee(scores[playerb]) < ScoreYahtzee(scores[playera])
	end,
	
	payout = function(game)
		for player, roll in CalmDownandGamble:sortedpairs(player_scores, game.mode.sort_rolls) do
			CalmDownandGamble:MessageChat(player.." Roll: "..FormatYahtzee(roll).." Score: "..ScoreYahtzee(roll))
		end
		game.data.cash_winnings = game.data.gold_amount
	end,

}
