class_name BNIFile
extends BinaryReadable

var filesize: int;
var entry_count: int;
var files: Array[BNIFileEntry] = []

var sprites:Dictionary[String, MDKSpriteAnimation]
var images:Dictionary[String, MDKImage]

func read(reader: ByteBuffer) -> void:
	filesize = reader.get_u32()
	entry_count = reader.get_u32()
	files = [];
	files.resize(entry_count)
	for i in range(entry_count):
		files[i] = BNIFileEntry.new()
		files[i].read(reader)

	for i in range(8, 33):
		var file = files[i]
		reader.set_position(file.offset+4);
		var sprite = MDKSpriteAnimation.new(file.name)
		sprite.read(reader)
		#sprite.unpack()
		#sprite.address = reader.get_position()
		sprites[file.name] = sprite

	for i in range(34, 56):
		var file = files[i]
		reader.set_position(file.offset+4)
		var img = MDKImage.new(file.name)
		img.read(reader)
		images[file.name] = img


class BNIFileEntry:
	extends BinaryReadable
	var name:String;
	var offset:int;

	func read(file: ByteBuffer) -> void:
		name = file.get_chars(12)
		offset = file.get_u32()
		

class Task:
	var thread:Thread
	var result:Object
	var anim:MDKSpriteAnimation;
	var file:ByteBuffer

	func Start():
		thread = Thread.new()
		thread.start(Process)

	func Process():
		anim.read(file);

	func Wait():
		thread.wait_to_finish()
