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
const ENEMY_SPAWN_POS := Vector2(1900, 540)
const ENEMY_SPAWN_Y_VARIANCE := 300

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
		spawn_boulder(Vector2(center.x, start_y + ii * spacing), types[ii])

# Prepare game, cleaning up old entities, resetting scores, and spawning initial entities.
func prepare_game():
	spawn_player(false) # Spawn player, but do not give control yet
	spawn_boulder()
	# !!! TODO spawn initial wave and have them rally
	
	# !!! TEMP (First wave should be spawned by wave logic, not here. Prepare should still rally the first wave.)
	spawn_enemy_basic(EnemyBasic.EnemyType.BASIC)
	for ii in range(10):
		spawn_enemy_basic(EnemyBasic.EnemyType.FAST)
	for enemy in enemies:
		enemy.startRally()

# Start game, enabling player control and (!!!) enemies + wave logic
func start_game():
	player.control_enabled = true
	
	# !!! TODO start the rallying wave, show initial wave title, and kick off game loop
	# !!! In place of wave logic, just wait a few seconds then send off initial wave. (First wave is pre-spawned for menu)
	await get_tree().create_timer(10.0).timeout
	for enemy in enemies:
		enemy.startCharge()
	
# Spawning methods
func spawn_player(has_control: bool = false):
	if !player: # Player is not deleted, so only spawn if null
		player = player_scene.instantiate() as Player
		player.player_died.connect(_on_player_died)
	player.position = PLAYER_SPAWN_POS
	player.control_enabled = has_control
	add_child(player)

func spawn_boulder(spawn_pos: Vector2 = INIT_BOULDER_POS, spawn_type: Boulder.Type = Boulder.Type.BASIC):
	var boulder := boulder_scene.instantiate() as Boulder
	boulder.position = spawn_pos
	boulder.type = spawn_type
	add_child(boulder)
	boulders.append(boulder)

func spawn_enemy_basic(type: EnemyBasic.EnemyType):
	var enemy := enemy_basic_scene.instantiate() as EnemyBasic
	enemy.position = ENEMY_SPAWN_POS + Vector2(randi_range(-5, 5), randi_range(-ENEMY_SPAWN_Y_VARIANCE, ENEMY_SPAWN_Y_VARIANCE))
	enemy.enemy_type = type
	enemy.enemy_died.connect(_on_enemy_died)
	add_child(enemy)
	enemies.append(enemy)

# Handle signals from entities
func _on_enemy_died(enemy: Enemy) -> void:
	enemies.erase(enemy)
	if enemies.size() == 0:
		# !!! TODO wave logic, spawn next wave
		pass

func _on_player_died() -> void:
	remove_child(player) # Do not delete player, it may still be referenced
	# !!! TODO lives logic. For now just respawn player after a second.
	await get_tree().create_timer(1.0).timeout
	spawn_player(true)
