# cache.gd
class_name Cache extends VBoxContainer

#------ Variables ----------------

@export_group("Cache Properties")
## The amount of blocks that go into the cache.
@export var blockNumber :int
## The amount of blocks that go into one set.
@export var associativityDegree :int
## The replacement policy decides which cache line must be replaced upon a conflict or capacity cache miss.
@export_enum("Random", "LRU", "LFU") var replacementPolicy: String = "Random"

# Private (underscore) count that is used in _add_cache_line()
var _blockCount:int = 0

## This is where all the information is stored, eg. the "cache" 
@onready var cacheBody :ItemList = $CacheBody

## The top of the cache list that stores the column names
@onready var cacheHeader :ItemList = $Header


#--------- Constructor ----------------------

## Initializes the cache and fills it with [member blockNumber] many empty lines.
func _ready() -> void:	
	var setTmp :int = 0
	var setCounter :int = 0
	
	# dynamic tree creation depending on @blockNumber and @associativityDegree
	for i in range(0, blockNumber):
		if (setTmp == associativityDegree):
			setCounter += 1
			setTmp = 0
		setTmp += 1
		
		_add_cache_line(str(i), str(setCounter), "", "")	
		
	#_modify_cache_line(3, "----","-----","keep","----","keep")
	
	
#------------- Public functions ------------------	
	
## This function sorts the given [param addressString] into the [Cache] scene. It calculates various parameters and extracts tag, index and offset from the address.
func sort_address_into_cache(addressString:String) -> void:
	# input validation: hex address must not be longer than 8 digits and must be a hex number
	if not _is_String_32_bit_hex_number(addressString): return
	
	var address :int = addressString.hex_to_int()
	var timestamp :String = Time.get_datetime_string_from_system(false, true)
	
	# cache parameter calculations:
	var setNumber :int = blockNumber / associativityDegree
	var blockSize :int = 16 # in [Byte], maybe *8 if we want to access individual bits
	var offsetBits :int = log(blockSize) / log(2)			# equivalent to log2(blockSize)
	var indexBits :int = log(setNumber) / log(2)
	var tagBits :int = 32 - (indexBits + offsetBits)							# 32-bit address
	
	
	# ------ debugging / testing: ---------
	var bitmasks :Array[String] = _create_bitmasks(tagBits, indexBits, offsetBits)
	var offsetBitmask :int = bitmasks[2].bin_to_int()
	var indexBitmask :int = bitmasks[1].bin_to_int()
	var tagBitmask :int = bitmasks[0].bin_to_int()
	var addressBinary :int = 0b1111001001111001010
	
	var debugresults :Dictionary = _get_tag_index_offset(address, tagBits, indexBits, offsetBits)
	var debugtag :int = debugresults["tag"]
	var debugindex :int = debugresults["index"]
	var debugoffset :int = debugresults["offset"]
	
	print("%d blocks à %d Byte, %d sets" % [blockNumber, blockSize, setNumber])	
	print("=> %d tag bits, %d index bits, %d offset bits" % [tagBits, indexBits, offsetBits])	
	print("offset Bitmask:	%32s" % bitmasks[2])
	print("index Bitmask:	%32s" % bitmasks[1])
	print("tag bitmask:		%32s" % bitmasks[0])
	print("offset:	%d" % debugoffset)
	print("index:	%d" % debugindex)
	print("tag:		%d" % debugtag)
	# ------------- end debuggin/testing -------------------------------------
	
	var results :Dictionary = _get_tag_index_offset(address, tagBits, indexBits, offsetBits)
	var tag :int = results["tag"]
	var index :int = results["index"]
	var offset :int = results["offset"]
	
	# place address (tag) in one of the 'possibleLines'
	var possibleLines :Array[int] = _get_line_indices_for_set(index)
	var wasLinePlaced :bool = false
	for lineIdx in possibleLines:
		var line :Dictionary = _get_cache_line(lineIdx)
		if line["tag"] == "" or line["tag"] == str(tag):
			_modify_cache_line(lineIdx,"keep","keep",str(tag), timestamp)		
			wasLinePlaced = true
			break
	#TODO: implement cache hit procedure that updates the info field according to the chosen replacement policy (eg. a hit count for LFU, ...)
			
	# in case of a cache miss (due to conflict or capacity):		
	var replacedLine :Dictionary
	if wasLinePlaced == false:	
		# choose which of the existing lines must be replaced and update that line. For now no action regarding the replaced address (like showing it into the world)
		var lineToReplace :int = _choose_line_to_replace(possibleLines)
		if lineToReplace == -1: return
		replacedLine = _get_cache_line(lineToReplace)				#TODO: do something with it (show it in the world)
		_modify_cache_line(lineToReplace,"keep","keep",str(tag),"replaced at random")		#TODO: change 'info' message depending on replacement policy
		wasLinePlaced = true
			
	#TODO: implement cache conflict/replaced procedure that puts replaced lines into a list or so
		
		
#---------- "Private"/Internal functions, do not call from outside (usually) ----------------

## Adds the line consisting of parameters [param block] ... [param info] to the end of the cache. Ignores new lines exceeding the [member blockNumber] limit
func _add_cache_line(block:String="0", set:String="0", tag:String="0x0", info:String="...") -> void:
	if(_blockCount >= blockNumber): return
	cacheBody.add_item(block)
	cacheBody.add_item(set)
	cacheBody.add_item(tag)
	cacheBody.add_item(info)
	_blockCount += 1


## Modifes the cache line parameters at [param index]. Ignores indices that point to non-existent cache lines.
## Parameters with the String keyword [code]"keep"[/code] do not modify their respective value
func _modify_cache_line(index:int, block:String, set:String, tag:String, info:String) -> void:
	if(index < 0 or index >= blockNumber): return
	index *= cacheBody.get_max_columns()							# index calculation: index represents the row index
	if block != "keep": 	cacheBody.set_item_text(index, block)
	if set != "keep": 	cacheBody.set_item_text(index+1, set)
	if tag != "keep": 	cacheBody.set_item_text(index+2, tag)
	if info != "keep": 	cacheBody.set_item_text(index+3, info)
	

## Returns the cache line parameters at [param index]. Ignores indices that point to non-existent cache lines
func _get_cache_line(index:int) -> Dictionary:
	if(index < 0 or index >= blockNumber): return {}
	index *= cacheBody.get_max_columns()
	return {	"block" : cacheBody.get_item_text(index),
			"set" : cacheBody.get_item_text(index+1),
			"tag" : cacheBody.get_item_text(index+2),
			"info" : cacheBody.get_item_text(index+3)}
	

## Returns [code]true[/code] if [param what] is a valid 32-bit hex number, else [code]false[/code]
func _is_String_32_bit_hex_number(what: String) -> bool:
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
	
	
## Returns three bitmasks that each extract the tag, index and offset from a 32-bit address with following structure: [code][tagBitmask, indexBitmask, offsetBitmask][/code].
## Parameters specify the length of the tag, index and offset bitmasks
## eg. the [code]tagBitmask[/code] has [param tagBits] many [i]1[/i]s [br]
## Example: [code]indexBitmask[/code] of length 3 = [code]"111"[/code]
func _create_bitmasks(tagBits:int, indexBits:int, offsetBits:int) -> Array[String]:
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
	

## Returns a dictionary containing "tag", "index", "offset" values for given address
func _get_tag_index_offset(fromAddress:int, tagBits:int, indexBits:int, offsetBits:int) -> Dictionary:
	# create bitmasks to extract offset, index and tag from given address:int (does not need to be in binary)
	var bitmasks :Array[String] = _create_bitmasks(tagBits, indexBits, offsetBits)
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
	

## returns all line indices of a given set for the current cache configuration
func _get_line_indices_for_set(set:int) -> Array[int]:
	var lines :Array[int]
	#base case i = 0: first line of set
	# 0 < i < n: next n=assoc.degree lines belong in set too
	for i in range(0, associativityDegree):
		var index :int = (associativityDegree * set) + i
		lines.append(index)
	return lines
	
	
## returns the cache line from 'lines' that must be replaced, according to the 'replacementPolicy'
## the "info" field of the cache line may be considered to choose which line to replace
## returns -1 on error
## => choose which of the existing lines must be replaced (use "info" field of cache._get_cache_line(idx))
func _choose_line_to_replace(lines:Array[int]) -> int:
	if len(lines) == 0: return -1
	if len(lines) == 1: return lines[0]
	# implement all the usual replacement policies (capsulate later into own functions):
	match replacementPolicy:
		"LRU":		# chooses the line with the oldest hit
			pass
		"LFU":		# chooses the line with the lowest hit count
			pass
		"Random": 	# chooses a random line from lines that is within that range
			var rng:RandomNumberGenerator = RandomNumberGenerator.new()
			return rng.randi_range(lines[0], lines[len(lines)-1])		
		_:			# default case. No replacementPolicy was set, so return error
			return -1
	
	return -1	
