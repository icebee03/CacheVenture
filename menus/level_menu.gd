extends Control


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")




# If all 3 (current) levels were played, display the token to unlock the survey
func _on_tut_lvl_1_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/tutorial.tscn")
	Global.tutorialPlayed = true
	if not Global.tokenExists and Global.tutorialPlayed and Global.level1Played and Global.level2Played:
		Global.show_survey_token()
		
	
	
func _on_lvl_1_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_1.tscn")
	Global.level1Played = true
	if not Global.tokenExists and Global.tutorialPlayed and Global.level1Played and Global.level2Played:
		Global.show_survey_token()


func _on_lvl_2_button_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/level_2.tscn")
	Global.level2Played = true
	if not Global.tokenExists and Global.tutorialPlayed and Global.level1Played and Global.level2Played:
		Global.show_survey_token()
