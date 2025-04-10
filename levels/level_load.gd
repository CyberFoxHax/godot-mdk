extends Node3D

const BASE_PATH := "D:/Projects/mdk/MDK-Game"

@onready var ui_list:ItemList = $ItemList

var _textures_dict: Dictionary = {}
var _textures: Array[ImageTexture] = []

static var palette: PackedColorArray = []

func create_texture(image: MDKImage) -> ImageTexture:
	var width := image.width
	var height := image.height
	if width > 1000 or height > 1000:
		return null;
	var texture := ImageTexture.new()
	var image_data := Image.create(width, height, false, Image.FORMAT_RGBA8)
	#image_data.fill(Color.BLACK)
	

	var sw := Time.get_ticks_msec()
	if image.frames != null:  # Image sequence
		texture.set("name", image.name)
		var pixels := PackedByteArray()
		pixels.resize(width * height * 4)
		for pi in range(pixels.size()/4):
			var v := image.data[pi]
			if v < palette.size():
				pixels[pi*4+0] = palette[v].r*255.0
				pixels[pi*4+1] = palette[v].g*255.0
				pixels[pi*4+2] = palette[v].b*255.0
				pixels[pi*4+3] = 255
			else: # Magenta for invalid
				pixels[pi*4+0] = 255
				pixels[pi*4+1] = 0
				pixels[pi*4+2] = 255
				pixels[pi*4+3] = 255
		image_data.set_data(width, height, false, Image.FORMAT_RGBA8, pixels)
		texture = ImageTexture.create_from_image(image_data)
		#texture.texture_filter = Texture2D.TEXTURE_FILTER_NEAREST  # Fixed here
	else:  # Normal texture
		texture.set("name", image.name)
		var pixels := PackedByteArray()
		pixels.resize(width * height * 4)
		for pi in pixels.size()/4:
			var v := image.data[pi]
			if v < palette.size():
				pixels[pi*4+0] = palette[v].r*255.0
				pixels[pi*4+1] = palette[v].g*255.0
				pixels[pi*4+2] = palette[v].b*255.0
				pixels[pi*4+3] = 255
			else: # Magenta for invalid
				pixels[pi*4+0] = 255
				pixels[pi*4+1] = 0
				pixels[pi*4+2] = 255
				pixels[pi*4+3] = 255
		image_data.set_data(width, height, false, Image.FORMAT_RGBA8, pixels)
		texture = ImageTexture.create_from_image(image_data)
		#texture.texture_filter = Texture2D.TEXTURE_FILTER_NEAREST  # Fixed here
	_textures.append(texture)
	if image.name == null:
		return texture
	if not _textures_dict.has(image.name):
		_textures_dict[image.name] = texture
	#ui_list.add_item(image.name, texture)
	print("Image \"%s\" (%dx%d) loaded in %dms" % [image.name, width, height, (Time.get_ticks_msec() - sw)])
	sw = Time.get_ticks_msec()
	return texture

func create_mesh(mdkmesh: MDKMesh, _name: String) -> Node3D:
	var obj := Node3D.new()
	obj.name = _name
	self.add_child(obj)
	var mr := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	
	var vertices:= PackedVector3Array ()
	var uvs:= PackedVector2Array ()
	var indices_indices:Array[PackedInt32Array]
	
	var submeshes:Dictionary = {}
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
	
	var indice := 0
	for flags in submeshes.keys():
		var submesh :Array[Polygon]= submeshes[flags]
		var indices :PackedInt32Array= []
		for poly in submesh:
			indices.append(indice)
			indices.append(indice + 1)
			indices.append(indice + 2)
			indice += 3
			vertices.append(Vector3(mdkmesh.vertices[poly.v3].x, mdkmesh.vertices[poly.v3].z, mdkmesh.vertices[poly.v3].y))
			vertices.append(Vector3(mdkmesh.vertices[poly.v2].x, mdkmesh.vertices[poly.v2].z, mdkmesh.vertices[poly.v2].y))
			vertices.append(Vector3(mdkmesh.vertices[poly.v1].x, mdkmesh.vertices[poly.v1].z, mdkmesh.vertices[poly.v1].y))
			if materials_map.has(poly.flags):
				var tex: Texture2D = materials_map[poly.flags]
				var tex_size := Vector2(tex.get_width(), tex.get_height())
				uvs.append(poly.t3 / tex_size)
				uvs.append(poly.t2 / tex_size)
				uvs.append(poly.t1 / tex_size)
			else:
				uvs.append(Vector2.ZERO)
				uvs.append(Vector2.ZERO)
				uvs.append(Vector2.ZERO)
		indices_indices.append(indices)
	
	var arrays := []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	
	for i in range(indices_indices.size()):
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(i, material_array[i])
		#mesh.surface_set_triangles(indices_indices[i], i)
	
	mr.mesh = mesh
	obj.add_child(mr)
	return obj

var files := MDKFiles.new()
var skybox: Texture2D

func create_material(flags: int, materials_map: Dictionary[int, Texture2D]) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.roughness = 0.9
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
	
	for loc in files.o_mto.room_locations:
		if loc.name == "DANT_8":
			continue
		var room = loc.room
		for i in room.palette.size():
			palette[i + 64] = room.palette[i]
		for sss in room.mti_items:
			create_texture(sss.image)
		create_mesh(room.level_model, loc.name)
	
	for item in files.s_mti.entries:
		if item.image != null:
			create_texture(item.image)
	
	for i in range(8, files.o_sni.files.size()):
		var file = files.o_sni.files[i]
		if file.name == "CDANT_8":
			continue
		create_mesh(file.mesh, file.name)
	
	skybox = create_texture(files.dti.skybox_image)
	#skybox.set("filter_mode", Texture2D.FILTER_BILINEAR)
	#skybox.set("wrap_mode_u", Texture2D.WRAP_REPEAT)
	#skybox.set("wrap_mode_v", Texture2D.WRAP_CLAMP)
	#RenderingServer.global_shader_parameter_set("skybox", skybox)
	
	print("Level constructed in %d ms" % (Time.get_ticks_msec() - sw))
