extends Control

signal showUpgradeMenu()
signal continueToNextStage()

@export var stage :int = 1

@onready var message = $PanelContainer/VBoxContainer/RichTextLabel

func _process(delta: float) -> void:
	message.text = "PASSED STAGE "+str(stage)
	


func _on_upgrades_button_pressed() -> void:
	showUpgradeMenu.emit()


func _on_continue_button_pressed() -> void:
	continueToNextStage.emit()
