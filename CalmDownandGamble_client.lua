

-- Declare the new addon and load the libraries we want to use 
CDGClient = LibStub("AceAddon-3.0"):NewAddon("CDGClient", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "AceSerializer-3.0")
local CDGClient	= LibStub("AceAddon-3.0"):GetAddon("CDGClient")
local AceGUI = LibStub("AceGUI-3.0")

local DEBUG = false

-- Basic Adddon Initialization stuff, virtually inherited functions 
-- ================================================================ 

-- CONSTRUCTOR 
function CDGClient:OnInitialize()
	if DEBUG then self:Print("Load Begin") end

	-- Set up Infrastructure
	local defaults = {
	   global = {
			rankings = { },
			game_mode_index = 1, 
			window_shown = false,
			auto_pop = true
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

end

-- Slash Command Setup and Calls
-- =========================================================
function CDGClient:RegisterCallbacks()
	-- Register Some Slash Commands
	self:RegisterChatCommand("cdgc", "ShowUI")
	self:RegisterChatCommand("cdgchide", "HideUI")
	self:RegisterChatCommand("cdgcdebug", "SetDebug")
	self:RegisterChatCommand("cdgcdisable", "DisablePop")
	self:RegisterChatCommand("cdgcenable", "EnablePop")

	self:RegisterEvent("CHAT_MSG_SYSTEM", "RollCallback")
	
    -- callbacks to get game information from master
    self:RegisterComm("CDG_NEW_GAME", "NewGameCallback")
    self:RegisterComm("CDG_NEW_ROLL", "NewRollsCallback")
    self:RegisterComm("CDG_END_GAME", "GameResultsCallback")
	
	if DEBUG then self:Print("REGISTRATIONS COMPLETE") end
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

function CDGClient:DisablePop()
	self.db.global.auto_pop = false
end
function CDGClient:EnablePop()
	self.db.global.auto_pop = true
end

function CDGClient:ResetStats()
	self.db.global.rankings = {}
end

-- ChatFrame Interaction Callbacks (Entry and Rolls)
-- ==================================================== 
function CDGClient:RollCallback(...)
	-- Parse the input Args 
	local roll_text = select(2, ...)
	local message = self:SplitString(roll_text, "%S+")
	local sender, roll, roll_range = message[1], message[3], message[4]
	
	-- Check that the roll is valid ( also that the message is for us)
	local valid_roll = self.current_game and (self.current_game.roll_range == roll_range) 

	local player, realm = UnitName("player")
	local valid_source = (sender == player) 
	
	if valid_roll and valid_source then 
        -- BRODACAST TO MASTER -- 
        -- Example AceComm call to send rolls to master so we can do this in guild
        -- Master needs to register for CDG_ROLL_DICE event
        self:SendCommMessage("CDG_ROLL_DICE", roll_text, self.current_game.addon_const)
		local roll_msg = "Rolled: "..roll.." "..self.current_game.roll_range.."  Cash: "..self.current_game.cash_winnings
		--self.ui.CDG_Frame:SetStatusText(roll_msg)
		if DEBUG then self:Print(roll_text) end
	end
	
end

function CDGClient:ChatChannelCallback(...)
	local message = select(2, ...)
	local sender = select(3, ...)

    -- DUNNO IF WE NEED THIS -- 
end

function CDGClient:NewGameCallback(...)
    -- Reset Game Settings -- 
    --self.current_game = {}
	if DEBUG then self:Print("NEWGAME") end
	local callback = select(1, ...)
	local message = select(2, ...)
	local chat = select(3, ...)
	local sender = select(4, ...)
	message = self:SplitString(message, "%S+")
	
	self.current_game = {}
	self.current_game.roll_lower = message[1]
	self.current_game.roll_upper = message[2]
	self.current_game.cash_winnings = message[3]
	self.current_game.channel_const = message[4]
	self.current_game.addon_const = chat
	self.current_game.roll_range = "("..self.current_game.roll_lower.."-"..self.current_game.roll_upper..")"
	

	local player, realm = UnitName("player")
	if DEBUG then player = "DEBUG" end
	
	local valid_source = (sender ~= player) 
	if self.db.global.auto_pop and valid_source then
		self.ui.CDG_Frame:Show()
		local new_game_msg = "Roll: "..self.current_game.roll_range.."   Cash: "..self.current_game.cash_winnings
		self.ui.CDG_Frame:SetStatusText(new_game_msg)
	end
	
	if DEBUG then
		self:Print(self.current_game.roll_lower)
		self:Print(self.current_game.roll_upper)
		self:Print(self.current_game.channel_const)
		self:Print(self.current_game.roll_range)
	end
	
end

function CDGClient:NewRollsCallback(...)
    -- self.current_game.accepting_rolls = true
end

function CDGClient:GameResultsCallback(...)
	self.current_game.accepting_rolls = false
	local callback = select(1, ...)
	local message = select(2, ...)
	local chat = select(3, ...)
	local sender = select(4, ...)

	message = self:SplitString(message, "%S+")	
	
    self.current_game.winner = message[1]
	self.current_game.loser = message[2]
    self.current_game.cash_winnings = message[3]
	
	local results_msg = self.current_game.cash_winnings.."g "..self.current_game.loser.." = > "..self.current_game.winner
	self.ui.CDG_Frame:SetStatusText(results_msg)
	
end

-- Button Interaction Callbacks (State and Settings)
-- ==================================================== 
function CDGClient:RollForMe()
	RandomRoll(self.current_game.roll_lower, self.current_game.roll_upper)
end

function CDGClient:EnterForMe()
	if self.current_game then 
		SendChatMessage("1", self.current_game.channel_const)
	end
end

function CDGClient:TradeOpen()
    self.current_game.trade_open = true
end

function CDGClient:OpenTradeWinner()
	self:RegisterEvent("TRADE_SHOW", function() self:TradeOpen() end)
    if (self.current_game.trade_open) then
        local copper = self.current_game.cash_winnings * 100 * 100 
        SetTradeMoney(copper)

        local sys_msg = "You added "..self.current_game.cash_winnings.." gold to the trade window."
        SendSystemMessage(sys_msg)

        self.current_game.trade_open = false
		if DEBUG then self:Print(copper) end
    else
        InitiateTrade(self.current_game.winner)
        
    end
end

-- UI ELEMENTS 
-- ======================================================
function CDGClient:ConstructUI()
	
	-- Settings to be used -- 
	local cdg_ui_elements = {
		-- Main Box Frame -- 
		main_frame = {
			width = 335,
			height = 95
		},
		
		-- Order in which the buttons are layed out -- 
		button_index = {
			"enter_for_me",
			"roll_for_me",
			"open_trade"
		},
		
		-- Button Definitions -- 
		buttons = {
			roll_for_me = {
				width = 97,
				label = "Roll",
				click_callback = function() self:RollForMe() end
			},
			enter_for_me = {
				width = 97,
				label = "Enter",
				click_callback = function() self:EnterForMe() end
			},
			open_trade = {
				width = 97,
				label = "Payout",
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
	self.ui.CDG_Frame:EnableResize(false)
	self.ui.CDG_Frame:SetCallback("OnClose", function() self:HideUI() end)
	-- self.ui.CDG_Frame:DisableResize()
	-- self.ui.CDG_Frame:SetUserPlaced()
	
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
function CDGClient:SplitString(str, pattern)
	local ret_list = {}
	local index = 1
	for token in string.gmatch(str, pattern) do
		ret_list[index] = token
		index = index + 1
	end
	return ret_list
end

