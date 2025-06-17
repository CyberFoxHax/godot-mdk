#todo
# load neighbouring arenas

class_name LevelLoad
extends Node3D

static var _static_load_level_has_value:bool = false
static var _static_load_level:MDKFiles.Levels

@export var unit_scale: float = 1
@export var level: MDKFiles.Levels = MDKFiles.Levels.LEVEL7
@export var player: Player
@export var player_material: ShaderMaterial
@export var material_black: Material
@export var enviroment: WorldEnvironment
@export var palette_parser_shader: Shader
@export var spritesheet_parser_shader: Shader
@export var texture_shader: Shader
@export var color_shader: Shader
@export var shiny_shader: Shader
@export var transparent_shader: Shader
@export var godot_converter: GodotConverterHelpers
@export var group_list: ItemList

var room_list:Dictionary[String, DTIFile.DTIArena] = {}

var textures_dict: Dictionary[String, Texture2D] = {}
var sprites_dict: Dictionary[String, Texture2D] = {}
var files:MDKFiles
static var palette: PackedColorArray = []

# arenas sorted into groups
# Full type would have been Dictionary[String, Dictionary[int, Array[Node]]]
# but this can't be expressed in gdscript, so you get this abomination instead
var _arenaObjectsById:=ArenaObjectGroups.new()
class ArenaObjectGroups:
	class ArrayOfNode3D:
		var arr:Array[Node3D] = []
	class DictOfArrayOfNode3D:
		var dict:Dictionary[int, ArrayOfNode3D] = {}

	var arenas: Dictionary[String, DictOfArrayOfNode3D] = {}

	func add_object(arena_id:String, id:int, object:Node3D) -> void:
		if not arenas.has(arena_id):
			arenas[arena_id] = DictOfArrayOfNode3D.new()

		if not arenas[arena_id].dict.has(id):
			arenas[arena_id].dict[id] = ArrayOfNode3D.new()
		
		arenas[arena_id].dict[id].arr.append(object)

	func get_object(arena_id:String, id:int) -> Array[Node3D]:
		return arenas[arena_id].dict[id].arr

	func clear():
		arenas = {}

func _ready() -> void:
	var sw_total := Time.get_ticks_msec()
	
	load_files()
	load_textures()
	load_skybox()
	load_kurt()

	var sw = Time.get_ticks_msec()
	await RenderingServer.frame_post_draw
	MyGlobal.print_info("All textures loaded %d ms" % (Time.get_ticks_msec() - sw_total))
	sw = Time.get_ticks_msec()

	var traverse = files.traverse[level]
	for loc in traverse.o_mto.room_locations:
		if room_list.has(loc.name) == false:
			continue
		if cut_content[level].dict.get(loc.name) == true:
			continue
		create_mesh(loc.room.level_model, loc.name, false)

	for file in traverse.o_sni.files:
		if room_list.has(file.name) == false:
			continue
		if cut_content[level].dict.get(file.name) == true:
			continue
		create_mesh(file.mesh, file.name, true)

	var i:=0
	for arena:DTIFile.DTIArena in traverse.dti.arenas:
		for entity in arena.entities:
			i = i + 1
			var bounds = Bounds.new()
			bounds._min = MDKFiles.swizzle_vector(entity.pos_min)*unit_scale
			bounds._max = MDKFiles.swizzle_vector(entity.pos_max)*unit_scale

			var mi = MeshInstance3D.new()
			mi.name = "%s %s %s #%d" % [DTIFile.DTIEntityType.keys()[entity.kind], arena.name, entity.id, i]
			mi.mesh = BoxMesh.new()
			mi.position = bounds.get_center()
			mi.scale = bounds.get_size()

			if mi.scale == Vector3.ZERO:
				mi.scale = Vector3.ONE*unit_scale*5
			
			if mi.scale.x == 0:
				mi.scale.x = unit_scale
			if mi.scale.y == 0:
				mi.scale.y = unit_scale
			if mi.scale.z == 0:
				mi.scale.z = unit_scale

			add_child(mi)
			mi.set_meta("kind", DTIFile.DTIEntityType.keys()[entity.kind])
			mi.set_meta("arena_name", arena.name)
			mi.set_meta("id", entity.id)
			mi.set_meta("value", entity.value)
			mi.set_meta("pos_min", bounds._min)
			mi.set_meta("pos_max", bounds._max)

	player.position = MDKFiles.swizzle_vector(traverse.dti.meta_data.starting_pos)*unit_scale + Vector3(0,4,0)
	player.set_y_rotation_degrees(traverse.dti.meta_data.starting_rot+90)
	
	MyGlobal.print_info("Level constructed in %d ms" % (Time.get_ticks_msec() - sw))
	MyGlobal.print_info("Total loading time %d ms" % (Time.get_ticks_msec() - sw_total))

	# for key:String in _arenaObjectsById.arenas:
	# 	print("%s" % key)
	# 	var arena :ArenaObjectGroups.DictOfArrayOfNode3D = _arenaObjectsById.arenas[key]
	# 	for key2 in arena.dict:
	# 		print("\tgroupid:%d count:%d" % [key2, len(arena.dict[key2].arr)])

	
	# for arena in _level_arenas:
	# 	arena.node.visible = false
	
	# _level_arenas[0].node.visible = true

	player_arena_changed.connect(_on_arena_changed)
	group_list.multi_selected.connect(group_list_selected)

func group_list_selected(index: int, selected: bool)->void:
	var child = group_list.get_item_text(index)
	var id = int(child)
	for node in _arenaObjectsById.arenas[current_arena.name].dict[id].arr:
		node.visible = !selected

func _on_arena_changed(oldArena: LevelArena, newArena:LevelArena) -> void:
	return
	if oldArena != null:
		oldArena.node.visible = false
	newArena.node.visible = true

	group_list.clear()
	for key in _arenaObjectsById.arenas[newArena.name].dict:
		group_list.add_item(str(key))

signal player_arena_changed(oldArena: LevelArena, newArena:LevelArena)

var time: float = 0

var current_arena : LevelArena
func _process(delta: float) -> void:
	time += delta

	## check which arena player is in, if changed dispatch event
	# possible gotcha: Player can be in multiple arenas
	# possible gotcha: Arena is mesh bounding box for group 0
	var new_arena:LevelArena
	for arena in _level_arenas:
		if arena.bounds.is_point_inside(player.get_player_position()):
			new_arena = arena
			break
	if new_arena != null:
		if new_arena != current_arena:
			player_arena_changed.emit(current_arena, new_arena)
		current_arena = new_arena


class CutContent:
	func _init(mdict:Dictionary[String, bool]) -> void:
		dict = mdict

	var dict:Dictionary[String, bool]


var cut_content:Dictionary[MDKFiles.Levels, CutContent] = {
	MDKFiles.Levels.LEVEL3: CutContent.new({
		"HMO_3":true,
		"HMO_7":true,
		"CHMO_3":true,
		"CHMO_7":true
	}),
	MDKFiles.Levels.LEVEL4: CutContent.new({
		"MEAT_2":true,
		"MEAT_9":true,
		"CMEAT_2":true,
		"CMEAT_9":true,
	}),
	MDKFiles.Levels.LEVEL5: CutContent.new({
		"MUSE_6":true,
		"MUSE_7":true,
		"MUSE_8":true,
		"MUSE_9":true,
		"MUSE_10":true,
		"CMUSE_5":true,
		"CMUSE_6":true,
		"CMUSE_7":true,
		"CMUSE_8":true,
		"CMUSE_9":true
	}),
	MDKFiles.Levels.LEVEL6: CutContent.new({
		"OLYM_9":true,
		"COLYM_9":true
	}),
	MDKFiles.Levels.LEVEL7: CutContent.new({
		"DANT_8": true,
		"CDANT_8": true
	}),
	MDKFiles.Levels.LEVEL8: CutContent.new({
		"GUNT_9": true,
		"CGUNT_8": true
	})
}

class LevelArena:
	var mdk_mesh: MDKMesh
	var name: String
	var node: Node3D
	var bounds: Bounds
	var is_corridor: bool

var _level_arenas: Array[LevelArena] = []

class Bounds:
	var _min: Vector3
	var _max: Vector3

	var _first = true

	func expand(point: Vector3) -> void:
		if _first:
			_first = false
			_min = point
			_max = point
		else:
			_min = _min.min(point)
			_max = _max.max(point)

	func get_center() -> Vector3:
		return (_min + _max) / 2.0

	func get_size() -> Vector3:
		return _max - _min

	func is_point_inside(point: Vector3) -> bool:
		return (point.x >= _min.x and point.x <= _max.x and
				point.y >= _min.y and point.y <= _max.y and
				point.z >= _min.z and point.z <= _max.z)

	func clone():
		var d := Bounds.new()
		d._min = _min
		d._max = _max
		return d

func create_mesh(mdkmesh: MDKMesh, _name: String, is_corridor:bool) -> Node3D:
	var obj := Node3D.new()
	obj.name = _name
	self.add_child(obj)
	var arena := LevelArena.new()
	arena.mdk_mesh = mdkmesh
	arena.name = _name
	arena.node = obj
	arena.is_corridor = is_corridor;
	arena.bounds = Bounds.new()
	_level_arenas.append(arena)

	var submeshes:Dictionary[int, Array] = {}
	for poly in mdkmesh.polygons:
		if poly.is_hidden():
			continue
		var key = poly.submesh_id()
		if not submeshes.has(key):
			var arr:Array[Polygon] = []
			submeshes[key] = arr
		submeshes[key].append(poly)
	
	var materials_map :Dictionary[int, Texture2D]= {}
	for i in range(mdkmesh.material_names.size()):
		var item := mdkmesh.material_names[i]
		if textures_dict.has(item):
			materials_map[i] = textures_dict[item]
	
	var material_array :Array[Material]= []
	for submesh:Array[Polygon] in submeshes.values():
		var material_flags := submesh[0].material_flags
		var mmm := create_material(material_flags, materials_map)
		material_array.append(mmm)

	var submeshIndex := 0
	var unique_i := 0
	for submesh:Array[Polygon] in submeshes.values():
		unique_i = unique_i + 1
		var obj2 = Node3D.new()
		var poly1 := submesh[0]
		obj2.name = "mat:%d - id:%d #%d" % [poly1.material_flags, poly1.id, unique_i]

		var arrays := []
		var vertices:= PackedVector3Array ()
		var uvs:= PackedVector2Array ()
		arrays.resize(ArrayMesh.ARRAY_MAX)
		arrays[ArrayMesh.ARRAY_VERTEX] = vertices
		arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
		for poly in submesh:
			var v1 := MDKFiles.swizzle_vector(mdkmesh.vertices[poly.v1])*unit_scale
			var v2 := MDKFiles.swizzle_vector(mdkmesh.vertices[poly.v2])*unit_scale
			var v3 := MDKFiles.swizzle_vector(mdkmesh.vertices[poly.v3])*unit_scale
			vertices.append(v1)
			vertices.append(v2)
			vertices.append(v3)
			if poly1.id == 0:
				arena.bounds.expand(v1)
				arena.bounds.expand(v2)
				arena.bounds.expand(v3)
			
			if materials_map.has(poly.material_flags):
				var tex: Texture2D = materials_map[poly.material_flags]
				var tex_size := Vector2(tex.get_width(), tex.get_height())
				uvs.append(poly.t1 / tex_size)
				uvs.append(poly.t2 / tex_size)
				uvs.append(poly.t3 / tex_size)
			else:
				uvs.append(Vector2.ZERO)
				uvs.append(Vector2.ZERO)
				uvs.append(Vector2.ZERO)
		
		var mr := MeshInstance3D.new()
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(0, material_array[submeshIndex])
		var submeshHash:int = hash(poly1.submesh_id())
		material_array[submeshIndex].set_shader_parameter("tint", Vector4(
			float(submeshHash & 0xff)/0xff,
			float(submeshHash>>8 & 0xff)/0xff,
			float(submeshHash>>16 & 0xff)/0xff,
			0
		)*0.2)
		
		submeshIndex = submeshIndex+1;
	
		mr.mesh = mesh
		obj2.add_child(mr)

		var staticbody3d = StaticBody3D.new()
		var shape = ConcavePolygonShape3D.new()
		shape.set_faces(mesh.get_faces())
		var collider = CollisionShape3D.new()
		collider.shape = shape
		staticbody3d.add_child(collider)
		obj2.add_child(staticbody3d);
		_arenaObjectsById.add_object(_name, poly1.id, obj2)

		obj.add_child(obj2)

	return obj

func create_material(material_flags: int, materials_map: Dictionary[int, Texture2D]) -> Material:
	if material_flags >= -255 and material_flags <= -1: # simple color
		var material := ShaderMaterial.new()
		material.shader = color_shader;
		if -material_flags < palette.size():
			material.set_shader_parameter("main_color", palette[-material_flags])
		return material
	elif material_flags >= 0 and material_flags <= 255: # standard textured
		var material := ShaderMaterial.new()
		material.shader = texture_shader;
		if materials_map.has(material_flags):
			material.set_shader_parameter("main_texture", materials_map[material_flags])
		else:
			return material_black
		return material
	elif material_flags >= -1010 && material_flags <= -990: # shiny
		var reflection_offset_y = -990 - material_flags;
		var material := ShaderMaterial.new()
		material.shader = shiny_shader
		material.set_shader_parameter("main_texture", skybox)
		material.set_shader_parameter("reflection_offset_y", float(reflection_offset_y)/float(skybox.get_height()))
		return material;
	elif material_flags >= -1027 && material_flags <= -1024: # transparent color
		var v = -material_flags - 1024
		var transparent_color = files.traverse[level].dti.meta_data.transparency_colors[v];
		var material := ShaderMaterial.new()
		material.shader = transparent_shader
		material.set_shader_parameter("main_color", transparent_color);
		return material;
	elif material_flags == -1028:
		# wobble effect for under water stuff???
		MyGlobal.print_warn("Unimplemented material wobble effect");
		return null
	elif material_flags < -1028:
		# no idea
		MyGlobal.print_warn("Material flag less than -1028, what does this mean? Who knows, find the surface in-game to learn something");
		return null
	else:
		MyGlobal.print_error("Uknown flag: %d" % material_flags)
	return null

func load_files():
	if _static_load_level_has_value:
		level = _static_load_level
	_static_load_level_has_value = false
	var sw := Time.get_ticks_msec()
	files = MDKFiles.get_instance()
	files.load_traverse(Globals.MDK_PATH, level)

	var traverse = files.traverse[level]

	if traverse.load_success == false:
		MyGlobal.print_error("failed to load level %s" % MDKFiles.Levels.keys()[level])
		return
	MyGlobal.print_info("Data loaded in %d ms" % (Time.get_ticks_msec() - sw))

	palette.resize(traverse.dti.palette.size())
	for i in range(traverse.dti.palette.size()):
		palette[i] = traverse.dti.palette[i]
	sw = Time.get_ticks_msec()

	for room in traverse.dti.arenas:
		room_list.set(room.name, room)



var skybox:Texture2D
func load_skybox():
	var traverse = files.traverse[level]
	skybox = await godot_converter.create_texture(self, traverse.dti.skybox_image, palette, textures_dict, false)
	enviroment.environment.sky.sky_material.set_shader_parameter("main_texture", skybox);


func load_textures():
	var traverse = files.traverse[level]
	for loc in traverse.o_mto.room_locations:
		if cut_content[level].dict.get(loc.name) == true:
			continue
		var room = loc.room
		for i in room.palette.size():
			palette[i + 64] = room.palette[i]
		for sss in room.mti_items:
			godot_converter.create_texture(self, sss.image, palette.duplicate(), textures_dict, true)
	
	for item in traverse.s_mti.entries:
		if item.image != null:
			godot_converter.create_texture(self, item.image, palette, textures_dict, true)

	await RenderingServer.frame_post_draw


func load_kurt():
	var sw = Time.get_ticks_msec()

	var idle = files.traverse_bni.sprites["K_RUN"]
	idle.unpack()
	MyGlobal.print_info("Kurt unpacked in %d ms" % (Time.get_ticks_msec() - sw))

	
	var spritesheet = await godot_converter.create_spritesheet(self, idle, palette);
	player_material.set_shader_parameter("main_texture", spritesheet)
	var rects: Array[Vector4] = [];
	var margins: Array[Vector2] = [];
	var spritesheet_width = float(spritesheet.get_width())
	var spritesheet_height = float(spritesheet.get_height())
	
	var largest_frame = Vector2(0, 0)
	var offset_x = 0;
	#total_texture.blit_rect(
	#	img,
	#	Rect2i(0, 0, v.width, v.height),
	#	Vector2i(offset-v.x_ui_shift+v.width/2, -v.y_ui_shift+v.height/2)
	#);
	#offset += v.width+v.x_ui_shift
	for dat:MDKSpriteAnimation.SpriteEntry in idle.images:
		var newrect = Vector4(
			offset_x,
			0,
			dat.width,
			dat.height
		)
		
		newrect.x /= spritesheet_width;
		newrect.y /= spritesheet_height;
		newrect.z /= spritesheet_width;
		newrect.w /= spritesheet_height;

		offset_x += dat.width;
		
		var margin = Vector2(
			float(dat.x_ui_shift)/(spritesheet_width+dat.x_ui_shift),
			float(dat.y_ui_shift)/(spritesheet_height+dat.y_ui_shift)
		)
		margins.append(margin)

		largest_frame.x = max(largest_frame.x, dat.width/spritesheet_width)
		largest_frame.y = max(largest_frame.y, dat.height/spritesheet_height)
		rects.append(newrect)

	player_material.set_shader_parameter("frame_count", len(rects))
	player_material.set_shader_parameter("frame_rects", rects)
	player_material.set_shader_parameter("frame_margins", margins)
	player_material.set_shader_parameter("largest_frame", largest_frame)
