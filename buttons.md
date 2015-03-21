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

#general example of how a button works, including the script call and the anchors. This example is the Roll button!