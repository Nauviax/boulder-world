extends Node2D
class_name LevelScene

signal set_background_music(music: AudioStream)
signal game_over # !!! NYI, show game over menu

# Scene references for spawning
@export var player_scene: PackedScene
@export var boulder_scene: PackedScene
@export var explosion_scene: PackedScene
@export var coin_scene: PackedScene
@export var enemy_basic_scene: PackedScene
@export var enemy_cart_scene: PackedScene

# Music references for playing audio
@export var castle_song: AudioStream
@export var battle_song: AudioStream
@export var death_song: AudioStream

@onready var effect_spawner: EffectSpawner = $EffectSpawner

# Initial spawns of various items
const PLAYER_SPAWN_POS := Vector2(200, 540)
const PLAYER_RESPAWN_DELAY := 1.0 # Delay in seconds before respawning player after death
const INIT_BOULDER_POS := Vector2(100, 540)
const ENEMY_SPAWN_POS := Vector2(1900, 540)
const ENEMY_SPAWN_Y_VARIANCE := 300

# Coin spawning consts
const COIN_GUARANTEED_COUNT = 3 # Coins are guaranteed to drop if there are less than this many coins on the map.
const COIN_SPAWN_PENALTY = 0.2 # Each coin on map past guaranteed count reduces chance of further coins by this much. (Additive)

# Game initial state consts
const INITIAL_LIVES = 3 # Number of lives the player starts with. Lost when player or castle takes damage.

# References to game entities, for convenience
var player: Player
var boulders: Array[Boulder] = []
var enemies: Array[Enemy] = []
var coins: Array[Coin] = []

# Game state
var lives_left: int = -1 # Number of lives the player has left
var coin_count: int = -1 # Number of coins collected by the player

# Prepare game, cleaning up old entities, resetting scores, and spawning initial entities.
func prepare_game():
	set_background_music.emit(castle_song)
	# Reset game state
	lives_left = INITIAL_LIVES
	coin_count = 0
	if player: # !!! This cleanup may not be needed, I may just remove the whole level node and re-create it !!!
		player.queue_free()
		player = null
	for boulder in boulders:
		boulder.queue_free()
	boulders.clear()
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	for coin in coins:
		coin.queue_free()
	coins.clear()
	# Initial spawns
	spawn_player(false) # Spawn player, but do not give control yet
	spawn_boulder()

	# !!! Testing boulders, this is temporary code. (!!!)
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

	# !!! TODO spawn initial wave and have them rally
	
	# !!! TEMP (First wave should be spawned by wave logic, not here. Prepare should still rally the first wave.)
	spawn_enemy_basic(EnemyBasic.EnemyType.BASIC)
	for ii in range(10):
		spawn_enemy_basic(EnemyBasic.EnemyType.FAST)
	for enemy in enemies:
		enemy.startRally()

# Start game, enabling player control and (!!!) enemies + wave logic
func start_game():
	set_background_music.emit(battle_song)
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
	boulder.create_explosion.connect(create_explosion)
	add_child(boulder)
	boulders.append(boulder)

# Coin spawning is based on current map coin count. More coins means less spawning in.
func spawn_coin(spawn_pos: Vector2, guaranteed: bool):
	var effective_coin_count: int = coins.size() - COIN_GUARANTEED_COUNT + 1 # +1 because this coin is not yet added to the list
	if not guaranteed and effective_coin_count > 0:
		# Chance to not spawn a coin
		var spawn_chance := 1.0 - effective_coin_count * COIN_SPAWN_PENALTY
		if randf() > spawn_chance:
			return # Do not spawn a coin
	var coin := coin_scene.instantiate() as Coin
	coin.position = spawn_pos
	coin.coin_collected.connect(_on_coin_collected)
	add_child(coin)
	coins.append(coin)

func spawn_enemy_basic(type: EnemyBasic.EnemyType):
	var enemy := enemy_basic_scene.instantiate() as EnemyBasic
	enemy.position = ENEMY_SPAWN_POS + Vector2(randi_range(-5, 5), randi_range(-ENEMY_SPAWN_Y_VARIANCE, ENEMY_SPAWN_Y_VARIANCE))
	enemy.enemy_type = type
	enemy.enemy_died.connect(_on_enemy_died)
	enemy.create_explosion.connect(create_explosion)
	add_child(enemy)
	enemies.append(enemy)

func spawn_enemy_cart():
	pass # NYI

# ===== Signals ===== #

# Create an explosion (Note that this is a SIGNAL response, and not spawned in at level's will)
func create_explosion(explosion_position: Vector2, explosion_damage: float = -1, explosion_radius: float = -1, explosion_extra_stun: float = -1):
	var explosion := explosion_scene.instantiate() as Explosion
	explosion.position = explosion_position
	if explosion_damage >= 0:
		explosion.explosion_damage = explosion_damage
	if explosion_radius >= 0:
		explosion.explosion_radius = explosion_radius
	if explosion_extra_stun >= 0:
		explosion.explosion_extra_stun = explosion_extra_stun
	add_child(explosion)

# Handle enemy death
func _on_enemy_died(enemy: Enemy):
	enemy.queue_free() # Remove enemy from scene
	enemies.erase(enemy)
	spawn_coin(enemy.position, false) # Chance to spawn a coin at the enemy's death position
	if enemies.size() == 0:
		# !!! TODO wave logic, spawn next wave
		pass

# Handle player death
func _on_player_died():
	remove_child(player) # Do not delete player, it may still be referenced
	lives_left -= 1
	if lives_left <= 0: # Game over, show game over screen and reset game
		# !!! TODO game over logic
		set_background_music.emit(death_song)
		game_over.emit() # Show game over menu
	else: # Respawn player after a delay
		await get_tree().create_timer(PLAYER_RESPAWN_DELAY).timeout
		spawn_player(true)

# Handle coin collection
func _on_coin_collected(coin: Coin):
	coin.queue_free() # Remove coin from scene
	coins.erase(coin)
