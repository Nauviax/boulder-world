extends Node2D
class_name LevelScene

@export var player_scene: PackedScene
@export var boulder_scene: PackedScene
@export var enemy_basic_scene: PackedScene
@export var enemy_cart_scene: PackedScene

@onready var effect_spawner: EffectSpawner = $EffectSpawner

# Initial spawns of various items
const PLAYER_SPAWN_POS := Vector2(200, 540)
const INIT_BOULDER_POS := Vector2(100, 540)

# References to game entities, for convenience
var player: Player
var boulders: Array[Boulder] = []
var enemies: Array[Enemy] = []

# !!! Debugging, game should not do things on ready for now.
func _ready() -> void:
	# Testing boulders, this is temporary code. (!!!)
	var center := Vector2(50, 540)
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

# Prepare game, cleaning up old entities, resetting scores, and spawning initial entities.
func prepare_game():
	player = player_scene.instantiate()
	player.position = PLAYER_SPAWN_POS
	add_child(player)
	var boulder := boulder_scene.instantiate()
	boulder.position = INIT_BOULDER_POS
	add_child(boulder)
	boulders.append(boulder)
	# !!! TODO spawn initial wave and have them rally

# Start game, enabling player control and (!!!) enemies + wave logic
func start_game():
	player.control_enabled = true
	# !!! TODO start the rallying wave, show initial wave title, and kick off game loop
	
