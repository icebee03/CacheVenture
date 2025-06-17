class_name Level2 extends Node

## Time between address spawns
@export var spawnRate: float = 1.0
## Time between spawn and cache contact
@export var pathSpeed: float = 3.0


#TODO: add second timer for nested loop, and maybe values for i and j (iterating variables)
#TODO: do matrix multiplication (3 nested loops)
# For Matrix multiplication: A is size N x K; B is size K x M; C is size N x M
# Each element is of type int and size 4 Bytes
var N :int = 100
var K :int = 100
var M :int = 100
var base_address_A :int = 0x000000		# Matrix A has addresses beginning at 0x00000
var base_address_B :int = 0x100000
var base_address_C :int = 0x200000
var i :int = 0
var j :int = 0
var k :int = 0
var step1_finished :bool = false		# accessing A[i][k]
var step2_finished :bool = false		# accessing B[k][j]
# PSEUDOCODE:
# (Idea: generate addresses on the fly using i,j,k, base_address_A..C and N,K,M in _generate_address()
#for i in range(N):
	#for j in range(M):
		#for k in range(K):
			#C[i][j] += A[i][k] * B[k][j]
			# => STEP 1: access A[i][k] 
			# STEP 2: and then B[k][j]


## Spawn timer, after timeout spawning new addresses on path
var timer: Timer = Timer.new()
var prevAddresses:Array[String] = ["0x1228"]
var timerToLoop: Timer = Timer.new()
var loopTimerFinished:bool = false				# After that timer is finished, only spawn previous addresses (simulates loop)

#--- for score calculation -----
var totalAccessCount:int = 0
var hitCount:int = 0
var hitRate:float = 0.0				# in %
var missCount:int = 0
var missRate:float = 0.0				# in %

var current_stage : int = 1


@onready var the_memory : TheMemory = $"The Memory"
@onready var cache :Cache = $Cache
@onready var hitbox :CollisionShape2D = $Cache/Hitbox/CollisionShape2D
@onready var pathToCache: PathFollow2D = $Path2D/PathFollow2D
@onready var path: Path2D = $Path2D
@onready var pauseMenu = $"Pause Menu"
@onready var stagePassedMenu = $"Stage Passed Menu"
@onready var gameOverMenu = $"Game Over Menu"
@onready var upgradeMenu = $"Upgrade Menu"
@onready var stageProgressBar = $StageProgressBar
@onready var stageLabel = $StageLabel


# Timers for all different stages
@onready var stage1Timer = $Stage1Timer
@onready var stage2Timer = $Stage2Timer
@onready var stage3Timer = $Stage3Timer
@onready var stage4Timer = $Stage4Timer
@onready var stage5Timer = $Stage5Timer
@onready var stage6Timer = $Stage6Timer
@onready var stage7Timer = $Stage7Timer
@onready var stage8Timer = $Stage8Timer
@onready var stage9Timer = $Stage9Timer
@onready var stage10Timer = $Stage10Timer
@onready var stageTimers = [null, stage1Timer, stage2Timer, stage3Timer, 	#dummy entry at index 0 to be able access via current_stage which starts at 1
	stage4Timer, stage5Timer, stage6Timer, stage7Timer, stage8Timer, stage9Timer, stage10Timer]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HUD/LoopTimerLabel.visible = true
	_fit_hitbox_to_cache()
	pathToCache.start(pathSpeed)
	
	timer.wait_time = spawnRate
	timer.autostart = true
	timer.one_shot = false		# spawn timer will continuously restart
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	Global.level2Stats["coins"] = 0
	Global.level2Stats["max_coins"] = 0
	Global.level2Stats["blocknumber"] = cache.blockNumber
	Global.level2Stats["blocksize"] = cache.blockSize
	Global.level2Stats["associativity"] = cache.associativityDegree
	for u in Global.level2Upgrades:
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
	
	# Connect stage timer timeouts
	for stageTimer in stageTimers:
		if stageTimer == null: continue
		stageTimer.timeout.connect(_on_stage_timer_timeout)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$HUD.update_timer_label(timerToLoop.time_left)
	
	if gameOverMenu.is_visible_in_tree(): return	# to prevent showing Pause Menu behing Game Over screen
	if Input.is_action_just_pressed("ui_cancel") and not pauseMenu.is_visible_in_tree():
		#await get_tree().create_timer(0.2).timeout
		pauseMenu.pause()
	elif Input.is_action_just_pressed("ui_cancel") and pauseMenu.is_visible_in_tree():
		#await get_tree().create_timer(0.2).timeout
		pauseMenu.unpause()
		
	stageProgressBar.value = 1 - (stageTimers[current_stage].time_left / stageTimers[current_stage].wait_time)
	stageLabel.text = "Stage "+str(current_stage)



## Fits the hitbox to the dynamic size of the cache
func _fit_hitbox_to_cache() -> void:
	var midpointOfCache :Vector2 = cache.get_size() * 0.5
	hitbox.set_position(midpointOfCache)
	hitbox.shape.set_size(cache.get_size())
	
	
## Generates the needed address for matrices with num columns at indices [i][j]
func _generate_address(base, i, j, num_columns) -> String:
	var address :int = base + (i * num_columns + j) * 4			# each element 4 bytes big
	return "0x%x" % address 		# int to hex-String conversion	
	
	
## Handles matrix multiplication access pattern and just calls _generate_address(...) accordingly
func _generate_next_address() -> String:
	if i < N:
		if j < M:
			if k < K:
				if not step1_finished:
					# STEP 1: access A[i][k]
					step1_finished = true		# => do STEP 2 next time
					return _generate_address(base_address_A, i, k, K)
				if not step2_finished:
					#STEP 2: access B[k][j]
					step1_finished = false
					step2_finished = false
					k += 1
					return _generate_address(base_address_B, k, j, M)
			else:
				j += 1
				k = 0
				step1_finished = false
				step2_finished = false
				_generate_next_address()	 # k-loop finished, restart with next j-row
		else: 
			i += 1
			j = 0
			k = 0
			_generate_next_address() # j-loop finished, restart with next i-row
	return "0xBABA"	
# Matrix Multiplication:
# (Idea: generate addresses on the fly using i,j,k, base_address_A..C and N,K,M in _generate_address()
#for i in range(N):
	#for j in range(M):
		#C[i][j] = 0 
		# STEP 1: access to address C[i][j], e.g. _generate_address(base_address_C, i, j, M)
		#for k in range(K):
			# STEP 2: access A[i][k]
			# STEP 3: access B[k][j]
			#C[i][j] += A[i][k] * B[k][j]
			# => access A[i][k] and then B[k][j]
			
# PSEUDOCODE:
#if i < N:
#	if j < M:
#		if not step1_finished:
#			STEP 1
#			step1_finished = true
#			return STEP 1
#		if k < K:
#			if not step2_finished:
#				STEP 2
#				step2_finished = true
#				return STEP 2
#			if not step3_finished:
#				STEP 3
#				step3_finished = true
#				k++
#				return STEP 3


## Collision with Cache -> sort address and delete it from path
func _on_area_2d_area_entered(area: Area2D) -> void:
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
	$HUD.display_chat_message("The Memory took -"+str(damage)+" HP damage from address "+who)
	
	
func _on_the_memory_dead() -> void:
	$HUD.display_chat_message("Game Over.")
	get_tree().paused = true
	$"Game Over Menu".visible = true
		
		
		
## On timeout, spawn new address on Path to Cache
func _on_timer_timeout() ->void:
	var newAddress: Node = preload("res://floating_address.tscn").instantiate()
	var pathFollow: PathFollow2D = PathFollow2D.new()
	pathFollow.rotates = false
	var tween = get_tree().create_tween()
	# Generate next address based on matrix multiplication logic/pattern:
	newAddress.text = _generate_next_address()	
	newAddress.set_position(Vector2(0,0))
	path.add_child(pathFollow)
	pathFollow.add_child(newAddress)
	tween.tween_property(pathFollow, "progress_ratio", 1.0, pathSpeed)
	
	
## Triggers start of imaginary loop, old addresses are constantly accessed	
#func _on_timerToLoop_timeout() -> void:
	#loopTimerFinished = true
	#$HUD.display_chat_message("------- Loop has started (repeating addresses now) ----------")
	
	
## Update score and put message in event log
func _on_cache_cache_hit(address:String) -> void:
	# Score count & calculation
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
	# Score count & calculation
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
		$HUD.display_chat_message("Miss (Conflict) address " + replacedAddress+" was in set %d with tag 0x%x" % [tio["index"],tio["tag"]])
	elif type == cache.cacheMissType.CAPACITY:
		$HUD.display_chat_message("Miss (Capacity) address " + replacedAddress+" was in set %d with tag 0x%x" % [tio["index"],tio["tag"]])
	# Display address coming out of cache, delete it and path after animation is done
	#var newAddress: Node = preload("res://floating_address.tscn").instantiate()
	#var pathFollow: PathFollow2D = PathFollow2D.new()
	#var tween = get_tree().create_tween()
	#newAddress.text = replacedAddress
	#newAddress.set_position(Vector2(0,0))
	#pathFromCache.add_child(pathFollow)
	#pathFollow.add_child(newAddress)					# This line seems to have this error: "Cant change this state while flushing queries" # for now works without though (Godot 4.4.stable.mono)
	#pathFollow.rotates = false
	#tween.tween_property(pathFollow, "progress_ratio", 1.0, 4.0)
	#tween.finished.connect(func(): pathFollow.queue_free())


func _on_pause_menu_show_upgrade_menu() -> void:
	upgradeMenu.show()
	upgradeMenu.update_focus()


func _on_stage_passed_menu_show_upgrade_menu() -> void:
	upgradeMenu.show()
	upgradeMenu.update_focus()


func _on_stage_passed_menu_continue_to_next_stage() -> void:
	get_tree().paused = false
	stagePassedMenu.hide()
	stagePassedMenu.stage += 1
	current_stage += 1
	# Reset damage and basically entire level for next stage:
	cache.blockNumber = Global.level2Stats["blocknumber"]
	cache.blockSize = Global.level2Stats["blocksize"]
	cache.associativityDegree = Global.level2Stats["associativity"]
	cache.update_layout()
	$HUD.reset()
	the_memory.add_health(100)
	totalAccessCount = 0
	hitCount = 0
	hitRate = 0.0				# in %
	missCount = 0
	missRate = 0.0				# in %
	prevAddresses.resize(1)
	var deleteList = path.get_children()
	for e in deleteList: e.queue_free()
	if current_stage == 11: return
	stageTimers[current_stage].start()
	set_stage_settings()


func _on_stage_timer_timeout() -> void:
	Engine.time_scale = 1.0
	$HUD.display_chat_message("Earned 5 coins.")
	upgradeMenu.unlockUpgrades(current_stage)
	$HUD.display_chat_message("Unlocked new upgrades.")
	get_tree().paused = true
	await get_tree().create_timer(1).timeout
	stagePassedMenu.show()
	Global.level2Stats["coins"] += 5
	Global.level2Stats["max_coins"] += 5
	


## Changes the levels settings (spawning speed, etc.) depending on the current stage
func set_stage_settings() -> void:
	match current_stage:
		1:
			pass
		2:
			spawnRate = 0.9
			pathSpeed = 2.9
			pass # a little bit harder/faster
		3: 
			spawnRate = 0.8
			pathSpeed = 2.7
			pass # even faster / more challenging, need better upgrades now at the least
		4:
			spawnRate = 0.5
			pathSpeed = 2.7
			pass
		5: 
			spawnRate = 0.3
			pathSpeed = 2.0
			pass
		6: 
			spawnRate = 0.3
			pathSpeed = 1.7
			pass
		7:
			spawnRate = 0.2
			pathSpeed = 1.5
			pass
		8:
			spawnRate = 0.1
			pathSpeed = 1.2
			pass
		9:
			spawnRate = 0.08
			pathSpeed = 1.2
			pass
		10:
			spawnRate = 0.05
			pathSpeed = 1.0
			pass # very hard, much is going on!
	timer.wait_time = spawnRate


func _on_game_over_menu_restart() -> void:
	get_tree().change_scene_to_file("res://levels/level_2.tscn")
