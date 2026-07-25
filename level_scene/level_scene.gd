extends Node2D
class_name LevelScene

# Signals for communicating with main scene and UI elements
signal set_background_music(music: AudioStream)
signal game_over
signal second_changed(minutes: int, seconds: int, game_seconds: int)
signal coin_count_changed(new_count: int)

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
@onready var next_sub_wave_timer: Timer = $SubWaveTimer # Timer for the current sub-wave. Can be stopped early if all existing enemies are defeated.

# Initial spawns of various items (Assumes level is 1920x1080)
const PLAYER_SPAWN_POS := Vector2(200, 540)
const PLAYER_RESPAWN_DELAY := 1.0 # Delay in seconds before respawning player after death
const INIT_BOULDER_POS := Vector2(100, 540)
const ENEMY_SPAWN_POS := Vector2(1900, 540)
const ENEMY_SPAWN_Y_VARIANCE := 350
const LEVEL_CENTER := Vector2(960, 540) # Used for text mostly

# Wave timing consts
const ENEMY_RALLY_DURATION := 5.0 # Time in seconds that enemies will rally before charging the player
const SUB_WAVE_DURATION := 5.0 # Time in seconds between a sub-wave charging and the next sub-wave rallying.
const WAVE_PREP_DURATION := 15.0 # Time in seconds between beating a wave and the next wave starting

# Coin spawning consts
const COIN_GUARANTEED_COUNT = 3 # Coins are guaranteed to drop if there are less than this many coins on the map.
const COIN_SPAWN_PENALTY = 0.2 # Each coin on map past guaranteed count reduces chance of further coins by this much. (Additive)

# Game initial state consts
const INITIAL_LIVES = 3 # Number of lives the player starts with. Lost when player or castle takes damage.

# References to game entities, for convenience (Part of game state technically)
var player: Player
var boulders: Array[Boulder] = []
var enemies: Array[Enemy] = []
var coins: Array[Coin] = []

# Game state
var lives_left: int = -1 # Number of lives the player has left
var coin_count: int = -1 # Number of coins collected by the player
var current_wave: int = 0 # Current wave number, starting at 1. 0 implies no wave is active
var current_sub_wave: int = 0 # Current sub-wave number, starting at 0
var current_wave_sub_wave_count: int = 0 # Number of sub-waves in the current wave
var current_wave_spawn_defs: Array[Enemy.SpawnDef] = [] # Spawn defs for the current wave

# Time tracking
var game_active: bool = false # True when the game is active, false when in menu or game over
var game_time: float = 0.0
var last_reported_second: int = -1 # Updates timers each second

# Advance game time and emit signal each second
func _process(delta: float) -> void:
	if game_active:
		game_time += delta
		var sec := int(game_time)
		if sec != last_reported_second:
			last_reported_second = sec
			second_changed.emit(int(sec / 60.0), sec % 60, sec)

# Prepare game, cleaning up old entities, resetting scores, and manually rallying the initial wave.
func prepare_game():
	set_background_music.emit(castle_song)
	# Reset game state (!!! This cleanup may not be needed, I may just remove the whole level node and re-create it !!!)
	lives_left = INITIAL_LIVES
	coin_count = 0
	coin_count_changed.emit(coin_count)
	game_active = false
	game_time = 0.0
	last_reported_second = 0
	second_changed.emit(0, 0, 0)
	if player:
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
	# Wave initialization
	set_wave(1) # We manually rally the first wave, so it can be seen while in menu
	rally_sub_wave(false) # Will not auto-charge the first wave (Player has no control yet)
	# Timer for triggering sub-waves. (!!! Max do I just make this a node?)
	next_sub_wave_timer.wait_time = SUB_WAVE_DURATION
	next_sub_wave_timer.timeout.connect(rally_sub_wave) # Connecting in code, seems less fragile than editor. !!! ERRORS, but ehh may remove, see above note on cleanup
	next_sub_wave_timer.stop() # Do not start timer yet (Redundant line, but ehhh)

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

# Start game, enabling player control, displaying first wave text, and manually charging the first wave.
func start_game():
	set_background_music.emit(battle_song)
	player.control_enabled = true
	game_active = true
	show_wave_start_text() # Show wave text, as it wasn't shown during prepare_game() due to auto_charge == false.
	call_deferred("charge_sub_wave_async") # Manually charge the enemies after a delay. Deferred to avoid blocking this function.
	
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

# Spawn enemies based on a spawnDef and current sub-wave
func spawn_enemies(spawnDef: Enemy.SpawnDef, spawning_sub_wave: int):
	var enemy_scene: PackedScene = null
	match spawnDef.type:
		Enemy.Type.BASIC:
			enemy_scene = enemy_basic_scene
		Enemy.Type.CART:
			enemy_scene = enemy_cart_scene
	var enemy_count = spawnDef.counts[spawning_sub_wave]
	for ii in range(enemy_count):
		var enemy: Enemy = enemy_scene.instantiate()
		enemy.sub_type = spawnDef.sub_type
		enemy.position = ENEMY_SPAWN_POS + Vector2(randi_range(-5, 5), randi_range(-ENEMY_SPAWN_Y_VARIANCE, ENEMY_SPAWN_Y_VARIANCE))
		enemy.enemy_died.connect(_on_enemy_died)
		enemy.create_explosion.connect(create_explosion)
		add_child(enemy)
		enemies.append(enemy)

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
		all_enemies_dead() # All enemies defeated. Trigger next sub-wave early, or complete wave.

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
	effect_spawner.create_floating_text(FloatingText.Type.Small, "+1 Coin", coin.position) # Show floating text at coin position
	coin.queue_free() # Remove coin from scene
	coins.erase(coin)
	coin_count += 1
	coin_count_changed.emit(coin_count)

# ===== Wave logic ===== #

# Called on new wave starts, but also when player first gains control in start_game().
func show_wave_start_text():
	var plural := "" if current_wave_sub_wave_count == 1 else "s"
	effect_spawner.create_floating_text(FloatingText.Type.Large, "WAVE %d" % current_wave, LEVEL_CENTER + Vector2(0, -40))
	effect_spawner.create_floating_text(FloatingText.Type.SubLarge, "Contains %d sub-wave%s" % [current_wave_sub_wave_count, plural], LEVEL_CENTER)
	effect_spawner.create_floating_game_timer(second_changed, last_reported_second, LEVEL_CENTER + Vector2(0, 50))

# Called on wave completion.
func show_wave_completed_text():
	effect_spawner.create_floating_text(FloatingText.Type.Large, "WAVE COMPLETED", LEVEL_CENTER + Vector2(0, -90))
	effect_spawner.create_floating_text(FloatingText.Type.SubLarge, "Speed increased temporarily, prepare!", LEVEL_CENTER + Vector2(0, -50))
	effect_spawner.create_floating_countdown(second_changed, last_reported_second, int(WAVE_PREP_DURATION), LEVEL_CENTER + Vector2(0, 00))

# Start the next wave, preparing wave state as needed. Called on game start and when prep time ends.
# Should be called only when the previous wave is finished, and after prep time is over.
# This should NOT be called to start the first wave.
func start_next_wave(next_wave_number: int):
	set_wave(next_wave_number) # Enemies to spawn this wave
	show_wave_start_text() # Show new wave text after current state is updated
	rally_sub_wave() # Start the first sub-wave of the wave

# Spawn, rally, and charge the next sub-wave. Called when all enemies are defeated for the current sub-wave.
func rally_sub_wave(auto_charge: bool = true):
	current_sub_wave += 1
	if current_sub_wave >= current_wave_sub_wave_count:
		return # No more sub-waves to rally, do nothing.
	# Spawn enemies for the next sub-wave
	for spawnDef in current_wave_spawn_defs:
		spawn_enemies(spawnDef, current_sub_wave)
	# Rally new enemies
	for enemy in enemies:
		if enemy.desired_state == Enemy.State.JUSTSPAWNED:
			enemy.startRally()
	if auto_charge: # True in all cases aside from first wave spawn
		call_deferred("charge_sub_wave_async") # Deferred to avoid blocking rally_sub_wave()

# Charge the currently rallying enemies, after a delay. Called by rally_sub_wave, and also on game start if needed.
# Async, call with call_deferred() to avoid blocking the current function.
func charge_sub_wave_async():
	# Wait for rally duration, then charge enemies
	await get_tree().create_timer(ENEMY_RALLY_DURATION).timeout
	for enemy in enemies:
		if enemy.desired_state == Enemy.State.RALLYING:
			enemy.startCharge()
	# Start the timer for next sub-wave. If all enemies are defeated before the timer ends, the next sub-wave will start early.
	next_sub_wave_timer.start()

# Triggered on all enemies being defeated. If there are more sub-waves, start the next sub-wave. Otherwise, complete the wave.
func all_enemies_dead():
	next_sub_wave_timer.stop() # Stop the sub-wave timer; we either start next sub-wave early, or complete the wave.
	if current_sub_wave < current_wave_sub_wave_count - 1:
		rally_sub_wave() # Start next sub-wave
	else:
		call_deferred("wave_completed_async") # Complete the wave and prepare for the next one. Deferred to avoid blocking this function.

# Show wave completed, allow player to prepare, then trigger next wave.
# Async, call with call_deferred() to avoid blocking the current function.
func wave_completed_async():
	show_wave_completed_text()
	player.fastmode = true # Allow player to move faster during prep time
	await get_tree().create_timer(WAVE_PREP_DURATION).timeout # Wait for prep time to end
	player.fastmode = false
	start_next_wave(current_wave + 1) # Start the next wave

# Set next wave state, including enemy spawn defs.
func set_wave(wave_number: int):
	current_wave = wave_number
	current_sub_wave = -1
	current_wave_spawn_defs = get_wave(current_wave)
	current_wave_sub_wave_count = current_wave_spawn_defs[0].counts.size()

# Calculate the enemy spawn defs for a given wave number. Returns an array of SpawnDefs, one for each enemy type in the wave.
func get_wave(wave_number: int) -> Array[Enemy.SpawnDef]:
	# Note that wave 0 does not exist
	match wave_number:
		1:
			return [
				Enemy.SpawnDef.new(Enemy.Type.BASIC, Enemy.SubType.BASIC, [3]) # 3
			]
		2:
			return [
				Enemy.SpawnDef.new(Enemy.Type.BASIC, Enemy.SubType.BASIC, [5, 3]) # 8
			]
		3:
			return [ # Wave power: 13 + 10 = 23 | Infinite power: 24 * 2 = 48
				Enemy.SpawnDef.new(Enemy.Type.BASIC, Enemy.SubType.BASIC, [5, 5, 3]), # 13
				Enemy.SpawnDef.new(Enemy.Type.BASIC, Enemy.SubType.FAST, [2, 0, 2]) # 4
			]
		4:
			return [ # Wave power: 24 + 22.5 = 46.5 | Infinite power: 28 * 2 = 56
				Enemy.SpawnDef.new(Enemy.Type.BASIC, Enemy.SubType.BASIC, [7, 7, 5, 5]), # 24
				Enemy.SpawnDef.new(Enemy.Type.BASIC, Enemy.SubType.FAST, [3, 2, 2, 2]) # 9
			]
		5:
			return [ # Wave power: 28 + 25 + 20 = 73 | Infinite power: 32 * 3 = 96
				Enemy.SpawnDef.new(Enemy.Type.BASIC, Enemy.SubType.BASIC, [5, 7, 9, 7]), # 28
				Enemy.SpawnDef.new(Enemy.Type.BASIC, Enemy.SubType.FAST, [2, 2, 4, 2]), # 10
				Enemy.SpawnDef.new(Enemy.Type.CART, Enemy.SubType.BASIC, [1, 0, 0, 1]) # 2
			]
		_:
			# Infinite waves
			var sub_waves: int = 4 + int(wave_number / 4.0) # Add a sub-wave every 4 waves, starting at 5 on wave 6. (5.5 technically)
			var base_enemy_count: int = 12 + wave_number * 4 # +4 per wave, 36 on wave 6.
			return [
				Enemy.SpawnDef.new(Enemy.Type.BASIC, Enemy.SubType.BASIC, calc_sub_wave_counts(base_enemy_count, 1.0, sub_waves)),
				Enemy.SpawnDef.new(Enemy.Type.BASIC, Enemy.SubType.FAST, calc_sub_wave_counts(base_enemy_count, 0.4, sub_waves)),
				Enemy.SpawnDef.new(Enemy.Type.CART, Enemy.SubType.BASIC, calc_sub_wave_counts(base_enemy_count, 0.1, sub_waves))
			]

# Helper function for infinite waves, spreading enemy count across multiple sub-waves.
func calc_sub_wave_counts(base_enemy_count: int, enemy_weight: float, sub_waves: int) -> Array[int]:
	var enemy_count := int(base_enemy_count * enemy_weight) # Rounded down
	var sub_wave_counts: Array[int] = []
	sub_wave_counts.resize(sub_waves)
	sub_wave_counts.fill(0)
	for ii in range(enemy_count):
		# Assign each enemy to a random sub-wave
		var sub_wave := randi_range(0, sub_waves - 1)
		sub_wave_counts[sub_wave] += 1
	return sub_wave_counts
