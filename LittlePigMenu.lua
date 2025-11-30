LittlePigOptions = {
	{
		text = "Chat Filter",
		checkBoxes = {
			{ text = "Uncommon Roll", var = "SPAM_UNCOMMON", tooltip = "Hide uncommon (green) loot roll messages." },
			{ text = "Rare Roll", var = "SPAM_RARE", tooltip = "Hide rare (blue) loot roll messages." },
			{ text = "Epic Roll", var = "SPAM_EPIC", tooltip = "Hide epic (purple) loot roll messages." },
			{ text = "Poor-Common Loot", var = "SPAM_LOOT", tooltip = "Hide grey and white loot roll messages." },
		},
	},
	{
		text = "World Chat Mute",
		checkBoxes = {
			{ text = "Dungeons", var = "WORLDDUNGEON", tooltip = "Mute world chat while in dungeons.", setFunc = LittlePig_ZoneCheck },
			{ text = "Raids", var = "WORLDRAID", tooltip = "Mute world chat while in raids.", setFunc = LittlePig_ZoneCheck },
			{ text = "Battlegrounds", var = "WORLDBG", tooltip = "Mute world chat while in battlegrounds.", setFunc = LittlePig_ZoneCheck },
			{ text = "Mute Permanently", var = "WORLDUNCHECK", tooltip = "Mute world chat for good...", setFunc = LittlePig_ZoneCheck }
		},
	},
	{
		text = "Salvation Remover",
		exclusive = true,
		checkBoxes = {
			{ text = ALWAYS, var = "SALVA", value = 1, tooltip = ALWAYS, setFunc = LittlePig_CheckSalvation },
			{ text = "Smart", var = "SALVA", value = 2, tooltip = "Smart", tooltipSub = "Auto remove if:\nYou are Warrior and have shield equipped,\nYou are Druid in Bear Form,\nYou are Paladin with Righteous Fury.", setFunc = LittlePig_CheckSalvation },
		},
	},
	{
		text = MISCELLANEOUS,
		checkBoxes = {
			{ text = "Mana Buffs Remover", var = "REMOVEMANABUFFS", tooltip = "Auto remove from Warrior or Rogue buffs: Blessing of Wisdom / Arcane Intellect / Prayer of Spirit.", setFunc = LittlePig_CheckManaBuffs },
			{ text = "Loot Window Auto Position", var = "LOOT", tooltip = "Loot Window Auto Position", tooltipSub = "Position the loot window under the mouse cursor."},
			{ text = "Resurrect Auto Accept", var = "REZ", tooltip = "Instance Resurrection Auto Accept", tooltipSub = "Auto accept resurrection in raids, dungeons and battlegrounds if player resurrecting you is out of combat." },
		},
	},
}

function LittlePig_CreateOptionsFrame()
	-- Option Frame
	local frame = CreateFrame("Frame", "LittlePigOptionsFrame", UIParent)
	tinsert(UISpecialFrames,"LittlePigOptionsFrame")
	frame:SetFrameStrata("DIALOG")
	frame:SetWidth(240)
	frame:SetHeight(340)
	frame:SetPoint("CENTER", UIParent, 0, 80)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 }
	})
	frame:SetBackdropColor(0, 0, 0, .8)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(false)
	frame:RegisterForDrag("LeftButton")
	frame:Hide()
	frame:SetScript("OnMouseDown", function()
		if arg1 == "LeftButton" and not this.isMoving then
			this:StartMoving();
			this.isMoving = true;
		end
	end)
	frame:SetScript("OnMouseUp", function()
		if arg1 == "LeftButton" and this.isMoving then
			this:StopMovingOrSizing();
			this.isMoving = false;
		end
	end)
	frame:SetScript("OnHide", function()
		if this.isMoving then
			this:StopMovingOrSizing();
			this.isMoving = false;
		end
	end)

	-- MenuTitle Frame
	local texture_title = frame:CreateTexture("LittlePigOptionsFrameTitle")
	texture_title:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header", true);
	texture_title:SetWidth(296)
	texture_title:SetHeight(58)
	texture_title:SetPoint("CENTER", frame, "TOP", 0, -20)

	frame.texture_title = texture_title

	-- MenuTitle FontString
	local fs_title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	local LP_VERSION = GetAddOnMetadata("LittlePig", "Version")
	fs_title:SetPoint("CENTER", frame.texture_title, "CENTER", 0, 12)
	fs_title:SetText("LittlePig Options")
	
	local versionText = frame:CreateFontString("$parentVersionText", "ARTWORK", "GameFontNormalSmall")
	versionText:SetPoint("TOPLEFT", frame, 20, -20)
	versionText:SetText("version: "..LP_VERSION)

	frame.fs_title = fs_title

	-- Close Setting Window Button
	local btn_close = CreateFrame("Button", "LittlePigOptionsFrameCloseButton", frame, "UIPanelCloseButton")
	btn_close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -12)
	btn_close:SetWidth(32)
	btn_close:SetHeight(32)
	
	frame.btn_close = btn_close

	frame.btn_close:SetScript("OnClick", function()
		this:GetParent():Hide()
	end)

	local height = 16
	local insetLeft = 30
	local insetTop = -32
	local columnWidth = 240
	local offsetX, offsetY = insetLeft, insetTop
	local index = 1
	for i = 1, getn(LittlePigOptions) do
		if i == 10 then
			offsetX, offsetY = insetLeft + columnWidth, insetTop
		end
		
		-- Check box group title
		local fontString = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		fontString:SetPoint("TOPLEFT", frame, "TOPLEFT", offsetX, offsetY - 10)
		fontString:SetTextColor(1, 1, 1, 1)
		fontString:SetText(LittlePigOptions[i].text)
		
		offsetY = offsetY - height - 5
		
		for j = 1, getn(LittlePigOptions[i].checkBoxes) do
			local checkBox = CreateFrame("CheckButton", "$parentCheckBox"..index, frame, "UICheckButtonTemplate")
			local checkBoxText = _G[checkBox:GetName().."Text"]
			
			checkBox:SetPoint("TOPLEFT", frame, "TOPLEFT", offsetX + 5, offsetY)
			checkBox:SetWidth(22)
			checkBox:SetHeight(22)
			checkBoxText:SetText(LittlePigOptions[i].checkBoxes[j].text)
			checkBox.textR, checkBox.textG, checkBox.textB = checkBoxText:GetTextColor()
			
			-- Makes text clickable
			checkBox:SetHitRectInsets(0, -(checkBoxText:GetWidth() + 5), 0, 0)
			
			LittlePigOptions[i].checkBoxes[j].frame = checkBox
			checkBox.tooltip = LittlePigOptions[i].checkBoxes[j].tooltip
			checkBox.tooltipSub = LittlePigOptions[i].checkBoxes[j].tooltipSub
			checkBox.var = LittlePigOptions[i].checkBoxes[j].var
			checkBox.value = LittlePigOptions[i].checkBoxes[j].value
			checkBox.exclusive = LittlePigOptions[i].exclusive
			checkBox.checkBoxes = LittlePigOptions[i].checkBoxes
			checkBox.setFunc = LittlePigOptions[i].checkBoxes[j].setFunc

			checkBox:SetScript("OnShow", function()
				local value = this.value or true
				if LPCONFIG[this.var] == value then
					this:SetChecked(true)
					if this.exclusive then
						for _, data in pairs(this.checkBoxes) do
							if data.frame ~= this then
								data.frame:SetChecked(false)
							end
						end
					end
				else
					this:SetChecked(false)
				end
			end)

			checkBox:SetScript("OnClick", function()
				if this.exclusive then
					for _, data in pairs(this.checkBoxes) do
						if data.frame ~= this then
							data.frame:SetChecked(false)
						end
					end
				end
				local value = this.value or true
				if type(value) == "boolean" then
					LPCONFIG[this.var] = not LPCONFIG[this.var]
					-- this:SetChecked(LPCONFIG[this.var])
				elseif type(value) == "number" then
					LPCONFIG[this.var] = this:GetChecked() and this.value or nil
					-- this:SetChecked(LPCONFIG[this.var] == 0 and true or LPCONFIG[this.var])
				end
				if this.setFunc then
					this.setFunc()
				end
				PlaySound("igMainMenuOptionCheckBoxOn")
			end)

			checkBox:SetScript("OnEnter", function()
				_G[this:GetName().."Text"]:SetTextColor(1, 1, 1)
				if this.tooltip then
					GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT")
					GameTooltip:SetBackdropColor(.01, .01, .01, .91)
					GameTooltip:SetText(this.tooltip, nil, nil, nil, 1, true)
					if this.tooltipSub then
						GameTooltip:AddLine(this.tooltipSub, 1, 1, 1, true)
					end
					GameTooltip:Show()
				end
			end)

			checkBox:SetScript("OnLeave", function()
				_G[this:GetName().."Text"]:SetTextColor(this.textR, this.textG, this.textB)
				GameTooltip:Hide()
			end)

			offsetY = offsetY - height
			index = index + 1
		end
	end
end
