class_name FTIFile
extends BinaryReadable

var filesize: int
var entry_count: int
var entries: Array
var sys_palette: SysPalette

func read(file: ByteBuffer) -> void:
	filesize = file.get_u32()
	entry_count = file.get_u32()
	
	entries.resize(entry_count)
	for i in range(entry_count):
		entries[i] = FTIEntry.new()
		entries[i].read(file)
	
	var palette_entry = entries.filter(func(e): return e.name == "SYS_PAL")[0]
	var original_position := file.get_position()
	file.seek(palette_entry.offset + 4)
	sys_palette = SysPalette.new()
	sys_palette.read(file)
	file.seek(original_position)

func _init(file: ByteBuffer = null) -> void:
	if file != null:
		read(file)

class FTIEntry:
	extends BinaryReadable
	
	var name: String
	var offset: int
	
	func read(file: ByteBuffer) -> void:
		name = file.get_chars(8)
		offset = file.get_u32()
