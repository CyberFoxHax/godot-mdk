class_name FTIFile
extends BinaryReadable

var filesize: int
var entry_count: int
var entries: Array
var sys_palette: SysPalette

var fontbig:MDKFont
var fontsml:MDKFont

func _init(_name:String):
	pass

func read(file: ByteBuffer) -> void:
	filesize = file.get_u32()
	entry_count = file.get_u32()
	
	entries.resize(entry_count)
	for i in range(entry_count):
		entries[i] = FTIEntry.new()
		entries[i].read(file)
	
	var dict:Dictionary[String, FTIEntry] = {}
	for f in entries:
		dict[f.name] = f
	
	sys_palette = _read_section(file, dict["SYS_PAL"], SysPalette)
	fontbig = _read_section(file, dict["FONTBIG"], MDKFont)
	fontsml = _read_section(file, dict["FONTSML"], MDKFont)
	fontbig.name = "FONTBIG"
	fontsml.name = "FONTSML"

func _read_section(file:ByteBuffer, entry:FTIEntry, type:GDScript):
	file.seek(entry.offset + 4)
	var instance:BinaryReadable = type.new()
	instance.read(file)
	return instance


class FTIEntry:
	extends BinaryReadable
	
	var name: String
	var offset: int
	
	func read(file: ByteBuffer) -> void:
		name = file.get_chars(8)
		offset = file.get_u32()
