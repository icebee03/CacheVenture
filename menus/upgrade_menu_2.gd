extends Control

# To set the starting configuration from outside
@export var current_blocknumber :int = 2
@export var current_blocksize :int = 16
@export var current_associativity :int = 2

# Widgets that display the current selected setting
@onready var blocknumberLabel = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Blocknumber/PanelContainer/BlockNumberLabel"
@onready var blocksizeLabel = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Blocksize/PanelContainer/BlockSizeLabel"
@onready var associativityLabel = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Associativity/PanelContainer/AssociativityLabel"

# For the right-hand side of the menu (buying & displaying info)
var upgrade_type : String 
@onready var upgrade_icon : Label = $"VBox/Bottom/Right Side/Details/Info & Buy Button/Info & Buy Button/Info & Buy Button/Icon/Upgrade Icon/Upgrade Label"
@onready var upgrade_info_text : Label = $"VBox/Bottom/Right Side/Details/Info & Buy Button/Info & Buy Button/Info & Buy Button/Upgrade Info Text"
@onready var upgrade_cost : Label = $"VBox/Bottom/Right Side/Details/Info & Buy Button/Info & Buy Button/Info & Buy Button/Upgrade Cost & Button/Upgrade Cost"

# For the bottom part of the menu: The lists of different upgrade options for individual modules
@onready var arrow : Label = $"Module Arrow"
@onready var focus_outline : PanelContainer = $"Focus Outline"
@onready var info_and_buy : VBoxContainer = $"VBox/Bottom/Right Side/Details/Info & Buy Button/Info & Buy Button/Info & Buy Button"
@onready var upgrade_title : RichTextLabel = $"VBox/Bottom/Right Side/Details/Info & Buy Button/Info & Buy Button/Info & Buy Button/Upgrade Title"
@onready var block_number_module = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Blocknumber"
@onready var block_size_module = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Blocksize"
@onready var associativity_module = $"VBox/Bottom/Left Side/VBoxContainer/Module Selector/Margin/HBox/Associativity"
@onready var blocknumberUpgrades = $"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Block Number Upgrades"
@onready var blocksizeUpgrades = $"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Block Size Upgrades"
@onready var associativityUpgrades = $"VBox/Bottom/Left Side/VBoxContainer/Upgrade Options/Associativity Upgrades"



func _ready() -> void:
	update_displays()
	

func _process(delta: float) -> void:
	update_displays()
	display_focused_info()
	set_focus_outline()


func update_displays() -> void:
	blocknumberLabel.text = str(current_blocknumber)
	blocksizeLabel.text = str(current_blocksize)+" B"
	associativityLabel.text = str(current_associativity)+"x"


func _on_back_button_pressed() -> void:
	visible = false
	
	
func display_focused_info() -> void:
	var focused :Control =  get_viewport().gui_get_focus_owner()
	if focused == null: return
	if focused is not PanelContainer: return
	var focused_child_0 = focused.get_child(0)
	if focused_child_0 == null: return
	var upgrade_text : String = focused_child_0.text
	upgrade_icon.text = upgrade_text
	upgrade_type = upgrade_title.text
	if upgrade_type == "Block Number":
		var info_text : String = "%s" % upgrade_text
		upgrade_info_text.text = info_text
		upgrade_cost.text = "Upgrade Cost: 5 🪙"
	elif upgrade_type == "Block Size":
		var info_text : String = "Stores %syte of Data in each block.\n\n+SPATIAL PERFORMANCE" % upgrade_text
		upgrade_info_text.text = info_text
		upgrade_cost.text = "Upgrade Cost: 2 🪙"
	elif upgrade_type == "Degree of Associativity":
		var info_text : String = "%s" % upgrade_text
		upgrade_info_text.text = info_text
		upgrade_cost.text = "Upgrade Cost: 10 🪙"


func _on_upgrade_button_upgrade_bought(price: int) -> void:
	var new_text:String = $"VBox/Bottom/Right Side/Details/Coins Display/Currency Label".text
	var first_slice:String = new_text.get_slice(" ", 0)
	var coins = first_slice.to_int()
	coins = coins - price
	new_text = new_text.replace(first_slice, str(coins))
	$"VBox/Bottom/Right Side/Details/Coins Display/Currency Label".text = new_text
	
	
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
	upgrade_title.text = "Block Number"
	blocknumberUpgrades.visible = 	true
	blocksizeUpgrades.visible = 		false
	associativityUpgrades.visible = 	false


func _on_blocksize_focus_entered() -> void:
	print("Focus on block size!")
	var x_pos = block_size_module.global_position[0]
	x_pos += (block_size_module.size[0]/2) - arrow.size[0]/2
	arrow.set_position(Vector2(x_pos, 400))
	upgrade_title.text = "Block Size"
	blocknumberUpgrades.visible = 	false
	blocksizeUpgrades.visible = 		true
	associativityUpgrades.visible = 	false


func _on_associativity_focus_entered() -> void:
	print("Focus on associativity!")
	var x_pos = associativity_module.global_position[0]
	x_pos += (associativity_module.size[0]/2) - arrow.size[0]/2
	arrow.set_position(Vector2(x_pos, 400))
	upgrade_title.text = "Degree of Associativity"
	blocknumberUpgrades.visible = 	false
	blocksizeUpgrades.visible = 		false
	associativityUpgrades.visible = 	true
