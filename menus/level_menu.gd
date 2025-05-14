extends Control


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://First Level Prototype.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")


func _on_upgrade_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://upgrade_menu_2.tscn")
