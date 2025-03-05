extends PathFollow2D

func _ready() -> void:
	#var tween = get_tree().create_tween()
	#tween.tween_property($".", "progress_ratio", 1.0, 4)
	
	#await get_tree().create_timer(6.0).timeout
	#$"Floating Address".queue_free()
	pass
	
func start(speed: float) -> void:
	progress_ratio = 0.0
	var tween = get_tree().create_tween()
	tween.tween_property($".", "progress_ratio", 1.0, speed)
	pass
	
