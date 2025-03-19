extends Button

var timer:Timer = Timer.new()
@onready var button : Button = $"."
@onready var progress_bar:ProgressBar = get_parent()

## Sets the duration for which the button has to be held to buy the upgrade
@export var buy_speed : float = 0.5
## A toggle to deactivate the button if the upgrade is already purchased
@export var owned : bool = false

signal upgrade_bought(price : int)


func _ready() -> void:
	progress_bar.value = progress_bar.min_value
	if owned: set_owned()
	add_child(timer)
	timer.wait_time = buy_speed
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	
	
func _process(delta: float) -> void:
	if not timer.is_stopped():
		var timer_progress : float = 1.0 - (timer.time_left / timer.wait_time)
		progress_bar.value = progress_bar.max_value * timer_progress
		
		
func set_owned() -> void:
	button.disabled = true
	button.text = "Owned"
	button.add_theme_constant_override("outline_size", 10)		#change text outline for toggled button
	var new_progress_stylebox : StyleBoxFlat = progress_bar.get_theme_stylebox("fill").duplicate()
	#new_progress_stylebox.draw_center = false
	new_progress_stylebox.bg_color = Color(0.92, 0.753, 0.202, 0.427)
	new_progress_stylebox.shadow_size = 15
	progress_bar.add_theme_stylebox_override("fill", new_progress_stylebox)
	progress_bar.value = progress_bar.max_value
		

func _on_button_down() -> void:
	timer.start()
	#button.flat = true
	

func _on_button_up() -> void:
	if timer.time_left > 0:
		timer.stop()
		progress_bar.value = 0.0
	
	
func _on_timer_timeout() -> void:
	print("Button pressed!")	
	set_owned()
	upgrade_bought.emit(5)
