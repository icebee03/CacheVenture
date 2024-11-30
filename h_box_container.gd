extends HBoxContainer

@export var blockNumber :int
@export var associativityDegree :int

func _ready() -> void:
	var blocks :ItemList = $Blocks
	var sets :ItemList = $Sets
	var tags :ItemList = $Tags
	var offsets :ItemList = $Offsets
	
	blocks.add_item("Blocks")
	sets.add_item("Sets")
	tags.add_item("Tags")
	offsets.add_item("Offset")

	var setTmp :int = 0
	var setCounter :int = 0
	
	# dynamic tree creation depending on @blockNumber and @associativityDegree
	for i in range(0, blockNumber):
		if (setTmp == associativityDegree):
			setCounter += 1
			setTmp = 0
				
		blocks.add_item(str(i))
		sets.add_item(str(setCounter))
		tags.add_item("0x"+str(i)+str(i))
		offsets.add_item("0x0")
		
		setTmp += 1
