extends ItemList

@export var blockNumber :int
@export var associativityDegree :int


func _ready() -> void:
	var list :ItemList = $"."
	list.add_item("Block")
	list.add_item("Set")
	list.add_item("Tag")
	list.add_item("Offset")
	list.add_item("Info (LRU, LFU)")
	#var hline :HSeparator = HSeparator.new()
	#add_child(hline)
	
	var setTmp :int = 0
	var setCounter :int = 0
	
	# dynamic tree creation depending on @blockNumber and @associativityDegree
	for i in range(0, blockNumber):
		if (setTmp == associativityDegree):
			setCounter += 1
			setTmp = 0
				
		list.add_item(str(i))
		list.add_item(str(setCounter))
		list.add_item("")
		list.add_item("")
		list.add_item("21s ago, 20 hits")
		
		setTmp += 1
	
	print(list.get_item_text(6))
