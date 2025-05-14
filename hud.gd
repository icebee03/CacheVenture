extends CanvasLayer


func _ready() -> void:
	pass

func update_score(hitRate:float, missRate:float) -> void:
	hitRate = hitRate * 100 			# eg: 0.33333 -> 33.333
	missRate = missRate * 100
	$ScoreLabel.text = "[u] Score [/u]\nHit Rate: %.1f%%\nMiss Rate: %.1f%%" % [hitRate, missRate]		#display hitRate as eg. 33.3% (rounding to 1 decimal and displaying '%' char after)


func update_timer_label(time:float) -> void:
	if time == 0.0: 
		$LoopTimerLabel.text = "   Loop has started (no new addresses)"
	else:
		$LoopTimerLabel.text = "   Time until start of loop: %.0fs" % time
