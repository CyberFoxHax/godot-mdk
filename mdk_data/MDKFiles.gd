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
	
	var fontfti := base_path.path_join("MISC").path_join("mdkfont.fti")
	var levelcmi := path.path_join(level + ".CMI")
	var leveldti := path.path_join(level + ".DTI")
	var levelmto := path.path_join(level + "O.MTO")
	var levelosni := path.path_join(level + "O.SNI")
	var levelsmti := path.path_join(level + "S.MTI")
	var levelssni := path.path_join(level + "S.SNI")
	
	fti = load_file(fontfti, FTIFile)
	cmi = load_file(levelcmi, CMIFile)
	dti = load_file(leveldti, DTIFile)
	o_mto = load_file(levelmto, MTOFile)
	o_sni = load_file(levelosni, SNIFile)
	s_mti = load_file(levelsmti, MTIFile)
	s_sni = load_file(levelssni, SNIFile)

func load_file(path: String, data_type: GDScript) -> Variant:
	var file :FileAccess= FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: %s" % path)
		return null
	
	var buffer := file.get_buffer(file.get_length())
	var byteBuffer = ByteBuffer.new(buffer)

	var data = data_type.new()
	data.read(byteBuffer)
	file.close()
	return data
