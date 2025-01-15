class_name FirstLevel extends Node

@onready var cache :Cache = $Cache
@onready var hitbox :CollisionShape2D = $Cache/Area2D/CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var midpointCache :Vector2 = cache.get_size() * 0.5
	hitbox.set_position(midpointCache)
	hitbox.shape.set_size(cache.get_size())
	#print("Midpoint position: ",hitbox.get_position())
	#print("hitbox size: ", hitbox.shape.get_size())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
