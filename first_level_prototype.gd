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
var loopTimerFinished:bool = false

#--- for score calculation ---
var totalAccessCount:int = 0
var hitCount:int = 0
var hitRate:float = 0.0				# in %
var missCount:int = 0
var missRate:float = 0.0				# in %


@onready var cache :Cache = $Cache
@onready var hitbox :CollisionShape2D = $Cache/Hitbox/CollisionShape2D
@onready var pathToCache: PathFollow2D = $Path2D/PathFollow2D
@onready var path: Path2D = $Path2D
@onready var pathFromCache: Path2D = $PathFromCache

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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



## Collision with Cache -> sort it and delete it from path
func _on_area_2d_area_entered(area: Area2D) -> void:
	var floatingAddress = area.get_parent()
	if floatingAddress is not RichTextLabel: return
	var address = floatingAddress.text
	cache.sort_address_into_cache(address)
	var pathFollow: Node = floatingAddress.get_parent()
	if pathFollow is not PathFollow2D: return
	pathFollow.queue_free()
		
		
		
## On timeout, spawn new address on Path to Cache
func _on_timer_timeout() ->void:
	var newAddress: Node = preload("res://floating_address.tscn").instantiate()
	var pathFollow: PathFollow2D = PathFollow2D.new()
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
	
	
## Place replacedAddress on pathFromCache and update score
# TODO: some error with adding the pathFollow to the scene
func _on_cache_cache_miss(type: Cache.cacheMissType, replacedAddress: String) -> void:
	totalAccessCount += 1
	missCount += 1
	hitRate = float(hitCount) / float(totalAccessCount)
	missRate = 1 - hitRate
	$HUD.update_score(hitRate, missRate)
	
	if type == cache.cacheMissType.COMPULSORY: return			# do nothing visually on a Compulsory Miss
	var newAddress: Node = preload("res://floating_address.tscn").instantiate()
	var pathFollow: PathFollow2D = PathFollow2D.new()
	var tween = get_tree().create_tween()
	newAddress.text = replacedAddress
	newAddress.set_position(Vector2(0,0))
	pathFromCache.add_child(pathFollow)
	pathFollow.add_child(newAddress)					# This line seems to have this error: "Cant change this state while flushing queries"
	pathFollow.rotates = false
	tween.tween_property(pathFollow, "progress_ratio", 1.0, 4.0)
	tween.finished.connect(func(): pathFollow.queue_free())
	
	

## Just update the score
func _on_cache_cache_hit() -> void:
	totalAccessCount += 1
	hitCount += 1
	hitRate = float(hitCount) / float(totalAccessCount)
	missRate = 1 - hitRate
	$HUD.update_score(hitRate, missRate)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/level_menu.tscn")
