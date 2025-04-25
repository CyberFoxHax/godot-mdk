## TODO
# Implemnt lines rendering using the TRIFLAGS
# After unwinding the mesh, all vertices have a new ID, but some stuff is still reference old IDs, need to a dictionary of them
# Hide rooms that are not adjecent to your current location. And going back, doors always lock behind you

class_name LevelLoad
extends Node3D

const BASE_PATH := "D:/Projects/mdk/MDK-Game"

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

var room_list:Dictionary[String, DTIFile.RoomListItem] = {}

var textures_dict: Dictionary[String, Texture2D] = {}
var sprites_dict: Dictionary[String, Texture2D] = {}
var files:MDKFiles
static var palette: PackedColorArray = []

func _ready() -> void:
	var sw_total := Time.get_ticks_msec()
	
	load_files()
	load_textures()
	load_skybox()
	load_kurt()

	var sw = Time.get_ticks_msec()
	await RenderingServer.frame_post_draw
	print("All textures loaded %d ms" % (Time.get_ticks_msec() - sw_total))
	sw = Time.get_ticks_msec()

	var traverse = files.traverse[level]
	for loc in traverse.o_mto.room_locations:
		if room_list.has(loc.name) == false:
			continue
		if cut_content[level].dict.get(loc.name) == true:
			continue
		create_mesh(loc.room.level_model, loc.name)

	for file in traverse.o_sni.files:
		if room_list.has(file.name) == false:
			continue
		if cut_content[level].dict.get(file.name) == true:
			continue
		create_mesh(file.mesh, file.name)

	player.position = MDKFiles.swizzle_vector(traverse.dti.meta_data.starting_pos)*unit_scale + Vector3(0,4,0)
	player.set_y_rotation_degrees(traverse.dti.meta_data.starting_rot+90)
	
	print("Level constructed in %d ms" % (Time.get_ticks_msec() - sw))
	print("Total loading time %d ms" % (Time.get_ticks_msec() - sw_total))


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

func create_mesh(mdkmesh: MDKMesh, _name: String) -> Node3D:
	var obj := Node3D.new()
	obj.name = _name
	self.add_child(obj)
	
	var submeshes:Dictionary[int, Array] = {}
	for poly in mdkmesh.polygons:
		if poly.is_hidden():
			continue
		if not submeshes.has(poly.material_flags):
			var arr:Array[Polygon] = []
			submeshes[poly.material_flags] = arr
		submeshes[poly.material_flags].append(poly)
	
	var materials_map :Dictionary[int, Texture2D]= {}
	for i in range(mdkmesh.material_names.size()):
		var item := mdkmesh.material_names[i]
		if textures_dict.has(item):
			materials_map[i] = textures_dict[item]
	
	var material_array :Array[Material]= []
	for material_flags in submeshes.keys():
		material_array.append(create_material(material_flags, materials_map))
	
	var submeshIndex := 0
	for material_flags in submeshes.keys():
		var obj2 = Node3D.new()
		obj2.name = str(material_flags)
		var submesh :Array[Polygon]= submeshes[material_flags]
		var arrays := []
		var vertices:= PackedVector3Array ()
		var uvs:= PackedVector2Array ()
		arrays.resize(ArrayMesh.ARRAY_MAX)
		arrays[ArrayMesh.ARRAY_VERTEX] = vertices
		arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
		for poly in submesh:
			vertices.append(MDKFiles.swizzle_vector(mdkmesh.vertices[poly.v1])*unit_scale)
			vertices.append(MDKFiles.swizzle_vector(mdkmesh.vertices[poly.v2])*unit_scale)
			vertices.append(MDKFiles.swizzle_vector(mdkmesh.vertices[poly.v3])*unit_scale)
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
		#mesh.surface_set_material(submeshIndex, material_array[submeshIndex])
		
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
		print("Wobble effect");
		return null
	elif material_flags < -1028:
		# no idea
		print("Less than -1028");
		return null
	else:
		push_error("Uknown flag: %d" % material_flags)
	return null

func load_files():
	if _static_load_level_has_value:
		level = _static_load_level
	_static_load_level_has_value = false
	var sw := Time.get_ticks_msec()
	files = MDKFiles.get_instance()
	files.load_traverse(BASE_PATH, level)

	var traverse = files.traverse[level]

	if traverse.load_success == false:
		print("failed to load level %s" % MDKFiles.Levels.keys()[level])
		return
	print("Data loaded in %d ms" % (Time.get_ticks_msec() - sw))

	palette.resize(traverse.dti.palette.size())
	for i in range(traverse.dti.palette.size()):
		palette[i] = traverse.dti.palette[i]
	sw = Time.get_ticks_msec()

	for room in traverse.dti.room_list_items:
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
	print("Kurt unpacked in %d ms" % (Time.get_ticks_msec() - sw))

	
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
