class_name DTIFile
extends BinaryReadable

var _filesize: int
var name: String
var _filesize2: int
var _offset_metadata: int
var _offset_spawnpoints: int
var _offset_roomlist: int
var _offset_palette: int
var _offset_skyboximage: int

var meta_data: MetaData_
var spawnpoints: Array[Spawnpoint]
var arenas: Array[DTIArena]
var palette: PackedColorArray
var skybox_image: MDKImage

func _init(_name:String):
	pass

func read(file: ByteBuffer) -> void:
	_filesize = file.get_u32()
	name = file.get_chars(12)
	_filesize2 = file.get_u32()
	
	_offset_metadata = file.get_u32()
	_offset_spawnpoints = file.get_u32()
	_offset_roomlist = file.get_u32()
	_offset_palette = file.get_u32()
	_offset_skyboximage = file.get_u32()
	
	var original_position := file.get_position()
	file.seek(_offset_metadata + 4)
	meta_data = MetaData_.new()
	meta_data.read(file)
	file.seek(original_position)
	
	original_position = file.get_position()
	file.seek(_offset_spawnpoints + 4)
	var spawn_count :int= file.get_u32()
	spawnpoints.resize(spawn_count)
	for i in range(spawn_count):
		spawnpoints[i] = Spawnpoint.new()
		spawnpoints[i].read(file)
	file.seek(original_position)
	
	original_position = file.get_position()
	file.seek(_offset_roomlist + 4)
	var room_count :int= file.get_u32()
	arenas.resize(room_count)
	for i in range(room_count):
		arenas[i] = DTIArena.new()
		arenas[i].read(file)
	file.seek(original_position)
	
	original_position = file.get_position()
	file.seek(_offset_palette + 4)
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
	file.seek(_offset_skyboximage + 4)
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

#1,3,6,7,8 is used in level7
enum DTIEntityType {
	Invalid = 0,
	ArenaShowZone = 1,
	Hotgen = 2, #
	ArenaActivateZone = 3,
	Hotpick = 4, #
	HidingSpot = 5, #
	ArenaConnectZone = 6,
	Fan = 7,
	JumpPoint = 8,
	Slidething = 9, #
}

class DTIArena:
	extends BinaryReadable
	
	var name: String
	var arena_offset: int
	var room_cam_angle: float
	var num_entities: int

	var entities: Array[ArenaEntity] = []
	
	func read(file: ByteBuffer) -> void:
		name = file.get_chars(8)
		arena_offset = file.get_u32()
		room_cam_angle = file.get_float()

		file.push_position(arena_offset+4)
		num_entities = file.get_u32()

		for i in num_entities:
			var entity = ArenaEntity.new()
			entity.kind = file.get_u32();
			entity.id = file.get_u32();
			entity.value = file.get_u32();
			entity.pos_min = Vector3(
				file.get_float(),
				file.get_float(),
				file.get_float()
			);
			entity.pos_max = Vector3(
				file.get_float(),
				file.get_float(),
				file.get_float()
			);
			if entity.pos_max == Vector3.ZERO:
				entity.pos_max = entity.pos_min

			entities.append(entity)

			#if kind != 2 && kind != 6 {
			#	assert_eq!(value, 0);
			#}
		file.pop_position()

class ArenaEntity:
	var kind: DTIEntityType
	var id: int
	var value: int
	var pos_min: Vector3
	var pos_max: Vector3

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
