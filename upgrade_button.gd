extends Button

var timer:Timer = Timer.new()
@onready var button : Button = $"."
@onready var progress_bar:ProgressBar = get_parent()

## Sets the duration for which the button has to be held to buy the upgrade
@export var buy_speed : float = 0.5

signal upgrade_bought(price : int)

const progressBarNotOwned:StyleBoxFlat = preload("res://menus/progressBarFillStyleboxNotOwned.tres")
const buttonNotEnoughCoins :StyleBoxFlat = preload("res://menus/upgradeButtonNotEnoughCoins.tres")
const buttonEnoughCoins :StyleBoxFlat = preload("res://menus/upgradeButton.tres")

var too_poor:bool = false


func _ready() -> void:
	progress_bar.value = progress_bar.min_value
	add_child(timer)
	timer.wait_time = buy_speed
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	set_prohibited("Not enough coins!")
	
	
func _process(delta: float) -> void:
	if not timer.is_stopped():
		var timer_progress : float = 1.0 - (timer.time_left / timer.wait_time)
		progress_bar.value = progress_bar.max_value * timer_progress
		
		
func set_owned() -> void:
	button.disabled = true
	too_poor = false
	button.text = "Owned"
	button.add_theme_constant_override("outline_size", 10)		#change text outline for toggled button
	button.add_theme_stylebox_override("normal", buttonEnoughCoins)
	button.add_theme_stylebox_override("focus", buttonEnoughCoins)
	button.add_theme_stylebox_override("hover", buttonEnoughCoins)
	button.add_theme_stylebox_override("pressed", buttonEnoughCoins)
	progress_bar.add_theme_stylebox_override("fill", progressBarNotOwned)
	var new_progress_stylebox : StyleBoxFlat = progress_bar.get_theme_stylebox("fill").duplicate()
	new_progress_stylebox.bg_color = Color(0.92, 0.753, 0.202, 0.427)
	new_progress_stylebox.shadow_size = 15
	progress_bar.add_theme_stylebox_override("fill", new_progress_stylebox)
	progress_bar.value = progress_bar.max_value
	
	
func set_not_owned() -> void:
	button.disabled = false
	too_poor = false
	button.text = "Purchase"
	button.add_theme_constant_override("outline_size", 0)
	button.add_theme_stylebox_override("normal", buttonEnoughCoins)
	button.add_theme_stylebox_override("focus", buttonEnoughCoins)
	button.add_theme_stylebox_override("hover", buttonEnoughCoins)
	button.add_theme_stylebox_override("pressed", buttonEnoughCoins)
	progress_bar.add_theme_stylebox_override("fill", progressBarNotOwned)
	progress_bar.value = progress_bar.min_value
	
	
func set_prohibited(text:String) -> void:
	too_poor = true
	button.disabled = false
	button.text = text
	button.add_theme_constant_override("outline_size", 0)
	button.add_theme_stylebox_override("normal", buttonNotEnoughCoins)
	button.add_theme_stylebox_override("focus", buttonNotEnoughCoins)
	button.add_theme_stylebox_override("hover", buttonNotEnoughCoins)
	button.add_theme_stylebox_override("pressed", buttonNotEnoughCoins)
	progress_bar.add_theme_stylebox_override("fill", progressBarNotOwned)
	progress_bar.value = progress_bar.min_value

		

func _on_button_down() -> void:
	if too_poor: return
	timer.start()
	print("I am here!")
	#button.flat = true
	

func _on_button_up() -> void:
	if timer.time_left > 0:
		timer.stop()
		progress_bar.value = 0.0
	
	
func _on_timer_timeout() -> void:
	print("Button pressed!")	
	set_owned()
	upgrade_bought.emit(5)
