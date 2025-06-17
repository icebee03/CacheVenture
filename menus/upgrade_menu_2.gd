extends Control


## Used only inside the tutorial to advance the checkbox
signal continueTutorial


## Valid: "Level 1", "Level 2" or "Tutorial 1"
@export var insideLevel :String = "Level 1"
var levelStats			# e.g. if inside "Level 1", then this is level1Stats
var levelUpgrades		# e.g. if inside "Level 1", then this is level1Upgrades

# Widgets that display the current selected setting
@onready var blocknumberLabel = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Blocknumber/PanelContainer/BlockNumberLabel"
@onready var blocksizeLabel = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Blocksize/PanelContainer/BlockSizeLabel"
@onready var associativityLabel = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Associativity/PanelContainer/AssociativityLabel"

# For the right-hand side of the menu (buying & displaying info)
var upgrade_type : String 
@onready var coins_label = $"VBox/Bottom/Right Side/Details/Coins Display/CoinsLabel"
@onready var info_and_buy : VBoxContainer = $"VBox/Bottom/Right Side/Details/Info & Buy Button/Info & Buy Button/Info & Buy Button"
@onready var upgrade_title : RichTextLabel = $"VBox/Bottom/Right Side/Details/Info & Buy Button/Info & Buy Button/Info & Buy Button/Upgrade Title"
@onready var upgrade_quantity = $"VBox/Bottom/Right Side/Details/Info & Buy Button/Info & Buy Button/Info & Buy Button/Icon/Upgrade Icon/UpgradeQuantityLabel"
@onready var upgrade_description : Label = $"VBox/Bottom/Right Side/Details/Info & Buy Button/Info & Buy Button/Info & Buy Button/UpgradeDescriptionLabel"
@onready var upgrade_cost : Label = $"VBox/Bottom/Right Side/Details/Info & Buy Button/Info & Buy Button/Info & Buy Button/Upgrade Cost & Button/Upgrade Cost"
@onready var upgrade_button = $"VBox/Bottom/Right Side/Details/Info & Buy Button/Info & Buy Button/Info & Buy Button/Upgrade Cost & Button/ProgressBar/Upgrade Button"

# For the bottom part of the menu: The lists of different upgrade options for individual modules
@onready var arrow = $"Module Arrow"
@onready var focus_outline : PanelContainer = $"Focus Outline"
@onready var block_number_module = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Blocknumber"
@onready var block_size_module = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Blocksize"
@onready var associativity_module = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Associativity"

@onready var blocknumberUpgrades = $"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Block Number Upgrades"
@onready var blocksizeUpgrades = $"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Block Size Upgrades"
@onready var associativityUpgrades = $"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Associativity Upgrades"
const UpgradeTemplate = preload("res://menus/upgrade_template.tscn")
const UpgradeNotBoughtStylebox = preload("res://menus/upgradeNotBought.tres")
const UpgradeBoughtStylebox = preload("res://menus/upgradeBought.tres")



func _ready() -> void:
	if insideLevel == "Level 1":
		levelStats = Global.level1Stats
		levelUpgrades = Global.level1Upgrades
	elif insideLevel == "Level 2":
		levelStats = Global.level2Stats
		levelUpgrades = Global.level2Upgrades
	elif insideLevel == "Tutorial 1":
		levelStats = Global.tutorial1Stats
		levelUpgrades = Global.tutorial1Upgrades
	update_displays()
	init_upgrades()
	#_on_blocksize_focus_entered()
	#set_focus_outline()
	coins_label.text = str(levelStats["coins"])+" / "+str(levelStats["max_coins"])
	
	

func _process(delta: float) -> void:
	update_displays()
	display_focused_info()
	#TODO: display current purchase button state (needed after e.g. reset button)
	set_focus_outline()
	coins_label.text = str(levelStats["coins"])+" / "+str(levelStats["max_coins"])
	

func update_displays() -> void:
	blocknumberLabel.text = str(levelStats["blocknumber"])
	blocksizeLabel.text = str(levelStats["blocksize"])+" B"
	associativityLabel.text = str(levelStats["associativity"])+"x"
	
	
## Adds the upgrades from Global.levelXUpgrades to the scene with appropiate settings.
## Visible if unlocked.
## Gold color if bought.
func init_upgrades() -> void:
	# Firstly, delete all previously existing / outdated upgrades
	var free_list = $"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Block Number Upgrades/GridContainer".get_children()
	free_list.append_array($"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Block Size Upgrades/GridContainer".get_children())
	free_list.append_array($"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Associativity Upgrades/GridContainer".get_children())
	for e in free_list: e.queue_free()	
	for upgrade in levelUpgrades:
		var new = UpgradeTemplate.instantiate()
		if upgrade["bought"]: 
			new.add_theme_stylebox_override("panel", UpgradeBoughtStylebox)
		else:
			new.add_theme_stylebox_override("panel", UpgradeNotBoughtStylebox)
			
		if upgrade["type"] == "Block Number":
			new.set_text(str(upgrade["quantity"]))
			new.visible = upgrade["unlocked"]
			new.upgrade = upgrade
			blocknumberUpgrades.get_child(0).add_child(new)
		elif upgrade["type"] == "Block Size":
			new.set_text(str(upgrade["quantity"])+" B")
			new.visible = upgrade["unlocked"]
			new.upgrade = upgrade
			blocksizeUpgrades.get_child(0).add_child(new)
		elif upgrade["type"] == "Associativity":
			new.set_text(str(upgrade["quantity"])+"x")
			new.visible = upgrade["unlocked"]
			new.upgrade = upgrade
			associativityUpgrades.get_child(0).add_child(new)


func _on_back_button_pressed() -> void:
	visible = false
	continueTutorial.emit()
	
	
func display_focused_info() -> void:
	# Get current focus owner	
	var upgradeChoice : Control = get_viewport().gui_get_focus_owner()
	if upgradeChoice == null or upgradeChoice is not UpgradeTemplate: return	# Disregard any that are not valid upgrade choices (i.e. other ui elements)
	#TODO: add logic to update Purchase Button Look even when upgrade option is not in focus; maybe like: get upgrade info from text that is currently displayed on the right (opposite to this function)
	# Search for matching Global upgrade and save its index and contents for reference
	var idx :int			# index of this upgrade inside of Global.levelXUpgrades
	var type :String
	var quantity :int
	var cost :int
	var bought :bool
	for i in range(len(levelUpgrades)):
		if levelUpgrades[i]["type"] == upgradeChoice.upgrade["type"] and levelUpgrades[i]["quantity"] == upgradeChoice.upgrade["quantity"]:
			idx = i
			type = levelUpgrades[idx]["type"]
			quantity = levelUpgrades[idx]["quantity"]
			cost = levelUpgrades[idx]["cost"]
			bought = levelUpgrades[idx]["bought"]

	# Depending on upgrade["type"] and ["cost"], display info and description on the right panel of the menu
	upgrade_title.text = type
	if type == "Block Number":
		upgrade_quantity.text = str(quantity)
		upgrade_description.text = "Upgrades the amount of blocks the cache can hold."
		upgrade_cost.text = "Upgrade Cost: %d" % cost
	elif type == "Block Size":
		upgrade_quantity.text = str(quantity)+" B"
		upgrade_description.text = "Upgrades the amount of data each block can hold."
		upgrade_cost.text = "Upgrade Cost: %d" % cost
	elif type == "Associativity":
		upgrade_quantity.text = str(quantity)+"x"
		upgrade_description.text = "Upgrades the amount of blocks each set holds."
		upgrade_cost.text = "Upgrade Cost: %d" % cost
		
	if bought: upgrade_button.set_owned()
	else: # other button states/locks
		if not levelUpgrades[idx-1]["bought"]:
			upgrade_button.set_prohibited("Buy previous first!")
		elif levelStats["coins"] - cost < 0:
			upgrade_button.set_prohibited("Not enough coins!")		# Then you cannot buy the upgrade
		#TODO: maybe add other constraints such as that associativity cannot be larger than blocknumber
		else:
			upgrade_button.set_not_owned()
		


func _on_upgrade_button_upgrade_bought(price: int) -> void:
	var idx :int			# index of this upgrade inside of Global.levelXUpgrades
	var type :String
	var quantity :int
	var cost :int
	var bought :bool
	for i in range(len(levelUpgrades)):
		if levelUpgrades[i]["type"] == upgrade_title.text and levelUpgrades[i]["quantity"] == upgrade_quantity.text.to_int():
			idx = i
			type = levelUpgrades[idx]["type"]
			quantity = levelUpgrades[idx]["quantity"]
			cost = levelUpgrades[idx]["cost"]
	levelUpgrades[idx]["bought"] = true
	levelStats["coins"] -= cost
	if type == "Block Number":
		levelStats["blocknumber"] = quantity
	elif type == "Block Size":
		levelStats["blocksize"] = quantity
	elif type == "Associativity":
		levelStats["associativity"] = quantity
	init_upgrades()
		

## Resets the upgrades to the starting equipment, allowing for a redistribution of upgrades and coins
func _on_reset_button_pressed() -> void:
	for u in levelUpgrades:
		if not u["starter"]:		# reset everything except the starter equipment
			u["bought"] = false
		elif u["starter"]:		# reset cache config to starting equipment
			if u["type"] == "Block Number": levelStats["blocknumber"] = u["quantity"]
			if u["type"] == "Block Size": levelStats["blocksize"] = u["quantity"]
			if u["type"] == "Associativity": levelStats["associativity"] = u["quantity"]
	levelStats["coins"] = levelStats["max_coins"]
	init_upgrades()				# apply changes to shop
	display_focused_info()
		
			
		
## Unlocks better upgrades for each stage of a level.	
func unlockUpgrades(stage:int) -> void:
	if insideLevel == "Level 1":		# 10 Stages in Level 1
		match stage:
			1:
				for u in Global.level1Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 2 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 4 else false
					elif u["type"] == "Associativity":
						u["unlocked"] = true if u["quantity"] <= 2 else false
			2:
				for u in Global.level1Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 4 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 8 else false
					elif u["type"] == "Associativity":
						u["unlocked"] = true if u["quantity"] <= 4 else false
			3:
				for u in Global.level1Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 8 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 16 else false
					elif u["type"] == "Associativity":
						u["unlocked"] = true if u["quantity"] <= 8 else false
			4: 
				for u in Global.level1Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 16 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 32 else false
					elif u["type"] == "Associativity":
						u["unlocked"] = true if u["quantity"] <= 16 else false
			5:
				for u in Global.level1Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 32 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 64 else false
					elif u["type"] == "Associativity":
						u["unlocked"] = true if u["quantity"] <= 32 else false
			6:
				for u in Global.level1Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 64 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 128 else false
			7:
				for u in Global.level1Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 128 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 256 else false
			8: 
				for u in Global.level1Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 256 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 512 else false
			9:
				for u in Global.level1Upgrades: 
					if u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 1024 else false
						
	elif insideLevel == "Level 2":
		match stage:
			1:
				for u in Global.level2Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 4 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 8 else false
					elif u["type"] == "Associativity":
						u["unlocked"] = true if u["quantity"] <= 4 else false
			2:
				for u in Global.level2Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 4 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 8 else false
					elif u["type"] == "Associativity":
						u["unlocked"] = true if u["quantity"] <= 4 else false
			3:
				for u in Global.level2Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 8 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 16 else false
					elif u["type"] == "Associativity":
						u["unlocked"] = true if u["quantity"] <= 8 else false
			4: 
				for u in Global.level2Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 16 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 32 else false
					elif u["type"] == "Associativity":
						u["unlocked"] = true if u["quantity"] <= 16 else false
			5:
				for u in Global.level2Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 32 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 64 else false
					elif u["type"] == "Associativity":
						u["unlocked"] = true if u["quantity"] <= 32 else false
			6:
				for u in Global.level2Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 64 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 128 else false
			7:
				for u in Global.level2Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 128 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 256 else false
			8: 
				for u in Global.level2Upgrades: 
					if u["type"] == "Block Number":
						u["unlocked"] = true if u["quantity"] <= 256 else false
					elif u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 512 else false
			9:
				for u in Global.level2Upgrades: 
					if u["type"] == "Block Size":
						u["unlocked"] = true if u["quantity"] <= 1024 else false
						
	elif insideLevel == "Tutorial 1":
		if stage == 1:
			for u in Global.tutorial1Upgrades: 
				if u["type"] == "Block Number":
					u["unlocked"] = true if u["quantity"] <= 8 else false
				elif u["type"] == "Block Size":
					u["unlocked"] = true if u["quantity"] <= 8 else false
				elif u["type"] == "Associativity":
					u["unlocked"] = true if u["quantity"] <= 4 else false
	init_upgrades()
	
	
	
## Draws the focus outline around the currently focused upgrade option	
func set_focus_outline() -> void:
	var focused :Control =  get_viewport().gui_get_focus_owner()
	if focused == null: return
	if focused is not PanelContainer: return
	var pos : Vector2 = focused.global_position
	var offset : Vector2 = (focus_outline.size - focused.size) / 2
	# animate the movement of the focus rectangle
	var tween : Tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(focus_outline, "position", pos-offset, 0.1)
	
	
## Called from within the levels which triggers the shop to update its focus outline.
func update_focus() -> void:
	_on_blocknumber_focus_entered()



func _on_blocknumber_focus_entered() -> void:
	print("Focus on block number!")
	var x_pos = block_number_module.global_position[0]
	x_pos += (block_number_module.size[0] / 2) - (arrow.size[0]/2)
	arrow.set_position(Vector2(x_pos, 560))
	blocknumberUpgrades.visible = 	true
	blocksizeUpgrades.visible = 		false
	associativityUpgrades.visible = 	false
	# Set focus to highest unlocked (visible) upgrade
	var upgrades = blocknumberUpgrades.get_child(0).get_children()
	var highestVisible :UpgradeTemplate
	for u in upgrades:
		if u.visible: highestVisible = u
	highestVisible.grab_focus()
	set_focus_outline()


func _on_blocksize_focus_entered() -> void:
	print("Focus on block size!")
	var x_pos = block_size_module.global_position[0]
	x_pos += (block_size_module.size[0]/2) - arrow.size[0]/2
	arrow.set_position(Vector2(x_pos, 560))
	blocknumberUpgrades.visible = 	false
	blocksizeUpgrades.visible = 		true
	associativityUpgrades.visible = 	false
	# Set focus to highest unlocked (visible) upgrade
	var upgrades = blocksizeUpgrades.get_child(0).get_children()
	var highestVisible :UpgradeTemplate
	for u in upgrades:
		if u.visible: highestVisible = u
	highestVisible.grab_focus()
	set_focus_outline()
	


func _on_associativity_focus_entered() -> void:
	print("Focus on associativity!")
	var x_pos = associativity_module.global_position[0]
	x_pos += (associativity_module.size[0]/2) - arrow.size[0]/2
	arrow.set_position(Vector2(x_pos, 560))
	blocknumberUpgrades.visible = 	false
	blocksizeUpgrades.visible = 		false
	associativityUpgrades.visible = 	true
	# Set focus to highest unlocked (visible) upgrade
	var upgrades = associativityUpgrades.get_child(0).get_children()
	var highestVisible :UpgradeTemplate
	for u in upgrades:
		if u.visible: highestVisible = u
	highestVisible.grab_focus()
	set_focus_outline()
