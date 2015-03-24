

-- Declare the new addon and load the libraries we want to use 
CDGClient = LibStub("AceAddon-3.0"):NewAddon("CDGClient", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "AceSerializer-3.0")
local CDGClient	= LibStub("AceAddon-3.0"):GetAddon("CDGClient")
local AceGUI = LibStub("AceGUI-3.0")

local DEBUG = true

-- Basic Adddon Initialization stuff, virtually inherited functions 
-- ================================================================ 

-- CONSTRUCTOR 
function CDGClient:OnInitialize()
	if DEBUG then self:Print("Load Begin") end

	-- Set up Infrastructure
	local defaults = {
	   global = {
			rankings = { },
			chat_index = 1,
			game_mode_index = 1, 
			window_shown = false
		}
	}

    self.db = LibStub("AceDB-3.0"):New("CDGClientDB", defaults)
	self:ConstructUI()
	self:RegisterCallbacks()
	self:InitState()

	if DEBUG then self:Print("Load Complete!!") end
end

-- INIT FOR ENABLE  
function CDGClient:OnEnable()
end

-- DESTRUCTOR  
function CDGClient:OnDisable()
end


-- Initialization Helper Functions
-- ===========================================
function CDGClient:InitState()
	-- Chat Context -- 
	self.chat = {}
	self.game = {}
	self:SetChannelSettings()
end

function CDGClient:SetChannelSettings() 

	self.chat.options = {
			{ label = "Raid"  , const = "RAID"  , callback = "CHAT_MSG_RAID"  , callback_leader = "CHAT_MSG_RAID_LEADER"  }, -- Index 1
			{ label = "Party" , const = "PARTY" , callback = "CHAT_MSG_PARTY" , callback_leader = "CHAT_MSG_PARTY_LEADER" }, -- Index 2
			{ label = "Guild" , const = "GUILD" , callback = "CHAT_MSG_GUILD" , callback_leader = nil },                     -- Index 3
			{ label = "Say"   , const = "SAY"   , callback = "CHAT_MSG_SAY"   , callback_leader = nil },                     -- Index 4
	}	
	self.chat.channel_const = "RAID"   -- What the WoW API is looking for, CHANNEL for numeric channels
	
	if DEBUG then self:Print(self.chat.options[self.db.global.chat_index].label) end
	
	self.chat.channel_const = self.chat.options[self.db.global.chat_index].const
	self.ui.chat_channel:SetText(self.chat.options[self.db.global.chat_index].label)
	self.chat.channel_callback = self.chat.options[self.db.global.chat_index].callback
	self.chat.channel_callback_leader = self.chat.options[self.db.global.chat_index].callback_leader

end

-- Slash Command Setup and Calls
-- =========================================================
function CDGClient:RegisterCallbacks()
	-- Register Some Slash Commands
	self:RegisterChatCommand("cdgcshow", "ShowUI")
	self:RegisterChatCommand("cdgchide", "HideUI")
	self:RegisterChatCommand("cdgcdebug", "SetDebug")

    -- callbacks to get game information from master
    self:RegisterComm("CDG_NEW_GAME", "NewGameCallback")
    self:RegisterComm("CDG_NEW_ROLL", "NewRollsCallback")
    self:RegisterComm("CDG_END_GAME", "GameResultsCallback")
end

function CDGClient:SetDebug()
	DEBUG = not DEBUG
end

function CDGClient:ShowUI()
	self.ui.CDG_Frame:Show()
	self.db.global.window_shown = true
end

function CDGClient:HideUI()
	self.ui.CDG_Frame:Hide()
	self.db.global.window_shown = false
end

function CDGClient:ResetStats()
	self.db.global.rankings = {}
end

-- ChatFrame Interaction Callbacks (Entry and Rolls)
-- ==================================================== 
function CDGClient:RollCallback(...)
	-- Parse the input Args 
	local roll_text = select(2, ...)
	local message = SplitString(roll_text, "%S+")
	local player, roll, roll_range = message[1], message[3], message[4]
	
	-- Check that the roll is valid ( also that the message is for us)
	local valid_roll = (self.current_game.roll_range == roll_range) 

	if valid_roll then 
        -- BRODACAST TO MASTER -- 
        -- Example AceComm call to send rolls to master so we can do this in guild
        -- Master needs to register for CDG_ROLL_DICE event
        -- self:SendCommMessage("CDG_ROLL_DICE", roll_text, "GUILD")
	end
	
end

function CDGClient:ChatChannelCallback(...)
	local message = select(2, ...)
	local sender = select(3, ...)

    -- DUNNO IF WE NEED THIS -- 
end

function CDGClient:NewGameCallback(...)
    -- Reset Game Settings -- 
    self.current_game = {}

    -- self.current_game.roll_lower = 
    -- self.current_game.roll_upper = 
    -- self.current_game.roll_range =
    -- "("..self.current_game.roll_lower.."-"..self.current_game.roll_upper..")"
end

function CDGClient:NewRollsCallback(...)
    -- self.current_game.accepting_rolls = true
end

function CDGClient:GameResultsCallback(...)
    -- self.current_game.accepting_rolls = false
    -- self.current_game.winner = 
    -- self.current_game.cash_winnings =
end

-- Button Interaction Callbacks (State and Settings)
-- ==================================================== 
function CDGClient:RollForMe()
	RandomRoll(self.current_game.roll_lower, self.current_game.roll_upper)
end

function CDGClient:EnterForMe()
	SendChatMessage("1", self.chat.channel_const)
end

function CDGClient:ChatChannelToggle()
	self.db.global.chat_index = self.db.global.chat_index + 1
	if self.db.global.chat_index > table.getn(self.chat.options) then self.db.global.chat_index = 1 end

	self:SetChannelSettings()
end

function CDGClient:TradeOpen()
    self.current_game.trade_open = true
end

function CDGClient:OpenTradeWinner()
    if (self.current_game.trade_open) then
        local copper = self.current_game.cash_winnings * 100 * 100 
        SetTradeMoney(copper)
        self.current_game.trade_open = false
    else
        InitiateTrade(self.current_game.winner)
        self:RegisterEvent("TRADE_SHOW", function() self:TradeOpen() end)
    end
end

-- UI ELEMENTS 
-- ======================================================
function CDGClient:ConstructUI()
	
	-- Settings to be used -- 
	local cdg_ui_elements = {
		-- Main Box Frame -- 
		main_frame = {
			width = 300,
			height = 125
		},
		
		-- Order in which the buttons are layed out -- 
		button_index = {
			"roll_for_me",
			"enter_for_me",
			"open_trade",
			"chat_channel"
            
		},
		
		-- Button Definitions -- 
		buttons = {
			chat_channel = {
				width = 125,
				label = "Raid",
				click_callback = function() self:ChatChannelToggle() end
			},
			roll_for_me = {
				width = 125,
				label = "Roll For Me",
				click_callback = function() self:RollForMe() end
			},
			enter_for_me = {
				width = 125,
				label = "Enter Me",
				click_callback = function() self:EnterForMe() end
			},
			open_trade = {
				width = 125,
				label = "Trade Winner",
				click_callback = function() self:OpenTradeWinner() end
			}
		}
	};
	
	-- Give us a base UI Table to work with -- 
	self.ui = {}
	
	-- Constructor Calls -- 
	self.ui.CDG_Frame = AceGUI:Create("Frame")
	self.ui.CDG_Frame:SetTitle("Calm Down Gambling")
	self.ui.CDG_Frame:SetStatusText("")
	self.ui.CDG_Frame:SetLayout("Flow")
	self.ui.CDG_Frame:SetStatusTable(cdg_ui_elements.main_frame)
	
	-- Set up Buttons Above Text Box-- 
	for _, button_name in pairs(cdg_ui_elements.button_index) do
		local button_settings = cdg_ui_elements.buttons[button_name]
	
		self.ui[button_name] = AceGUI:Create("Button")
		self.ui[button_name]:SetText(button_settings.label)
		self.ui[button_name]:SetWidth(button_settings.width)
		self.ui[button_name]:SetCallback("OnClick", button_settings.click_callback)
		
		self.ui.CDG_Frame:AddChild(self.ui[button_name])
	end
	
	if not self.db.global.window_shown then
		self.ui.CDG_Frame:Hide()
	end
	
end


-- Util Functions -- Lua doesnt provide alot of basic functionality
-- =======================================================================
function SplitString(str, pattern)
	local ret_list = {}
	local index = 1
	for token in string.gmatch(str, pattern) do
		ret_list[index] = token
		index = index + 1
	end
	return ret_list
end

function CopyTable(T)
  local u = { }
  for k, v in pairs(T) do u[k] = v end
  return setmetatable(u, getmetatable(T))
end

function TableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function PrintTable(T)
	for k, v in pairs(T) do
		CDGClient:Print(k.."  "..v)
	end
end

function sortedpairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end
    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end