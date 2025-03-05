class_name FirstLevel extends Node

## Time between address spawns
@export var spawnRate: float
@export var pathSpeed: float

var timer: Timer = Timer.new()
var prevAddress:String = "0x1228"

@onready var cache :Cache = $Cache
@onready var hitbox :CollisionShape2D = $Cache/Hitbox/CollisionShape2D
@onready var pathToCache: PathFollow2D = $Path2D/PathFollow2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_fit_hitbox_to_cache()
	pathToCache.start(pathSpeed)
	
	timer.wait_time = spawnRate
	timer.one_shot = true
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



func _on_area_2d_area_entered(area: Area2D) -> void:
	print("Area Entered!")
	var label = area.get_parent()
	if label is RichTextLabel:
		var text = label.text
		if text == "": return
		print("Sorting "+text+" into cache")
		cache.sort_address_into_cache(text)
		# Remove all children of path after 4s
		#await get_tree().create_timer(4.0).timeout
		var pathChildren: Array[Node] = pathToCache.get_children()
		for child in pathChildren:
			if child is RichTextLabel:
				var childText = child.text
				if childText == text: child.free()		# only free collided Address, not other addresses still on the path
		timer.start()
		
	
	
	
		
		
# On timeout, spawn new address on Path to Cache
func _on_timer_timeout() ->void:
	var newAddress: Node = preload("res://floating_address.tscn").instantiate()
	newAddress.text = _generate_next_address()
	newAddress.set_position(Vector2(0,0))
	pathToCache.add_child(newAddress)
	pathToCache.start(pathSpeed)
	
	
func _generate_next_address() -> String:
	prevAddress = "0x%x" % (prevAddress.hex_to_int() + 4)
	return prevAddress
	
