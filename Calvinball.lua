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
	local scoreMod = math.floor(0.2*(game.data.roll_upper - game.data.roll_lower) + 0.5)
	local text = player.." has caught the boomerang..."
	-- Is the boomerang good or bad? --
	local good = coinFlip()
	if good then
		text = text.." In their hand!"
	else
		text = text.." With their face!"
	end
	local opposite = isOpposite()
	-- If !inverse and good or inverse and bad, add 20% to score --
	if (not opposite and good) or (opposite and not good) then
		score = score + scoreMod
	-- If !inverse and bad or inverse and good, subtract 20% from score --
	elseif (opposite and good) or (not opposite and not good) then
		score = score - scoreMod
	end
	return score, text
end

local function oddEven(roll, score, player, game)
	local text = player.." is caught between the time wickets..."
	local opposite = isOpposite()
	local scoreMod = math.floor(0.3*(game.data.roll_upper - game.data.roll_lower) + 0.5)
	-- Is Odd or Even good? --
	local oddIsGood = coinFlip()
	if oddIsGood then
		text = text.." Lost in the future..."
	else
		text = text.." Stuck in the past..."
	end

	local oddRoll = roll % 2 == 1
	if oddRoll then
		text = text.." Falling backwards in time"
	else
		text = text.." Leaping forward in time"
	end
	if (oddIsGood and oddRoll and not opposite) or
	   (oddIsGood and not oddRoll and opposite) or
	   (not oddIsGood and not oddRoll and not opposite) or
	   (not oddIsGood and oddRoll and opposite) then
		score = score + scoreMod
	else
		score = score - scoreMod
	end
	return score, text
end

local function hotChip(roll, score, player, game)
	local text = player.." is eating hot chip..."
	local isGood = coinFlip()
	local opposite = isOpposite()
	local scoreMod = math.floor(0.2*(game.data.roll_upper - game.data.roll_lower) + 0.5)
	if isGood then
		text = text.." and they could put down their hot chip for a second"
		if opposite then
			score = score - scoreMod
		else
			score = score + scoreMod
		end
	else
		text = text.." but they could not put down their hot chip for a second"
		if opposite then
			score = score + scoreMod
		else
			score = score - scoreMod
		end
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
	local text = player.."'s roll has matching digits! How cute."
	local matchingIsGood = coinFlip()
	local opposite = isOpposite
	if (not opposite and matchingIsGood) or (opposite and not matchingIsGood) then
		score = math.floor(score*1.3 + 0.5)
	else
		score = math.floor(score*0.7 + 0.5)
	end
	return score, text
end

local function changeDigits(roll, score, player, game)
	local text = player.."'s score"
	local addingDigit = coinFlip()
	local scoreString = tostring(score)
	local scoreLen = string.len(scoreString)
    local newScore = score
	if addingDigit then
		local newDigit = tostring(math.random(0, 9))
		local digitLoc = math.random(1, scoreLen+1)
		if digitLoc == scoreLen+1 then
			newScore = tonumber(scoreString..newDigit)
		elseif digitLoc == 1 then
			newScore = tonumber(newDigit..scoreString)
		else
			local scoreStart = string.sub(scoreString, 1, digitLoc - 1)
			local scoreEnd = string.sub(scoreString, digitLoc, scoreLen)
			newScore = tonumber(scoreStart..newDigit..scoreEnd)
		end
		text = text.." doesn't have enough digits... Adding a "..newDigit.." somewhere"
	else -- removing a digit --
		text = text.." has too many digits..."
		if scoreLen == 1 then
			text = text.." And it only has one digit... SAD."
			newScore = score
		else
			local digitLoc = math.random(1, scoreLen)
			local newScoreStart = string.sub(scoreString, 1, digitLoc - 1)
			local newScoreEnd = string.sub(scoreString, digitLoc + 1, scoreLen)
			local removedDigit = string.sub(scoreString, digitLoc, digitLoc)
			text = text.." So I got rid of that pesky "..removedDigit.." for you :)"
			newScore = tonumber(newScoreStart..newScoreEnd)
		end
	end
    return newScore, text
end

local function goalPost(roll, score, player, game)
	local newScore = score
	local text = player.." has found a new goalpost tree at..."
	local tree = math.random(game.data.roll_lower, game.data.roll_upper)
	local distance = math.abs(roll-tree)
	text = text.." "..tree.."!"
	local thisIsGood = coinFlip()
	local opposite = isOpposite()
	if thisIsGood then
		text = text.." Proud of you."
	else
		text = text.." How dare you."
	end
	if (not opposite and thisIsGood) or (opposite and not thisIsGood) then
		newScore = newScore + distance
	else
		newScore = newScore - distance
	end
	return newScore, text
end

local function foundBall(roll, score, player, game)
	local thisIsGood = coinFlip()
	local opposite = isOpposite()
	local scoreMod = math.floor(game.data.roll_lower + game.data.roll_upper + 0.5)
	local newScore = score
	local calvinBallFound = math.random(1,100) > 80
    if not calvinBallFound then
        return score, nil
    end
	text = player.." has found the CALVINBALL!!!"
	if thisIsGood then
		if opposite then
			newScore = score - scoreMod
		else
			newScore = score + scoreMod
		end
	else
		text = text.." But it turned out to be a rotten egg."
		if opposite then
			newScore = score + scoreMod
		else
			newScore = score - scoreMod
		end
	end
	return newScore, text
end

local function upDownSort(scores, playera, playerb)
	if isOpposite() then
		return CDG_SORT_ASCENDING(scores, playera, playerb)
	else
		return CDG_SORT_DESCENDING(scores, playera, playerb)
	end
end

local function madHatter_pickPlayer(playoff)
	local num_players = CalmDownandGamble:TableLength(playoff)
	local playerNames = {}
	for player,roll in pairs(playoff) do
		tinsert(playerNames, player)
	end
	return playerNames[math.random(num_players)]
end

local madHatter_winnersLines = {
	function(player)
		return player..", what are you doing in winners bracket? You still haven't returned my VHS of Men in Black 2... "..player.." is now in the losers bracket!"
	end,
	function(player)
		return "It seems "..player.." has been using loaded dice... "..player.." is now in the losers bracket!"
	end,
	function(player)
		return player.." opened their fanny pack and all their spaghetti fell out onto their nice khakis... "..player.." is now in the losers bracket!"
	end,
	function(player)
		return player.." forgot this game has no rules. "..player.." is now in the losers bracket!"
	end
}

local madHatter_losersLines = {
	function(player)
		return "How much "..player.." would a "..player.."chuck chuck if a "..player.."chuck could chuck "..player.."?... One! "..player.." is now in the winners bracket!"
	end,
	function(player)
		return player.." is definitely not sleeping with the raid leader... "..player.." is now in the winners bracket!"
	end,
	function(player)
		return "It's lonely at the top... so "..player.." is now in the winners bracket!"
	end,
	function(player)
		return player.." remembered this game has no rules. "..player.." is now in the winners bracket!"
	end
}

local function madHatter_winners_line(pickedPlayer)
	local num_lines = CalmDownandGamble:TableLength(madHatter_winnersLines)
	local line = madHatter_winnersLines[math.random(num_lines)]
	return line(pickedPlayer)
end

local function madHatter_losers_line(pickedPlayer)
	local num_lines = CalmDownandGamble:TableLength(madHatter_losersLines)
	local line = madHatter_losersLines[math.random(num_lines)]
	return line(pickedPlayer)
end

local function madHatter_moveWinner(game, next_round)
	local pickedPlayer = madHatter_pickPlayer(game.data.high_score_playoff)
	game.data.high_score_playoff[pickedPlayer] = nil
	game.data.low_score_playoff[pickedPlayer] = -1
	if next_round == CDGConstants.LOSERS_ROUND then
		game.data.player_rolls[pickedPlayer] = -1
	elseif next_round == CDGConstants.WINNERS_ROUND then
		game.data.player_rolls[pickedPlayer] = nil
	end
	return madHatter_winners_line(pickedPlayer)
end

local function madHatter_moveLoser(game, next_round)
	local pickedPlayer = madHatter_pickPlayer(game.data.low_score_playoff)
	game.data.low_score_playoff[pickedPlayer] = nil
	game.data.high_score_playoff[pickedPlayer] = -1
	if next_round == CDGConstants.WINNERS_ROUND then
		game.data.player_rolls[pickedPlayer] = -1
	elseif next_round == CDGConstants.LOSERS_ROUND then
		game.data.player_rolls[pickedPlayer] = nil
	end
	return madHatter_losers_line(pickedPlayer)
end

local function madHatter(game, current_round, current_rollers, next_round, next_rollers)
	local text = "'CHANGE PLACES!!' yells the Mad Hatter..."

	local winnersEligible = CalmDownandGamble:TableLength(game.data.high_score_playoff) > 2
	local losersEligible = CalmDownandGamble:TableLength(game.data.low_score_playoff) > 2

	if not next_round 
	   or next_round == CDGConstants.INITIAL_ROUND 
	   or (not losersEligible and not winnersEligible) then
		return nil
	end

	if winnersEligible and losersEligible then
		local removeWinner = coinFlip()
		if removeWinner then
			text = text.." "..madHatter_moveWinner(game, next_round)
		else
			text = text.." "..madHatter_moveLoser(game, next_round)
		end
	elseif winnersEligible then
		text = text.." "..madHatter_moveWinner(game, next_round)
	elseif losersEligible then
		text = text.." "..madHatter_moveLoser(game, next_round)
	end
	return text
end

local function maxBetPayout(game)
	return game.data.gold_amount, "Max Bet"
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

local function secretPayout(game)
	return game.data.gold_amount, "But only if they share a secret they wouldn't tell their parents."
end

local CB_ALL_SCORING_RULES = {oddEven,
								hotChip,
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
	local num_rules = CalmDownandGamble:TableLength(CB_ALL_SCORING_RULES)
	local pickedRules = {}
	local idx = 1
	while idx <= num_rules do
		pickedRules[idx] = false
		idx = idx + 1
	end
	while numRulesToAdd > 0 do
		local rule_idx = math.random(num_rules)
		if not pickedRules[rule_idx] then
            table.insert(result_rules, CB_ALL_SCORING_RULES[rule_idx])
			pickedRules[rule_idx] = true
			numRulesToAdd = numRulesToAdd - 1
		end
	end
	return result_rules
end

function CB_ApplyScoringRules(roll, player, game)
	if catchBoomerang() then
		tinsert(CB_CURRENT_SCORING_RULES, scoreBoomerang)
	end
	local score = roll;
	for _,rule in pairs(CB_CURRENT_SCORING_RULES) do
		local newScore, text = rule(roll, score, player, game)
        if text then
            CalmDownandGamble:MessageChat(text)
        end
	end
	if score < 1 then score = 1 end
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

local CB_CURRENT_SORTING_RULE = upDownSort

function CB_ApplySortingRule(scores, playera, playerb)
    return CB_CURRENT_SORTING_RULE(scores, playera, playerb)
end
    
function CB_SetSortingRule(game)
	CB_CURRENT_SORTING_RULE = upDownSort
end

CB_ALL_ROUND_RESOLVED_RULES = {madHatter}
CB_CURRENT_ROUND_RESOLVED_RULES = {}

function CB_ApplyRoundResolvedRules(game, current_round, current_rollers, next_round, next_rollers)
	for _, rule in pairs(CB_CURRENT_ROUND_RESOLVED_RULES) do
		local text = rule(game, current_round, current_rollers, next_round, next_rollers)
		if text then
			CalmDownandGamble:MessageChat(text)
		end
	end
end

function CB_SetRoundResolvedRules()
	CB_CURRENT_ROUND_RESOLVED_RULES = {}
	local num_rules = CalmDownandGamble:TableLength(CB_ALL_ROUND_RESOLVED_RULES)
	local rule_idx = math.random(10)
	if rule_idx <= num_rules then
		tinsert(CB_CURRENT_ROUND_RESOLVED_RULES, CB_ALL_ROUND_RESOLVED_RULES[rule_idx])
	end
end

local CB_ALL_PAYOUT_RULES = {maxBetPayout, badEconomyPayout, singPayout, complimentPayout, secretPayout}
local CB_PAYOUT_RULE = maxBetPayout

function CB_ApplyPayoutRule(game)
	return CB_PAYOUT_RULE(game)
end

function CB_SetPayoutRule()
    local num_rules = CalmDownandGamble:TableLength(CB_ALL_PAYOUT_RULES)
	local payout_idx = math.random(10)
	if payout_idx <= num_rules then
		CB_PAYOUT_RULE = CB_ALL_PAYOUT_RULES[payout_idx]
    else
        CB_PAYOUT_RULE = maxBetPayout
	end
end

function CB_HandleHogwartsHouses(game)
    local houses = {"Gryffindor", "Hufflepuff", "Ravenclaw", "Slytherin"}
    local house = houses[math.random(40)]
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
	CB_CURRENT_ROUND_RESOLVED_RULES = {}
    CB_CURRENT_SORTING_RULE = upDownSort
    CB_PAYOUT_RULE = maxBetPayout
    cb_opposite = false
    cb_boomerang_active = false
end