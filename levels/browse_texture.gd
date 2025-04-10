extends Control


@onready var list:ItemList = $ItemList


# Called when the node enters the scene tree for the first time.
func _ready():
	for key in MDKData.image_textures:
		list.add_item(key, MDKData.image_textures[key])
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
