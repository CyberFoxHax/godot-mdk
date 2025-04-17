extends Node3D

const BASE_PATH := "D:/Projects/mdk/MDK-Game"


@export var unit_scale: float = 1
@export var level: Levels = Levels.LEVEL7

enum Levels{
	LEVEL3,
	LEVEL4,
	LEVEL5,
	LEVEL6,
	LEVEL7,
	LEVEL8
}

class CutContent:
	func _init(mdict:Dictionary[String, bool]) -> void:
		dict = mdict

	var dict:Dictionary[String, bool]


var cut_content:Dictionary[Levels, CutContent] = {
	Levels.LEVEL3: CutContent.new({
		"HMO_3":true,
		"HMO_7":true,
		"CHMO_3":true,
		"CHMO_7":true
	}),
	Levels.LEVEL4: CutContent.new({
		"MEAT_2":true,
		"MEAT_9":true,
		"CMEAT_2":true,
		"CMEAT_9":true,
	}),
	Levels.LEVEL5: CutContent.new({
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
	Levels.LEVEL6: CutContent.new({
		"OLYM_9":true,
		"COLYM_9":true
	}),
	Levels.LEVEL7: CutContent.new({
		"DANT_8": true,
		"CDANT_8": true
	}),
	Levels.LEVEL8: CutContent.new({
		"GUNT_9": true,
		"CGUNT_8": true
	})
}

@export var player: Node3D
@export var player_material: ShaderMaterial
@export var material_black: Material
@export var enviroment: WorldEnvironment
@export var palette_parser_shader: Shader
@export var spritesheet_parser_shader: Shader
@export var texture_shader: Shader
@export var color_shader: Shader
@export var shiny_shader: Shader
@export var transparent_shader: Shader

@onready var ui_list:ItemList = $ItemList

var room_list:Dictionary[String, DTIFile.RoomListItem] = {}

var textures_dict: Dictionary[String, Texture2D] = {}
var sprites_dict: Dictionary[String, Texture2D] = {}
var files := MDKFiles.new()

static var palette: PackedColorArray = []

func create_spritesheet(spritesheet: MDKSpriteAnimation, _palette:PackedColorArray) -> Texture2D:
	var total_width = 0
	var total_height = 0
	
	for sprite:MDKSpriteAnimation.SpriteEntry in spritesheet.images:
		#total_width += task.image.width-task.image.x_ui_shift
		#total_height = max(total_height, task.image.height+task.image.y_ui_shift)
		total_width += sprite.width
		total_height = max(total_height, sprite.height)

	var total_texture = Image.create(total_width, total_height, false, Image.FORMAT_R8)

	var offset = 0
	for sprite:MDKSpriteAnimation.SpriteEntry in spritesheet.images:
		var tex = Image.create(sprite.width, sprite.height, false, Image.FORMAT_R8)
		tex.set_data(sprite.width, sprite.height, false, Image.FORMAT_R8, sprite.img_data)

		total_texture.blit_rect(
			tex,
			Rect2i(0, 0, sprite.width, sprite.height),
			Vector2i(offset, 0)
			#Vector2i(offset-v.x_ui_shift+v.width/2, -v.y_ui_shift+v.height/2)
		);
		offset += sprite.width

	var viewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport.render_target_clear_mode  = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var colorRect = ColorRect.new()
	viewport.add_child(colorRect)
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = spritesheet_parser_shader
	colorRect.material = shader_material
	var material = shader_material

	var beforeImage = ImageTexture.create_from_image(total_texture)
	
	viewport.size = Vector2i(total_width, total_height)
	colorRect.size = viewport.size
	material.set_shader_parameter("palette", _palette)
	material.set_shader_parameter("main_texture", beforeImage)


	await RenderingServer.frame_post_draw


	var newtexture = viewport.get_texture().get_image()

	var texture = ImageTexture.create_from_image(newtexture)
	if spritesheet.name == null:
		return texture
	if not sprites_dict.has(spritesheet.name):
		sprites_dict[spritesheet.name] = texture
	ui_list.add_item(spritesheet.name, texture)
	print("Spritesheet \"%s\" (%dx%d) loaded" % [spritesheet.name, total_width, total_height])

	viewport.queue_free()

	#newtexture.save_png("C:\\test.png");

	return texture


func create_texture(image: MDKImage, _palette:PackedColorArray, _dict:Dictionary[String, Texture2D]) -> Texture2D:
	var width := image.width
	var height := image.height
	if width > 5000 or height > 5000:
		return null;

	var viewport = SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var colorRect = ColorRect.new()
	viewport.add_child(colorRect)
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = palette_parser_shader
	colorRect.material = shader_material

	var beforeTexture = Image.create(width, height, false, Image.FORMAT_R8)
	beforeTexture.set_data(width, height, false, Image.FORMAT_R8, image.data)
	var beforeImage = ImageTexture.create_from_image(beforeTexture)
	
	viewport.size = Vector2i(width, height)
	colorRect.size = Vector2i(width, height)
	shader_material.set_shader_parameter("palette", _palette)
	shader_material.set_shader_parameter("main_texture", beforeImage)
	

	await RenderingServer.frame_post_draw


	var img = viewport.get_texture().get_image()
	var texture = ImageTexture.create_from_image(img)
	
	if image.name == null:
		return texture
	if not _dict.has(image.name):
		_dict[image.name] = texture
	ui_list.add_item(image.name, texture)
	print("Image \"%s\" (%dx%d) loaded" % [image.name, image.width, image.height])

	viewport.queue_free()
	return texture

func create_mesh(mdkmesh: MDKMesh, _name: String) -> Node3D:
	var obj := Node3D.new()
	obj.name = _name
	self.add_child(obj)
	var mr := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	
	var submeshes:Dictionary[int, Array] = {}
	for poly in mdkmesh.polygons:
		if not submeshes.has(poly.flags):
			var arr:Array[Polygon] = []
			submeshes[poly.flags] = arr
		submeshes[poly.flags].append(poly)
	
	var materials_map :Dictionary[int, Texture2D]= {}
	for i in range(mdkmesh.material_names.size()):
		var item := mdkmesh.material_names[i]
		if textures_dict.has(item):
			materials_map[i] = textures_dict[item]
	
	var material_array :Array[Material]= []
	for flags in submeshes.keys():
		material_array.append(create_material(flags, materials_map))
	
	var submeshIndex := 0
	for flags in submeshes.keys():
		var submesh :Array[Polygon]= submeshes[flags]
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
			if materials_map.has(poly.flags):
				var tex: Texture2D = materials_map[poly.flags]
				var tex_size := Vector2(tex.get_width(), tex.get_height())
				uvs.append(poly.t1 / tex_size)
				uvs.append(poly.t2 / tex_size)
				uvs.append(poly.t3 / tex_size)
			else:
				uvs.append(Vector2.ZERO)
				uvs.append(Vector2.ZERO)
				uvs.append(Vector2.ZERO)
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(submeshIndex, material_array[submeshIndex])
		
		submeshIndex = submeshIndex+1;
	
	mr.mesh = mesh
	obj.add_child(mr)

	var staticbody3d = StaticBody3D.new()
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	var collider = CollisionShape3D.new()
	collider.shape = shape
	staticbody3d.add_child(collider)
	obj.add_child(staticbody3d);

	return obj

func create_material(flags: int, materials_map: Dictionary[int, Texture2D]) -> Material:
	if flags >= -255 and flags <= -1: # simple color
		var material := ShaderMaterial.new()
		material.shader = color_shader;
		if -flags < palette.size():
			material.set_shader_parameter("main_color", palette[-flags])
		return material
	elif flags >= 0 and flags <= 255: # standard textured
		var material := ShaderMaterial.new()
		material.shader = texture_shader;
		if materials_map.has(flags):
			material.set_shader_parameter("main_texture", materials_map[flags])
		else:
			return material_black
		return material
	elif flags >= -1010 && flags <= -990: # shiny
		var reflection_offset_y = -990 - flags;
		var material := ShaderMaterial.new()
		material.shader = shiny_shader
		material.set_shader_parameter("main_texture", skybox)
		material.set_shader_parameter("reflection_offset_y", float(reflection_offset_y)/float(skybox.get_height()))
		return material;
	elif flags >= -1027 && flags <= -1024: # transparent color
		var v = -flags - 1024
		var transparent_color = files.dti.meta_data.transparency_colors[v];
		var material := ShaderMaterial.new()
		material.shader = transparent_shader
		material.set_shader_parameter("main_color", transparent_color);
		return material;
	elif flags == -1028:
		# wobble effect for under water stuff???
		print("Wobble effect");
		return null
	elif flags < -1028:
		# no idea
		print("Less than -1028");
		return null
	else:
		push_error("Uknown flag: %d" % flags)
	return null

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


	for loc in files.o_mto.room_locations:
		if room_list.has(loc.name) == false:
			continue
		if cut_content[level].dict.get(loc.name) == true:
			continue
		create_mesh(loc.room.level_model, loc.name)

	for file in files.o_sni.files:
		if room_list.has(file.name) == false:
			continue
		if cut_content[level].dict.get(file.name) == true:
			continue
		create_mesh(file.mesh, file.name)

	player.position = MDKFiles.swizzle_vector(files.dti.meta_data.starting_pos) + Vector3(0,4,0)
	
	print("Level constructed in %d ms" % (Time.get_ticks_msec() - sw))
	print("Total loading time %d ms" % (Time.get_ticks_msec() - sw_total))

func load_files():
	var sw := Time.get_ticks_msec()
	files = MDKFiles.new()
	if files.load_traverse(BASE_PATH, Levels.keys()[level]) == false:
		print("failed to load level %s" % Levels.keys()[level])
		return
	print("Data loaded in %d ms" % (Time.get_ticks_msec() - sw))

	palette.resize(files.dti.palette.size())
	for i in range(files.dti.palette.size()):
		palette[i] = files.dti.palette[i]
	sw = Time.get_ticks_msec()

	for room in files.dti.room_list_items:
		room_list.set(room.name, room)


var skybox:Texture2D
func load_skybox():
	skybox = await create_texture(files.dti.skybox_image, palette, textures_dict)
	enviroment.environment.sky.sky_material.set_shader_parameter("main_texture", skybox);


func load_textures():
	for loc in files.o_mto.room_locations:
		if cut_content[level].dict.get(loc.name) == true:
			continue
		var room = loc.room
		for i in room.palette.size():
			palette[i + 64] = room.palette[i]
		for sss in room.mti_items:
			create_texture(sss.image, palette.duplicate(), textures_dict)
	
	for item in files.s_mti.entries:
		if item.image != null:
			create_texture(item.image, palette, textures_dict)

	await RenderingServer.frame_post_draw


func load_kurt():
	var sw = Time.get_ticks_msec()

	var idle = files.traverse_bni.sprites["K_RUN"]
	idle.unpack()
	var spritesheet = await create_spritesheet(idle, palette);

	print("Kurt unpacked in %d ms" % (Time.get_ticks_msec() - sw))

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
