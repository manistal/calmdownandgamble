## TextBox 
  OnEnterPressed(text) -- Set the CDG Value for the Currency Amount


## Buttons
  OnClick() -- No args

  ### CallEntries 
    -- Print a message to the current chat context asking for entries
    -- Register Event Callback Listener for Entries

  ### StartRolls 
    -- Print message to start rolls with /roll command 
    -- Register Event Callback listener for Rolls

  ### LastCall 
    -- If no roll active, print last call for entry message and start timer
    -- If roll active, print who still needs to roll

  ### RollForMe
    -- Roll with the correct roll command

  ### Enter Me
    -- Add entry (1 in chat?) in the current chat context

  ### Print Stats
    -- Print rankings table in current chat context
  
  ## Print Bans
    -- Print Bans in the current chat context
  
  ## Chat Button
    -- Toggle between different chat contexts

  ## Reset
    -- End the current game


## Chat Events

  ### Rolls
    -- Needs to always be registered
    -- Event is: CHAT_MSG_SYSTEM


