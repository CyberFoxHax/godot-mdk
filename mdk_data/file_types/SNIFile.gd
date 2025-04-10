class_name SNIFile
extends BinaryReadable

var archive_length: int
var archive_name: String
var payload_end: int
var files_count: int
var files: Array

func read(file: ByteBuffer) -> void:
	archive_length = file.get_u32()
	archive_name = file.get_chars(12)
	payload_end = file.get_u32()
	files_count = file.get_u32()
	
	files.resize(files_count)
	for i in range(files_count):
		files[i] = FileEntry.new()
		files[i].read(file)

class FileEntry:
	extends BinaryReadable
	
	var name: String
	var type: int
	var offset: int
	var size: int
	var wav_audio: PackedByteArray
	var mesh: MDKMesh
	
	func read(file: ByteBuffer) -> void:
		name = file.get_chars(12)
		type = file.get_u32()
		offset = file.get_u32()
		size = file.get_u32()
		
		var original_position := file.get_position()
		file.seek(offset + 4)
		var header := file.get_chars(4)
		if header == "RIFF":
			file.seek(file.get_position() - 4)
			wav_audio = file.get_bytes(size)
		else:
			file.seek(file.get_position() - 4)
			mesh = MDKMesh.new()
			mesh.read(file)  # No try-catch in GDScript; errors will propagate
		file.seek(original_position)
