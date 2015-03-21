Line 4, <Frame name="CrossGambling_Frame" parent="UIParent" toplevel="true" movable="true" enableMouse="true">
Main frame, everything sits inside this.

Line 11, <Backdrop bgFile="Interface\DialogFrame\UI-DialogBox-Background" edgeFile="Interface\DialogFrame\UI-DialogBox-Border" tile="true">
Adds the border to the window, as well as the grey background

Line 22, <Layers> is used for showing the name of the addon and the version (this is mostly useless lol)

Close button, <Button name="CrossGambling_Close" inherits="UIPanelCloseButton"> 
easy as pie here, boys. anchor it awaaaaaay

<Button name="CrossGambling_ROLL_Button" inherits="OptionsButtonTemplate" movable="true" text="Roll!">
				<Anchors>
					<Anchor point="BOTTOM">
						<Offset x="-105" y="35" />
					</Anchor>
				</Anchors>
				<Scripts>
					<OnClick>
						CrossGambling_OnClickROLL();
					</OnClick>
				</Scripts>
			</Button>

# ^ general example of how a button works, including the script call and the anchors. This example is the Roll button!


#Example of the use of the edit box to determine the roll amount. TGhis is optional, could be (should be) worked around, could really be replaced with a simple slash command)
				<Layers>
					<Layer level="BACKGROUND">
						<Texture name="Texture2" file="Interface\ChatFrame\UI-ChatInputBorder-Right">
							<Size>
								<AbsDimension x="75" y="32" />
							</Size>
							<Anchors>
								<Anchor point="RIGHT">
									<Offset x="9" />
								</Anchor>
							</Anchors>
							<TexCoords left="0.7" right="1" top="0" bottom="1" />
						</Texture>
						<Texture name="Texture1" file="Interface\ChatFrame\UI-ChatInputBorder-Left">
							<Size>
								<AbsDimension x="75" y="32" />
							</Size>
							<Anchors>
								<Anchor point="LEFT">
									<Offset x="-14" />
								</Anchor>
							</Anchors>
							<TexCoords left="0" right="0.2" top="0" bottom="1" />
						</Texture>
					</Layer>
				</Layers>
				<Scripts>
          <OnLoad>
            CrossGambling_EditBox_OnLoad();
          </OnLoad>
					<OnEscapePressed>
						self:ClearFocus();
					</OnEscapePressed>
				</Scripts>
				<FontString inherits="ChatFontNormal" />
			</EditBox>