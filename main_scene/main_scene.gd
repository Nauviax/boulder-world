extends Node2D

@export var boulder_scene: PackedScene

func _ready() -> void:
	# Testing boulders, this is temporary code. (!!!)
	var center := Vector2(100, 540)
	var spacing := 128.0

	var types := [
		Boulder.Type.BASIC,
		Boulder.Type.RED,
		Boulder.Type.GREEN,
		Boulder.Type.BLUE,
		Boulder.Type.YELLOW,
	]

	var start_y := center.y - ((types.size() - 1) * spacing) * 0.5

	for ii in types.size():
		var boulder := boulder_scene.instantiate() as Boulder
		boulder.type = types[ii]
		boulder.position = Vector2(center.x, start_y + ii * spacing)
		add_child(boulder)
