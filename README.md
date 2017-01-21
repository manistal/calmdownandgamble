# Calm Down and Gamble!
    
When you have downtime between wipes, what do you do? Calm Down. And Gamble.     
     
Authors: [Calm Down] US-Magtheridon - Gambling guild with a raiding problem.    
Curse Download Page: http://mods.curse.com/addons/wow/calm-down-and-gamble    
Curse Project Page: http://wow.curseforge.com/addons/calm-down-and-gamble/    


Base Class - Inside namespace CalmDownandgamble
	Game
		GameType
			Label (__name__)
				- Name of the game
			Init (__init__)
				- Lays out the rules of the game
			Evaulate (__play__)
				- Figures out who won and who lost
	
		start_game()
			- Inits everything, sends out "gamestart" signal to clients
			- Inits the game mode, players, etc
		
		start_rolls() 
			- Inits the game itself, pulls in all client rolls
			
		evaluate_game()
			- Calls game when all rolls are recieved
			
		log_results()
			- update the scoreboard
			
		end_game() 
			- clean up clear everything
	
	
XML
	- <scriptfile> 
		- CDGServer
		- CDGClient
		- CDGYahtzee
		- CDGHighLow
		- CDGetc
		
		
		
		
