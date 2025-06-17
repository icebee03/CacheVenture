extends Control

signal showUpgradeMenu()


#@onready var this = $"."	
@export var insideLevel :String	


#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("ui_cancel") and is_visible_in_tree():
		#unpause()


# HINT/WARNING: always use get_tree().paused = true/false ONLY before changing scenes (else: crashes)
func pause():
	get_tree().paused = true
	show()
	
func unpause():
	get_tree().paused = false
	hide()


func _on_resume_button_pressed() -> void:
	unpause()
	# TODO: connect to $HUD.enableSpeedControl() somehow
	var level = get_parent()
	level.get_node("HUD").enableSpeedControl()
	
	

func _on_upgrades_button_pressed() -> void:
	#get_tree().paused = false
	#get_tree().change_scene_to_file("res://upgrade_menu_2.tscn")
	showUpgradeMenu.emit()


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit(0)


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	if insideLevel == "Level 1": get_tree().change_scene_to_file("res://First Level Prototype.tscn")
	if insideLevel == "Level 2": get_tree().change_scene_to_file("res://levels/level_2.tscn")
	if insideLevel == "Tutorial 1": get_tree().change_scene_to_file("res://levels/Tutorial-Level-Blocks-Associativity.tscn")
	
	
	


func _on_options_button_pressed() -> void:
#	TODO
#	get_tree().paused = false
#	get_tree().change_scene_to_file(<OPTIONSMENU>)
	pass # Replace with function body.
