class_name MTIFile
extends BinaryReadable

var address: int
var size: int
var name: String
var size2: int
var entry_count: int
var entries: Array

func read(file: ByteBuffer) -> void:
	address = file.get_position()
	size = file.get_u32()
	name = file.get_chars(12)
	size2 = file.get_u32()
	entry_count = file.get_u32()
	
	entries.resize(entry_count)
	for i in range(entry_count):
		entries[i] = MTIListItem.new()
		entries[i].read(file)
