class_name MTIFile
extends BinaryReadable

var _address: int
var _size: int
var name: String
var _size2: int
var _entry_count: int
var entries: Array[MTIListItem]

func _init(_name:String):
	pass

func read(file: ByteBuffer) -> void:
	_address = file.get_position()
	_size = file.get_u32()
	name = file.get_chars(12)
	_size2 = file.get_u32()
	_entry_count = file.get_u32()
	
	entries.resize(_entry_count)
	for i in range(_entry_count):
		entries[i] = MTIListItem.new()
		entries[i].read(file)
