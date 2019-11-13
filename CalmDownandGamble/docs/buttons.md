#Roll Button

#This command will roll for the user. Uses function CDG_OnClickROLL

			<Button name="CDG_ROLL_Button" inherits="OptionsButtonTemplate" movable="true" text="ROLL!">
				<Anchors>
					<Anchor point="BOTTOM">
						<Offset x="-105" y="35" />
					</Anchor>
				</Anchors>
				<Scripts>
					<OnClick>
						CDG_OnClickROLL();
					</OnClick>
				</Scripts>
			</Button>

			
#Entry button

#This button will notify users the game has begun and entries are now accepted. Should also announce game mode and wager.
#Button click executes CDG_OnClickEntry

			<Button name="CDG_Entry_Button" inherits="OptionsButtonTemplate" text="Entries">
				<Anchors>
					<Anchor point="BOTTOM">
						<Offset x="-105" y="75" />
					</Anchor>
				</Anchors>
				<Scripts>
					<OnClick>
						CDG_OnClickEntry();

					</OnClick>
				</Scripts>
			</Button>
			
	
#Last call button

#This button will shout 'Last call!' and then after 10 seconds, inform everyone that entries are closed and they can ROLL! 
#Clicking this button executes CDG_OnClickLASTCALL

 			<Button name="CDG_LASTCALL_Button" inherits="OptionsButtonTemplate" movable="true" text="Last Call">
				<Anchors>
					<Anchor point="BOTTOM">
						<Offset x="-105" y="55" />
					</Anchor>
				</Anchors>
				<Scripts>
					<OnClick>
						CDG_OnClickLASTCALL();
					</OnClick>
				</Scripts>
			</Button>
			
#X for the top right Corner?
			<Button name="CDG_Close" inherits="UIPanelCloseButton">
				<Anchors>
					<Anchor point="TOPRIGHT" relativeTo="CDG_Frame" relativePoint="TOPRIGHT">
						<Offset>
							<AbsDimension x="7" y="6"/>
						</Offset>
					</Anchor>
				</Anchors>
			</Button>		

#Stats Button

#This button will post the highest and lowest scores in chat, using command CDG_OnClickSTATS	

<Button name="CDG_STATS_Button" inherits="OptionsButtonTemplate" movable="true" text="Stats">
				<Anchors>
					<Anchor point="BOTTOM">
						<Offset x="105" y="35" />
					</Anchor>
				</Anchors>
				<Scripts>
					<OnClick>
						CDG_OnClickSTATS();
					</OnClick>
				<OnLoad>CDG_STATS_Button.tooltipText="Show's all user stats."</OnLoad>
				</Scripts>
			</Button>
			