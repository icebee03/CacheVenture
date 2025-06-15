extends Control

signal restart

@export var insideLevel :String

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	restart.emit()
	#get_tree().change_scene_to_file("res://First Level Prototype.tscn")	#every level that uses this should restart itself not start level 1 from here


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit(0)
