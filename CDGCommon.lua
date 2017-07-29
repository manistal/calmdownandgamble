-- Common code betwene the Client and Master like slash commands and minimap button

-- Global 3 way UI Toggler 
-- ==========================
local ToggleClientAndCasino = function() 
    if (CalmDownandGamble.db.global.window_shown) then
        CalmDownandGamble:HideUI()
        CDGClient:ShowUI()
    elseif (CDGClient.db.global.window_shown) then
        CDGClient:HideUI()
    else
        CalmDownandGamble:ShowUI()
    end
end

-- MiniMap Icon Definition
-- =========================
function CalmDownandGamble:ConstructMiniMapIcon() 
	self.minimap = { }
	self.minimap.icon_data = LibStub("LibDataBroker-1.1"):NewDataObject("CalmDownandGambleIcon", {
		type = "data source",
		text = "Calm Down and Gamble!",
		icon = "Interface\\Icons\\INV_Misc_Coin_02",
		OnClick = ToggleClientAndCasino,

		OnTooltipShow = function(tooltip)
			tooltip:AddLine("Calm Down and Gamble!",1,1,1)
			tooltip:Show()
		end,
	})

	self.minimap.icon = LibStub("LibDBIcon-1.0")
	self.minimap.icon:Register("CalmDownandGambleIcon", self.minimap.icon_data, self.db.global.minimap)
end

-- Debug Setup
-- ==================
function CalmDownandGamble:PrintDebug(msg)
	if self.DEBUG_ENABLED then self:Print("[CDG_DEBUG] "..msg) end
end

-- Custom Channel Handling
-- ==========================
function CalmDownandGamble:GetCustomChannelName() 
    -- Figure out the Channel Name
    guildName, guildRankName, guildRankIndex = GetGuildInfo("player")
    guildName = string.gsub(guildName, "%s+", "")
    channel_name = guildName.."Gambling"
    return channel_name
end

function CalmDownandGamble:JoinCustomChannel() 
    channel_name = self:GetCustomChannelName()

    -- Joining a channel without the slash command is wonky, so kind've abusing the slashcmd list
    SlashCmdList["JOIN"](channel_name)
    channel_number, channel_string, instanceID = GetChannelName(channel_name)

    -- Update our references so we send chat to the right place
    self.db.global.custom_channel_index = channel_number
    CDGClient.db.global.custom_channel_index = channel_number

    -- Add it to the consts table so we can see it     
    custom_channel = { 
        label = "CDG Chat", 
        const = "CHANNEL", 
        addon_const = "GUILD", 
        callback = "CHAT_MSG_CHANNEL", 
        callback_leader = nil 
    }
    table.insert(self.chat.CHANNEL_CONSTS, custom_channel)

    -- Remove it on logout/reload to avoid conflicts
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "LeaveCustomChannel")
end

function CalmDownandGamble:LeaveCustomChannel() 
    channel_name = self:GetCustomChannelName()

    -- Leave and remove the channel from the index
    LeaveChannelByName(channel_name)
    self.chat.CHANNEL_CONSTS[#self.chat.CHANNEL_CONSTS] = nil
    self.db.global.custom_channel_index = nil
    CDGClient.db.global.custom_channel_index = nil
end

-- Slash Commands
-- ================

-- Handler Needed to support multiargument commands 
function CalmDownandGamble:SlashCommandHandler(...)
    command = select(1, ...)

    if (command == "") then 
        ToggleClientAndCasino()

    elseif (command == "ban") then 
        player = select(2, ...)
	    self.db.global.ban_list[player] = true

    elseif (command == "unban") then 
        player = select(2, ...)
	    self.db.global.ban_list[player] = nil

    elseif (command == "resetStats") then 
        self.db.global.rankings = {}

    elseif (command == "resetBans") then 
        self.db.global.ban_list = {}

    elseif (command == "autoPop") then 
        CDGClient.db.global.auto_pop = not CDGClient.db.global.auto_pop

    elseif (command == "debug") then 
        self.DEBUG_ENABLED = not self.DEBUG_ENABLED

    elseif (command == "joinChat") then 
        self:JoinCustomChannel()

    elseif (command == "leaveChat") then 
        self:LeaveCustomChannel()

    end
end

-- Called from constructor of main addon
function CalmDownandGamble:RegisterSlashCommands() 
	self:RegisterChatCommand("cdg", "SlashCommandHandler")

    -- Legacy Support - TODO: Remove
	self:RegisterChatCommand("cdgm", "ShowUI")
end