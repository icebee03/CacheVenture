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
@onready var pathFromCache: Path2D = $PathFromCache


func _ready() -> void:
	_fit_hitbox_to_cache()
	$HUD/LoopTimerLabel.visible = false			# not relevant to this scene
	$Cache/Hitbox.area_entered.connect(_on_cache_hitbox_area_entered)		# Connect Hitbox signal to sorting method
	cache.cacheHit.connect(_on_cache_cache_hit)
	cache.cacheMiss.connect(_on_cache_cache_miss)
	

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
	cache.sort_address_into_cache(address)
	var pathFollow: Node = floatingAddress.get_parent()
	if pathFollow is not PathFollow2D: return
	pathFollow.queue_free()
	

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
	
	
## When pressing this button, advance the level, e.g. send new address on the path to the cache	
func _on_continue_button_pressed() -> void:
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
	
	
## Just update the score
func _on_cache_cache_hit(address:String) -> void:
	totalAccessCount += 1
	hitCount += 1
	hitRate = float(hitCount) / float(totalAccessCount)
	missRate = 1 - hitRate
	$HUD.update_score(hitRate, missRate)
	$HUD.display_chat_message("Cache Hit with address "+address)


## Place replacedAddress on pathFromCache and update score
# TODO: some error with adding the pathFollow to the scene
func _on_cache_cache_miss(type: Cache.cacheMissType, replacedAddress: String) -> void:
	totalAccessCount += 1
	missCount += 1
	hitRate = float(hitCount) / float(totalAccessCount)
	missRate = 1 - hitRate
	$HUD.update_score(hitRate, missRate)
	# Custom Event message depending on the type of cache miss
	if type == cache.cacheMissType.COMPULSORY: 
		$HUD.display_chat_message("Compulsory Cache Miss with address " + replacedAddress)# + " (tag: 0xYZ, index: 0xYZ, offset: 0xYZ)")
		return
	elif type == cache.cacheMissType.CONFLICT:
		$HUD.display_chat_message("Conflict Cache Miss with address " + replacedAddress)# + " (tag: 0xYZ, index: 0xYZ, offset: 0xYZ)")
	elif type == cache.cacheMissType.CAPACITY:
		$HUD.display_chat_message("Capacity Cache Miss with address " + replacedAddress)# + " (tag: 0xYZ, index: 0xYZ, offset: 0xYZ)")
	# Display address coming out of cache, delete it and path after animation is done
	var newAddress: Node = preload("res://floating_address.tscn").instantiate()
	var pathFollow: PathFollow2D = PathFollow2D.new()
	var tween = get_tree().create_tween()
	newAddress.text = replacedAddress
	newAddress.set_position(Vector2(0,0))
	pathFromCache.add_child(pathFollow)
	pathFollow.add_child(newAddress)					# This line seems to have this error: "Cant change this state while flushing queries" # for now works without though (Godot 4.4.stable.mono)
	pathFollow.rotates = false
	tween.tween_property(pathFollow, "progress_ratio", 1.0, 4.0)
	tween.finished.connect(func(): pathFollow.queue_free())
	
