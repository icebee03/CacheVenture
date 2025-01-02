class_name Cache
extends VBoxContainer

@export_group("Cache Properties")
## The amount of blocks that go into the cache.
@export var blockNumber :int
## The amount of blocks that go into one set.
@export var associativityDegree :int
## The replacement policy decides which cache line must be replaced upon a conflict or capacity cache miss.
@export_enum("Random", "LRU", "LFU") var replacementPolicy: String = "Random"
## This is where all the information is stored, eg. the "cache" 
@onready var cache:ItemList = $CacheBody
# Private (underscore) count that is used in add_cache_line()
var _blockCount:int = 0



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
		
		add_cache_line(str(i), str(setCounter), "", "")	
		
	#modify_cache_line(3, "----","-----","keep","----","keep")
		

## Adds the line consisting of parameters [param block] ... [param info] to the end of the cache. Ignores new lines exceeding the [member blockNumber] limit
func add_cache_line(block:String="0", set:String="0", tag:String="0x0", info:String="...") -> void:
	if(_blockCount >= blockNumber): return
	cache.add_item(block)
	cache.add_item(set)
	cache.add_item(tag)
	cache.add_item(info)
	_blockCount += 1


## Modifes the cache line parameters at [param index]. Ignores indices that point to non-existent cache lines.
## Parameters with the String keyword [code]"keep"[/code] do not modify their respective value
func modify_cache_line(index:int, block:String, set:String, tag:String, info:String) -> void:
	if(index < 0 or index >= blockNumber): return
	index *= cache.get_max_columns()							# index calculation: index represents the row index
	if block != "keep": 	cache.set_item_text(index, block)
	if set != "keep": 	cache.set_item_text(index+1, set)
	if tag != "keep": 	cache.set_item_text(index+2, tag)
	if info != "keep": 	cache.set_item_text(index+3, info)
	

## Returns the cache line parameters at [param index]. Ignores indices that point to non-existent cache lines
func get_cache_line(index:int) -> Dictionary:
	if(index < 0 or index >= blockNumber): return {}
	index *= cache.get_max_columns()
	return {	"block" : cache.get_item_text(index),
			"set" : cache.get_item_text(index+1),
			"tag" : cache.get_item_text(index+2),
			"info" : cache.get_item_text(index+3)}
	
