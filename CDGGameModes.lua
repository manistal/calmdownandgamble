
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
		if tonumber(roll) == 1 then
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
			game.data.roll_upper = game.data.w_bullets
		-- Decrease l bullets on losers round --
		elseif current_round == "loser" then
			game.data.l_bullets = game.data.l_bullets - 1
			game.data.roll_upper = game.data.l_bullets
		-- Game over, do nothing --
		else
		end
		
		-- Check who needs to reload --
		local everyone_is_dead = true
		local any_losers = false
		for player, roll in pairs(current_rollers) do
			if roll > 1 then
				everyone_is_dead = false
			elseif roll == 1 then
				any_losers = true
			end
		end
		-- If everyone shot themselves, reload --
		if everyone_is_dead then
			CalmDownandGamble:MessageChat("You all shot yourself... Reload!") 
			if next_round == "initial" or next_round == "winners" then
				game.data.w_bullets = 6
				game.data.roll_upper = game.data.w_bullets
			elseif next_round == "losers" then
				game.data.l_bullets = 6
				game.data.roll_upper = game.data.l_bullets
			else
			end
		-- Empty chamber condition on initial or winners rounds--
		elseif (next_round == "initial" or next_round == "winners") and game.data.w_bullets < 2 then
			CalmDownandGamble:MessageChat("Only one chamber left. Reload!") 
			game.data.w_bullets = 6
			game.data.roll_upper = game.data.w_bullets
		elseif next_round == "losers" then
			if any_losers then
				-- Losers in the losers round (everyone_is_dead condition means at least 1 winner) --
				CalmDownandGamble:MessageChat("All you losers shot yourself. Reload!") 
				game.data.l_bullets = 6
				game.data.roll_upper = game.data.l_bullets
			-- Empty chamber condition --
			elseif game.data.l_bullets < 2 then
				CalmDownandGamble:MessageChat("Only one chamber left. Reload!") 
				game.data.l_bullets = 6
				game.data.roll_upper = game.data.l_bullets
			end
		else
		end
		game.data.roll_range = "("..game.data.roll_lower.."-"..game.data.roll_upper..")"
	end
}

-- Yahtzee
-- ============

-- Sorts dice_rolls into table where index = dice roll and value = count
local function bucketDiceRolls(dice_rolls)
	local buckets = {0,0,0,0,0,0}
	for index,digit in ipairs(dice_rolls) do
		buckets[digit] = buckets[digit] + 1
	end
	return buckets
end

local function getYahtzeeScore(dice_rolls)
	local result = 0
	for digit,count in ipairs(bucketDiceRolls(dice_rolls)) do
		if count >= 5 then
			result = 50
		end
	end
	return result
end

local function getHighStraightScore(dice_rolls)
	local result = 0
	local buckets = bucketDiceRolls(dice_rolls)
	local num_straight = 0
	for digit,count in ipairs(buckets) do
		if count > 0 then
			num_straight = num_straight + 1
		else
			num_straight = 0
		end
		if num_straight >= 5 then
			result = 40
		end
	end
	return result
end

local function getLowStraightScore(dice_rolls)
	local result = 0
	local num_straight = 0
	for digit,count in ipairs(bucketDiceRolls(dice_rolls)) do
		if count > 0 then
			num_straight = num_straight + 1
		else
			num_straight = 0
		end
		if num_straight >= 4 then
			result = 30
		end
	end
	return result
end

local function getFullHouseScore(dice_rolls)
	local result = 0
	local three_count = false
	local two_count = false
	for digit,count in ipairs(bucketDiceRolls(dice_rolls)) do
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

local function getFourOfAKindScore(dice_rolls)
	local result = 0
	local total = 0
	local foakFound = false
	for digit,count in ipairs(bucketDiceRolls(dice_rolls)) do
		total = total + (digit * count)
		if count == 4 then
			foakFound = true
		end
	end
	if foakFound then
		result = total
	end
	return result
end

local function getThreeOfAKindScore(dice_rolls)
	local result = 0
	local total = 0
	local toakFound = false
	for digit,count in ipairs(bucketDiceRolls(dice_rolls)) do
		total = total + (digit * count)
		if count == 3 then
			toakFound = true
		end
	end
	if toakFound then
		result = total
	end
	return result
end

local function getDieScore(num, dice_rolls)
	local total = 0
	for index,digit in ipairs(dice_rolls) do
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
	end,
	
	roll_to_score = function(roll)
		local hand, score, dice_rolls = ScoreYahtzee(roll)
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
			local hand, score, dice_rolls = ScoreYahtzee(game.data.all_player_rolls[player])
			CalmDownandGamble:MessageChat(player.." Dice: "..FormatDiceRolls(dice_rolls).." Score: "..score.." - "..hand)
		end
		game.data.cash_winnings = game.data.gold_amount
	end,

	roll_accepted_callback = function(game, player, roll)
		local dice_rolls = CollectDiceRolls(roll)
		local text = player.." rolled "..FormatDiceRolls(dice_rolls)
		CalmDownandGamble:MessageChat(text)
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
		CDG_LANDMINES.num_mines = math.floor(0.25 * game.data.roll_upper + 0.5)
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
		CalmDownandGamble:MessageChat("Landmines: Roll from 1 to bet amount. 25% of rolls are landmines. Roll a landmine and you lose. Last survivor wins. Payout is bet amount.")
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
