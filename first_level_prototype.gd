class_name FirstLevel extends Node

@onready var cache :Cache = $Cache
@onready var hitbox :CollisionShape2D = $Cache/Hitbox/CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_fit_hitbox_to_cache()


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
