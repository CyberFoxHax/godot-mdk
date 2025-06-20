class_name CutContent

func _init(mdict:Dictionary[String, bool]) -> void:
    dict = mdict

var dict:Dictionary[String, bool]

static func is_cut(level:MDKFiles.Levels, name:String) -> bool:
    return cut_content[level].dict.get(name) == true

static var cut_content:Dictionary[MDKFiles.Levels, CutContent] = {
	MDKFiles.Levels.LEVEL3: CutContent.new({
		"HMO_3":true,
		"HMO_7":true,
		"CHMO_3":true,
		"CHMO_7":true
	}),
	MDKFiles.Levels.LEVEL4: CutContent.new({
		"MEAT_2":true,
		"MEAT_9":true,
		"CMEAT_2":true,
		"CMEAT_9":true,
	}),
	MDKFiles.Levels.LEVEL5: CutContent.new({
		"MUSE_6":true,
		"MUSE_7":true,
		"MUSE_8":true,
		"MUSE_9":true,
		"MUSE_10":true,
		"CMUSE_5":true,
		"CMUSE_6":true,
		"CMUSE_7":true,
		"CMUSE_8":true,
		"CMUSE_9":true
	}),
	MDKFiles.Levels.LEVEL6: CutContent.new({
		"OLYM_9":true,
		"COLYM_9":true
	}),
	MDKFiles.Levels.LEVEL7: CutContent.new({
		"DANT_8": true,
		"CDANT_8": true
	}),
	MDKFiles.Levels.LEVEL8: CutContent.new({
		"GUNT_9": true,
		"CGUNT_8": true
	})
}