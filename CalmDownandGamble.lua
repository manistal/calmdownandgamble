

-- Declare the new addon and load the libraries we want to use -- 
CalmDownandGamble = LibStub("AceAddon-3.0"):NewAddon("CalmDownandGamble", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", "AceSerializer-3.0")
local CalmDownandGamble	= LibStub("AceAddon-3.0"):GetAddon("CalmDownandGamble")


-- Basic Adddon Initialization stuff, virtually inherited functions -- 
-- ================================================================ -- 




-- CONSTRUCTOR -- 
function CalmDownandGamble:OnInitialize()
    -- Set up a database so we can save results -- 
	self:Print("Load Begin")

	self:RegisterChatCommand("cdgshow", "ShowUI")
	self:RegisterChatCommand("cdgroll", "GenerateRoll")
	self:RegisterChatCommand("cdgleave", "LeaveGame")
    self.db = LibStub("AceDB-3.0"):New("CalmDownandGambleDB")
	
	self:Print("Load Complete!!")

end

-- INIT FOR ENABLE -- 
function CalmDownandGamble:OnEnable()
    
	

end

-- DESTRUCTOR -- 
function CalmDownandGamble:OnDisable()
end


-- Some Util functions to clean up life -- 
-- =================================== -- 
function CalmDownandGamble:RegisterCDCallbacks()

end

-- Corresponding Chat command funcs -- 
function CalmDownandGamble:GenerateRoll()
end

function CalmDownandGamble:ShowUI(input)
	-- TODO -- Change this object name to match CalmDownandGamble in the XML
	CrossGambling_Frame:Show(); 
end

function CalmDownandGamble:LeaveGame()
end














