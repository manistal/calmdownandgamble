
-- Consts for Sorting, shortcuts for common cases
local CDG_SORT_DESCENDING = function(scores, playera, playerb) return scores[playerb] < scores[playera] end
local CDG_SORT_ASCENDING  = function(scores, playera, playerb) return scores[playerb] > scores[playera] end
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
	
	fmt_score = function(roll) return roll end,

	sort_rolls = CDG_SORT_DESCENDING,

	sort_scores = CDG_SORT_DESCENDING,
	
	payout = function(game)
		game.data.cash_winnings = game.data.winning_score - game.data.losing_score
	end
}

-- Mystery
-- ==============
CDG_MYSTERY = {
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
	
	fmt_score = function(roll) return roll end,

	sort_rolls = CDG_SORT_DESCENDING,

	sort_scores = CDG_SORT_DESCENDING,
	
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
	
	fmt_score = function(roll) return roll end,
	
	sort_rolls = CDG_SORT_DESCENDING,

	sort_scores = CDG_SORT_DESCENDING,
	
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
	
	fmt_score = function(roll) return roll end,
	
	sort_rolls = CDG_SORT_ASCENDING,

	sort_scores = CDG_SORT_ASCENDING,
	
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
	
	fmt_score = function(roll) return roll end,
	
	sort_rolls = CDG_SORT_ASCENDING,

	sort_scores = CDG_SORT_ASCENDING,
	
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
		game.data.low_tiebreak_callback = function(game)
			game.data.l_bullets = game.data.l_bullets - 1
			if game.data.l_bullets < 2 then
				CalmDownandGamble:MessageChat("Reload!") 
				game.data.l_bullets = 6
			end
			game.data.roll_upper = game.data.l_bullets
			game.data.roll_range = "("..game.data.roll_lower.."-"..game.data.roll_upper..")"
		end
		game.data.high_tiebreak_callback = function(game)
			game.data.w_bullets = game.data.w_bullets - 1
			if game.data.w_bullets < 2 then
				CalmDownandGamble:MessageChat("Reload!") 
				game.data.w_bullets = 6
			end
			game.data.roll_upper = game.data.w_bullets
			game.data.roll_range = "("..game.data.roll_lower.."-"..game.data.roll_upper..")"
		end
		game.data.high_tie_callback = function(game)
			if game.data.round == "winners" then
				game.data.w_bullets = game.data.w_bullets - 1
				if game.data.w_bullets < 2 then
					CalmDownandGamble:MessageChat("Reload!") 
					game.data.w_bullets = 6
				end
				game.data.roll_upper = game.data.w_bullets
			elseif game.data.round == "losers" then
				game.data.l_bullets = game.data.l_bullets - 1
				if game.data.l_bullets < 2 then
					CalmDownandGamble:MessageChat("Reload!") 
					game.data.l_bullets = 6
				end
				game.data.roll_upper = game.data.l_bullets
			else -- Initial round --
				game.data.w_bullets = game.data.w_bullets - 1
				game.data.l_bullets = game.data.l_bullets - 1
				if game.data.w_bullets < 2 or game.data.l_bullets < 2 then
					CalmDownandGamble:MessageChat("Reload!") 
					game.data.w_bullets = 6
					game.data.l_bullets = 6
				end
				game.data.roll_upper = game.data.w_bullets
			end
			game.data.roll_range = "("..game.data.roll_lower.."-"..game.data.roll_upper..")"
		end
		game.data.low_tie_callback = function(game)
			CalmDownandGamble:MessageChat("You all shot yourself... Reload!") 
			if game.data.round == "winners" then
				game.data.w_bullets = 6
				game.data.roll_upper = game.data.w_bullets
			elseif game.data.round == "losers" then
				game.data.l_bullets = 6
				game.data.roll_upper = game.data.l_bullets
			else -- Initial round --
				game.data.w_bullets = 6
				game.data.l_bullets = 6
				game.data.roll_upper = 6
			end
			game.data.roll_range = "("..game.data.roll_lower.."-"..game.data.roll_upper..")"
		end
	end,
	
	roll_to_score = function(roll)
		if tonumber(roll) == 1 then
			return 0 -- They LOSE
		else
			return 1
		end
	end,
	
	fmt_score = function(roll) return roll end,
	
	sort_rolls = CDG_SORT_DESCENDING,

	sort_scores = CDG_SORT_DESCENDING,

	custom_intro = function()
		return "Roll 1 and you're dead. Last player alive wins. First player dead loses."
	end,
	
	payout = function(game)
		game.data.cash_winnings = game.data.gold_amount
	end
}

-- Yahtzee
-- ============
local function ScoreYahtzee(roll)
	-- Get the total of this dice, common score
	total = 0
	for digit in string.gmatch(roll, "%d") do
		if (tonumber(digit) == 0) then
			total = total + 1 -- Adjust for 0
		else
			total = total + tonumber(digit)
		end
	end
	
	hand, score, highroll = "", 0, 0
	
	-- Evaluate best possible hand
	for digit in string.gmatch(roll, "%d") do
	
		-- If you hit these your other numbers wont be better
		local _, count = string.gsub(roll, digit, "")
		if (count == 5) then
			return "YAHTZEE!", 100 + total
		end
		
		if (count == 4) then
			return "Four of a Kind!", 80
		end
		
		if (count == 3) then
			-- Check for Full House
			for digit in string.gmatch(roll, "%d") do
				local _, other_count = string.gsub(roll, digit, "")
				if (other_count == 2) then
					return "Full House!", 75
				end
			end
			
			return "Three of a Kind!", 30
		end
		
		
		-- Doubles, could get better
		if (count == 2) then
			-- Check for full house
			for digit in string.gmatch(roll, "%d") do
				local _, other_count = string.gsub(roll, digit, "")
				if (other_count == 3) then
					return "Full House!", 75
				end
			end
			
			-- Doubles are the dice added together, 0->1 
			new_score = tonumber(digit)*2 
			if (tonumber(digit) == 0) then
				new_score = 2 + total
			end
			
			-- Evaluate the best doubles
			if (new_score > score) then
				score = new_score 
				hand = "Double "..digit.."s!"
			end
		end
		
		-- Singles UGH
		if (count == 1) then
			if (tonumber(digit) > highroll) then
				highroll = tonumber(digit)
			end
		end
		
	end	
	
	-- Singles Bummer
	if (score == 0) then
		score = highroll
		hand = "Singles, "..highroll.." High"
		if (highroll == 0) then
			score = 1
		end
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
	
	roll_to_score = function(roll)
		hand, score = ScoreYahtzee(roll)
		return score
	end,
	
	fmt_score = function(roll)
		hand, score = ScoreYahtzee(roll)
		return " "..score.." - "..hand
	end,
	
	sort_rolls =  function(scores, playera, playerb) 
		local _, scoreA = ScoreYahtzee(scores[playera])
		local _, scoreB = ScoreYahtzee(scores[playerb])
		-- Sort from Highest to Lowest
		return scoreB < scoreA
	end,

	sort_scores = CDG_SORT_DESCENDING,
	
	payout = function(game)
		for player, roll in CalmDownandGamble:sortedpairs(game.data.player_rolls, game.mode.sort_rolls) do
			local hand, score = ScoreYahtzee(roll)
			CalmDownandGamble:MessageChat(player.." Roll: "..FormatYahtzee(roll).." Score: "..score.." - "..hand)
		end
		game.data.cash_winnings = game.data.gold_amount
	end
}

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
	
	fmt_score = function(roll) return roll end,
	
	sort_rolls =  function(scores, playera, playerb) 
		local scoreA = CDG_CURLING.roll_to_score(scores[playera])
		local scoreB = CDG_CURLING.roll_to_score(scores[playerb])
		-- Sort from Highest to Lowest
		return scoreB > scoreA
	end,

	sort_scores = CDG_SORT_ASCENDING,
	
	payout = function(game)
		winning_roll = game.data.player_rolls[game.data.winner]
		losing_roll = game.data.player_rolls[game.data.loser]
		game.data.cash_winnings = math.abs(CDG_CURLING.game.target_roll - losing_roll)
		CalmDownandGamble:MessageChat("Bullseye for Curling was: "..CDG_CURLING.game.target_roll) 
		CalmDownandGamble:MessageChat(game.data.winner.." was closest with a "..winning_roll)
		CalmDownandGamble:MessageChat(game.data.loser.." was furthest away with a "..losing_roll)
	end
}
