class_name FTIFile
extends BinaryReadable

var _filesize: int
var _entry_count: int
var _entries: Array[FTIEntry]

var sys_palette: SysPalette

var fontbig:MDKFont
var fontsml:MDKFont

var strings: Dictionary[String, String] = {}

func _init(_name:String):
	pass

func read(file: ByteBuffer) -> void:
	_filesize = file.get_u32()
	_entry_count = file.get_u32()
	
	_entries.resize(_entry_count)
	for i in range(_entry_count):
		_entries[i] = FTIEntry.new()
		_entries[i].read(file)
	
	var dict:Dictionary[String, FTIEntry] = {}
	for f in _entries:
		dict[f.name] = f
	
	sys_palette = _read_section(file, dict["SYS_PAL"], SysPalette)
	fontbig = _read_section(file, dict["FONTBIG"], MDKFont)
	fontsml = _read_section(file, dict["FONTSML"], MDKFont)
	fontbig.name = "FONTBIG"
	fontsml.name = "FONTSML"
	
	for i in range(6, 328):
		var entry = _entries[i]
		file.seek(entry.offset + 4)
		var text: String = ""
		while true:
			var code = file.get_u8()
			if code == 0:
				break
			text += String.chr(code)
		strings[entry.name] = text

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
