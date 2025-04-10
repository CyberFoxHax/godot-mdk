class_name CMIFile
extends BinaryReadable

var address: int
var version: int
var identifier: String
var data_size: int

func read(file: ByteBuffer) -> void:
	address = file.get_position()
	version = file.get_u32()
	identifier = file.get_chars(8)
	data_size = file.get_u32()