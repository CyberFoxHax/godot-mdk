class_name SNIFile
extends BinaryReadable

var _archive_length: int
var archive_name: String
var _payload_end: int
var _files_count: int
var files: Array[FileEntry]

func _init(_name:String):
	pass

func read(file: ByteBuffer) -> void:
	_archive_length = file.get_u32()
	archive_name = file.get_chars(12)
	_payload_end = file.get_u32()
	_files_count = file.get_u32()
	
	files.resize(_files_count)
	for i in range(_files_count):
		files[i] = FileEntry.new()
		files[i].read(file)

class FileEntry:
	extends BinaryReadable
	
	var name: String
	var type: int
	var _offset: int
	var _size: int
	
	var wav_audio: PackedByteArray
	var mesh: MDKMesh
	
	func read(file: ByteBuffer) -> void:
		name = file.get_chars(12)
		type = file.get_u32()
		_offset = file.get_u32()
		_size = file.get_u32()
		
		var original_position := file.get_position()
		file.seek(_offset + 4)
		var header := file.get_chars(4)
		if header == "RIFF":
			file.seek(file.get_position() - 4)
			wav_audio = file.get_bytes(_size)
		else:
			file.seek(file.get_position() - 4)
			mesh = MDKMesh.new()
			mesh.read(file)  # No try-catch in GDScript; errors will propagate
		file.seek(original_position)
