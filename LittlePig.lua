local _G = _G or getfenv(0)

-- Default SavedVariables
LPCONFIG = {}
LPCONFIG.WORLDDUNGEON = false       -- Mute Wolrd chat while in dungeons
LPCONFIG.WORLDRAID = false          -- Mute Wolrd chat while in raid
LPCONFIG.WORLDBG = false            -- Mute Wolrd chat while in battleground
LPCONFIG.WORLDUNCHECK = false       -- Mute Wolrd chat always
LPCONFIG.SPAM_UNCOMMON = false      -- Hide green items roll messages
LPCONFIG.SPAM_RARE = false          -- Hide blue items roll messages
LPCONFIG.SPAM_EPIC = false          -- Hide epic items roll messages
LPCONFIG.SPAM_LOOT = false          -- Hide grey and white roll messages
LPCONFIG.REZ = false                -- Auto accept resurrection while in raid, dungeon or bg if resurrecter is out of combat
LPCONFIG.SALVA = nil                -- [number or nil] Autoremove Blessing of Salvation
LPCONFIG.REMOVEMANABUFFS = false    -- Autoremove Blessing of Wisdom, Arcane Intellect, Prayer of Spirit from Warrior or Rogue

local Original_ChatFrame_OnEvent = ChatFrame_OnEvent;

local channelstatus = nil

local ScheduleFunction = {}
local ChatMessage = {{}, {}, INDEX = 1}

function LittlePig_OnLoad()
	ChatFrame_OnEvent = LittlePig_ChatFrame_OnEvent;
	
	SLASH_LITTLEPIG1 = "/lp";
	SLASH_LITTLEPIG2 = "/Littlepig";
	SlashCmdList["LITTLEPIG"] = LittlePig_Command;

	this:RegisterEvent("ADDON_LOADED")
	this:RegisterEvent("PLAYER_LOGIN")
	this:RegisterEvent("CHAT_MSG")
	this:RegisterEvent("RESURRECT_REQUEST")
	this:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	this:RegisterEvent("PLAYER_UNGHOST")
	this:RegisterEvent("PLAYER_AURAS_CHANGED")
	this:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
	this:RegisterEvent("UNIT_INVENTORY_CHANGED")
end

function LittlePig_Command()
	if LittlePigOptionsFrame:IsShown() then
		LittlePigOptionsFrame:Hide()
	else
		LittlePigOptionsFrame:Show()
	end
end

function LittlePig_OnEvent(event)
	if event == "ADDON_LOADED" and arg1 == "LittlePig" then
		this:UnregisterEvent("ADDON_LOADED")
		local title = GetAddOnMetadata("LittlePig", "Title")
		local version = GetAddOnMetadata("LittlePig", "Version")
		DEFAULT_CHAT_FRAME:AddMessage(title.." v"..version.."|cffffffff".." loaded, type".."|cff00eeee".." /lp".."|cffffffff for options")

	elseif event == "PLAYER_LOGIN" then
		LittlePig_CreateOptionsFrame()
		LittlePig_CheckSalvation();
		LittlePig_CheckManaBuffs();
		LittlePig_ZoneCheck();

	elseif event == "PLAYER_AURAS_CHANGED" then
		LittlePig_CheckSalvation()
		LittlePig_CheckManaBuffs()
	
	elseif event == "UNIT_INVENTORY_CHANGED" and LittlePig_PlayerClass("Warrior", "player") then
		LittlePig_CheckSalvation()

	elseif event == "UPDATE_BONUS_ACTIONBAR" and LittlePig_PlayerClass("Druid", "player") then
		LittlePig_CheckSalvation()
	
	elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_UNGHOST" then
		LittlePig_ZoneCheck()

	elseif event == "RESURRECT_REQUEST" and LPCONFIG.REZ then
		UIErrorsFrame:AddMessage(arg1.." - Resurrection")
		TargetByName(arg1, true)
		if GetCorpseRecoveryDelay() == 0 and (LittlePig_Raid() or LittlePig_Dungeon() or LittlePig_BG()) and UnitIsPlayer("target") and UnitIsVisible("target") and not UnitAffectingCombat("target") then
			AcceptResurrect()
			StaticPopup_Hide("RESURRECT_NO_TIMER");
			StaticPopup_Hide("RESURRECT_NO_SICKNESS");
			StaticPopup_Hide("RESURRECT");
		end
		TargetLastTarget();
	end
end

function LittlePig_Raid()
	local inInstance, instanceType = IsInInstance()
	return inInstance and instanceType == "raid"
end

function LittlePig_Dungeon()
	local inInstance, instanceType = IsInInstance()
	return inInstance and instanceType == "party"
end

function LittlePig_BG()
	local inInstance, instanceType = IsInInstance()
	return inInstance and instanceType == "pvp"
end

local process = function(ChatFrame, name)
    for index, value in ChatFrame.channelList do
        if strupper(name) == strupper(value) then
            return true
        end
    end
    return nil
end

function LittlePig_ZoneCheck()
	local leavechat = LPCONFIG.WORLDRAID and LittlePig_Raid() or LPCONFIG.WORLDDUNGEON and LittlePig_Dungeon() or LPCONFIG.WORLDBG and LittlePig_BG() or LPCONFIG.WORLDUNCHECK
	for i = 1, NUM_CHAT_WINDOWS do
		local ChatFrame = _G["ChatFrame"..i]
		if ChatFrame:IsVisible() and not UnitIsDeadOrGhost("player") then
			local id, name = GetChannelName("world")
			if id > 0 then
				if leavechat then
					if process(ChatFrame, name)  then
						ChatFrame_RemoveChannel(ChatFrame, name)
						channelstatus = true
						UIErrorsFrame:Clear();
						UIErrorsFrame:AddMessage("Leaving World")
					end
					return
				end
			end
			if (LPCONFIG.WORLDRAID or LPCONFIG.WORLDDUNGEON or LPCONFIG.WORLDBG) and not leavechat then
				local framename = ChatFrame:GetName()
				if id == 0 then
					UIErrorsFrame:Clear();
					UIErrorsFrame:AddMessage("Joining World");
					JoinChannelByName("world", nil, ChatFrame:GetID());
				else
					if (not process(ChatFrame, name) or channelstatus) and framename == "ChatFrame1" then
						ChatFrame_AddChannel(ChatFrame, name);
						UIErrorsFrame:Clear();
						UIErrorsFrame:AddMessage("Joining World");
						channelstatus = false
					end
				end
			end
		end
	end
end

function LittlePig_PlayerClass(class, unit)
	if class then
		local unit = unit or "player"
		local _, c = UnitClass(unit)
		if c then
			if string.lower(c) == string.lower(class) then
				return true
			end
		end
	end
	return false
end

function LittlePig_HasRighteousFury()
	if not LittlePig_PlayerClass("Paladin", "player") then 
		return false 
	end
	local counter = 0
	while GetPlayerBuff(counter) >= 0 do
		local index, untilCancelled = GetPlayerBuff(counter)
		if untilCancelled == 1 then
			local texture = GetPlayerBuffTexture(index)
			if texture and string.find(texture, "Spell_Holy_SealOfFury") then
				return true
			end
		end
		counter = counter + 1
	end
	return false
end

function LittlePig_IsBearForm()
	for i = 1 , GetNumShapeshiftForms() do
		local _, name, isActive = GetShapeshiftFormInfo(i);
		if isActive and LittlePig_PlayerClass("Druid", "player") and (name == "Bear Form" or name == "Dire Bear Form") then
			return true
		end
	end
	return false
end

function LittlePig_IsShieldEquipped()
	local link = GetInventoryItemLink("player", 17)
	local _, _, id = string.find(link or "", "item:(%d+)")
	id = tonumber(id)
	if id then
		local _, _, _, _, _, _, _, invType = GetItemInfo(id)
		if invType == "INVTYPE_SHIELD" then
			return true
		end
	end
	return false
end

local salvationbuffs = {
	"Spell_Holy_SealOfSalvation",
	"Spell_Holy_GreaterBlessingofSalvation"
}
function LittlePig_CheckSalvation()
	if not LPCONFIG.SALVA then
		return
	end
	if not (LPCONFIG.SALVA == 1 or (LPCONFIG.SALVA == 2 and (LittlePig_IsShieldEquipped() and LittlePig_PlayerClass("Warrior", "player") or LittlePig_IsBearForm() or LittlePig_HasRighteousFury()))) then
		return
	end
	local counter = 0
	while GetPlayerBuff(counter) >= 0 do
		local index, untilCancelled = GetPlayerBuff(counter)
		if untilCancelled ~= 1 then
			local texture = GetPlayerBuffTexture(index)
			if texture then  -- Check if texture is not nil
				local i = 1
					while salvationbuffs[i] do
						if string.find(texture, salvationbuffs[i]) then
						CancelPlayerBuff(index);
						UIErrorsFrame:Clear();
						UIErrorsFrame:AddMessage("Salvation Removed");
						return
					end
					i = i + 1
				end
			end
		end
		counter = counter + 1
	end
end

local manabuffs = {
	"Spell_Holy_SealOfWisdom",
	"Spell_Holy_GreaterBlessingofWisdom",
	"Spell_Holy_ArcaneIntellect",
	"Spell_Holy_MagicalSentry",
	"Spell_Holy_PrayerofSpirit",
	"Spell_Holy_DivineSpirit"
}
function LittlePig_CheckManaBuffs()
	if not LPCONFIG.REMOVEMANABUFFS then
		return
	end
	if LittlePig_BG() then
		return
	end
	if not LittlePig_PlayerClass("Warrior", "player") then 
		return
	end
	if not LittlePig_PlayerClass("Rogue", "player") then 
		return
	end
	local counter = 0
	while GetPlayerBuff(counter) >= 0 do
		local index, untilCancelled = GetPlayerBuff(counter)
		if untilCancelled ~= 1 then
			local texture = GetPlayerBuffTexture(index)
			if texture then  -- Check if texture is not nil
				local i = 1
				while manabuffs[i] do
					if string.find(texture, manabuffs[i]) then
						CancelPlayerBuff(index);
						UIErrorsFrame:Clear();
						UIErrorsFrame:AddMessage("Intellect or Wisdom or Spirit Removed");
						return
					end
					i = i + 1
				end
			end
		end
		counter = counter + 1
	end
end

function LittlePig_ChatFrame_OnEvent(event)
	if event == "CHAT_MSG_LOOT" or event == "CHAT_MSG_MONEY" then
		local check_zg_aq = string.find(arg1 ,"Bijou") or string.find(arg1 ,"Coin") or string.find(arg1 ,"Idol") or string.find(arg1, "Scarab")
		local check_green = LPCONFIG.SPAM_UNCOMMON and string.find(arg1 ,"1eff00")
		local check_blue = LPCONFIG.SPAM_RARE and string.find(arg1 ,"0070dd")
		local check_epic = LPCONFIG.SPAM_EPIC and string.find(arg1 ,"a335ee")
		local check_white = LPCONFIG.SPAM_LOOT and (string.find(arg1 ,"9d9d9d") or string.find(arg1 ,"ffffff"))
		local check_money = LPCONFIG.SPAM_LOOT and string.find(arg1 ,"Your share of the loot")

		local check_you = string.find(arg1 ,"You") or string.find(arg1 ,"won") or string.find(arg1 ,"receive")
		
		if (not check_you and (check_green or check_blue or check_epic or check_white)) or check_money or check_zg_aq then
			return
		end
	end

    -- suppress BigWigs spam
	if event == "CHAT_MSG_SAY" and string.find(arg1 or "" ,"^Casted %u[%a%s]+ on %u[%a%s]+") then
        return
    end

	-- supress #showtooltip spam
	if string.find(arg1 or "" , "^#showtooltip") then
		return
	end
	
	Original_ChatFrame_OnEvent(event);
end
