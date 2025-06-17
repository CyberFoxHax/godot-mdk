class_name GodotConverterHelpers
extends Resource

@export var palette_parser_shader: Shader
@export var spritesheet_parser_shader: Shader

func _print_info(msg: String):
	MyGlobal.print_info(msg)

func create_bitmap_font(ctx:Node, mdk_font: MDKFont, _palette:PackedColorArray) -> FontFile:
	var total_width = 0
	var total_height = 0

	for code in mdk_font.glyphs:
		var glyph = mdk_font.glyphs[code]
		total_width += glyph.width
		total_height = max(total_height, glyph.height())

	var total_texture := Image.create(total_width, total_height, false, Image.FORMAT_R8)
	var rectangles:Dictionary[int, Rect2] = {}
	var offset = 0
	for code in mdk_font.glyphs:
		var glyph = mdk_font.glyphs[code]
		var tex = Image.create(glyph.width, glyph.height(), false, Image.FORMAT_R8)
		tex.set_data(glyph.width, glyph.height(), false, Image.FORMAT_R8, glyph.data)

		rectangles[code] = Rect2(offset, 0, glyph.width, glyph.height())
		var r1 := rectangles[code]
		r1.position.x = 0
		total_texture.blit_rect(tex, r1, Vector2i(offset, 0));
		offset += glyph.width


	var viewport := SubViewport.new()
	viewport.transparent_bg = true
	viewport.render_target_clear_mode  = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	ctx.add_child(viewport)
	var colorRect := ColorRect.new()
	viewport.add_child(colorRect)
	
	var shader_material := ShaderMaterial.new()
	shader_material.shader = spritesheet_parser_shader
	colorRect.material = shader_material
	var mmaterial = shader_material

	var beforeImage := ImageTexture.create_from_image(total_texture)
	
	viewport.size = Vector2i(total_width, total_height)
	colorRect.size = viewport.size
	mmaterial.set_shader_parameter("palette", _palette)
	mmaterial.set_shader_parameter("main_texture", beforeImage)


	await RenderingServer.frame_post_draw


	var newtexture := viewport.get_texture().get_image()

	_print_info("Font atlas generated \"%s\" (%dx%d)" % [mdk_font.name, total_width, total_height])

	viewport.queue_free()

	#newtexture.save_png("C:\\font_test.png");

	var font := FontFile.new()
	font.font_name = mdk_font.name
	font.fixed_size = 20
	var cache_index := 0
	var font_size := Vector2i(font.fixed_size, 0)
	font.set_texture_image(0, font_size, 0, newtexture)

	var space_char_code = 32
	var space_glyph_index = font.get_glyph_index(font.fixed_size, space_char_code, 0)
	font.set_glyph_uv_rect(cache_index, font_size, space_glyph_index, Rect2(-1, 0, 1, 1))
	font.set_glyph_texture_idx(cache_index, font_size, space_glyph_index, 0)
	font.set_glyph_size(cache_index, font_size, space_glyph_index, Vector2(font.fixed_size, font.fixed_size))  # Same size for consistency
	font.set_glyph_advance(cache_index, font.fixed_size, space_glyph_index, Vector2(16, 0))  # Critical: Set advance
	font.set_glyph_offset(cache_index, font_size, space_glyph_index, Vector2(0, 0))

	for code in rectangles:
		var rect:Rect2 = rectangles[code]
		var mdk_glyph := mdk_font.glyphs[code]
		var glyph_size = Vector2i(int(rect.size.x), int(rect.size.y))

		var glyph_index = font.get_glyph_index(font.fixed_size, code, 0)
		# Set glyph properties
		font.set_glyph_uv_rect(cache_index, font_size, glyph_index, rect)
		font.set_glyph_texture_idx(cache_index, font_size, glyph_index, 0)
		font.set_glyph_size(cache_index, font_size, glyph_index, glyph_size)
		font.set_glyph_advance(cache_index, font.fixed_size, glyph_index, Vector2(rect.size.x, 0))
		font.set_glyph_offset(cache_index, font_size, glyph_index, Vector2(0,  total_height-mdk_glyph.height()+mdk_glyph.vertical_shift-total_height*0.7))

	font.set_cache_ascent(cache_index, font.fixed_size, 0.0)  # Ascent (above baseline)
	font.set_cache_descent(cache_index, font.fixed_size, 0.0)  # Descent (below baseline)
	

	return font



func create_spritesheet(ctx:Node, spritesheet: MDKSpriteAnimation, _palette:PackedColorArray) -> ImageTexture:
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
	ctx.add_child(viewport)
	var colorRect = ColorRect.new()
	viewport.add_child(colorRect)
	
	var shader_material := ShaderMaterial.new()
	shader_material.shader = spritesheet_parser_shader
	colorRect.material = shader_material
	var material := shader_material

	var beforeImage := ImageTexture.create_from_image(total_texture)
	
	viewport.size = Vector2i(total_width, total_height)
	colorRect.size = viewport.size
	material.set_shader_parameter("palette", _palette)
	material.set_shader_parameter("main_texture", beforeImage)


	await RenderingServer.frame_post_draw


	var newtexture := viewport.get_texture().get_image()

	var texture := ImageTexture.create_from_image(newtexture)
	if spritesheet.name == null:
		return texture
	_print_info("Spritesheet \"%s\" (%dx%d) loaded" % [spritesheet.name, total_width, total_height])

	viewport.queue_free()

	#newtexture.save_png("C:\\test.png");

	return texture




func create_texture(ctx:Node, image: MDKImage, _palette:PackedColorArray, _dict:Dictionary[String, Texture2D], mipmaps:bool=true) -> ImageTexture:
	var width := image.width
	var height := image.height
	if width > 5000 or height > 5000:
		return null;

	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	ctx.add_child(viewport)
	var colorRect := ColorRect.new()
	viewport.add_child(colorRect)
	
	var shader_material := ShaderMaterial.new()
	shader_material.shader = palette_parser_shader
	colorRect.material = shader_material

	var beforeTexture := Image.create(width, height, false, Image.FORMAT_R8)
	beforeTexture.set_data(width, height, false, Image.FORMAT_R8, image.data)
	var beforeImage := ImageTexture.create_from_image(beforeTexture)
	
	viewport.size = Vector2i(width, height)
	colorRect.size = Vector2i(width, height)
	shader_material.set_shader_parameter("palette", _palette)
	shader_material.set_shader_parameter("main_texture", beforeImage)
	

	await RenderingServer.frame_post_draw


	var img := viewport.get_texture().get_image()
	if mipmaps==true:
		img.generate_mipmaps()
	var texture := ImageTexture.create_from_image(img)
	
	if image.name == null:
		return texture
	if not _dict.has(image.name):
		_dict[image.name] = texture
	_print_info("Image \"%s\" (%dx%d) loaded" % [image.name, image.width, image.height])

	#img.save_png("C:\\MDK\\%s.png"%image.name);

	viewport.queue_free()
	return texture
