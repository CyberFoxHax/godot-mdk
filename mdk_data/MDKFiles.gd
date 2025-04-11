class_name MDKFiles

var fti: FTIFile
var cmi: CMIFile
var dti: DTIFile
var o_mto: MTOFile
var o_sni: SNIFile
var s_mti: MTIFile
var s_sni: SNIFile

func load_level(base_path: String, level: String) -> void:
	var path := base_path.path_join("TRAVERSE").path_join(level)
	
	# Define file paths
	var file_paths := {
		"fti": base_path.path_join("MISC").path_join("mdkfont.fti"),
		"cmi": path.path_join(level + ".CMI"),
		"dti": path.path_join(level + ".DTI"),
		"o_mto": path.path_join(level + "O.MTO"),
		"o_sni": path.path_join(level + "O.SNI"),
		"s_mti": path.path_join(level + "S.MTI"),
		"s_sni": path.path_join(level + "S.SNI")
	}
	
	# Define data types for each file
	var data_types := {
		"fti": FTIFile,
		"cmi": CMIFile,
		"dti": DTIFile,
		"o_mto": MTOFile,
		"o_sni": SNIFile,
		"s_mti": MTIFile,
		"s_sni": SNIFile
	}
	
	# Dictionary to store threads and their results
	var threads := {}
	var results := {}
	
	# Start a thread for each file
	for key in file_paths:
		var thread := Thread.new()
		threads[key] = thread
		thread.start(load_file.bind(file_paths[key], data_types[key], results, key))
	
	# Wait for all threads to complete
	for key in threads:
		var thread: Thread = threads[key]
		thread.wait_to_finish()
	
	# Assign results to class variables
	fti = results["fti"]
	cmi = results["cmi"]
	dti = results["dti"]
	o_mto = results["o_mto"]
	o_sni = results["o_sni"]
	s_mti = results["s_mti"]
	s_sni = results["s_sni"]

func load_file(path: String, data_type: GDScript, results: Dictionary, result_key: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var buffer := file.get_buffer(file.get_length())
	var byteBuffer = ByteBuffer.new(buffer)
	
	var data = data_type.new()
	data.read(byteBuffer)
	file.close()
	
	print("loaded " + path)
	results[result_key] = data