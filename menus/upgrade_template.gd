class_name UpgradeTemplate extends PanelContainer

## Use this *only* as a "reference" to Global.levelXUpgrades and to match to it.
## WARNING: Not intended to be modified outside of upgrade_menu_2.gd.init_ugprades(), always modify the Global.levelXUpgrades array containing all upgrades for that level!
var upgrade : Dictionary

func set_text(text:String)-> void:
	$Label.text = text

func get_text() -> String:
	return $Label.text
