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

function YZ_CollectDiceRolls(roll)
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

function YZ_ScoreYahtzee(roll)
	local dice_rolls = YZ_CollectDiceRolls(roll)
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

function YZ_FormatDiceRolls(dice_rolls)
	local text = ""
	for index,digit in ipairs(dice_rolls) do
		text = text..digit
		if index < 5 then
			text = text.."-"
		end
	end
	return text
end