extends Control

@onready var logo_particles = $"GameLogo! (particles)"


func _process(delta: float) -> void:
	if Global.token == "-1": return
	$SurveyTokenLabel.text = "Survey Token: [color=blue]%s[/color]" % Global.token
	

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/level_menu.tscn")
	


func _on_quit_button_pressed() -> void:
	get_tree().quit(0)

	
