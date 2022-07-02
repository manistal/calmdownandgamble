
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

local function getYahtzeeScore(digits)
	local result = 0
	local scoringDigit = digits[1]
	local isYahtzee = true
	for index, digit in ipairs(digits) do
		if digit ~= scoringDigit then
			isYahtzee = false
		end
	end
	if isYahtzee then
		result = 50
	end
	return result
end

local function getHighStraightScore(digits)
	local result = 0
	table.sort(digits)
	if digits[1] + 4 == digits[2] + 3
	   and digits[1] + 4 == digits[3] + 2
	   and digits[1] + 4 == digits[4] + 1 
	   and digits[1] + 4 == digits[5] then
		result = 40
	end
	return result
end

local function getLowStraightScore(digits)
	local result = 0
	table.sort(digits)
	local last_digit = nil
	local num_straight = 1
	for index,digit in ipairs(digits) do
		if last_digit then
			if digit == last_digit + 1 then
				num_straight = num_straight + 1
			elseif digit ~= last_digit then
				num_straight = 1
			end
		end
		last_digit = digit
	end
	if num_straight >= 4 then
		result = 30
	end
	return result
end

local function getFullHouseScore(digits)
	local result = 0
	local buckets = {}
	for index,digit in ipairs(digits) do
		if not buckets[digit] then
			buckets[digit] = 1
		else
			buckets[digit] = buckets[digit] + 1
		end
	end
	local three_count = false
	local two_count = false
	for digit,count in ipairs(buckets) do
		if count == 2 then
			two_count = true
		elseif count == 3 then
			three_count = true
		end
	end
	if two_count and three_count then
		result = 25
	end
	return result
end

local function getFourOfAKindScore(digits)
	local result = 0
	local total = 0
	local buckets = {}
	for index,digit in ipairs(digits) do
		total = total + digit
		if not buckets[digit] then
			buckets[digit] = 1
		else
			buckets[digit] = buckets[digit] + 1
		end
	end
	for digit, count in ipairs(buckets) do
		if count >= 4 then
			result = total
		end
	end
	return result
end

local function getThreeOfAKindScore(digits)
	local result = 0
	local total = 0
	local buckets = {}
	for index,digit in ipairs(digits) do
		total = total + digit
		if not buckets[digit] then
			buckets[digit] = 1
		else
			buckets[digit] = buckets[digit] + 1
		end
	end
	for digit, count in ipairs(buckets) do
		if count >= 3 then
			result = total
		end
	end
	return result
end

local function getDieScore(num, digits)
	if num == 0 then num = 10 end
	local total = 0
	for index,digit in ipairs(digits) do
		if digit == num then
			total = total + digit
		end
	end
	return total
end

local function CollectDiceRolls(roll)
	local base10 = roll - 1
	local digits = {}
	local index = 1
	while index < 6 do
		local digit = math.floor(base10 / (6 ^ (5 - index))) + 1
		digits[index] = digit
		base10 = base10 % (6 ^ (5 - index))
		index = index + 1
	end
	return digits
end

local function ScoreYahtzee(roll)
	if roll == -1 then return "",-1 end
	local dice_rolls = CollectDiceRolls(roll)
	local scores = {
		{ name = "Yahtzee", score = getYahtzeeScore(dice_rolls)},
		{ name = "High Straight", score = getHighStraightScore(dice_rolls)},
		{ name = "Low Straight", score = getLowStraightScore(dice_rolls)},
		{ name = "Full House", score = getFullHouseScore(dice_rolls)},
		{ name = "4 of a Kind", score = getFourOfAKindScore(dice_rolls)},
		{ name = "3 of a Kind", score = getThreeOfAKindScore(dice_rolls)},
		{ name = "Sixes", score = getDieScore(6, dice_rolls)},
		{ name = "Fives", score = getDieScore(5, dice_rolls)},
		{ name = "Fours", score = getDieScore(4, dice_rolls)},
		{ name = "Threes", score = getDieScore(3, dice_rolls)},
		{ name = "Twos", score = getDieScore(2, dice_rolls)},
		{ name = "Ones", score = getDieScore(1, dice_rolls)}
	}
	table.sort(scores, function(a, b) return a.score > b.score end)
	for index, value in ipairs(scores) do
		return value.name, value.score, dice_rolls
	end
end

local function FormatDiceRolls(dice_rolls)
	local text = ""
	for index,digit in ipairs(dice_rolls) do
		text = text..digit
		if index < 5 then
			text = text.."-"
		end
	end
	return text
end

CDG_YAHTZEE = {
	label = "Yahtzee",
	
	init_game = function(game)
		game.data.roll_range = "(1-7776)"
		game.data.roll_upper = 7776
		game.data.roll_lower = 1
		game.data.roll_accepted_callback = function(player, roll)
			local hand, score, dice_rolls = ScoreYahtzee(roll)
			local text = player.." rolled "..FormatDiceRolls(dice_rolls).." Score: "..score.." - "..hand
			CalmDownandGamble:MessageChat(text)
		end
	end,
	
	-- Translates roll to a base6 five digit number --
	-- Each digit is a die roll from 1-6 --
	roll_to_score = function(roll)
		local hand, score, dice_rolls = ScoreYahtzee(roll)
		return score
	end,
	
	sort_rolls = CDG_SORT_DESCENDING,

	sort_scores = CDG_SORT_DESCENDING,
	
	payout = function(game)
		CalmDownandGamble:MessageChat("== Game Over! ==")
		for player, score in CalmDownandGamble:sortedpairs(game.data.all_player_scores, game.mode.sort_scores) do
			local hand, score, dice_rolls = ScoreYahtzee(game.data.all_player_rolls[player])
			CalmDownandGamble:MessageChat(player.." Dice: "..FormatDiceRolls(dice_rolls).." Score: "..score.." - "..hand)
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
	
	sort_rolls =  CDG_SORT_DESCENDING,

	sort_scores = CDG_SORT_ASCENDING,
	
	payout = function(game)
		game.data.cash_winnings = math.abs(CDG_CURLING.game.target_roll - game.data.losing_roll)
		CalmDownandGamble:MessageChat("Bullseye for Curling was: "..CDG_CURLING.game.target_roll) 
		CalmDownandGamble:MessageChat(game.data.winner.." was closest with a "..game.data.winning_roll)
		CalmDownandGamble:MessageChat(game.data.loser.." was furthest away with a "..game.data.losing_roll)
	end
}
