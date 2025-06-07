extends Node

signal displayToken

# If all levels have been played, then display unique token to enter in feedback survey and unlock it
var token : String = "-1"
var tokenExists : bool = false		# Prevent repeated code generation
var tutorialPlayed :bool = false
var level1Played : bool = false
var level2Played : bool = false


# Global game variables
var tutorial1Stats :Dictionary = {"coins" = 0, "max_coins" = 0, "blocknumber" = 0, "blocksize"=0, "associativity"=0}
var level1Stats :Dictionary = {"coins" = 0, "max_coins" = 0, "blocknumber" = 0, "blocksize"=0, "associativity"=0}
var level2Stats :Dictionary = {"coins" = 0, "max_coins" = 0, "blocknumber" = 0, "blocksize"=0, "associativity"=0}
#var upgrade : Dictionary = {"type"="", "quantity"=0, "cost"=0, "unlocked"=false, "bought"=false}; levelXUpgrades are just Arrays of upgrades
var tutorial1Upgrades : Array[Dictionary] = []	
var level1Upgrades :Array[Dictionary] = []	# List of upgrades, filled using register_update(), and initialized/modified (bought) in upgrade_menu_2.gd
var level2Upgrades :Array[Dictionary] = []


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
	# Initialize available upgrades
	register_upgrade("Level 1", "Block Number", 2, 2, true, false)
	register_upgrade("Level 1", "Block Number", 4, 2, false, false)
	register_upgrade("Level 1", "Block Number", 8, 2, false, false)
	register_upgrade("Level 1", "Block Number", 16, 2, false, false)
	register_upgrade("Level 1", "Block Number", 32, 2, false, false)
	register_upgrade("Level 1", "Block Number", 64, 2, false, false)
	register_upgrade("Level 1", "Block Number", 128, 2, false, false)
	register_upgrade("Level 1", "Block Number", 256, 2, false, false)
	
	register_upgrade("Level 1", "Block Size", 4, 5, true, false)
	register_upgrade("Level 1", "Block Size", 8, 5, false, false)
	register_upgrade("Level 1", "Block Size", 16, 5, false, false)
	register_upgrade("Level 1", "Block Size", 32, 5, false, false)
	register_upgrade("Level 1", "Block Size", 64, 5, false, false)
	register_upgrade("Level 1", "Block Size", 128, 5, false, false)
	register_upgrade("Level 1", "Block Size", 256, 5, false, false)
	register_upgrade("Level 1", "Block Size", 512, 5, false, false)
	register_upgrade("Level 1", "Block Size", 1024, 5, false, false)
	
	register_upgrade("Level 1", "Associativity", 1, 10, true, false)
	register_upgrade("Level 1", "Associativity", 2, 10, false, false)
	register_upgrade("Level 1", "Associativity", 4, 10, false, false)
	register_upgrade("Level 1", "Associativity", 8, 10, false, false)
	register_upgrade("Level 1", "Associativity", 16, 10, false, false)
	register_upgrade("Level 1", "Associativity", 32, 10, false, false)
	
	
func register_upgrade(level:String, type:String, quantity:int, cost:int, unlocked:bool, bought:bool) -> void:
	var upgrade : Dictionary = {"type"=type, "quantity"=quantity, "cost"=cost, "unlocked"=unlocked, "bought"=bought} # read e.g. quantity = 4 (B for type ="Block Size"), and cost = 5 (Coins)
	match level:
		"Tutorial 1":
			tutorial1Upgrades.append(upgrade)
		"Level 1": 
			level1Upgrades.append(upgrade)
		"Level 2":
			level2Upgrades.append(upgrade)
		_:
			print("Can't register upgrades to non-existent levels.")
	
