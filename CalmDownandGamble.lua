

-- Declare the new addon and load the libraries we want to use -- 
CalmDownandGamble = LibStub("AceAddon-3.0"):NewAddon("CalmDownandGamble", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "AceSerializer-3.0")
local CalmDownandGamble	= LibStub("AceAddon-3.0"):GetAddon("CalmDownandGamble")
local AceGUI = LibStub("AceGUI-3.0")

-- Basic Adddon Initialization stuff, virtually inherited functions -- 
-- ================================================================ -- 

-- CONSTRUCTOR -- 
function CalmDownandGamble:OnInitialize()
    -- Set up a database so we can save results -- 
	self:Print("Load Begin")

	self:RegisterChatCommand("cdgwoo", "ShowUI")
	self:RegisterChatCommand("cdgroll", "GenerateRoll")
	self:RegisterChatCommand("cdgleave", "LeaveGame")
    self.db = LibStub("AceDB-3.0"):New("CalmDownandGambleDB")
	self:ConstructUI()

	self:Print("Load Complete!!")

end

-- INIT FOR ENABLE -- 
function CalmDownandGamble:OnEnable()
    
	

end

-- DESTRUCTOR -- 
function CalmDownandGamble:OnDisable()
end

-- Corresponding Chat command funcs -- 
function CalmDownandGamble:GenerateRoll()
end

function CalmDownandGamble:ShowUI()
	self:Print("HAHAH");
	self.ui.CDG_Frame:Hide()
end

function CalmDownandGamble:LeaveGame()
end

function CalmDownandGamble:ButtonCallback()
	self:Print("DID IT WORK")
end

-- UI ELEMENTS --
-- ============================== -- 
function CalmDownandGamble:ConstructUI()
	
	-- Settings to be used -- 
	local cdg_ui_elements = {
		
		main_frame = {
			width = 450,
			height = 150
		},
		
		buttons = {
			accept_entries = {
				width = 125,
				label = "Accept Entries",
				click_callback = function() self:ButtonCallback() end
			},
			print_ban_list = {
				width = 125,
				label = "Print Bans",
				click_callback = function() self:ButtonCallback() end
			},
			print_stats_table = {
				width = 125,
				label = "Print Stats",
				click_callback = function() self:ButtonCallback() end
			},
			roll_for_me = {
				width = 125,
				label = "Roll For Me",
				click_callback = function() self:ButtonCallback() end
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
	self.ui.CDG_Frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	self.ui.CDG_Frame:SetStatusTable(cdg_ui_elements.main_frame)
	

	-- Set up Buttons -- 
	for button_name, button_settings in pairs(cdg_ui_elements.buttons) do
		self.ui[button_name] = AceGUI:Create("Button")
		self.ui[button_name]:SetText(button_settings.label)
		self.ui[button_name]:SetWidth(button_settings.width)
		self.ui[button_name]:SetCallback("OnClick", button_settings.click_callback)
		
		self.ui.CDG_Frame:AddChild(self.ui[button_name])
	end
	
	
	--[[
	local editbox = AceGUI:Create("EditBox")
	editbox:SetLabel("Insert text:")
	editbox:SetWidth(200)
	CDG_Frame:AddChild(editbox)

	local button = AceGUI:Create("Button")
	button:SetText("Click Me!")
	button:SetWidth(200)
	CDG_Frame:AddChild(button)
	--]]
end












