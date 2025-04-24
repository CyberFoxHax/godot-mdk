class_name MTOFile
extends BinaryReadable

var address: int
var length1: int
var name: String
var length2: int
var files_count: int
var room_locations: Array

func _init(_name:String):
	pass

func read(file: ByteBuffer) -> void:
	address = file.get_position()
	length1 = file.get_u32()
	name = file.get_chars(12)
	length2 = file.get_u32()
	files_count = file.get_u32()
	
	room_locations.resize(files_count)
	for i in range(files_count):
		room_locations[i] = RoomLocation.new()
		room_locations[i].read(file)

class RoomLocation:
	extends BinaryReadable
	
	var address: int
	var name: String
	var offset: int
	var room: Room
	
	func read(file: ByteBuffer) -> void:
		address = file.get_position()
		name = file.get_chars(8)
		offset = file.get_u32()
		
		var current_position := file.get_position()
		file.seek(offset)
		room = Room.new()
		room.read(file)
		file.seek(current_position)
