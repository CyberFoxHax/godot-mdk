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



var _textures_dict: Dictionary[String, Texture2D] = {}
var _sprites_dict: Dictionary[String, Texture2D] = {}
var files := MDKFiles.new()

static var palette: PackedColorArray = []

class RenderSpritesheetTask:
	var viewport:SubViewport
	var header:MDKSpriteAnimation
	var image:MDKSpriteAnimation.SpriteEntry

class RenderTextureTask:
	var viewport:SubViewport
	var image:MDKImage


func create_spritesheet(spritesheet: MDKSpriteAnimation, _palette:PackedColorArray) -> Texture2D:
	var tasks: Array[RenderSpritesheetTask] = []

	for image in spritesheet._sprite_data:
		var texturesConvertViewport = SubViewport.new()
		texturesConvertViewport.transparent_bg = true
		texturesConvertViewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		texturesConvertViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(texturesConvertViewport)
		var texturesConvertRect = ColorRect.new()
		texturesConvertViewport.add_child(texturesConvertRect)
		
		var shader_material = ShaderMaterial.new()
		shader_material.shader = spritesheet_parser_shader
		texturesConvertRect.material = shader_material
		var texturesConvertMaterial = shader_material

		var beforeTexture = Image.create(image.width, image.height, false, Image.FORMAT_R8)
		beforeTexture.set_data(image.width, image.height, false, Image.FORMAT_R8, image.img_data)
		var beforeImage = ImageTexture.create_from_image(beforeTexture)
		
		texturesConvertViewport.size = Vector2i(image.width, image.height)
		texturesConvertRect.size = Vector2i(image.width, image.height)
		texturesConvertMaterial.set_shader_parameter("palette", _palette)
		texturesConvertMaterial.set_shader_parameter("main_texture", beforeImage)
		
		var task := RenderSpritesheetTask.new()
		task.viewport = texturesConvertViewport
		task.header = spritesheet
		task.image = image
		tasks.append(task)

	await RenderingServer.frame_post_draw

	var total_width = 0
	var total_height = 0
	
	for task in tasks:
		total_width += task.image.width
		total_height = max(total_height, task.image.height)

	var total_texture = Image.create(total_width, total_height, false, Image.FORMAT_RGBA8)
	
	var offset = 0
	for task in tasks:
		var img = task.viewport.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		total_texture.blit_rect(
			img,
			Rect2i(0,0,task.image.width,task.image.height),
			Vector2i(offset, 0)
		);
		offset += task.image.width

	var texture = ImageTexture.create_from_image(total_texture)
	if spritesheet.name == null:
		return texture
	if not _sprites_dict.has(spritesheet.name):
		_sprites_dict[spritesheet.name] = texture
	ui_list.add_item(spritesheet.name, texture)
	print("Spritesheet \"%s\" (%dx%d) loaded" % [spritesheet.name, total_width, total_height])

	for v in tasks:
		v.viewport.queue_free()

	return texture


func create_texture(image: MDKImage, _palette:PackedColorArray, _dict:Dictionary[String, Texture2D]) -> Texture2D:
	var width := image.width
	var height := image.height
	if width > 5000 or height > 5000:
		return null;

	var texturesConvertViewport = SubViewport.new()
	texturesConvertViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(texturesConvertViewport)
	var texturesConvertRect = ColorRect.new()
	texturesConvertViewport.add_child(texturesConvertRect)
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = palette_parser_shader
	texturesConvertRect.material = shader_material
	var texturesConvertMaterial = shader_material

	var beforeTexture = Image.create(width, height, false, Image.FORMAT_R8)
	beforeTexture.set_data(width, height, false, Image.FORMAT_R8, image.data)
	var beforeImage = ImageTexture.create_from_image(beforeTexture)
	
	texturesConvertViewport.size = Vector2i(width, height)
	texturesConvertRect.size = Vector2i(width, height)
	texturesConvertMaterial.set_shader_parameter("palette", _palette)
	texturesConvertMaterial.set_shader_parameter("main_texture", beforeImage)
	
	var task := RenderTextureTask.new()
	task.viewport = texturesConvertViewport
	task.image = image

	await RenderingServer.frame_post_draw

	var img = task.viewport.get_texture().get_image()
	var texture = ImageTexture.create_from_image(img)
	
	if task.image.name == null:
		return texture
	if not _dict.has(task.image.name):
		_dict[task.image.name] = texture
	ui_list.add_item(task.image.name, texture)
	print("Image \"%s\" (%dx%d) loaded" % [task.image.name, task.image.width, task.image.height])

	task.viewport.queue_free()
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
		if _textures_dict.has(item):
			materials_map[i] = _textures_dict[item]
	
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
			vertices.append(Vector3(-mdkmesh.vertices[poly.v1].x, mdkmesh.vertices[poly.v1].z, mdkmesh.vertices[poly.v1].y)*unit_scale)
			vertices.append(Vector3(-mdkmesh.vertices[poly.v2].x, mdkmesh.vertices[poly.v2].z, mdkmesh.vertices[poly.v2].y)*unit_scale)
			vertices.append(Vector3(-mdkmesh.vertices[poly.v3].x, mdkmesh.vertices[poly.v3].z, mdkmesh.vertices[poly.v3].y)*unit_scale)
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

	await RenderingServer.frame_post_draw

	var sw = Time.get_ticks_msec()

	for loc in files.o_mto.room_locations:
		if loc.name == "DANT_8":
			continue
		create_mesh(loc.room.level_model, loc.name)

	for i in range(8, files.o_sni.files.size()):
		var file = files.o_sni.files[i]
		if file.name == "CDANT_8":
			continue
		create_mesh(file.mesh, file.name)
	
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


func load_skybox():
	var skybox := await create_texture(files.dti.skybox_image, palette, _textures_dict)
	enviroment.environment.sky.sky_material.set_shader_parameter("main_texture", skybox);


func load_textures():
	var sw = Time.get_ticks_msec()
	for loc in files.o_mto.room_locations:
		if loc.name == "DANT_8":
			continue
		var room = loc.room
		for i in room.palette.size():
			palette[i + 64] = room.palette[i]
		for sss in room.mti_items:
			create_texture(sss.image, palette.duplicate(), _textures_dict)
	
	for item in files.s_mti.entries:
		if item.image != null:
			create_texture(item.image, palette, _textures_dict)

	await RenderingServer.frame_post_draw

	print("Images loaded in %d ms" % (Time.get_ticks_msec() - sw))


func load_kurt():
	var sw = Time.get_ticks_msec()

	var idle = files.traverse_bni.sprites["K_IDLE"]
	idle.unpack()
	var spritesheet = await create_spritesheet(idle, palette);

	player_material.set_shader_parameter("main_texture", spritesheet)
	var rects: Array[Vector4] = [];
	var offset_x = 0;
	for dat in idle._sprite_data:
		var newrect = Vector4(
			offset_x/float(spritesheet.get_width()),
			0,
			dat.width/float(spritesheet.get_width()),
			1,
			
		)
		offset_x += dat.width
		rects.append(newrect)
	player_material.set_shader_parameter("frame_count", len(rects))
	player_material.set_shader_parameter("frame_rects", rects)

	print("Kurt loaded in %d ms" % (Time.get_ticks_msec() - sw))
