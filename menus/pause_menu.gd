extends Control

@onready var this = $"."

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_cancel") and not is_visible_in_tree():
		await get_tree().create_timer(0.2).timeout
		pause()
	elif Input.is_action_pressed("ui_cancel") and is_visible_in_tree():
		await get_tree().create_timer(0.2).timeout
		unpause()
		


# HINT/WARNING: always use get_tree().paused = true/false ONLY before changing scenes (else: crashes)
func pause():
	get_tree().paused = true
	show()
	
func unpause():
	get_tree().paused = false
	hide()


func _on_resume_button_pressed() -> void:
	unpause()


func _on_upgrades_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://upgrade_menu_2.tscn")


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit(0)


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://First Level Prototype.tscn")
	


func _on_options_button_pressed() -> void:
#	TODO
#	get_tree().paused = false
#	get_tree().change_scene_to_file(<OPTIONSMENU>)
	pass # Replace with function body.
