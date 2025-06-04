extends Control

signal showUpgradeMenu()
signal continueToNextStage()

## Keeps track of the current stage
@export var stage :int = 1
## This value should be set (dictated) by the level that instanciates this scene
@export var totalStages :int = 10

@onready var message = $PanelContainer/VBoxContainer/RichTextLabel

func _process(delta: float) -> void:
	message.text = "PASSED STAGE "+str(stage)
	if stage == totalStages:
		message.text = "FINISHED LEVEL"
		$PanelContainer/VBoxContainer/UpgradesButton.hide()
		$PanelContainer/VBoxContainer/BlocksIcon2.hide()
		$PanelContainer/VBoxContainer/ContinueButton.hide()
		$PanelContainer/VBoxContainer/MainMenuButton.show()
	
	


func _on_upgrades_button_pressed() -> void:
	showUpgradeMenu.emit()


func _on_continue_button_pressed() -> void:
	continueToNextStage.emit()


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
