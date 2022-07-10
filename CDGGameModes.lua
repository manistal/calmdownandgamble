-- Consts for Sorting, shortcuts for common cases
CDG_SORT_DESCENDING = function(scores, playera, playerb) return scores[playerb] < scores[playera] end
CDG_SORT_ASCENDING  = function(scores, playera, playerb) return scores[playerb] > scores[playera] end
local CDG_MAX_ROLL = function(roll) return (tonumber(roll) > 1000000) and 1000000 or tonumber(roll) end

-- High/Low 
-- ==================
CDG_HILO = {
	-- String for game name
	label = "HiLo",
	
	init_game = function(game)
		game.data.roll_lower = 1
		game.data.roll_upper = CDG_MAX_ROLL(game.data.gold_amount)
		game.data.roll_range = "(1-"..game.data.roll_upper..")"
	end,
	
	roll_to_score = function(roll)
		return tonumber(roll)
	end,

	sort_rolls = CDG_SORT_DESCENDING,

	sort_scores = CDG_SORT_DESCENDING,

	print_help = function()
		CalmDownandGamble:MessageChat("HiLo: Roll from 1 to bet amount. Highest roll wins. Lowest roll loses. Payout is roll difference between winner and loser.")
	end,
	
	payout = function(game)
		game.data.cash_winnings = game.data.winning_score - game.data.losing_score
	end
}

-- BigTwos 
-- ==============
CDG_BIGTWOS = {
	label = "Big2s",
	
	init_game = function(game)
		game.data.roll_lower = 1
		game.data.roll_upper = 2
		game.data.roll_range = "(1-2)"
	end,
	
	roll_to_score = function(roll)
		return tonumber(roll)
	end,
	
	sort_rolls = CDG_SORT_DESCENDING,

	sort_scores = CDG_SORT_DESCENDING,

	print_help = function()
		CalmDownandGamble:MessageChat("Big2s: Roll from 1 to 2. A 2 roll wins. A 1 roll loses. Payout is the bet amount.")
	end,
	
	payout = function(game)
		game.data.cash_winnings = game.data.gold_amount
	end
}

-- LILONES
-- ==============
CDG_LILONES = {
	label = "LilOnes",
	
	init_game = function(game)
		game.data.roll_lower = 1
		game.data.roll_upper = 2
		game.data.roll_range = "(1-2)"
	end,
	
	roll_to_score = function(roll)
		return tonumber(roll)
	end,
	
	sort_rolls = CDG_SORT_ASCENDING,

	sort_scores = CDG_SORT_ASCENDING,

	print_help = function()
		CalmDownandGamble:MessageChat("LilOnes: Roll from 1 to 2. A 1 roll wins. A 2 roll loses. Payout is the bet amount")
	end,
	
	payout = function(game)
		game.data.cash_winnings = game.data.gold_amount
	end
}

-- Inverse
-- ===========
CDG_INVERSE = {
	label = "Inverse",
	
	init_game = function(game)
		game.data.roll_lower = 1
		game.data.roll_upper = CDG_MAX_ROLL(game.data.gold_amount)
		game.data.roll_range = "(1-"..game.data.roll_upper..")"
	end,
	
	roll_to_score = function(roll)
		return tonumber(roll)
	end,
	
	sort_rolls = CDG_SORT_ASCENDING,

	sort_scores = CDG_SORT_ASCENDING,

	print_help = function()
		CalmDownandGamble:MessageChat("Inverse: Roll from 1 to bet amount. Lowest roll wins. Highest roll loses. Payout is roll difference between winner and loser.")
	end,
	
	payout = function(game)
		game.data.cash_winnings = game.data.losing_score - game.data.winning_score
	end
}

-- Russian Roullette
-- ===================
CDG_ROULETTE = {
	label = "Russian Roulette",

	init_game = function(game)
		game.data.roll_lower = 1
		game.data.roll_upper = 6
		game.data.roll_range = "(1-6)"
		game.data.w_bullets = 6
		game.data.l_bullets = 6
	end,
	
	roll_to_score = function(roll)
		if roll == 1 then
			return 0 -- They LOSE
		else
			return 1
		end
	end,
	
	sort_rolls = CDG_SORT_DESCENDING,

	sort_scores = CDG_SORT_DESCENDING,

	print_help = function()
		CalmDownandGamble:MessageChat("Russian Roulette: Roll from 1 to 6. Roll a 1 and you die. Last player alive wins. Your roll range changes to match your remaining chambers. Reload when there's only one chamber left or when you shoot yourself. Payout is the bet amount.")
	end,
	
	payout = function(game)
		game.data.cash_winnings = game.data.gold_amount
	end,

	round_resolved_callback = function(game, current_round, current_rollers, next_round, next_rollers)

		-- Count the shot just made --
		-- Decrease w bullets on initial and winners rounds --
		if current_round == "initial" or current_round == "winners" then
			game.data.w_bullets = game.data.w_bullets - 1
		-- Decrease l bullets on losers round --
		elseif current_round == "loser" then
			game.data.l_bullets = game.data.l_bullets - 1
		-- Game over, do nothing --
		else
		end

		-- Set roll range for next round --
		if next_round == "initial" or next_round == "winners" then
			-- No empty chamber condition on initial or winners rounds--
			if game.data.w_bullets < 2 then
				game.data.w_bullets = 2
			end
			game.data.roll_upper = game.data.w_bullets
		elseif next_round == "losers" then
			-- No empty chamber condition on losers rounds--
			if game.data.l_bullets < 2 then
				game.data.l_bullets = 2
			end
			game.data.roll_upper = game.data.l_bulletss
		-- Game over, do nothing --
		else
		end

		game.data.roll_range = "("..game.data.roll_lower.."-"..game.data.roll_upper..")"
	end
}

-- Yahtzee
-- ============
CDG_YAHTZEE = {
	label = "Yahtzee",
	
	init_game = function(game)
		game.data.roll_range = "(1-7776)"
		game.data.roll_upper = 7776
		game.data.roll_lower = 1
	end,
	
	roll_to_score = function(roll)
		local hand, score, dice_rolls = YZ_ScoreYahtzee(roll)
		return score
	end,
	
	sort_rolls = CDG_SORT_DESCENDING,

	sort_scores = CDG_SORT_DESCENDING,

	print_help = function()
		CalmDownandGamble:MessageChat("Yahtzee: Roll from 1 to 7776. This roll is translated into five 6-sided dice (7776 possible combinations). Yahtzee scores are applied and take your rolls highest score. Highest score wins. Lowest score loses. Payout is the bet amount.")
	end,
	
	payout = function(game)
		CalmDownandGamble:MessageChat("== Game Over! ==")
		for player, score in CalmDownandGamble:sortedpairs(game.data.all_player_scores, game.mode.sort_scores) do
			local hand, score, dice_rolls = YZ_ScoreYahtzee(game.data.all_player_rolls[player])
			CalmDownandGamble:MessageChat(player.." Dice: "..YZ_FormatDiceRolls(dice_rolls).." Score: "..score.." - "..hand)
		end
		CalmDownandGamble:MessageChat("===============")
		game.data.cash_winnings = game.data.gold_amount
	end,

	roll_accepted_callback = function(game, player, roll)
		local dice_rolls = YZ_CollectDiceRolls(roll)
		local text = player.." rolled "..YZ_FormatDiceRolls(dice_rolls)
		CalmDownandGamble:MessageChat(text)
	end
}

-- Curling
-- ==========
CDG_CURLING = {
	label = "Curling",
	target_roll = 0,
	
	init_game = function(game)
		game.data.roll_lower = 1
		game.data.roll_upper = CDG_MAX_ROLL(game.data.gold_amount) 
		game.data.roll_range = "(1-"..game.data.roll_upper..")"
		game.target_roll = math.random(game.data.roll_upper)
		CDG_CURLING.game = game
	end,

	custom_intro = function()
		return "Roll from 1-"..CDG_CURLING.game.data.gold_amount.." to try and hit "..CDG_CURLING.game.target_roll.."!"
	end,
			
	roll_to_score = function(roll)
		return math.abs(CDG_CURLING.game.target_roll - tonumber(roll))
	end,
	
	sort_rolls =  CDG_SORT_DESCENDING,

	sort_scores = CDG_SORT_ASCENDING,

	print_help = function()
		CalmDownandGamble:MessageChat("Curling: A random target between 1 and bet amount is found. Roll 1 to bet amount. The closest to the target wins. Furthest from the target loses. Payout is loser's distance to target.")
	end,
	
	payout = function(game)
		game.data.cash_winnings = math.abs(CDG_CURLING.game.target_roll - game.data.losing_roll)
		CalmDownandGamble:MessageChat("Bullseye for Curling was: "..CDG_CURLING.game.target_roll) 
		CalmDownandGamble:MessageChat(game.data.winner.." was closest with a "..game.data.winning_roll)
		CalmDownandGamble:MessageChat(game.data.loser.." was furthest away with a "..game.data.losing_roll)
	end
}

local function GenerateLandmines(game)
	local mines = {}
	local i = 1
	while i <= game.data.roll_upper do
		mines[i] = false
		i = i + 1
	end
	i = CDG_LANDMINES.num_mines
	while i > 0 do
		local roll = math.random(game.data.roll_lower, game.data.roll_upper)
		if not mines[roll] then
			mines[roll] = true
			i = i - 1
		end
	end
	return mines
end

CDG_LANDMINES = {
	label = "Landmines",
	
	init_game = function(game)
		game.data.roll_lower = 1
		game.data.roll_upper = CDG_MAX_ROLL(game.data.gold_amount)
		game.data.roll_range = "(1-"..game.data.roll_upper..")"
		CDG_LANDMINES.num_mines = math.floor(0.5 * game.data.roll_upper + 0.5)
		CDG_LANDMINES.landmines = GenerateLandmines(game)
	end,

	custom_intro = function()
		return "Planting "..CDG_LANDMINES.num_mines.." mines..."
	end,
			
	roll_to_score = function(roll)
		if CDG_LANDMINES.landmines[roll] then
			return 0
		else
			return 1
		end
	end,
	
	sort_rolls =  CDG_SORT_DESCENDING,

	sort_scores = CDG_SORT_DESCENDING,

	print_help = function()
		CalmDownandGamble:MessageChat("Landmines: Roll from 1 to bet amount. 50% of rolls are landmines. Roll a landmine and you lose. Last survivor wins. Payout is bet amount.")
	end,
	
	payout = function(game)
		game.data.cash_winnings = game.data.gold_amount
	end,

	roll_accepted_callback = function(game, player, roll)
		if CDG_LANDMINES.landmines[roll] then
			CalmDownandGamble:MessageChat("BOOM! "..player.." exploded.")
		end
	end
}

CDG_CALVINBALL = {
	label = "Calvinball",
	inverse = false,
	boomerang_active = false,
			
	roll_to_score = function(roll, player, game)
		CB_SetScoringRules()
		return CB_ApplyScoringRules(roll, player, game)
	end,
	
	sort_rolls = CDG_SORT_DESCENDING,

	sort_scores = function(scores, playera, playerb)
		return CB_ApplySortingRule(scores, playera, playerb)
	end,
	
	print_help = function()
		CalmDownandGamble:MessageChat("Other kids' games are all such a bore! They've gotta have rules and they gotta keep score! Calvinball is better by far! It's never the same! It's always bizarre! You don't need a team or a referee! You know that it's great. 'cause it's named after me!")
	end,
	
	payout = function(game)
		CB_SetPayoutRule()
		local winnings, text = CB_ApplyPayoutRule(game)
		game.data.cash_winnings = winnings
		if text then
			game.data.additional_win_text = " "..text
		end
	end,

	round_start_callback = function(game)
		CB_HandleHogwartsHouses(game)
	end,

	roll_accepted_callback = function(game, player, roll)
	end,

	round_resolved_callback = function(game, current_round, current_rollers, next_round, next_rollers)
		CB_SetSortingRule(game)
	end,
	
	init_game = function(game)
		CB_Reset()
		game.data.roll_lower = 1
		game.data.roll_upper = CDG_MAX_ROLL(game.data.gold_amount)
		game.data.roll_range = "("..game.data.roll_lower.."-"..game.data.roll_upper..")"
	end
}