class_name MTOFile
extends BinaryReadable

var _address: int
var _length1: int
var name: String
var _length2: int
var _files_count: int
var room_locations: Array[RoomLocation]

func _init(_name:String):
	pass

func read(file: ByteBuffer) -> void:
	_address = file.get_position()
	_length1 = file.get_u32()
	name = file.get_chars(12)
	_length2 = file.get_u32()
	_files_count = file.get_u32()
	
	room_locations.resize(_files_count)
	for i in range(_files_count):
		room_locations[i] = RoomLocation.new()
		room_locations[i].read(file)

class RoomLocation:
	extends BinaryReadable
	
	var _address: int
	var name: String
	var _offset: int
	var room: Room
	
	func read(file: ByteBuffer) -> void:
		_address = file.get_position()
		name = file.get_chars(8)
		_offset = file.get_u32()
		
		var current_position := file.get_position()
		file.seek(_offset)
		room = Room.new()
		room.read(file)
		file.seek(current_position)
