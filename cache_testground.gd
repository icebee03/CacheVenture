# cacheTestground.gd
class_name CacheTestground extends Node

## The [Cache] scene where incoming addresses are stored
@onready var cache :VBoxContainer = $Cache		
## Pressing this button triggers the scene to sort the address from [member input] into the [member cache]
@onready var button :Button = $Button
## Input field to write 32-bit hex addresses into
@onready var input :LineEdit = $LineEdit
# show replaced addresses that get sent over the cache_miss signal in this text field
@onready var output:RichTextLabel = $ReplacedAddressField


## Signal handler for when the button was pressed: sort the address from the text field into the cache then clear the text field
func _on_button_pressed() -> void:
	var text :String = input.get_text()
	if text == "": return
	cache.sort_address_into_cache(text)
	input.set_text("")
	#if not text.begins_with("0x"): text = "0x"+text
	#cache.modify_cache_line(3, "keep", "keep", text, "keep", timestamp)
	


func _on_cache_cache_miss(type: Cache.cacheMissType, replacedAddress: String) -> void:
	if type == Cache.cacheMissType.CONFLICT:
		output.set_text("Replaced Address: " + replacedAddress + " (Conflict Miss)")	
	elif type == Cache.cacheMissType.CAPACITY:
		output.set_text("Replaced Address: " + replacedAddress + " (Capacity Miss)")
