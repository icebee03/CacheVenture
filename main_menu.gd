extends Control

@onready var logo_particles = $"GameLogo! (particles)"

func _ready() -> void:
	#TODO: animate the particles of the logo (sway/bob)
	pass


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://First Level Prototype.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit(0)
