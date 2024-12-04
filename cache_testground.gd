extends Node

@onready var cache :VBoxContainer = $VBoxContainer		# TODO change the node name from "VBoxContainer" to "Cache"
@onready var button :Button = $Button
@onready var input :LineEdit = $LineEdit


func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# signal handler for when the button was pressed: sort the address from the text field into the cache
func _on_button_pressed() -> void:
	var text :String = input.get_text()
	if text == "": return
	sort_address_into_cache(text)
	input.set_text("")
	#if not text.begins_with("0x"): text = "0x"+text
	#cache.modify_cache_line(3, "keep", "keep", text, "keep", timestamp)



func sort_address_into_cache(addressString:String) -> void:
	# input validation: hex address must not be longer than 8 digits and must be a hex number
	if not is_String_32_bit_hex_number(addressString): return
	
	var address :int = addressString.hex_to_int()
	var timestamp :String = Time.get_datetime_string_from_system(false, true)
	
	# cache parameter calculations:
	var setNumber :int = cache.blockNumber / cache.associativityDegree
	var blockSize :int = 16 # in [Byte], maybe *8 if we want to access individual bits
	var offsetBits :int = log(cache.blockNumber * blockSize) / log(2)			# equivalent to log2(blockNo*blockSize)
	var indexBits :int = log(setNumber) / log(2)
	var tagBits :int = 32 - (indexBits + offsetBits)							# 32-bit address
	
	
	# ------ debugging / testing: ---------
	var bitmasks :Array[String] = create_bitmasks(tagBits, indexBits, offsetBits)
	var offsetBitmask :int = bitmasks[2].bin_to_int()
	var indexBitmask :int = bitmasks[1].bin_to_int()
	var tagBitmask :int = bitmasks[0].bin_to_int()
	var addressBinary :int = 0b1111001001111001010
	
	var debugresults :Dictionary = get_tag_index_offset(address, tagBits, indexBits, offsetBits)
	var debugtag :int = debugresults["tag"]
	var debugindex :int = debugresults["index"]
	var debugoffset :int = debugresults["offset"]
	
	print("%d blocks à %d Byte, %d sets" % [cache.blockNumber, blockSize, setNumber])	
	print("=> %d tag bits, %d index bits, %d offset bits" % [tagBits, indexBits, offsetBits])	
	print("offset Bitmask:	%32s" % bitmasks[2])
	print("index Bitmask:	%32s" % bitmasks[1])
	print("tag bitmask:		%32s" % bitmasks[0])
	print("offset:	%d" % debugoffset)
	print("index:	%d" % debugindex)
	print("tag:		%d" % debugtag)
	# ------------- end debuggin/testing -------------------------------------
	
	var results :Dictionary = get_tag_index_offset(address, tagBits, indexBits, offsetBits)
	var tag :int = results["tag"]
	var index :int = results["index"]
	var offset :int = results["offset"]
	
	# place address (tag) in one of the 'possibleLines'
	var possibleLines :Array[int] = get_line_indices_for_set(index)
	var wasLinePlaced :bool = false
	for lineIdx in possibleLines:
		var line :Dictionary = cache.get_cache_line(lineIdx)
		if line["tag"] == "" or line["tag"] == str(tag):
			cache.modify_cache_line(lineIdx,"keep","keep",str(tag), str(offset), timestamp)
			wasLinePlaced = true
			break
			
	if wasLinePlaced == false:
		# TODO: implement replacement policy
		# => choose which of the existing lines must be replaced (use "info" field of cache.get_cache_line(idx))
		pass
		
	

# Returns a dictionary containing "tag", "index", "offset" values for given address
func get_tag_index_offset(fromAddress:int, tagBits:int, indexBits:int, offsetBits:int) -> Dictionary:
	# create bitmasks to extract offset, index and tag from given address:int (does not need to be in binary)
	var bitmasks :Array[String] = create_bitmasks(tagBits, indexBits, offsetBits)
	var offsetBitmask :int = bitmasks[2].bin_to_int()
	var indexBitmask :int = bitmasks[1].bin_to_int()
	var tagBitmask :int = bitmasks[0].bin_to_int()
	# now apply the bitmasks to the least significant bits of fromAddress, shifting it to the right before applying the next bitmask
	# eg. offset = 11110000111 AND 1111 = 0111
	# eg. index = (11110000111 >> 4) AND 111 = 1111000 AND 111 = 000
	# eg. tag = (1111000 >> 3) AND 1111 = 1111 AND 1111 = 1111
	var offset :int = fromAddress & offsetBitmask
	fromAddress = fromAddress >> offsetBits
	var index :int = fromAddress & indexBitmask
	fromAddress = fromAddress >> indexBits
	var tag :int = fromAddress & tagBitmask
	
	return {"tag":tag, "index":index, "offset":offset}
		
		
# returns true if 'what' is a valid 32-bit hex number, else false
func is_String_32_bit_hex_number(what: String) -> bool:
	# length check
	if (what.begins_with("0x") and what.length() > 10) or (!what.begins_with("0x") and what.length() > 8):
		print("number too long")
		return false
	# correct digits check
	var hexDigits :String = "0123456789abcdefABCDEF"
	if what.begins_with("0x"):
		for e in what.substr(2):
			if e not in hexDigits:
				print(e + " is not a hex digit")
				return false
	else: 
		for e in what:
			if e not in hexDigits:
				print(e + " is not a hex digit")
				return false
	return true 


# returns three bitmasks that each extract the tag, index and offset from a 32-bit address: [tagBitmask, indexBitmask, offsetBitmask]
# parameters specify the length of the tag, index and offset bitmasks
# eg. in tagBitmask the bitmask is of length 'tagBits' with as many "1"s
# eg. an indexBitmask with length 3: "111"
func create_bitmasks(tagBits:int, indexBits:int, offsetBits:int) -> Array[String]:
	var offsetBitmask :String = ""				# use String concatenation to create the mask, then convert it back to int
	var indexBitmask :String = ""
	var tagBitmask :String = ""
	
	for i in range(0,tagBits):					# tag mask part
		tagBitmask += "1"
	for i in range(0,indexBits):					# index mask part
		indexBitmask += "1"
	for i in range (0,offsetBits):				# offset mask part
		offsetBitmask += "1"
		
	return [tagBitmask, indexBitmask, offsetBitmask]


# returns all line indices of a given set for the current cache configuration
func get_line_indices_for_set(set:int) -> Array[int]:
	var lines :Array[int]
	#base case i = 0: first line of set
	# 0 < i < n: next n=assoc.degree lines belong in set too
	for i in range(0, cache.associativityDegree):
		var index :int = (cache.associativityDegree * set) + i
		lines.append(index)
	return lines
