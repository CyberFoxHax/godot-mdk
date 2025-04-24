class_name DTIFile
extends BinaryReadable

var filesize: int
var name: String
var filesize2: int
var offset_metadata: int
var offset_spawnpoints: int
var offset_roomlist: int
var offset_palette: int
var offset_skyboximage: int
var meta_data: MetaData_
var spawnpoints: Array[Spawnpoint]
var room_list_items: Array[RoomListItem]
var palette: PackedColorArray
var skybox_image: MDKImage

func _init(_name:String):
	pass

func read(file: ByteBuffer) -> void:
	filesize = file.get_u32()
	name = file.get_chars(12)
	filesize2 = file.get_u32()
	
	offset_metadata = file.get_u32()
	offset_spawnpoints = file.get_u32()
	offset_roomlist = file.get_u32()
	offset_palette = file.get_u32()
	offset_skyboximage = file.get_u32()
	
	var original_position := file.get_position()
	file.seek(offset_metadata + 4)
	meta_data = MetaData_.new()
	meta_data.read(file)
	file.seek(original_position)
	
	original_position = file.get_position()
	file.seek(offset_spawnpoints + 4)
	var spawn_count :int= file.get_u32()
	spawnpoints.resize(spawn_count)
	for i in range(spawn_count):
		spawnpoints[i] = Spawnpoint.new()
		spawnpoints[i].read(file)
	file.seek(original_position)
	
	original_position = file.get_position()
	file.seek(offset_roomlist + 4)
	var room_count :int= file.get_u32()
	room_list_items.resize(room_count)
	for i in range(room_count):
		room_list_items[i] = RoomListItem.new()
		room_list_items[i].read(file)
	file.seek(original_position)
	
	original_position = file.get_position()
	file.seek(offset_palette + 4)
	var unused_colors_count :int = file.get_u32()
	palette.resize(256)
	for i in range(256):
		palette[i] = Color(
			file.get_byte() / 255.0,
			file.get_byte() / 255.0,
			file.get_byte() / 255.0,
			1.0
		)
	file.seek(original_position)
	
	original_position = file.get_position()
	file.seek(offset_skyboximage + 4)
	skybox_image = MDKImage.new(name + "_skybox")
	skybox_image.width = meta_data.skybox_width + 4
	skybox_image.height = meta_data.skybox_height
	skybox_image.data = file.get_bytes(skybox_image.width * skybox_image.height)
	file.seek(original_position)

class Spawnpoint:
	extends BinaryReadable
	
	var room_id: int
	var room_index: int
	var spawn_position: Vector3
	var spawn_rotation: float
	
	func read(file: ByteBuffer) -> void:
		room_id = file.get_u32()
		room_index = file.get_u32()
		spawn_position = Vector3(
			file.get_float(),
			file.get_float(),
			file.get_float()
		)
		spawn_rotation = file.get_float()

class RoomListItem:
	extends BinaryReadable
	
	var name: String
	var offset_connectors: int
	var room_cam_angle: float
	
	func read(file: ByteBuffer) -> void:
		name = file.get_chars(8)
		offset_connectors = file.get_u32()
		room_cam_angle = file.get_float()

class MetaData_:
	extends BinaryReadable
	
	var starting_room_index: int
	var starting_pos: Vector3
	var starting_rot: float
	var skybox_top_clamp_color: int
	var skybox_bottom_clamp_color: int
	var skybox_shift_y: int
	var skybox_shift_x: int
	var skybox_width: int
	var skybox_height: int
	var reflective_skybox_floor_color: int
	var reflective_skybox_ceiling_color: int
	var transparency_colors: Array[Color]
	
	func read(file: ByteBuffer) -> void:
		starting_room_index = file.get_u32()
		starting_pos = Vector3(
			file.get_float(),
			file.get_float(),
			file.get_float()
		)
		starting_rot = file.get_float()
		skybox_top_clamp_color = file.get_u32()
		skybox_bottom_clamp_color = file.get_u32()
		skybox_shift_y = file.get_s32();
		skybox_shift_x = file.get_s32();
		skybox_width = file.get_u32()
		skybox_height = file.get_u32()
		reflective_skybox_floor_color = file.get_s32();
		reflective_skybox_ceiling_color = file.get_s32();
		transparency_colors.resize(4)
		for i in range(4):
			transparency_colors[i] = Color(
				(file.get_u32() & 0xFF) / 255.0,
				(file.get_u32() & 0xFF) / 255.0,
				(file.get_u32() & 0xFF) / 255.0,
				(file.get_u32() & 0xFF) / 255.0
			)
