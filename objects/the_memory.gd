# the_memory.gd
class_name TheMemory extends Node2D

# Signals
## Emitted when health drops to zero. Game Over.
signal dead()

# Have references to crystals to hide when health drops
@onready var crystalBlue_small1 = 	$"Crystals/CrystalBlue Small 1"
@onready var crystalGreen_big = 	$"Crystals/CrystalGreen Big"
@onready var crystalViolet_big = 	$"Crystals/CrystalViolet Big"
@onready var crystalBlue_medium1 = 	$"Crystals/CrystalBlue Medium 1"
@onready var crystalBlue_medium2 = 	$"Crystals/CrystalBlue Medium 2"
@onready var crystalLime_small = 	$"Crystals/CrystalLime Small"
@onready var MAINcrystalBlue = 		$"Crystals/MAIN CrystalBlue"
@onready var crystalBlue_small2 = 	$"Crystals/CrystalBlue Small 2"
@onready var crystalBlue_small3 = 	$"Crystals/CrystalBlue Small 3"
@onready var crystalBlue_small4	= 	$"Crystals/CrystalBlue Small 4"
@onready var crystalViolet_small = 	$"Crystals/CrystalViolet Small"
@onready var crystalBlue_medium3 = 	$"Crystals/CrystalBlue Medium 3"
@onready var crystalBlue_small5 = 	$"Crystals/CrystalBlue Small 5"
@onready var crystalGreen_small = 	$"Crystals/CrystalGreen Small"
## The order in which crystals are toggled invisible to visualize health and taken damage
@onready var visibilityOrder :Array[Sprite2D] = [crystalBlue_small4, crystalBlue_small3, crystalBlue_medium2, crystalViolet_small, crystalBlue_small1, 
	crystalViolet_big, crystalBlue_small2, crystalGreen_big, crystalBlue_small5, crystalGreen_small, crystalBlue_medium3, 
	crystalLime_small, crystalBlue_medium1, MAINcrystalBlue]

# References to Healthbar and related objects
@onready var healthbar = $Healthbar
@onready var damagebar = $Healthbar/DamageBar
@onready var showDamageTimer = $Healthbar/ShowDamageTimer


# Variables
## Health of the memory. 
## DO NOT MODIFY this variable directly! Instead use functions add/subtract_health(amount) (they will update other items too depending on this health value).
var health :float


func _ready() -> void:
	health = healthbar.max_value
	await get_tree().create_timer(3).timeout
	subtract_health(3)
	
	

## When an address hits the crystals.
## Calls handler functions.
func _on_hitbox_area_entered(area: Area2D) -> void:
	subtract_health(5.0)
	play_damage_animation()
	

## Adds [amount] health to the healt of the memory.
## Possible use-case: regeneration of health
func add_health(amount:float) -> void:
	if health + amount >= healthbar.max_value:
		return	# do nothing
	health += amount
	update_healthbar()
	update_crystals_visible()
	
	
## Substracts [amount] health from the health of the memory.
func subtract_health(amount:float) -> void:
	health -= amount
	update_healthbar() 
	update_damagebar()
	update_crystals_visible()
	if health <= 0:
		emit_signal("dead")		# Game Over.
		print("Game Over.")
	

## Updates the health bar with the current health value.
func update_healthbar() -> void:
	healthbar.value = health
	

## Adds little delay before updating the damage bar
func update_damagebar() -> void:
	showDamageTimer.start()
	await showDamageTimer.timeout
	damagebar.value = health
	

## Updates the amount of crystals that are visible, depending on the health.
func update_crystals_visible() -> void:
	if health == 100: for e in visibilityOrder: e.visible = true
	elif health >= 92: 
		for e in visibilityOrder.slice(0, 1): e.visible = false
		for e in visibilityOrder.slice(1): e.visible = true
	#TODO: do this for every stage
	#elif health >= 92: 
		#for e in visibilityOrder.slice(0, 1): e.visible = false
		#for e in visibilityOrder.slice(1): e.visible = true
	elif health == 0: for e in visibilityOrder: e.visible = false
			
	
	
## Plays a red animation on the crystals and shakes the screen
func play_damage_animation() -> void:
	pass
