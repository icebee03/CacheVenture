# THIS FILE is "tutorial_level_blocks_associativity.gd"
# THE FIRST TUTORIAL LEVEL

extends Node2D

## Time between spawn and cache contact
@export var pathSpeed: float = 1.0

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
@onready var stage1Timer = $Stage1Timer
@onready var stageTimers = [null, stage1Timer]


# For tutorial pacing and storytelling:
## Counts how many times "Continue" was pressed to advance in the tutorial accordingly the next time it is pressed
var continueCount = 0
@onready var continueButton = $ContinueButton
@onready var dialogueBox = $PanelContainer/HBoxContainer/DialogueBox
@onready var dialoguePanel = $PanelContainer


func _ready() -> void:
	_fit_hitbox_to_cache()
	
	$HUD/LoopTimerLabel.visible = false			# not relevant to this scene
	$"HUD/Speed Controls".visible = false
	$HUD/ChatLogControl.visible = false
	$HUD/ScoreLabel.visible = false
	
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
... but first we need a cache! [color=violet][Press Continue]"



func _process(delta: float) -> void:	
	if gameOverMenu.is_visible_in_tree(): return	# to prevent showing Pause Menu behing Game Over screen
	if Input.is_action_just_pressed("ui_cancel") and not pauseMenu.is_visible_in_tree():
		#await get_tree().create_timer(0.2).timeout
		pauseMenu.pause()
	elif Input.is_action_just_pressed("ui_cancel") and pauseMenu.is_visible_in_tree():
		#await get_tree().create_timer(0.2).timeout
		pauseMenu.unpause()
	

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
	$"Game Over Menu".visible = true
	
	
func _on_pause_menu_show_upgrade_menu() -> void:
	upgradeMenu.show()
	
	
func _on_stage_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = true
	await get_tree().create_timer(1).timeout
	stagePassedMenu.show()
	Global.tutorial1Stats["coins"] += 5
	Global.tutorial1Stats["max_coins"] += 5
	upgradeMenu.unlockUpgrades(1)


func _on_stage_passed_menu_show_upgrade_menu() -> void:
	upgradeMenu.show()
	

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
	await get_tree().create_timer(0.2).timeout
	dialogueBox.text =""
	match continueCount:
		1:
			cache.show()
			await get_tree().create_timer(0.7).timeout
			dialogueBox.text = "Great!
Let's first address (haha) how caches work, right?
Basically, they store data to access lightning fast later on!

This one is made up of 4 blocks, in each of which data can be stored.
We call the total amount of blocks the [i]block number[/i].

The amount of bytes each individual block will store is called the [i]block size[/i].
The block size of this cache is 4 bytes, so you can store exactly one int in each line.

The blocks are also grouped together into sets.
How many blocks go into a set we call [i]associativity[/i].
We can see that each set contains 2 blocks here so this is our associativity!

To see how data is stored in action, [color=violet][Press Continue]
"
		2:
			dialoguePanel.set_position(Vector2(700, 808))
			$HUD/ChatLogControl.visible = true
			await get_tree().create_timer(0.7).timeout
			dialogueBox.text = "This event log on the left will help you keep track of everything!"
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text += "\n\n I will now show you how addresses and their data is stored inside the cache! [color=violet][Press Continue]"
		
		3:
			# Send address towards cache
			send_address_to_cache()			
			await get_tree().create_timer(pathSpeed).timeout
			dialogueBox.text = "Now let's analyze what happened:"
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text += "\n\nWe can see that this address (or rather its data) was sorted into block 0, set 0 with tag 0x245 and in the future we can find it exactly there.
To determine in which block an address must be stored, it is first decomposed into three components: tag, index and offset."
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text += "\n\nFor this configuration, the offset part of the address is the first 2 bits from the right (since our block size is 4 B)."
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text += "\n\nSince we only have two sets, the index of the set in which the data will be stored can be determined by a single bit."
			dialogueBox.text += "\n\nAnd the remaining bits of the address is just the tag."
			dialogueBox.text += "\n\nThankfully, the cache does the math on its own, but it is nice to know what happens."
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text += "\n\nBut you probably noticed that this was a [color=red]miss[/color], right? \nCome on, I want so show you what really happens. [color=violet][Press Continue]"
			pass
		4: 
			dialoguePanel.set_position(Vector2(15, 560))
			await get_tree().create_timer(1.0).timeout
			the_memory.add_health(100)
			the_memory.show()
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text = "Now this is the real reason we do all of this.
You are looking at The Memory of this world, and we are its protectors.
The Memory knows all and it provides all knowledge to us.

The cache is a kind of shield to protect The Memory from unnecessary accesses and our task is to perfectly adapt it to all circumstances.

Let me show you what happens when an address miss occurs [color=violet][Press Continue]"
		5:
			send_address_to_cache()
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text = "We must at all costs prevent that."
			dialogueBox.text += "\n\nIf enough misses occure and the health bar of The Memory reaches zero, we are all doomed."
			await get_tree().create_timer(4.0).timeout
			the_memory.subtract_health(100)
			await get_tree().create_timer(1.0).timeout
			dialogueBox.text += "\n\nI will now show you how we prevent this. [color=violet][Press Restart]"
		6:
			the_memory.add_health(100)
			$HUD/ScoreLabel.show()
			$"HUD/Speed Controls".show()
			dialogueBox.text = "To keep track of how well it's going, you can see the hit rate in the top right corner. It tells you the percent of accesses are hits."
			dialogueBox.text += "\nIn the top left corner, you can manipulate the gameplay speed. [color=violet][Press Continue]"
		7:
			stageProgressBar.show()
			stageLabel.show()
			dialogueBox.text = "Each level consists of address accesses that must be cached perfectly, or else The Memory dies.\n\n"
			dialogueBox.text += "But there are stages in each level. At first it starts slow, but higher stages mean more and faster accesses so you need to be prepared for that.\n\n"
			dialogueBox.text += "For passing a stage, you get coins which you can invest into cache upgrades which will help you survive higher stages! [color=violet][Press Continue]"
		8:
			#TODO: simulate some accesses, start stage timer, open upgrade menu and then finish tutorial
			pass
			
			
