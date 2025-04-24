class_name BNIFile
extends BinaryReadable

var filename: String

var filesize: int
var entry_count: int
var files: Array[BNIFileEntry] = []

var sprites:Dictionary[String, MDKSpriteAnimation]
var images:Dictionary[String, MDKImage]
var palette_images:Dictionary[String, MDKImageWithPalette]

func _init(_name:String):
	filename = _name

func read(reader: ByteBuffer) -> void:
	filesize = reader.get_u32()
	entry_count = reader.get_u32()
	files = [];
	files.resize(entry_count)
	for i in range(entry_count):
		files[i] = BNIFileEntry.new()
		files[i].read(reader)

	
	## didn't work...
	# for myrange:MyRange in ranges[filename]:
	# 	for i in range(myrange.start, myrange.end):
	# 		var file = files[i]
	# 		var instance:BinaryReadable = myrange.type.new(file.name)
	# 		instance.read(reader)
	# 		myrange.dict[file.name] = instance

		

	if filename == "TRAVSPRT.BNI":
		for i in range(8, 33):
			var file = files[i]
			reader.set_position(file.offset+4);
			var sprite = MDKSpriteAnimation.new(file.name)
			sprite.read(reader)
			sprites[file.name] = sprite

		for i in range(34, 56):
			var file = files[i]
			reader.set_position(file.offset+4)
			var img = MDKImage.new(file.name)
			img.read(reader)
			images[file.name] = img

	elif filename == "OPTIONS.BNI":
		for i in range(0, 1):
			var file = files[i]
			reader.set_position(file.offset+4);
			var palette_image = MDKImageWithPalette.new(file.name)
			palette_image.read(reader)
			palette_images[file.name] = palette_image


class BNIFileEntry:
	extends BinaryReadable
	var name:String;
	var offset:int;

	func read(file: ByteBuffer) -> void:
		name = file.get_chars(12)
		offset = file.get_u32()



class MyRange:
	func _init(_start:int, _end:int, _type:GDScript):
		start = _start
		end = _end
		type = _type

	var start: int
	var end: int
	var type: GDScript

func _create_instance(reader:ByteBuffer, dict:Dictionary, name:String, type:GDScript)->void:
	var instance:BinaryReadable = type.new(name)
	instance.read(reader)
	dict[name] = instance

var ranges = {
	"TRAVSPRT":[
		MyRange.new( 8, 33, MDKSpriteAnimation),
		MyRange.new(34, 56, MDKImage)
	],
}
