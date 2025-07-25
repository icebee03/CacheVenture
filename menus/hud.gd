extends Control

# For Tutorial:
@export var eventLogVisible :bool = true
@export var scoreVisible :bool = true
@export var speedControlVisible :bool = true

## Toggle to disable speed inputs, if e.g. pause or stage passed menu is shown
@export var disableSpeed :bool = false

@onready var stopButton = $"Speed Controls/HBoxContainer/StopButton"
@onready var halfSpeedButton = $"Speed Controls/HBoxContainer/HalfSpeedButton"
@onready var normalSpeedButton = $"Speed Controls/HBoxContainer/NormalSpeedButton"
@onready var twiceSpeedButton = $"Speed Controls/HBoxContainer/TwiceSpeedButton"
@onready var tripleSpeedButton = $"Speed Controls/HBoxContainer/TripleSpeedButton"
@onready var quadrupleSpeedButton = $"Speed Controls/HBoxContainer/QuadrupleSpeedButton"
@onready var slider : Slider = $"Speed Controls/SpeedSlider"
@onready var chatlog: TextEdit = $ChatLogControl/MarginContainer/ChatLogTextEdit
	

func update_score(hitRate:float, missRate:float) -> void:
	hitRate = hitRate * 100 			# eg: 0.33333 -> 33.333
	missRate = missRate * 100
	$ScoreLabel.text = "[u] Score [/u]\nHit Rate: %.1f%%\nMiss Rate: %.1f%%" % [hitRate, missRate]		#display hitRate as eg. 33.3% (rounding to 1 decimal and displaying '%' char after)


func update_timer_label(time:float) -> void:
	if time == 0.0: 
		$LoopTimerLabel.text = ""
	else:
		$LoopTimerLabel.text = "   Time until start of loop: %.0fs" % time
		
		
func display_chat_message(msg:String) -> void:
	chatlog.text += msg + "\n"
	var lineCount :int = chatlog.get_line_count()
	# Limit the amount of messages (otherwise steady increase of memory use and potentially performance drops)
	# To see impact of limiting: While the game is running, open Debugger->Monitors in the Editor, check Memory(Static) and Objects
	var msgLimit :int = 500
	if lineCount > msgLimit:
		chatlog.text = chatlog.text.substr(lineCount-msgLimit)	# Keep only the most recent 500 messages, cut off the rest (older ones)
	chatlog.scroll_vertical = lineCount		# For autoscroll to bottom, e.g. newest message
	

## Enables input to speed buttons and slider movement
func enableSpeedControl() -> void:
	stopButton.disabled = false
	halfSpeedButton.disabled = false
	normalSpeedButton.disabled = false
	twiceSpeedButton.disabled = false
	tripleSpeedButton.disabled = false
	quadrupleSpeedButton.disabled = false

## Disables input to speed buttons (e.g. by mistake from pause menu with shortcut) and slider movement
func disableSpeedControl() -> void:
	stopButton.disabled = true
	halfSpeedButton.disabled = true
	normalSpeedButton.disabled = true
	twiceSpeedButton.disabled = true
	tripleSpeedButton.disabled = true
	quadrupleSpeedButton.disabled = true
	


## Changes the game speed based on slider input (0x -- 4x possible)
func change_game_speed(factor:float) -> void:
	if factor == 0.0:
		get_tree().paused = true
	else:
		get_tree().paused = false
		Engine.time_scale = factor


# stop gameplay for closer inspection
func _on_stop_button_pressed() -> void:
	slider.value = 0.0


# set gameplay to normal speed
func _on_normal_speed_button_pressed() -> void:
	slider.value = 1.0


func _on_half_speed_button_pressed() -> void:
	slider.value = 0.5


func _on_twice_speed_button_pressed() -> void:
	slider.value = 2.0


func _on_triple_speed_button_pressed() -> void:
	slider.value = 3.0


func _on_quadruple_speed_button_pressed() -> void:
	slider.value = 4.0


func _on_speed_multiplier_value_changed(value: float) -> void:
	#debouncing timer (hopefully works)
	await get_tree().create_timer(0.01).timeout
	change_game_speed(value)
	
	
## Restores Hit and Miss rates, empties Event Log, sets speed to 1
func reset() -> void:
	update_score(0.0, 0.0)
	chatlog.text = ""
	slider.value = 1.0
	change_game_speed(1.0)
	enableSpeedControl()
	
