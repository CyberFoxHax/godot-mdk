class_name MDKFiles

var fti: FTIFile
var cmi: CMIFile
var dti: DTIFile
var o_mto: MTOFile
var o_sni: SNIFile
var s_mti: MTIFile
var s_sni: SNIFile
var traverse_bni:BNIFile

# Define data types for each file
var data_types : Dictionary[String, GDScript] = {
	"fti": FTIFile,
	"cmi": CMIFile,
	"dti": DTIFile,
	"o_mto": MTOFile,
	"o_sni": SNIFile,
	"s_mti": MTIFile,
	"s_sni": SNIFile,
	"bni": BNIFile
}

func load_globals(base_path: String):
	var file_paths:Dictionary[String, String] = {
		"fti": base_path.path_join("MISC").path_join("mdkfont.fti"),
	}
	var results = start_load_thread(file_paths);

	pass

func load_fall3d(base_path: String, level: int):
	var path := base_path.path_join("FALL3D")
	var file_paths:Dictionary[String, String] = {
		"bni": path.path_join("FALL3D.BNI"),
		"s_sni": path.path_join("FALL3D.SNI"),
		"o_mti": path.path_join("FALL3D_%d.MTI"%level)
	}
	var results = start_load_thread(file_paths);

	pass

func load_stream(base_path: String, level: String):
	var path := base_path.path_join("STREAM")
	var file_paths:Dictionary[String, String] = {
		"bni": path.path_join("STREAM.BNI"),
		"s_mti": path.path_join("STREAM.MTI"),
	}
	var results = start_load_thread(file_paths);

	pass


func load_traverse(base_path: String, level: String) -> bool:
	var path := base_path.path_join("TRAVERSE").path_join(level)

	# Define file paths
	var file_paths:Dictionary[String, String] = {
		"cmi": path.path_join(level + ".CMI"),
		"dti": path.path_join(level + ".DTI"),
		"o_mto": path.path_join(level + "O.MTO"),
		"o_sni": path.path_join(level + "O.SNI"),
		"s_mti": path.path_join(level + "S.MTI"),
		"s_sni": path.path_join(level + "S.SNI"),

		"bni": base_path.path_join("TRAVERSE").path_join("TRAVSPRT.BNI")
	}
	
	#var pathh = base_path.path_join("TRAVERSE").path_join("TRAVSPRT.BNI");
	#load_file(pathh, BNIFile, [null], 0)

	var results = start_load_thread(file_paths);
	
	# Assign results to class variables
	cmi = results.pop_front()
	dti = results.pop_front()
	o_mto = results.pop_front()
	o_sni = results.pop_front()
	s_mti = results.pop_front()
	s_sni = results.pop_front()
	traverse_bni = results.pop_front()

	return true

func start_load_thread(file_paths:Dictionary[String, String]) -> Array[Object]:
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
		thread.start(load_file.bind(file_paths[key], data_types[key], results, i))
		i=i+1
	
	# Wait for all threads to complete
	for key in len(threads):
		var thread: Thread = threads[key]
		thread.wait_to_finish()

	return results

func load_file(path: String, data_type: GDScript, results: Array[Object], result_key: int) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var buffer := file.get_buffer(file.get_length())
	var byteBuffer = ByteBuffer.new(buffer)
	
	var data = data_type.new()
	data.read(byteBuffer)
	file.close()
	
	print("loaded " + path)
	results[result_key] = data
