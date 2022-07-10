-- Flip a coin, return true for heads, false for tails
local function coinFlip()
	if math.random(0,1) == 1 then
		return true
	else
		return false
	end
end

local cb_opposite = false
local function isOpposite()
	return cb_opposite
end

local function flipOpposite()
	cb_opposite = not cb_opposite
end

local cb_boomerang_active = false

local function throwBoomerang()
	cb_boomerang_active = true
end

local function catchBoomerang()
	if cb_boomerang_active then
		cb_boomerang_active = false
		return true
	else
		return false
	end
end

local function scoreBoomerang(roll, score, player, game)
	local result = score
	local text = player.." has caught the boomerang..."
	-- Is the boomerang good or bad? --
	local good = coinFlip()
	if good then
		text = text.." In their hand!"
	else
		text = text.." With their face!"
	end
	local opposite = isOpposite()
	-- If !inverse and good or inverse and bad, add 20% of score to score --
	if (not opposite and good) or (opposite and not good) then
		text = text.." plus 20% to score"
		result = math.floor(result*1.2 + 0.5)
	-- If !inverse and bad or inverse and good, subtract 20% of score from score --
	elseif (opposite and not good) or (not opposite and good) then
		text = text.." minus 20% from score"
		result = math.floor(result*0.8 + 0.5)
	end
	return score, text
end

local function oddEven(roll, score, player, game)
	local text = player.." is caught between the time wickets..."
	local opposite = isOpposite()
	local result = score

	-- Is Odd or Even good? --
	local oddIsGood = coinFlip()
	if oddIsGood then
		text = text.. " Lost in the future..."
	else
		text = text.. " Stuck in the past..."
	end

	local oddRoll = roll % 2 == 1
	if oddRoll then
		text = text.." Falling backwards in time..."
	else
		text = text.." Leaping forward in time..."
	end
	if (oddIsGood and oddRoll and not opposite) or
	   (oddIsGood and not oddRoll and opposite) or
	   (not oddIsGood and not oddRoll and not opposite) or
	   (not oddIsGood and oddRoll and opposite) then
		text = text.." Plus 50% to score!"
		result = math.floor(result*1.5 + 0.5)
	else
		text = text.." Minus 50% from score!"
		result = math.floor(result*0.5 + 0.5)
	end
	return score, text
end

local function vortexZone(roll, score, player, game)
	local newRoll = math.random(game.data.roll_lower, game.data.roll_upper)
	local text = player.." has entered the vortext zone! Your roll is now: "..newRoll..". I hope you learned your lesson."
	score = score + newRoll - roll
	return score, text
end

local function oppositePole(roll, score, player, game)
	flipOpposite()
	local text = player.." has tagged the opposite pole! Scoring is now"
	if isOpposite() then
		text = text.." reversed!"
	else
		text = text.." back to normal!"
	end
	return score, text
end

local function boomerang(roll, score, player, game)
	throwBoomerang()
	local text = player.." has thrown the boomerang! Watch out!"
	return score, text
end

local function matchingDigits(roll, score, player, game)
	local digitBuckets = {0,0,0,0,0,0,0,0,0,0}
	local rollString = tostring(roll)
	local idx = 1
	while idx <= string.len(rollString) do
		local digit = tonumber(string.sub(rollString,idx,idx))
		if digit == 0 then digit = 10 end
		digitBuckets[digit] = digitBuckets[digit] + 1
		idx = idx + 1
	end
	local matchingDigits = false
	for digit,count in pairs(digitBuckets) do
		if count > 1 then
			matchingDigits = true
		end
	end
	-- Leave if no matching digits --
	if not matchingDigits then return score,nil end
	local text = player.."'s roll has matching digits! How cute..."
	local matchingIsGood = coinFlip()
	local opposite = isOpposite
	if (not opposite and matchingIsGood) or (opposite and not matchingIsGood) then
		text = text.." Add 30% to score"
		score = math.floor(score*1.3 + 0.5)
	else
		text = text.." Subtract 30% from score"
		score = math.floor(score*0.7 + 0.5)
	end
	return score, text
end

local function changeDigits(roll, score, player, game)
	local text = player.."'s score"
	local addingDigit = coinflip()
	local scoreString = tostring(score)
	local scoreLen = string.len(scoreString)
	if addingDigit then
		local newDigit = tostring(math.random(0, 9))
		local digitLoc = math.random(1, scoreLen)
		if digitLoc == scoreLen then
			newScore = tonumber(newDigit..scoreString)
		elseif digitLoc == 1 then
			newScore = tonumber(scoreString..newDigit)
		else
			local scoreStart = string.sub(scoreString, 1, digitLoc - 1)
			local scoreEnd = string.sub(scoreString, digitLoc, scoreLen)
			local newScore = tonumber(scoreStart..newDigit..scoreEnd)
		end
		text = text.." doesn't have enough digits... Adding a "..newDigit.." somewhere"
		return newScore, text
	else -- removing a digit --
		text = text.." has too many digits..."
		if scoreLen == 1 then
			text = text.." And it only has one digit... SAD."
			return score, text
		end
		local digitLoc = math.random(1, scoreLen)
		local newScoreStart = string.sub(scoreString, 1, digitLoc - 1)
		local newScoreEnd = string.sub(scoreString, digitLoc + 1, scoreLen)
		local removedDigit = string.sub(scoreString, digitLoc, digitLoc)
		text = text.." So I got rid of that pesky "..removedDigit.." for you :)"
		return tonumber(newScoreStart..newScoreEnd), text
	end
end

local function goalPost(roll, score, player, game)
	local newScore = score
	local text = player.." has found a new goalpost tree at..."
	local tree = math.random(game.data.roll_lower, game.data.roll_upper)
	local distance = math.abs(roll-tree)
	text = text.." "..tree.."!"
	local thisIsGood = coinflip()
	local opposite = isOpposite()
	if thisisGood then
		text = text.." Proud of you."
	else
		text = text.." How dare you."
	end
	if (not opposite and thisIsGood) or (opposite and not thisIsGood) then
		text = text.." +"..distance.." to score!"
		newScore = newScore + distance
	else
		text = text.." -"..distance.." from score!"
		newScore = newScore - distance
	end
	return newScore, text
end

local function foundBall(roll, score, player, game)
	local newScore = score
	local thisIsGood = coinflip()
	local opposite = isOpposite()
	local calvinBallFound = math.random(1,100) > 80
	text = player.." has found the CALVINBALL!!!"
	if thisIsGood then
		if opposite then
			text = " Score set to 1"
			newScore = 1
		else
			text = " Score x 100"
			newScore = score * 100
		end
	else
		text = " But it turned out to be a rotten egg."
		if opposite then
			text = " Score x 100"
			newScore = score * 100
		else
			text = " Score set to 1"
			newScore = 1
		end
	end
	return newScore, text
end

local CB_ALL_SCORING_RULES = {oddEven, 
								vortexZone, 
								oppositePole, 
								boomerang, 
								matchingDigits, 
								changeDigits,
								goalPost,
								foundBall}
local CB_CURRENT_SCORING_RULES = {}

local function addScoringRules(numRulesToAdd)
	local result_rules = {}
	local num_rules = getn(CB_ALL_SCORING_RULES)
	local pickedRules = {}
	local idx = 1
	while idx <= num_rules do
		pickedRules[idx] = false
		idx = idx + 1
	end
	while numRulesToAdd > 0 do
		local rule_idx = math.random(num_rules)
		if not pickedRules[rule_idx] then

			pickedRules[rule_idx] = true
			numRulesToAdd = numRulesToAdd - 1
		end
	end
	return result_rules
end

local function upDownSort(scores, playera, playerb)
	if isOpposite then
		return CDG_SORT_ASCENDING(scores, playera, playerb)
	else
		return CDG_SORT_DESCENDING(scores, playera, playerb)
	end
end

local CB_CURRENT_SORTING_RULE = upDownSort

local function maxBetPayout(game)
	return game.data.gold_amount, "Max Bet"
end

local function differencePayout(game)
	local text = "Score difference!"
	local diff = game.data.winning_score - game.data.losing_score
	local payout = 0
	if diff > game.data.gold_amount then
		text = text.."... But it's "..(diff-game.data.gold_amount).." higher than the bet amount"
		payout = game.data.gold_amount
	else
		payout = diff
	end
	return payout, text
end

local function badEconomyPayout(game)
	return (game.data.gold_amount / 2), "Because the economy is in shambles."
end

local function singPayout(game)
	return game.data.gold_amount, "But only if they sing for it."
end

local function complimentPayout(game)
	return game.data.gold_amount, "But only if they say something nice about "..game.data.loser
end

local CB_ALL_PAYOUT_RULES = {maxBetPayout, differencePayout, badEconomyPayout, singPayout, complimentPayout}
local CB_PAYOUT_RULE = maxBetPayout

function CB_ApplyScoringRules(roll, player, game)
	if catchBoomerang() then
		tinsert(CB_CURRENT_SCORING_RULES, scoreBoomerang)
	end
	local score = roll;
	for _,rule in pairs(CB_CURRENT_SCORING_RULES) do
		score, text = rule(roll, score, player, game)
        if text then
            CalmDownandGamble:MessageChat(text)
        end
	end
	return score
end

function CB_SetScoringRules()
	local randomRules = math.random(20)
	if randomRules < 14 then
		CB_CURRENT_SCORING_RULES = {}
	elseif randomRules < 18 then
		CB_CURRENT_SCORING_RULES = addScoringRules(1)
	elseif randomRules < 20 then
		CB_CURRENT_SCORING_RULES = addScoringRules(2)
	else
		CB_CURRENT_SCORING_RULES = addScoringRules(3)
	end
end

function CB_ApplySortingRule(scores, playera, playerb)
    return CB_CURRENT_SORTING_RULE(scores, playera, playerb)
end
    
function CB_SetSortingRule(game)

end

function CB_ApplyPayoutRule(game)
	return CB_PAYOUT_RULE(game)
end

function CB_SetPayoutRule()
	local payout_idx = math.random(10) - getn(CB_ALL_PAYOUT_RULES)
	if payout_idx > 1 then
		CB_PAYOUT_RULE = CB_ALL_PAYOUT_RULES[payout_idx]
	end
end

function CB_HandleHogwartsHouses(game)
    local houses = {"Gryffindor", "Hufflepuff", "Ravenclaw", "Slytherin"}
    local idx = math.random(100)
    local house = houses[idx]
    if house then
        game.data.player_rolls[house] = -1
    end
    for _, house in pairs(houses) do
        if game.data.player_rolls[house] then
            game.data.player_rolls[house] = math.random(game.data.roll_lower, game.data.roll_upper)
        end
    end
end

function CB_Reset()
    CB_CURRENT_SCORING_RULES = {}
    CB_CURRENT_SORTING_RULE = upDownSort
    CB_PAYOUT_RULE = maxBetPayout
    cb_opposite = false
    cb_boomerang_active = false
end