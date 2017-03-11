
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
