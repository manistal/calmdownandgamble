-- Common code betwene the Client and Master like slash commands and minimap button

-- Global 3 way UI Toggler 
-- ==========================
local ToggleClientAndCasino = function() 
    if (CDGClient.db.global.window_shown) then
        CDGClient:ToggleClient()
    elseif (CalmDownandGamble.db.global.window_shown) then
        CalmDownandGamble:HideUI()
    else
        CDGClient:ShowUI()
    end
end

function CalmDownandGamble:ToggleCasino() 
    CalmDownandGamble:HideUI()
    CDGClient:ShowUI()
end

function CDGClient:ToggleClient() 
    CDGClient:HideUI()
    CalmDownandGamble:ShowUI()
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

function CalmDownandGamble:JoinCustomChannel(channel_name) 
    -- Only if we're not only in a channel 
    if (self.db.global.custom_channel.index) then return end
    if (channel_name == nil) then channel_name = self:GetCustomChannelName() end

    -- Joining a channel without the slash command is wonky, so kind've abusing the slashcmd list
    SlashCmdList["JOIN"](channel_name)
    channel_number, channel_string, instanceID = GetChannelName(channel_name)

    -- Update our references so we send chat to the right place
    self.db.global.custom_channel.index = channel_number
    self.db.global.custom_channel.name = channel_name

    -- Remove it on logout/reload to avoid conflicts
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "LeaveCustomChannel")
end

function CalmDownandGamble:LeaveCustomChannel() 
    LeaveChannelByName(self.db.global.custom_channel.name)
    self.db.global.custom_channel.index = nil
    self.db.global.custom_channel.name = ""
end

function CalmDownandGamble:PrintSlashCommandHelp()
    self:Print("CalmDown and Gamble Slash Commands: ")
    self:Print(" /cdg <command> ")
    self:Print("    <no command>  - Toggles UI like the minimap button does")
    self:Print("    ban <player> - Bans player from entering CDG")
    self:Print("    unban <player> - Unbans player")
    self:Print("    resetStats - Clears hall of fame/shame")
    self:Print("    resetBans - Clears all bans ")
    self:Print("    auto - Toggles auto activate of rolling UI")
    self:Print("    join - Join custom gambling channel for your guild")
    self:Print("    leave - Leave custom gambling channel")
end

-- Slash Commands
-- ================

-- Handler Needed to support multiargument commands 
function CalmDownandGamble:SlashCommandHandler(...)
    command_args = self:SplitString(select(1, ...), "%S+")
    command = command_args[1]

    if (command == nil) then 
        ToggleClientAndCasino()

    elseif (command == "ban") then 
        player = command_args[2]
	    self.db.global.ban_list[player] = true

    elseif (command == "unban") then 
        player = command_args[2]
	    self.db.global.ban_list[player] = nil

    elseif (command == "resetStats") then 
        self.db.global.rankings = {}

    elseif (command == "resetBans") then 
        self.db.global.ban_list = {}

    elseif (command == "stats") then 
        self:PrintRanklist()

    elseif (command == "auto") then 
        CDGClient.db.global.auto_pop = not CDGClient.db.global.auto_pop
        if CDGClient.db.global.auto_pop then 
            self:Print("Enabled auto show of rolling UI.")
        else
            self:Print("Disabled auto show of rolling UI.")
        end

    elseif (command == "debug") then 
        self.DEBUG_ENABLED = not self.DEBUG_ENABLED

    elseif (command == "join") then 
        channel_name = command_args[2]
        self:JoinCustomChannel(channel_name)

    elseif (command == "leave") then 
        self:LeaveCustomChannel()

    elseif (command == "help") then
        self:PrintSlashCommandHelp()

    else 
        self:Print("Unrecognized CDG Slash Command: ")
        self:Print(command)
        self:Print("Use /cdg help for more information.")

    end
end

-- Called from constructor of main addon
function CalmDownandGamble:RegisterSlashCommands() 
	self:RegisterChatCommand("cdg", "SlashCommandHandler")

    -- Legacy Support - TODO: Remove
	self:RegisterChatCommand("cdgm", "ShowUI")
end