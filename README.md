# Calm Down and Gamble!
    
When you have downtime between wipes, what do you do? Calm Down. And Gamble.     
     
Authors: [Calm Down] US-Magtheridon - Gambling guild with a raiding problem.    
Curse Download Page: http://mods.curse.com/addons/wow/calm-down-and-gamble    
Curse Project Page: http://wow.curseforge.com/addons/calm-down-and-gamble/    
			

BaseGameType
	Label (__name__)
		- Name of the game
	Init (__init__)
		- Lays out the rules of the game
	Evaulate (__sort__)
		- Returns an ordered dict of Players: Score
	Payout (__pay__)
		- Returns Winner, Loser, Payout
		
	Player 
		Name
		Realm
		Roll
		Score
		__string__
			returns print message for win/lose


XML
	- <scriptfile> 
		- CDGServer
		- CDGClient
		- CDGYahtzee
		- CDGHighLow
		- CDGetc
		
		
		
		
