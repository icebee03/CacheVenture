extends Node

signal displayToken

# If all levels have been played, then display unique token to enter in feedback survey and unlock it
var token : String = "-1"
var tokenExists : bool = false		# Prevent repeated code generation
var tutorialPlayed :bool = false
var level1Played : bool = false
var level2Played : bool = false


func show_survey_token() -> void:
	var timestamp : float = Time.get_unix_time_from_system()
	token = str(timestamp).sha1_text()
	var end = token.substr(len(token)-3) 	# last 3 chars of token
	end = "%x" % (end.hex_to_int() - (end.hex_to_int() % 7)) 	# make decimal conversion of end divisible by 7 (subtract the remainder)
	token = token.substr(0, len(token)-3) + end		# The last 3 numbers (in decimal/int conversion) of token are now divisible by 7
	# To check if token is valid:
	if (token.substr(len(token)-3).hex_to_int()) % 7 == 0:
		print(token)
		print("Valid Token.")
		tokenExists = true
	
	
	
func _ready() -> void:
	# Debugging:
	#show_survey_token()
	pass
	
	
