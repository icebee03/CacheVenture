# THIS FILE is "tutorial_level_blocks_associativity.gd"
# THE FIRST TUTORIAL LEVEL

extends Node2D

## Time between spawn and cache contact
@export var pathSpeed: float = 1.0

# For color-setting the cache concepts
@export var color :Color
var blocknumber_col :String = "#3881db"
var blocksize_col :String = "#d6ce38"
var associativity_col :String = "#4da86f"
var hit_col = "#00da00"
var miss_col = "#d63134"

var addressList : Array[String] = ["0x1228", "0x122c", "0x1230", "0x1234", "0x1238", "0x123c", "0x1240", 
"0x1244", "0x1248", "0x124c", "0x1250", "0x1254", "0x1258", "0x125c", "0x1260", "0x1264"] 
var addressIndex : int = 0				# Use this to iterate over the above list, while clicking through the tutorial

#--- for score calculation ---
var totalAccessCount:int = 0
var hitCount:int = 0
var hitRate:float = 0.0				# in %
var missCount:int = 0
var missRate:float = 0.0				# in %

@onready var cache :Cache = $Cache
@onready var hitbox :CollisionShape2D = $Cache/Hitbox/CollisionShape2D
@onready var path: Path2D = $PathToCache
@onready var the_memory :TheMemory = $"The Memory"
@onready var pauseMenu = $"Pause Menu"
@onready var stagePassedMenu = $"Stage Passed Menu"
@onready var gameOverMenu = $"Game Over Menu"
@onready var upgradeMenu = $"Upgrade Menu"
@onready var stageProgressBar = $StageProgressBar
@onready var stageLabel = $StageLabel

# Timers for all different stages
var current_stage : int = 1
@onready var stage1Timer = $Stage1Timer
@onready var stage2Timer = $Stage2Timer
@onready var stageTimers = [null, stage1Timer, stage2Timer]


# For tutorial pacing and storytelling:
## Counts how many times "Continue" was pressed to advance in the tutorial accordingly the next time it is pressed
var continueCount = 0
@onready var continueButton = $ContinueButton
@onready var dialogueBox = $PanelContainer/HBoxContainer/DialogueBox
@onready var dialoguePanel = $PanelContainer


func _ready() -> void:
	_fit_hitbox_to_cache()
	pathSpeed = pathSpeed * 3		# Half-speed animation for first access
	
	$HUD/LoopTimerLabel.visible = false			# not relevant to this scene
	$"HUD/Speed Controls".visible = false
	$HUD/ChatLogControl.visible = false
	$HUD/ScoreLabel.visible = false
	
	Global.tutorial1Stats["coins"] = 0
	Global.tutorial1Stats["max_coins"] = 0
	Global.tutorial1Stats["blocknumber"] = cache.blockNumber
	Global.tutorial1Stats["blocksize"] = cache.blockSize
	Global.tutorial1Stats["associativity"] = cache.associativityDegree
	
	for u in Global.tutorial1Upgrades:
		if (u["type"]=="Block Number" and not u["quantity"]==cache.blockNumber): 
			u["unlocked"] = false
			u["bought"] = false
		elif (u["type"]=="Block Size" and not u["quantity"]==cache.blockSize): 
			u["unlocked"] = false
			u["bought"] = false
		elif (u["type"]=="Associativity" and not u["quantity"]==cache.associativityDegree): 
			u["unlocked"] = false
			u["bought"] = false
		else:
			u["unlocked"] = true
			u["bought"] = true 
			u["starter"] = true
	
	$Cache/Hitbox.area_entered.connect(_on_cache_hitbox_area_entered)		# Connect Hitbox signal to sorting method
	cache.cacheHit.connect(_on_cache_cache_hit)
	cache.cacheMiss.connect(_on_cache_cache_miss)
	# Connect stage timer timeouts
	for stageTimer in stageTimers:
		if stageTimer == null: continue
		stageTimer.timeout.connect(_on_stage_timer_timeout)
	
	dialoguePanel.set_position(Vector2(39, 808))
	dialogueBox.text = "Welcome to our world!
So you want to become a guardian? 
I'll gladly walk you through what we do here!

We will start with the basic cache mechanics...
... but first we need a cache! [color=violet][Press Continue or Space]"



func _process(delta: float) -> void:	
	if gameOverMenu.is_visible_in_tree(): return	# to prevent showing Pause Menu behing Game Over screen
	if Input.is_action_just_pressed("ui_cancel") and not pauseMenu.is_visible_in_tree():
		#await get_tree().create_timer(0.2).timeout
		pauseMenu.pause()
		$HUD.disableSpeedControl()
		if continueCount == 17: dialoguePanel.set_position(Vector2(490, 720))
	elif Input.is_action_just_pressed("ui_cancel") and pauseMenu.is_visible_in_tree():
		#await get_tree().create_timer(0.2).timeout
		pauseMenu.unpause()
		$HUD.enableSpeedControl()
		
	stageProgressBar.value = 1 - (stageTimers[current_stage].time_left / stageTimers[current_stage].wait_time)
	stageLabel.text = "Stage "+str(current_stage)
	

## Fits the hitbox to the dynamic size of the cache
func _fit_hitbox_to_cache() -> void:
	var midpointOfCache :Vector2 = cache.get_size() * 0.5
	hitbox.set_position(midpointOfCache)
	hitbox.shape.set_size(cache.get_size())
	
	
	
## Collision with Cache -> sort it and delete it from path
func _on_cache_hitbox_area_entered(area: Area2D) -> void:
	var floatingAddress = area.get_parent()
	if floatingAddress is not RichTextLabel: return
	var address = floatingAddress.text
	if not cache._will_be_hit(address):	# Let miss'ed addresses pass through the cache
		cache.sort_address_into_cache(address)
	else: # Cache Hit -> delete addresses from path
		cache.sort_address_into_cache(address)
		var pathFollow: Node = floatingAddress.get_parent()
		if pathFollow is not PathFollow2D: return
		pathFollow.queue_free()
		
		
func _on_the_memory_damaged(who: String, damage: int) -> void:
	if not the_memory.visible: 
		the_memory.add_health(100)
		return
	$HUD.display_chat_message("The Memory took -"+str(damage)+" HP damage from address "+who)
	
	
func _on_the_memory_dead() -> void:
	$HUD.display_chat_message("Game Over.")
	get_tree().paused = true
	await get_tree().create_timer(2.0).timeout
	$"Game Over Menu".visible = true
	
	
func _on_pause_menu_show_upgrade_menu() -> void:
	upgradeMenu.show()
	upgradeMenu.update_focus()
	
	
# Called when the Back button of the upgrade menu is pressed
func _on_upgrade_menu_continue_tutorial() -> void:
	if continueCount == 12: _on_continue_button_pressed()
	
	
func _on_stage_timer_timeout() -> void:
	Engine.time_scale = 1.0
	Global.tutorial1Stats["coins"] += 17
	Global.tutorial1Stats["max_coins"] += 17
	$HUD.display_chat_message("Earned 17 Coins.")
	upgradeMenu.unlockUpgrades(1)
	$HUD.display_chat_message("Unlocked new upgrades.")
	get_tree().paused = true
	await get_tree().create_timer(1).timeout
	stagePassedMenu.show()
	_on_continue_button_pressed()
	
	


func _on_stage_passed_menu_show_upgrade_menu() -> void:
	if continueCount == 10: _on_continue_button_pressed()
	dialoguePanel.set_position(Vector2(9, 815))
	upgradeMenu.show()
	upgradeMenu.update_focus()
	
	
func _on_stage_passed_menu_continue_to_next_stage() -> void:
	if continueCount <= 12: return		# To force players to open the upgrade menu in the first stages of tutorial
	get_tree().paused = false
	stagePassedMenu.hide()
	stagePassedMenu.stage += 1
	current_stage += 1
	# Reset damage and basically entire level for next stage:
	cache.blockNumber = Global.tutorial1Stats["blocknumber"]
	cache.blockSize = Global.tutorial1Stats["blocksize"]
	cache.associativityDegree = Global.tutorial1Stats["associativity"]
	cache.update_layout()
	$HUD.reset()
	the_memory.add_health(100)
	totalAccessCount = 0
	hitCount = 0
	hitRate = 0.0				# in %
	missCount = 0
	missRate = 0.0				# in %
	addressIndex = 0
	var deleteList = path.get_children()
	for e in deleteList: e.queue_free()
	#stageTimers[current_stage].start()
	
	_on_continue_button_pressed()
	#set_stage_settings()
	

func _on_game_over_menu_restart() -> void:
	gameOverMenu.hide()
	cache.update_layout()
	$HUD.reset()
	the_memory.add_health(100)
	addressIndex = 0
	_on_continue_button_pressed()
	

#TODO: change this function to fit the tutorial level. Idea: have button presses from dialogue trigger spawning of new address
### On timeout, spawn new address on Path to Cache
#func _on_timer_timeout() ->void:
	## Spawn new address on the path
	#var newAddress: Node = preload("res://floating_address.tscn").instantiate()
	#var pathFollow: PathFollow2D = PathFollow2D.new()
	#pathFollow.rotates = false
	#var tween = get_tree().create_tween()
	## Get next address to send towards cache
	#var decision:float = RandomNumberGenerator.new().randf()
	##if decision < 0.5 and not loopTimerFinished:
		##newAddress.text = _generate_next_address_spatial()
	##else:
		##newAddress.text = _generate_next_address_temporal()
	#newAddress.set_position(Vector2(0,0))
	#path.add_child(pathFollow)
	#pathFollow.add_child(newAddress)
	#tween.tween_property(pathFollow, "progress_ratio", 1.0, pathSpeed)

	
	
## Update score and put message in event log
func _on_cache_cache_hit(address:String) -> void:
	totalAccessCount += 1
	hitCount += 1
	hitRate = float(hitCount) / float(totalAccessCount)
	missRate = 1 - hitRate
	# Get tag, index, offset info for event log
	var bits :Dictionary = cache._get_cache_bitnumbers()
	var tio :Dictionary = cache._get_tag_index_offset(address.hex_to_int(), bits["tagbits"], bits["indexbits"], bits["offsetbits"])
	$HUD.update_score(hitRate, missRate)
	$HUD.display_chat_message("Hit with address "+address+" in set %d with tag 0x%x" % [tio["index"],tio["tag"]])


## Place replacedAddress on pathFromCache, update score and put message in event log
# TODO: some error with adding the pathFollow to the scene
func _on_cache_cache_miss(type: Cache.cacheMissType, replacedAddress: String) -> void:
	totalAccessCount += 1
	missCount += 1
	hitRate = float(hitCount) / float(totalAccessCount)
	missRate = 1 - hitRate
	$HUD.update_score(hitRate, missRate)
	# Get tag, index, offset info for event log
	var bits :Dictionary = cache._get_cache_bitnumbers()
	var tio :Dictionary = cache._get_tag_index_offset(replacedAddress.hex_to_int(), bits["tagbits"], bits["indexbits"], bits["offsetbits"])
	# Custom Event message depending on the type of cache miss
	if type == cache.cacheMissType.COMPULSORY: 
		$HUD.display_chat_message("Miss (Compulsory) with address " + replacedAddress+" in set %d with tag 0x%x" % [tio["index"],tio["tag"]])
		return
	elif type == cache.cacheMissType.CONFLICT:
		$HUD.display_chat_message("Miss (Conflict) with address " + replacedAddress+" in set %d with tag 0x%x" % [tio["index"],tio["tag"]])
	elif type == cache.cacheMissType.CAPACITY:
		$HUD.display_chat_message("Miss (Capacity) with address " + replacedAddress+" in set %d with tag 0x%x" % [tio["index"],tio["tag"]])

	
	
	
func send_address_to_cache() -> void:
	var newAddress : Node = preload("res://menus/floating_address.tscn").instantiate()
	var pathFollow: PathFollow2D = PathFollow2D.new()
	var tween = get_tree().create_tween()
	if addressIndex < len(addressList):
		newAddress.text = addressList[addressIndex]
		addressIndex += 1							# the next time the button is pressed, just addressList[addressIndex+1] is set as address -> enables fine-tuning for didactic showcase of cache concepts
	newAddress.set_position(Vector2(0,0))
	pathFollow.rotates = false
	path.add_child(pathFollow)
	pathFollow.add_child(newAddress)
	tween.tween_property(pathFollow, "progress_ratio", 1.0, pathSpeed)
	
	
	

## Main driver method of this level. Controls what is happening.
## When pressing this button, advance the level, e.g. send new address on the path to the cache	or reveal new elements/game mechanics
func _on_continue_button_pressed() -> void:
	continueCount += 1
	continueButton.hide()
	await get_tree().create_timer(0.2).timeout
	dialogueBox.text =""
	match continueCount:
		1:
			cache.show()
			await get_tree().create_timer(0.7).timeout
			dialogueBox.text = "Great!
Let's first address (haha) how caches work, right?
Basically, they store data that can be accessed really fast later!

This one is made up of [color=%s]4 blocks[/color], in each of which data can be stored.
We call the total amount of blocks the [color=%s][i]block number[/i][/color].

The amount of B each individual block will store is called the [color=%s][i]block size[/i][/color].
The block size of this cache is [color=%s]4 B[/color], so you can store exactly one int in each line.

The blocks are also grouped together into [color=%s]sets[/color].
How many blocks go into a set we call [color=%s][i]associativity[/i][/color].
We can see that each set contains [color=%s]2 blocks[/color] here so this is our associativity!

To see how data is stored in action, [color=violet][Press Continue or Space]" % [blocknumber_col, blocknumber_col, blocksize_col,blocksize_col, associativity_col,associativity_col,associativity_col]
			continueButton.show()
		2:
			dialoguePanel.set_position(Vector2(700, 808))
			$HUD/ChatLogControl.visible = true
			await get_tree().create_timer(0.7).timeout
			dialogueBox.text = "This event log on the left will help you keep track of everything!"
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text += "\n\n I will now show you how addresses and their data is stored inside the cache! [color=violet][Press Continue or Space]"
			continueButton.show()
		3:
			# Send address towards cache
			send_address_to_cache()			
			pathSpeed = pathSpeed / 3		# Normal speed now after first access
			await get_tree().create_timer(pathSpeed).timeout
			dialogueBox.text = "Now let's analyze what happened:"
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text += "\n\nWe can see that this address (or rather its data) was sorted into block 0, set 0 with tag 0x245 and in the future we can find it exactly there.
To determine in which block an address must be stored, it is first decomposed into three components: tag, index and offset."
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text += "\n\nFor this configuration, the [color=%s]offset[/color] part of the address is the first 2 bits from the right (since our [color=%s]block size is 4 B[/color])." % [blocksize_col, blocksize_col]
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text += "\n\nSince we only have [color=%s]two sets[/color], the index of the set in which the data will be stored can be determined by a single bit." % associativity_col
			dialogueBox.text += "\n\nAnd the remaining bits of the address is just the tag."
			dialogueBox.text += "\n\nThankfully, the cache does the math on its own, but it is nice to know what happens."
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text += "\n\nBut you probably noticed that this was a [color=%s]miss[/color], right? \nCome on, I want so show you what really happens then. [color=violet][Press Continue or Space]" % [miss_col]
			continueButton.show()
		4: 
			dialoguePanel.set_position(Vector2(15, 590))
			await get_tree().create_timer(1.0).timeout
			the_memory.add_health(100)
			the_memory.show()
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text = "Now this is the real reason we do all of this.
You are looking at The Memory of this world, and we are its protectors.
The Memory knows all and it provides all knowledge to us.

The cache is a kind of shield to protect The Memory from unnecessary accesses and our task is to perfectly adapt it to all circumstances.
By unnecessary I mean [color=%s]misses[/color] that would have been avoidable if the caching and mapping of addresses was better.

Let me show you what happens when an [color=%s]address miss[/color] occurs [color=violet][Press Continue or Space]" % [miss_col, miss_col]
			continueButton.show()
		5:
			send_address_to_cache()
			await get_tree().create_timer(pathSpeed).timeout
			dialogueBox.text = "We must at all costs prevent that."
			await get_tree().create_timer(2.0).timeout
			dialogueBox.text += "\n\nIf enough [color=%s]misses[/color] occur and the health bar of The Memory reaches zero, we are all doomed." % miss_col
			await get_tree().create_timer(5.0).timeout
			$HUD.display_chat_message("The Memory took -95 HP damage from DEMONSTRATION PURPOSES")
			the_memory.subtract_health(100)
			await get_tree().create_timer(2.0).timeout
			dialogueBox.text += "\n\nI will now show you how we prevent this. [color=violet][Press Restart][/color] to restart the level."
		6:
			the_memory.add_health(100)
			$HUD/ScoreLabel.show()
			$"HUD/Speed Controls".show()
			dialogueBox.text = "To keep track of how well it's going, you can see the [color=%s]hit rate[/color] in the top right corner. It tells you the ratio of all accesses that are [color=%s]hits[/color].
And the [color=%s]miss rate[/color] is exactly the opposite of the [color=%s]hit rate[/color].
Remember: we always want to keep the [color=%s]hit rate[/color] as high as possible, because when the [color=%s]hit rate[/color] is high enough, The Memory will take less damage and survive!" % [hit_col,hit_col,miss_col,hit_col,hit_col,hit_col]
			dialogueBox.text += "\n\nIn the top left corner, you can slow down or speed up the gameplay speed. [color=violet][Press Continue or Space]"
			continueButton.show()
		7:
			stageProgressBar.show()
			stageLabel.show()
			dialogueBox.text = "Each level consists of address accesses that must be cached perfectly, or else The Memory will take damage and eventually die.\n\n"
			dialogueBox.text += "But there are stages in each level. At first it starts slow, but higher stages mean more and faster accesses so you need to be prepared for that:\n\n"
			dialogueBox.text += "For passing a stage, you get coins which you can invest into cache upgrades which will help you survive higher stages! [color=violet][Press Continue or Space]"
			continueButton.show()
		8:
			dialogueBox.text = "[color=violet][Press Continue or Space][/color] to play the first stage!"	
			continueButton.show()	
		9:
			stage1Timer.start()
			send_address_to_cache()
			await get_tree().create_timer(1.0).timeout
			send_address_to_cache()
			await get_tree().create_timer(1.0).timeout
			send_address_to_cache()
			await get_tree().create_timer(1.0).timeout
			send_address_to_cache()
			await get_tree().create_timer(1.0).timeout
			send_address_to_cache()
			await get_tree().create_timer(1.0).timeout
			send_address_to_cache()
			await get_tree().create_timer(1.0).timeout
		10: # Coming from stage timer timout function here
			dialogueBox.text = "Great, you defended the memory in the first stage!
But as I mentioned, the next stages will not be so easy anymore. You will encounter more accesses which are also faster.

I gave you 17 coins to upgrade your cache, so please open the upgrade menu to spend them. [color=violet][Press Upgrades]"
		11: # Coming from opening upgrade menu signal
			dialoguePanel.set_position(Vector2(700, 250))
			dialogueBox.text = "Welcome to the place where you will be spending quite some time thinking about upgrade choices and their effects.

You can see the current cache configuration in the middle row right here. [color=violet][Press Continue or Space]"
			continueButton.show()

		12:
			dialoguePanel.set_position(Vector2(9, 815))
			dialogueBox.text = "When you click on any of them, it will show you all the upgrades that you have unlocked so far.
As you see, every module currently has exactly one new upgrade unlocked that you can buy, in addition to your starting equipment.

I gave you exactly 17 coins to buy all of them now.
Please buy all upgrades and then return to the previous screen by pressing the [color=violet][Back Button][/color] in the top right corner."
			#TODO: place this panel somewhere else or hide it after pressing continue
			
		13:	# Coming from Back button of Upgrade Menu (signal continueTutorial)
			dialoguePanel.set_position(Vector2(490, 620))
			if Global.tutorial1Stats["coins"] > 0:
				dialogueBox.text = "Please buy all unlocked upgrades before continuing."
				continueCount -= 1		# If there is still stuff to do, do not let the player advance (reminder: continueCount +=1 at the top of this method)
			else:
				dialogueBox.text = "Great! Now click [color=violet][Continue To Next Stage][/color] to see what your upgrades did."
		14:	# Coming from Continue To Next Stage button, ergo now in stage 2
			dialoguePanel.set_position(Vector2(15, 590))
			dialogueBox.text = "Look, your upgrades have been applied!
			
You now have [color=%s]twice the amount of blocks[/color] which also all now have [color=%s]twice the capacity[/color] than before!
The increased [color=%s]block size[/color] will mean that now, instead of storing just one integer, the cache will additionally store the next one too.
This is very good for accesses with spatial locality.

The [color=%s]amount of blocks that can be freely placed in each set is now doubled[/color] which should help reduce conflict misses. [color=violet][Press Continue or Space][/color]" % [blocknumber_col,blocksize_col,blocksize_col,associativity_col ]
			continueButton.show()
		15:
			dialogueBox.text = "[color=violet][Press Continue or Space][/color] to see how the same addresses are now cached."
			continueButton.show()
		16:
			stage2Timer.start()
			send_address_to_cache()
			await get_tree().create_timer(2.0).timeout
			send_address_to_cache()
			await get_tree().create_timer(2.0).timeout
			send_address_to_cache()
			await get_tree().create_timer(2.0).timeout
			send_address_to_cache()
			await get_tree().create_timer(2.0).timeout
			send_address_to_cache()
			await get_tree().create_timer(2.0).timeout
			send_address_to_cache()
			await get_tree().create_timer(2.0).timeout
			send_address_to_cache()
			await get_tree().create_timer(2.0).timeout
			send_address_to_cache()
			await get_tree().create_timer(2.0).timeout
			send_address_to_cache()
			stage2Timer.stop()
			dialogueBox.text = "Notice how much more [color=%s]hits[/color] there were!
Apart from [color=%s]compulsory misses[/color] which we can't prevent (except maybe with magic) there are now much less [color=%s]misses[/color]!
This means that our upgrades actually work! [color=violet][Press Continue or Space][/color]" % [hit_col,miss_col,miss_col]
			continueButton.show()
		17:
			dialogueBox.text = "I think you're ready now for the first challenge!
Play Level 1 and survive until the last stage to prove your abilities as a future guardian.

To play the first level, [color=violet][Press ESC][/color], return to the [color=violet][Main Menu][/color] and click [color=violet][Play/Level 1][/color].

After that, you can strenghten your prowess by playing Level 2 which simulates the access pattern of matrix multiplication.

[i](Creator: And don't forget to fill out the feedback questionnaire for which you need the ingame token. Your answers will help us improve the quality of this game and decide on upcoming features :) )[/i]"
			
			
			
		#TODO: simulate some accesses, start stage timer, open upgrade menu and then finish tutorial		
	
		
			
