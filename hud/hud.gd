# Copyright © 2021 Hugo Locurcio and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
extends Control

@onready var vitals: TextureRect = $Vitals
@onready var people_dead: TextureProgressBar = $Vitals/PeopleDead

func _ready() -> void:
	#vitals.texture = MDKData.image_textures["SC_STAT"]
	#people_dead.texture_progress = MDKData.image_textures["SC_BSTAT"]
	pass
	

func _process(delta: float) -> void:
	# Placeholder to see the progress bar being effective.
	$Vitals/PeopleDead.value += delta * 0.15
