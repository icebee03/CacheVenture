class_name FirstLevel extends Node

## Time between address spawns
@export var spawnRate: float
@export var pathSpeed: float

var timer: Timer = Timer.new()
var prevAddress:String = "0x1228"

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
	timer.connect("timeout", _on_timer_timeout)
	add_child(timer)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# Fits the hitbox to the dynamic size of the cache
func _fit_hitbox_to_cache() -> void:
	var midpointOfCache :Vector2 = cache.get_size() * 0.5
	hitbox.set_position(midpointOfCache)
	hitbox.shape.set_size(cache.get_size())
	
	
func _generate_next_address() -> String:
	prevAddress = "0x%x" % (prevAddress.hex_to_int() + 4)
	return prevAddress


# Collision with Cache -> sort it and delete it from path
func _on_area_2d_area_entered(area: Area2D) -> void:
	print("Area Entered!")
	var floatingAddress = area.get_parent()
	if floatingAddress is not RichTextLabel: return
	var address = floatingAddress.text
	print("Sorting "+address+" into cache")
	cache.sort_address_into_cache(address)
	# Remove relevant children of path (unique pathFollow2D's)
	#var pathFollows: Array[Node] = path.get_children()		# get all PathFollow2D children of Path2D
	#for pathFollow in pathFollows:
		#if pathFollow is not PathFollow2D: return
		#var labelText = pathFollow.get_child(0).text			# PathFollow2D has one RichTextLabel child with 'text' property 
		#if labelText == address: pathFollow.queue_free()		# only free collided Address, not other addresses still on the path
	var pathFollow: Node = floatingAddress.get_parent()
	if pathFollow is not PathFollow2D: return
	pathFollow.queue_free()
	# Start countown to spawn new Address
	#timer.start()
		
		
		
# On timeout, spawn new address on Path to Cache
func _on_timer_timeout() ->void:
	var newAddress: Node = preload("res://floating_address.tscn").instantiate()
	var pathFollow: PathFollow2D = PathFollow2D.new()
	var tween = get_tree().create_tween()
	newAddress.text = _generate_next_address()
	newAddress.set_position(Vector2(0,0))
	path.add_child(pathFollow)
	pathFollow.add_child(newAddress)
	tween.tween_property(pathFollow, "progress_ratio", 1.0, pathSpeed)
	
	

	
# Place replacedAddress on pathFromCache
# TODO: some error with adding the pathFollow to the scene
func _on_cache_cache_miss(type: Cache.cacheMissType, replacedAddress: String) -> void:
	if type == cache.cacheMissType.COMPULSORY: return			# do nothing visually on a Compulsory Miss
	print("Cache Miss!!!!")
	var newAddress: Node = preload("res://floating_address.tscn").instantiate()
	var pathFollow: PathFollow2D = PathFollow2D.new()
	var tween = get_tree().create_tween()
	newAddress.text = replacedAddress
	newAddress.set_position(Vector2(0,0))
	pathFromCache.add_child(pathFollow)
	pathFollow.add_child(newAddress)					# This line seems to have this error: "Cant change this state while flushing queries"
	tween.tween_property(pathFollow, "progress_ratio", 1.0, 4.0)
	
