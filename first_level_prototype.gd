class_name FirstLevel extends Node

## Time between address spawns
@export var spawnRate: float
## Time between spawn and cache contact
@export var pathSpeed: float
## Time until imaginary loop starts and no more sequential addresses are added
@export var timeToLoop:float = 90

var timer: Timer = Timer.new()
var prevAddresses:Array[String] = ["0x1228"]
var timerToLoop: Timer = Timer.new()
var loopTimerFinished:bool = false				# After that timer is finished, only spawn previous addresses (simulates loop)

#--- for score calculation ---
var totalAccessCount:int = 0
var hitCount:int = 0
var hitRate:float = 0.0				# in %
var missCount:int = 0
var missRate:float = 0.0				# in %


@onready var the_memory : TheMemory = $"The Memory"
@onready var cache :Cache = $Cache
@onready var hitbox :CollisionShape2D = $Cache/Hitbox/CollisionShape2D
@onready var pathToCache: PathFollow2D = $Path2D/PathFollow2D
@onready var path: Path2D = $Path2D
@onready var pathFromCache: Path2D = $PathFromCache
@onready var pauseMenu = $"Pause Menu"
@onready var gameOverMenu = $"Game Over Menu"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HUD/LoopTimerLabel.visible = true
	_fit_hitbox_to_cache()
	pathToCache.start(pathSpeed)
	
	timer.wait_time = spawnRate
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	timerToLoop.wait_time = timeToLoop
	timerToLoop.autostart = true
	timerToLoop.one_shot = true
	timerToLoop.timeout.connect(_on_timerToLoop_timeout)
	add_child(timerToLoop)
	

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


## Fits the hitbox to the dynamic size of the cache
func _fit_hitbox_to_cache() -> void:
	var midpointOfCache :Vector2 = cache.get_size() * 0.5
	hitbox.set_position(midpointOfCache)
	hitbox.shape.set_size(cache.get_size())
	
	
## Takes the previous address and adds 4 to it. Simulates sequential accesses (arrays, code, ...).
func _generate_next_address_spatial() -> String:
	var new:String = "0x%x" % (prevAddresses[-1].hex_to_int() + 4)
	prevAddresses.append(new)
	return new
	
	
## Returns a previously generated address. Simulates reocurring accesses (loops, frequently used data).
func _generate_next_address_temporal() -> String:
	var rng = RandomNumberGenerator.new()
	var rndIdx:int = rng.randf_range(0.0, len(prevAddresses))
	return prevAddresses[rndIdx]



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
	# Half of the time sequential access, the other half temporal
	var decision:float = RandomNumberGenerator.new().randf()
	if decision < 0.5 and not loopTimerFinished:
		newAddress.text = _generate_next_address_spatial()
	else:
		newAddress.text = _generate_next_address_temporal()
	newAddress.set_position(Vector2(0,0))
	path.add_child(pathFollow)
	pathFollow.add_child(newAddress)
	tween.tween_property(pathFollow, "progress_ratio", 1.0, pathSpeed)
	
	
## Triggers start of imaginary loop, old addresses are constantly accessed	
func _on_timerToLoop_timeout() -> void:
	loopTimerFinished = true
	$HUD.display_chat_message("------- Loop has started (repeating addresses now) ----------")
	
	
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
