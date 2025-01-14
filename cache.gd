# cache.gd
class_name Cache extends VBoxContainer

# Signals
## Emitted when the tag of an address is found in the cache
signal cacheHit
## Emitted when the tag of an address is not found in the cache. Three types of misses possible (see [enum cacheMissType])
signal cacheMiss(type:cacheMissType, replacedAddress:String)


# Enums
## COMPULSORY miss is when the tag is empty. Tag must be fetched from (imaginary) memory.
## CONFLICT miss is when the set is full (but the cache is not). Entails replacement. 
## CAPACITY miss is when the whole cache is full. Also entails replacement.
enum cacheMissType {COMPULSORY, CONFLICT, CAPACITY}
# helper enum used for _helper_update_cache_line() to indicate what action needs to be taken
enum updateType {HIT, COMPULSORY, CONFLICT_OR_CAPACITY}


#------ Variables ----------------

@export_group("Cache Properties")
## The amount of blocks that go into the cache.
@export var blockNumber :int
## The amount of blocks that go into one set.
@export var associativityDegree :int
## The replacement policy decides which cache line must be replaced upon a conflict or capacity cache miss.
@export_enum("Random", "LRU", "LFU") var replacementPolicy: String = "Random"

@export_group("Cache Controls")
## Controls the fixed_column_width value of the Header & CacheBody Lists. Overrides respective values, so always use this control.
## Exported so that it can be used in different levels better.
@export var columnWidth :int
## Controls how big the cache will appear vertically at its maximum.
## If [member blockNumber] < [member shownBlocks]: show only [member blockNumber] many rows.
## Internal maximum: 16 blocks shown.
@export var shownBlocks :int

# Private (underscore) count that is used in _add_cache_line()
var _blockCount:int = 0
# internal, stores precise unix time for every cache line. used for sub-second calculations in LRU
# initialized to size blockNumber in _ready(). Also stored in the tooltip of the "info" field
#var _timestampsUnix :Array[float]
# internal list of not-decomposed addresses that are stored in the cache. For easy access
var _addressList :Array[String]
## Internal metadata for every cache line. 
## Stores the address String that was decomposed into tag, index, offset and the unix timestamp for precise LRU sub-second calculations.
## Can be expanded in the future to hold more data (maybe statistics, etc.)
var _metadata :Array[Dictionary]


## This is where all the information is stored, eg. the "cache" 
@onready var cacheBody :ItemList = $CacheBody
## The top of the cache list that stores the column names
@onready var cacheHeader :ItemList = $CacheHeader


#--------- Constructor ----------------------

## Initializes the cache and fills it with [member blockNumber] many empty lines.
func _ready() -> void:	
	var setTmp :int = 0
	var setCounter :int = 0
	
	# varying "Info" field text depending on replacementPolicy:
	match replacementPolicy:
		"Random": 	cacheHeader.set_item_text(3, "Random Replacement")
		"LFU":		cacheHeader.set_item_text(3, "Access Count")
		"LRU": 		cacheHeader.set_item_text(3, "Last Access")
		_: 			print("Other replacement strategies than Random, LFU, LRU are not implemented!")
		
	# set same width for Cache Header and Body:
	cacheHeader.set_fixed_column_width(columnWidth)
	cacheBody.set_fixed_column_width(columnWidth)
	# set maximum height of Cache, measured in rows (before you need to scroll):
	# those pixel counts should be good, but could break in other resolutions(?!)
	const PIXELS_PER_BLOCK :int = 26
	const HEADER_PIXELS :int = 55
	shownBlocks = 16 if shownBlocks > 16 else shownBlocks		# upper bound of 16 rendered blocks on screen
	if blockNumber <= shownBlocks:								
		_set_size(Vector2(get_size()[0], HEADER_PIXELS + PIXELS_PER_BLOCK * blockNumber))	
	else:
		_set_size(Vector2(get_size()[0], HEADER_PIXELS + PIXELS_PER_BLOCK * shownBlocks))
			
	# cache creation depending on @blockNumber and @associativityDegree
	for i in blockNumber:
		if (setTmp == associativityDegree):
			setCounter += 1
			setTmp = 0
		setTmp += 1
		_add_cache_line(str(i), str(setCounter), "", "")	
		
	# initialize timestamps array to ensure safe access
	# _timestampsUnix.resize(blockNumber)
	# initialize metadata array that holds dictionaries with more info about each cache line.
	_metadata.resize(blockNumber)
	for i in blockNumber:
		_metadata[i] = {"block":i, "address":"", "timestampUnix":-1.0}
		
	
	
#------------- Public functions ------------------	
	
## This function sorts the given [param addressString] into the [Cache] scene. It calculates various parameters and extracts tag, index and offset from the address.
func sort_address_into_cache(addressString:String) -> void:
	# input validation: hex address must not be longer than 8 digits and must be a hex number
	if not _is_String_32_bit_hex_number(addressString): return
	
	var address :int = addressString.hex_to_int()
	
	# LRU timestamps:
	var timestamp :String = Time.get_datetime_string_from_system(false, true)	 # for the "info" field, calculations depend on Unix time system (see below)
	var timestampUnix :float = Time.get_unix_time_from_system()
	
	# cache parameter calculations:
	var setNumber :int = blockNumber / associativityDegree
	var blockSize :int = 16 								# in Byte
	var offsetBits :int = log(blockSize) / log(2)			# equivalent to log2(blockSize)
	var indexBits :int = log(setNumber) / log(2)
	var tagBits :int = 32 - (indexBits + offsetBits)		# 32-bit address
	
	var results :Dictionary = _get_tag_index_offset(address, tagBits, indexBits, offsetBits)
	var tag :int = results["tag"]
	var index :int = results["index"]
	var offset :int = results["offset"]
		
	# place address (tag) in one of the 'possibleLines':
	# update info field according to replacement policy (match ...)
	var possibleLines :Array[int] = _get_line_indices_for_set(index)
	var wasLinePlaced :bool = false
	
	# first attempt to place tag:
	for lineIdx in possibleLines:
		var line :Dictionary = _get_cache_line(lineIdx)
		
		if line["tag"] == str(tag):	# cache HIT, no replacement. only update info field and emit the hit signal 
			cacheHit.emit()	
			_helper_update_cache_line(lineIdx, line, addressString, tag, timestamp, timestampUnix, updateType.HIT)					
			wasLinePlaced = true
			break
		
		elif line["tag"] == "":			# COMPULSORY cache miss, no replacement
			cacheMiss.emit(cacheMissType.COMPULSORY, "")	
			_helper_update_cache_line(lineIdx, line, addressString, tag, timestamp, timestampUnix, updateType.COMPULSORY)
			wasLinePlaced = true
			break
			
	# second attempt to place tag, in case of a cache miss due to CONFLICT or CAPACITY in first attempt:  Replaces another tag/line	
	var replacedLine :Dictionary
	if wasLinePlaced == false:	
		# choose which of the existing lines must be replaced and update that line
		var lineToReplace :int = _choose_line_to_replace(possibleLines)
		if lineToReplace == -1: return
		replacedLine = _get_cache_line(lineToReplace)		# save it for output etc.
		if _is_cache_full():
			cacheMiss.emit(cacheMissType.CAPACITY, _metadata[lineToReplace]["address"])		# capacity miss, because whole cache is full
		else:
			cacheMiss.emit(cacheMissType.CONFLICT, _metadata[lineToReplace]["address"])		# conflict miss, because cache is not full, only the set is
		_helper_update_cache_line(lineToReplace, replacedLine, addressString, tag, timestamp, timestampUnix, updateType.CONFLICT_OR_CAPACITY)
		wasLinePlaced = true
			
	#TODO: implement cache conflict/replaced procedure that puts replacedLine(s) (see above!) into a list or so
			
	# ------ debugging / testing output: ---------
	#var bitmasks :Array[String] = _create_bitmasks(tagBits, indexBits, offsetBits)
	#var offsetBitmask :int = bitmasks[2].bin_to_int()
	#var indexBitmask :int = bitmasks[1].bin_to_int()
	#var tagBitmask :int = bitmasks[0].bin_to_int()
	##var addressBinary :int = 0b1111001001111001010
	#
	#var debugresults :Dictionary = _get_tag_index_offset(address, tagBits, indexBits, offsetBits)
	#var debugtag :int = debugresults["tag"]
	#var debugindex :int = debugresults["index"]
	#var debugoffset :int = debugresults["offset"]
	#
	#print("%d blocks à %d Byte, %d sets" % [blockNumber, blockSize, setNumber])	
	#print("=> %d tag bits, %d index bits, %d offset bits" % [tagBits, indexBits, offsetBits])	
	#print("offset Bitmask:	%32s" % bitmasks[2])
	#print("index Bitmask:	%32s" % bitmasks[1])
	#print("tag bitmask:		%32s" % bitmasks[0])
	#print("offset:	%d" % debugoffset)
	#print("index:	%d" % debugindex)
	#print("tag:		%d" % debugtag)
	#print("metadata:	",_metadata)
	# ------------- end debuggin/testing -------------------------------------
					
		
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
	

func _modify_cache_line_tooltips(index:int, block:String, set:String, tag:String, info:String) -> void:
	if(index < 0 or index >= blockNumber): return
	index *= cacheBody.get_max_columns()							# index calculation: index represents the row index
	if block != "keep": 	cacheBody.set_item_tooltip(index, block)
	if set != "keep": 	cacheBody.set_item_tooltip(index+1, set)
	if tag != "keep": 	cacheBody.set_item_tooltip(index+2, tag)
	if info != "keep": 	cacheBody.set_item_tooltip(index+3, info)
	

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
	

## Returns [code]true[/code] if every tag of the cache is full (eg. has a value). Else [code]false[/code]
func _is_cache_full() -> bool:
	for i in blockNumber:
		var line :Dictionary = _get_cache_line(i)
		if line["tag"] == "":
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
	

## Inverse to [method _get_tag_index_offset]: Reconstructs an address String from tag, index, offset decomposition
func _get_address(fromTag:int, fromIndex:int, fromOffset:int) -> String:
	return ""
	

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
	# implement all the usual replacement policies (maybe capsulate later into own functions):
	match replacementPolicy:
		"Random": 	# chooses a random line from lines that is within that range
			var rng:RandomNumberGenerator = RandomNumberGenerator.new()
			return rng.randi_range(lines[0], lines[len(lines)-1])	
			
		"LFU": # chooses the line with the minimal hit count (basically argmin_{accessCount}(lines))
			var line :int = lines[0]
			var minCount :int = _get_cache_line(lines[0])["info"].to_int()	
			for i in lines: 
				if _get_cache_line(lines[i])["info"].to_int() < minCount:		# smaller hit count found, so update line and continue search with that hit count
					line = i
					minCount = _get_cache_line(lines[i])["info"].to_int()
			return line
			
		"LRU": # chooses the line with the oldest hit timestamp (basically argmin_{timestamp}(lines); older timestamps have smaller values)
			var line :int = lines[0]
			#var oldestTimestamp :float = _timestampsUnix[lines[0]]
			var oldestTimestamp :float = _metadata[lines[0]]["timestampUnix"]
			for i in lines:
				if _metadata[lines[i]]["timestampUnix"] < oldestTimestamp:
					line = i
					oldestTimestamp = _metadata[lines[i]]["timestampUnix"]
			return line
		
	return -1	# default case. no replacementPolicy was set, so return an error
	
	
# Helper function for sort_address_into_cache(). Encapsulates the reapeated (match replacementPolicy) logic.
# On a HIT: tag = "keep", clear "random" field or increment LFU counter.
# On a COMPULSORY miss: tag = str(tag), clear "random" field or set LFU counter to 1.
# On a CONFLICT or CAPACITY miss: tag = str(tag), display replacement message for random or resetting the LFU counter to 1.
func _helper_update_cache_line(lineIdx:int, line:Dictionary, address:String, tag:int, timestamp:String, timestampUnix:float, type:updateType) -> void:
	# depending on update type, change parameters:
	var textForRandom :String
	var textForLFU :String
	var textForTag :String
	
	match type:
		updateType.HIT:
			textForRandom = ""
			var accessCount :int = line["info"].to_int()		
			accessCount += 1					# increment the counter by 1
			textForLFU = str(accessCount)
			textForTag = "keep"
		
		updateType.COMPULSORY:
			textForRandom = ""
			textForLFU = str(1)				# set the counter to 1
			textForTag = str(tag)

		updateType.CONFLICT_OR_CAPACITY:
			textForRandom = "replaced at random"
			textForLFU = str(1)				# reset the counter to 1
			textForTag = str(tag)

	match replacementPolicy:
			"Random":	
				_modify_cache_line(lineIdx,"keep","keep",textForTag,textForRandom)
			"LFU":
				_modify_cache_line(lineIdx,"keep","keep",textForTag,textForLFU)
			"LRU":		
				_modify_cache_line(lineIdx,"keep","keep",textForTag,timestamp)	
				_modify_cache_line_tooltips(lineIdx,"keep","keep","keep","Unix time: "+str(timestampUnix))		# shown when hovering over "info" field
				#_timestampsUnix[lineIdx] = timestampUnix			# keep track of precise timing using this helper array	
				_metadata[lineIdx]["address"] = address if address.begins_with("0x") else "0x"+address		# original address stored in metadata, just overwrites existing/replaced address
				_metadata[lineIdx]["timestampUnix"] = timestampUnix		# precise time stored in metadata
			_: 	print("Other replacement strategies than Random, LFU, LRU are not implemented!")
			
			
			
