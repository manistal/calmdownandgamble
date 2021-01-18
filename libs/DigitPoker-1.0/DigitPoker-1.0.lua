-- DigitPoker https://github.com/rissole/digit-poker-lua
-- hand = table of 5 digits
-- card = numbers, 0-9.

local MAJOR, MINOR = "DigitPoker-1.0", 0
local DigitPoker = LibStub and LibStub:NewLibrary(MAJOR, MINOR) or {}

local function clone(T)
    local u = { }
    for k, v in pairs(T) do u[k] = v end
    return setmetatable(u, getmetatable(T))
end

local function findKey(t, v)
	for k,v2 in pairs(t) do
		if v == v2 then return k end
	end
	return nil	
end

local function tableWithout(t, v)
	local t2 = {}
	for k,v2 in pairs(t) do
		if v ~= v2 then table.insert(t2, v2) end
	end
	return t2
end

function DigitPoker.parse(handString)
	local hand = {}
	for digit in handString:gmatch('%d') do
		table.insert(hand, tonumber(digit))
	end
	table.sort(hand, function(a,b) return a > b end)
	return hand
end

function DigitPoker.score(hand)
	local l = #hand
	hand = clone(hand)
	table.sort(hand, function(a,b) return a > b end)

	local valueHighCard = function(hand)
		local sum = 0
		for i, rank in ipairs(hand) do
			sum = sum + 11^(#hand-i) * (rank+1)
		end
		return sum
	end

	local valueFourOfAKind = function(hand)
		local c = getCountsTable(hand)
		local fourRank = findKey(c, 4)
		local oneRank = findKey(c, 1)
		return 11*(fourRank+1) + oneRank+1
	end

	local valueFullHouse = function(hand)
		local c = getCountsTable(hand)
		local threeRank = findKey(c, 3)
		local twoRank = findKey(c, 2)
		return 11*(threeRank+1) + twoRank+1
	end

	local valueThreeOfAKind = function(hand)
		local c = getCountsTable(hand)
		local threeRank = findKey(c, 3)
		local handWithoutThreeRank = tableWithout(hand, threeRank)

		return 11^3*(threeRank+1) + valueHighCard(handWithoutThreeRank)
	end

	local valueTwoPair = function(hand)
		local c = getCountsTable(hand)
		local lowPair = findKey(c, 2)
		c[lowPair] = 0
		local highPair = findKey(c, 2)
		local singleRank = findKey(c, 1)
		if (lowPair > highPair) then
			local x = lowPair
			lowPair = highPair
			highPair = x
		end

		return 11^3*(highPair+1) + 11^2*(lowPair+1) + singleRank+1
	end

	local valuePair = function(hand)
		local c = getCountsTable(hand)
		local pairRank = findKey(c, 2)
		local handWithoutPairRank = tableWithout(hand, pairRank)

		return 11^4*(pairRank+1) + valueHighCard(handWithoutPairRank)
	end

	local getBaseValue = function(i)
		return 11^(l + 2) * i
	end

	if (DigitPoker.isFiveOfAKind(hand)) then
		return getBaseValue(7) + hand[1]
	elseif (DigitPoker.isFourOfAKind(hand)) then
		return getBaseValue(6) + valueFourOfAKind(hand)
	elseif (DigitPoker.isFullHouse(hand)) then
		return getBaseValue(5) + valueFullHouse(hand)
	elseif (DigitPoker.isStraight(hand)) then
		return getBaseValue(4) + valueHighCard(hand)
	elseif (DigitPoker.isThreeOfAKind(hand)) then
		return getBaseValue(3) + valueThreeOfAKind(hand)
	elseif (DigitPoker.isTwoPair(hand)) then
		return getBaseValue(2) + valueTwoPair(hand)
	elseif (DigitPoker.isPair(hand)) then
		return getBaseValue(1) + valuePair(hand)
	else
		return valueHighCard(hand) 
	end
end

function DigitPoker.name(hand)
	local c = getCountsTable(hand)
	if (DigitPoker.isFiveOfAKind(hand)) then
		return string.format('Five of a kind (%ds)', hand[1])
	elseif (DigitPoker.isFourOfAKind(hand)) then
		local rank = findKey(c, 4)
		return string.format('Four of a kind (%ds)', rank)
	elseif (DigitPoker.isFullHouse(hand)) then
		local threeRank = findKey(c, 3)
		local twoRank = findKey(c, 2)
		return string.format('Full house (%ds on %ds)', threeRank, twoRank)
	elseif (DigitPoker.isStraight(hand)) then
		return string.format('Straight (%d high)', hand[1])
	elseif (DigitPoker.isThreeOfAKind(hand)) then
		local threesRank = findKey(c, 3)
		return string.format('Three of a kind (%d)', threesRank)
	elseif (DigitPoker.isTwoPair(hand)) then
		local lowPair = findKey(c, 2)
		c[lowPair] = 0
		local highPair = findKey(c, 2)
		if (lowPair > highPair) then
			local x = lowPair
			lowPair = highPair
			highPair = x
		end
		return string.format('Two pair (%ds and %ds)', highPair, lowPair)
	elseif (DigitPoker.isPair(hand)) then
		local pairRank = findKey(c, 2)
		return string.format('Pair (%ds)', pairRank)
	else
		return string.format('High card (%d high)', hand[1])
	end
end

function DigitPoker.formatHand(hand)
    local c = getCountsTable(hand)
    local t = {}
    for i=#hand,1,-1 do
        t[i] = {}
        for n, v in pairs(c) do
            if i == v then table.insert(t[i], n) end
        end
        table.sort(t[i], function(a,b) return a > b end)
    end
    local s = ''
    for i=#hand,1,-1 do
        for _,n in ipairs(t[i]) do
            for x=1,i do s = s .. n end
        end
    end
    return s
end

function DigitPoker.isFiveOfAKind(hand)
	return  hand[1] == hand[2] and 
			hand[1] == hand[3] and 
			hand[1] == hand[4] and
			hand[1] == hand[5]
end

function DigitPoker.isFourOfAKind(hand)
	for i=0,9 do
		local c = 0
		for _, v in ipairs(hand) do
			if v == i then
				c = c + 1
			end
		end
		if (c == 4) then
			return true
		end
	end
	return false
end

function getCountsTable(hand)
	local c = {}
	for i=0,9 do
		for _, v in ipairs(hand) do
			if v == i then
				c[i] = c[i] and c[i] + 1 or 1
			end
		end
	end
	return c
end

function DigitPoker.isFullHouse(hand)
	local c = getCountsTable(hand)

	local has3OfAKind = false
	local has2OfAKind = false
	for _, v in pairs(c) do
		if v == 2 then has2OfAKind = true end
		if v == 3 then has3OfAKind = true end
	end

	return has3OfAKind and has2OfAKind and #hand == 5
end

function DigitPoker.isStraight(hand)
	-- should already be sorted
	local hand2 = clone(hand)
	table.sort(hand2)
	for i=2,#hand do
		if hand2[i] ~= hand2[i-1] + 1 then return false end
	end
	return true
end

function DigitPoker.isThreeOfAKind(hand)
	local c = getCountsTable(hand)

	local has3OfAKind = false
	for _, v in pairs(c) do
		if v == 3 then has3OfAKind = true end
	end

	return has3OfAKind and not DigitPoker.isFullHouse(hand)
end

function DigitPoker.isTwoPair(hand)
	local c = getCountsTable(hand)

	local numPairs = 0
	for _, v in pairs(c) do
		if v == 2 then numPairs = numPairs + 1 end
	end

	return numPairs == 2
end

function DigitPoker.isPair(hand)
	local c = getCountsTable(hand)

	local numPairs = 0
	for _, v in pairs(c) do
		if v == 2 then numPairs = numPairs + 1 end
	end

	return numPairs == 1
end

return DigitPoker
