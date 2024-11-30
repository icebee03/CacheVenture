extends Tree

@export var blockNumber :int
@export var associativityDegree :int

func _ready() -> void:
	var tree :Tree = $"." #get_node("/root/Control/TestTree")
	var root :TreeItem = tree.create_item()
	#tree.hide_root = true
	#tree.hide_folding = true
	tree.set_column_title(0, "Block")
	tree.set_column_title(1, "Set")
	tree.set_column_title(2, "Tag")
	tree.set_column_title(3, "Offset")
	
	
	var setNumber :int = blockNumber / associativityDegree	#debug value
	var setTmp :int = 0
	var setCounter :int = 0
	
	# dynamic tree creation depending on @blockNumber and @associativityDegree
	for i in range(0, blockNumber):
		if (setTmp == associativityDegree):
			setCounter += 1
			setTmp = 0
			
		var	newLine = tree.create_item(root)
		newLine.set_text(0, str(i))
		newLine.set_text(1, str(setCounter))
		newLine.set_text(2, "0xFFFF")
		newLine.set_text(3, "0x0")
		
		setTmp += 1
