extends Node3D

const BASE_PATH := "D:/Projects/mdk/MDK-Game"

@onready var ui_list:ItemList = $ItemList
@export var parser_shader:Shader
@export var enviroment: WorldEnvironment

var _textures_dict: Dictionary = {}
var _textures: Array[ImageTexture] = []

static var palette: PackedColorArray = []

var texturesConvertViewport: SubViewport
var texturesConvertRect: ColorRect
var texturesConvertMaterial:Material

func create_texture(image: MDKImage) -> ImageTexture:
	var width := image.width
	var height := image.height
	if width > 5000 or height > 5000:
		return null;
	var sw := Time.get_ticks_msec()

	var beforeTexture = Image.create(width, height, false, Image.FORMAT_R8)
	beforeTexture.set_data(width, height, false, Image.FORMAT_R8, image.data)
	var beforeImage = ImageTexture.create_from_image(beforeTexture)

	
	texturesConvertViewport.size = Vector2i(width, height)
	texturesConvertRect.size = Vector2i(width, height)
	texturesConvertMaterial.set_shader_parameter("palette", palette)
	texturesConvertMaterial.set_shader_parameter("pixels_size", Vector2(width, height))
	texturesConvertMaterial.set_shader_parameter("pixels", beforeImage)
	
	await RenderingServer.frame_post_draw
	
	var img = texturesConvertViewport.get_texture().get_image()

	beforeTexture.blit_rect(
	var texture = ImageTexture.create_from_image(img)
	
	_textures.append(texture)
	if image.name == null:
		return texture
	if not _textures_dict.has(image.name):
		_textures_dict[image.name] = texture
	ui_list.add_item(image.name, texture)
	print("Image \"%s\" (%dx%d) loaded in %dms" % [image.name, width, height, (Time.get_ticks_msec() - sw)])
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
	
	var material_array :Array[StandardMaterial3D]= []
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
			vertices.append(Vector3(-mdkmesh.vertices[poly.v1].x, mdkmesh.vertices[poly.v1].z, mdkmesh.vertices[poly.v1].y))
			vertices.append(Vector3(-mdkmesh.vertices[poly.v2].x, mdkmesh.vertices[poly.v2].z, mdkmesh.vertices[poly.v2].y))
			vertices.append(Vector3(-mdkmesh.vertices[poly.v3].x, mdkmesh.vertices[poly.v3].z, mdkmesh.vertices[poly.v3].y))
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
	return obj

var files := MDKFiles.new()
var skybox: Texture2D

func create_material(flags: int, materials_map: Dictionary[int, Texture2D]) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.roughness = 1.0
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	material.albedo_color = Color.WHITE
	if flags >= -255 and flags <= -1:
		if -flags < palette.size():
			material.albedo_color = palette[-flags]
	elif flags >= 0 and flags <= 255:
		if materials_map.has(flags):
			material.albedo_texture = materials_map[flags]
		else:
			push_error("Material key not found: %d" % flags)
	
	return material

func _ready() -> void:
	var sw := Time.get_ticks_msec()
	
	files = MDKFiles.new()
	files.load_level(BASE_PATH, "LEVEL7")
	palette.resize(files.dti.palette.size())
	for i in range(files.dti.palette.size()):
		palette[i] = files.dti.palette[i]
	print("Data loaded in %d ms" % (Time.get_ticks_msec() - sw))
	sw = Time.get_ticks_msec()
	
	texturesConvertViewport = SubViewport.new()
	texturesConvertViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(texturesConvertViewport)
	texturesConvertRect = ColorRect.new()
	texturesConvertViewport.add_child(texturesConvertRect)
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = parser_shader
	texturesConvertRect.material = shader_material
	texturesConvertMaterial = shader_material
	

	for loc in files.o_mto.room_locations:
		if loc.name == "DANT_8":
			continue
		var room = loc.room
		for i in room.palette.size():
			palette[i + 64] = room.palette[i]
		for sss in room.mti_items:
			await create_texture(sss.image)
	
	for item in files.s_mti.entries:
		if item.image != null:
			await create_texture(item.image)

	for loc in files.o_mto.room_locations:
		if loc.name == "DANT_8":
			continue
		create_mesh(loc.room.level_model, loc.name)

	for i in range(8, files.o_sni.files.size()):
		var file = files.o_sni.files[i]
		if file.name == "CDANT_8":
			continue
		create_mesh(file.mesh, file.name)
	
	skybox = await create_texture(files.dti.skybox_image)
	enviroment.environment.sky.sky_material.set_shader_parameter("tex", skybox);
	#skybox.set("filter_mode", Texture2D.FILTER_BILINEAR)
	#skybox.set("wrap_mode_u", Texture2D.WRAP_REPEAT)
	#skybox.set("wrap_mode_v", Texture2D.WRAP_CLAMP)
	#RenderingServer.global_shader_parameter_set("skybox", skybox)
	
	texturesConvertViewport.queue_free()
	
	print("Level constructed in %d ms" % (Time.get_ticks_msec() - sw))
