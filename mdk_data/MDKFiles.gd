class_name MDKFiles

static var global_files:MDKFiles;

static func get_instance() -> MDKFiles:
	if global_files == null:
		global_files = MDKFiles.new()
	return global_files


enum Levels{
	LEVEL3,
	LEVEL4,
	LEVEL5,
	LEVEL6,
	LEVEL7,
	LEVEL8
}

var traverse:Dictionary[Levels, MDKTraverse] = {}

var fti: FTIFile
var traverse_bni: BNIFile
var options_bni: BNIFile

# Define data types for each file
var data_types:Dictionary[String, GDScript] = {
	"fti": FTIFile,
	"bni": BNIFile,
	"sni": SNIFile,
}

#convert MDK's coodinate system to Godot
static func swizzle_vector(v:Vector3) -> Vector3:
	return Vector3(-v.x, v.z, v.y)

func load_options_bni(base_path: String) -> void:
	var file_paths:Dictionary[String, String] = {
		"bni": base_path.path_join("MISC").path_join("OPTIONS.BNI"),
	}

	var results = _start_load_thread(file_paths);

	options_bni = results.pop_front()



func load_globals(base_path: String) -> void:
	var file_paths:Dictionary[String, String] = {
		"fti": base_path.path_join("MISC").path_join("mdkfont.fti"),
	}
	var results = _start_load_thread(file_paths);

	fti = results.pop_front()

	#_load_file(file_paths["fti"], FTIFile, [null], 0)

func load_fall3d(base_path: String, level: int) -> void:
	var path := base_path.path_join("FALL3D")
	var file_paths:Dictionary[String, String] = {
		"bni": path.path_join("FALL3D.BNI"),
		"s_sni": path.path_join("FALL3D.SNI"),
		"o_mti": path.path_join("FALL3D_%d.MTI"%level)
	}
	var results = _start_load_thread(file_paths);

	pass

func load_stream(base_path: String, level: String) -> void:
	var path := base_path.path_join("STREAM")
	var file_paths:Dictionary[String, String] = {
		"bni": path.path_join("STREAM.BNI"),
		"s_mti": path.path_join("STREAM.MTI"),
	}
	var results = _start_load_thread(file_paths);

	pass

# result will be in traverse[level]
func load_traverse(base_path: String, level: Levels) -> void:
	var t = MDKTraverse.new()
	t.load_traverse(base_path, Levels.keys()[level])

	var file_paths:Dictionary[String, String] = {
		"bni": base_path.path_join("TRAVERSE").path_join("TRAVSPRT.BNI")
	}

	var results = _start_load_thread(file_paths);
	
	# Assign results to class variables
	traverse_bni = results.pop_front()

	traverse[level] = t;


func _start_load_thread(file_paths:Dictionary[String, String]) -> Array[Object]:
	for key in file_paths:
		if FileAccess.file_exists(file_paths[key]) == false:
			assert(false, "Path not found: %s" % file_paths[key])

	# Dictionary to store threads and their results
	var threads:Array[Thread]= []
	var results:Array[Object]= []
	var files_count = len(file_paths)
	threads.resize(files_count)
	results.resize(files_count)
	
	# Start a thread for each file
	var i=0;
	for key in file_paths:
		var thread := Thread.new()
		threads[i] = thread
		thread.start(_load_file.bind(file_paths[key], data_types[key], results, i))
		i=i+1
	
	# Wait for all threads to complete
	for key in len(threads):
		var thread: Thread = threads[key]
		thread.wait_to_finish()

	return results

func _load_file(path: String, data_type: GDScript, results: Array[Object], result_key: int) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var buffer := file.get_buffer(file.get_length())
	var byteBuffer = ByteBuffer.new(buffer)

	var data = data_type.new(path.get_file())
	data.read(byteBuffer)
	file.close()
	
	print("loaded " + path)
	results[result_key] = data
