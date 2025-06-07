extends Control

## Valid: "Level 1", "Level 2" or "Tutorial 1"
@export var insideLevel :String = "Level 1"

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
@onready var arrow : Label = $"Module Arrow"
@onready var focus_outline : PanelContainer = $"Focus Outline"
@onready var block_number_module = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Blocknumber"
@onready var block_size_module = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Blocksize"
@onready var associativity_module = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Associativity"

@onready var blocknumberUpgrades = $"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Block Number Upgrades"
@onready var blocksizeUpgrades = $"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Block Size Upgrades"
@onready var associativityUpgrades = $"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Associativity Upgrades"
const UpgradeTemplate = preload("res://menus/upgrade_template.tscn")



func _ready() -> void:
	update_displays()
	init_upgrades()
	_on_blocknumber_focus_entered()
	coins_label.text = str(Global.level1Stats["coins"])+" 🪙 / "+str(Global.level1Stats["max_coins"])+" 🪙"
	
	

func _process(delta: float) -> void:
	update_displays()
	display_focused_info()
	set_focus_outline()
	coins_label.text = str(Global.level1Stats["coins"])+" 🪙 / "+str(Global.level1Stats["max_coins"])+" 🪙"
	

func update_displays() -> void:
	blocknumberLabel.text = str(Global.level1Stats["blocknumber"])
	blocksizeLabel.text = str(Global.level1Stats["blocksize"])+" B"
	associativityLabel.text = str(Global.level1Stats["associativity"])+"x"
	
	
## Adds the upgrades from Global.levelXUpgrades to the scene with appropiate settings.
## Visible if unlocked.
func init_upgrades() -> void:
	# Firstly, delete all previously existing / outdated upgrades
	var free_list = $"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Block Number Upgrades/GridContainer".get_children()
	free_list.append_array($"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Block Size Upgrades/GridContainer".get_children())
	free_list.append_array($"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Associativity Upgrades/GridContainer".get_children())
	for e in free_list: e.queue_free()
	if insideLevel == "Level 1":
		for upgrade in Global.level1Upgrades:
			if upgrade["type"] == "Block Number":
				var new = UpgradeTemplate.instantiate()
				new.set_text(str(upgrade["quantity"]))
				new.visible = upgrade["unlocked"]
				new.upgrade = upgrade
				blocknumberUpgrades.get_child(0).add_child(new)
			elif upgrade["type"] == "Block Size":
				var new = UpgradeTemplate.instantiate()
				new.set_text(str(upgrade["quantity"])+" B")
				new.visible = upgrade["unlocked"]
				new.upgrade = upgrade
				blocksizeUpgrades.get_child(0).add_child(new)
			elif upgrade["type"] == "Associativity":
				var new = UpgradeTemplate.instantiate()
				new.set_text(str(upgrade["quantity"])+"x")
				new.visible = upgrade["unlocked"]
				new.upgrade = upgrade
				associativityUpgrades.get_child(0).add_child(new)
	elif insideLevel == "Level 2":
		pass	# TODO: do the same as for Level 1, but use Global.level2Upgrades
	elif insideLevel == "Tutorial 1":
		pass	# TODO: do the same as for Level 1, but use Global.tutorial1Upgrades


func _on_back_button_pressed() -> void:
	visible = false
	
	
func display_focused_info() -> void:
	# Get current focus owner	
	var upgradeChoice : Control = get_viewport().gui_get_focus_owner()
	if upgradeChoice == null or upgradeChoice is not UpgradeTemplate: return	# Disregard any that are not valid upgrade choices (i.e. other ui elements)
	# Search for matching Global upgrade and save its index and contents for reference
	var idx :int			# index of this upgrade inside of Global.levelXUpgrades
	var type :String
	var quantity :int
	var cost :int
	var bought :bool
	if insideLevel == "Level 1":
		for i in range(len(Global.level1Upgrades)):
			if Global.level1Upgrades[i]["type"] == upgradeChoice.upgrade["type"] and Global.level1Upgrades[i]["quantity"] == upgradeChoice.upgrade["quantity"]:
				idx = i
				type = Global.level1Upgrades[idx]["type"]
				quantity = Global.level1Upgrades[idx]["quantity"]
				cost = Global.level1Upgrades[idx]["cost"]
				bought = Global.level1Upgrades[idx]["bought"]
	elif insideLevel == "Level 2":
		for i in range(len(Global.level2Upgrades)):
			if Global.level2Upgrades[i]["type"] == upgradeChoice.upgrade["type"] and Global.level2Upgrades[i]["quantity"] == upgradeChoice.upgrade["quantity"]:
				idx = i
				type = Global.level2Upgrades[idx]["type"]
				quantity = Global.level2Upgrades[idx]["quantity"]
				cost = Global.level2Upgrades[idx]["cost"]
				bought = Global.level2Upgrades[idx]["bought"]
	elif insideLevel == "Tutorial 1":
		for i in range(len(Global.tutorial1Upgrades)):
			if Global.tutorial1Upgrades[i]["type"] == upgradeChoice.upgrade["type"] and Global.tutorial1Upgrades[i]["quantity"] == upgradeChoice.upgrade["quantity"]:
				idx = i
				type = Global.tutorial1Upgrades[idx]["type"]
				quantity = Global.tutorial1Upgrades[idx]["quantity"]
				cost = Global.tutorial1Upgrades[idx]["cost"]
				bought = Global.tutorial1Upgrades[idx]["bought"]

	# Depending on upgrade["type"] and ["cost"], display info and description on the right
	upgrade_title.text = type
	if type == "Block Number":
		upgrade_quantity.text = str(quantity)
		upgrade_description.text = "Upgrades the amount of blocks the cache can hold."
		upgrade_cost.text = "Upgrade Cost: %d 🪙" % cost
	if type == "Block Size":
		upgrade_quantity.text = str(quantity)+" B"
		upgrade_description.text = "Upgrades the amount of data each block can hold."
		upgrade_cost.text = "Upgrade Cost: %d 🪙" % cost
	if type == "Associativity":
		upgrade_quantity.text = str(quantity)+"x"
		upgrade_description.text = "Upgrades the amount of blocks each set holds."
		upgrade_cost.text = "Upgrade Cost: %d 🪙" % cost
	if bought: upgrade_button.set_owned()
	else: 
		if Global.level1Stats["coins"] - cost < 0:
			upgrade_button.set_prohibited()		# Then you cannot buy the upgrade
			#TODO: maybe add other constraints such as that associativity cannot be larger than blocknumber
		else:
			upgrade_button.set_not_owned()
		


func _on_upgrade_button_upgrade_bought(price: int) -> void:
	# Get upgrade that is currently viewed and store its index for reference to Global.levelXUpgrades:
	#var idx :int
	#for i in range(len(Global.level1Upgrades)):
		#if Global.level1Upgrades[i]["type"] == upgrade_title.text and Global.level1Upgrades[i]["quantity"] == upgrade_quantity.text.to_int():
			#idx = i
	#var type:String = Global.level1Upgrades[idx]["type"]
	#var quantity:int = Global.level1Upgrades[idx]["quantity"]
	#var cost:int = Global.level1Upgrades[idx]["cost"]
	
	var idx :int			# index of this upgrade inside of Global.levelXUpgrades
	var type :String
	var quantity :int
	var cost :int
	var bought :bool
	if insideLevel == "Level 1":
		for i in range(len(Global.level1Upgrades)):
			if Global.level1Upgrades[i]["type"] == upgrade_title.text and Global.level1Upgrades[i]["quantity"] == upgrade_quantity.text.to_int():
				idx = i
				type = Global.level1Upgrades[idx]["type"]
				quantity = Global.level1Upgrades[idx]["quantity"]
				cost = Global.level1Upgrades[idx]["cost"]
		Global.level1Upgrades[idx]["bought"] = true
		Global.level1Stats["coins"] -= cost
		if type == "Block Number":
			Global.level1Stats["blocknumber"] = quantity
		elif type == "Block Size":
			Global.level1Stats["blocksize"] = quantity
		elif type == "Associativity":
			Global.level1Stats["associativity"] = quantity
			
	elif insideLevel == "Level 2":
		for i in range(len(Global.level2Upgrades)):
			if Global.level2Upgrades[i]["type"] == upgrade_title.text and Global.level2Upgrades[i]["quantity"] == upgrade_quantity.text.to_int():
				idx = i
				type = Global.level2Upgrades[idx]["type"]
				quantity = Global.level2Upgrades[idx]["quantity"]
				cost = Global.level2Upgrades[idx]["cost"]
		Global.level2Upgrades[idx]["bought"] = true
		Global.level2Stats["coins"] -= cost
		if type == "Block Number":
			Global.level2Stats["blocknumber"] = quantity
		elif type == "Block Size":
			Global.level2Stats["blocksize"] = quantity
		elif type == "Associativity":
			Global.level2Stats["associativity"] = quantity
			
	elif insideLevel == "Tutorial 1":
		for i in range(len(Global.tutorial1Upgrades)):
			if Global.tutorial1Upgrades[i]["type"] == upgrade_title.text and Global.tutorial1Upgrades[i]["quantity"] == upgrade_quantity.text.to_int():
				idx = i
				type = Global.tutorial1Upgrades[idx]["type"]
				quantity = Global.tutorial1Upgrades[idx]["quantity"]
				cost = Global.tutorial1Upgrades[idx]["cost"]
		Global.tutorial1Upgrades[idx]["bought"] = true
		Global.tutorial1Stats["coins"] -= cost
		if type == "Block Number":
			Global.tutorial1Stats["blocknumber"] = quantity
		elif type == "Block Size":
			Global.tutorial1Stats["blocksize"] = quantity
		elif type == "Associativity":
			Global.tutorial1Stats["associativity"] = quantity
			
		
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
		pass
	elif insideLevel == "Tutorial 1":
		pass
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



func _on_blocknumber_focus_entered() -> void:
	print("Focus on block number!")
	var x_pos = block_number_module.global_position[0]
	x_pos += (block_number_module.size[0] / 2) - (arrow.size[0]/2)
	arrow.set_position(Vector2(x_pos, 400))
	blocknumberUpgrades.visible = 	true
	blocksizeUpgrades.visible = 		false
	associativityUpgrades.visible = 	false


func _on_blocksize_focus_entered() -> void:
	print("Focus on block size!")
	var x_pos = block_size_module.global_position[0]
	x_pos += (block_size_module.size[0]/2) - arrow.size[0]/2
	arrow.set_position(Vector2(x_pos, 400))
	blocknumberUpgrades.visible = 	false
	blocksizeUpgrades.visible = 		true
	associativityUpgrades.visible = 	false


func _on_associativity_focus_entered() -> void:
	print("Focus on associativity!")
	var x_pos = associativity_module.global_position[0]
	x_pos += (associativity_module.size[0]/2) - arrow.size[0]/2
	arrow.set_position(Vector2(x_pos, 400))
	blocknumberUpgrades.visible = 	false
	blocksizeUpgrades.visible = 		false
	associativityUpgrades.visible = 	true
