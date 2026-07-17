extends CharacterBody2D
class_name Enemy

signal enemy_died(enemy: Enemy)

@onready var body: Node2D = $Body # Anything that rotates with the character
@onready var animation: AnimatedSprite2D = body.get_node("AnimatedSprite2D")
@onready var above_effect_spawner: EffectSpawner = $AboveEffectSpawner
@onready var screen_size := get_viewport_rect().size # To avoid being pushed offscreen

const RALLY_X_POS = 1550; # X coord that enemies try to rally at (!!! MAX TEST OVERCROUDING TOO)
const RALLY_X_VARIANCE = 25; # Allow some enemies to move forwards more. Also acts as tolerance.

# Base enemy variables; can be overridden by archetype
var base_speed: float = 40.0 # Base speed of the enemy
var rally_speed_mult: float = 2 # Multiplier to base speed when rallying
var aggro_speed_mult: float = 2.5 # Multiplier to base speed when aggro-ed on the player
var base_health: int = 100 # Max health, not current health
var avoidance_speed: float = 20.0 # Speed to move away from other bodies when too close
var max_stun_duration: float = 2.0 # Max duration of stun, if taking 100% damage in one hit. (Ignoring the fact this would kill)

# Enemy state (common to all enemies)
enum EnemyState { JUSTSPAWNED, RALLYING, CHARGING, AGGRO, STUNNED, DOOMED, DEAD } # !!! Investigate state machine nodes?
var state: EnemyState = EnemyState.JUSTSPAWNED # Note that JUSTSPAWNED has no behaviour.
var desired_state: EnemyState = EnemyState.JUSTSPAWNED # State to return to when losing sight of player or clearing stun
var rally_pos := RALLY_X_POS
var aggro_target: Node2D = null # Player to aggro, if any
var health: int = base_health # Current health, starts at max
var too_close_bodies: Array[Node2D] = [] # Bodies that are too close to this enemy, for collision avoidance

# Move towards rally point and wait
func startRally():
	rally_pos = RALLY_X_POS + randi_range(-RALLY_X_VARIANCE, RALLY_X_VARIANCE)
	if state == EnemyState.JUSTSPAWNED:
		state = EnemyState.RALLYING
	desired_state = EnemyState.RALLYING

# Charge towards castle
func startCharge():
	if state == EnemyState.RALLYING: # Don't start charging if stunned/aggroed etc
		state = EnemyState.CHARGING
	desired_state = EnemyState.CHARGING

# Aggro on the player
func startAggro(target: Node2D):
	if state == EnemyState.RALLYING or state == EnemyState.CHARGING:
		state = EnemyState.AGGRO # Can only enter aggro state when able to move
	aggro_target = target

# Stop aggro on the player, return to desired state
func stopAggro():
	if state == EnemyState.AGGRO:
		state = desired_state
	aggro_target = null # Clear target even if currently stunned etc.

# Stun the enemy for the given duration, often due to taking damage.
func stun(duration: float):
	state = EnemyState.STUNNED
	animation.play("hide")
	await get_tree().create_timer(duration).timeout
	state = EnemyState.AGGRO if aggro_target != null else desired_state # Potentially resume aggro
	animation.play("idle") # !!! It may be better to seperate state and animation state from this node? !!!

# Doom this enemy. Enemy will stop moving until it is dead
func doom():
	state = EnemyState.DOOMED
	animation.play("hide")
	# !!! TODO show a temporary alert sprite !!!

# Take damage, and die if health reaches 0
func apply_damage(damage: float):
	var stun_duration = (damage / base_health) * max_stun_duration
	health -= int(damage)
	if health <= 0:
		emit_signal("enemy_died", self)
		queue_free() # Remove enemy from scene. (!!! THIS IS TEMP BEFORE I GET SIGNALS WORKING)
	else: # Simply freeze enemy for short duration if not dead
		stun(stun_duration)

# ===== #

# On tick logic for each state
func _physics_process(_delta: float) -> void:
	match state:
		EnemyState.RALLYING:
			rally_tick()
		EnemyState.CHARGING:
			charge_tick()
		EnemyState.AGGRO:
			aggro_tick()

# Base logic for rallying (Can be overridden by archetype)
func rally_tick():
	var x_velocity: float = 0
	if position.x > rally_pos + RALLY_X_VARIANCE: # Tolerance for jittering at rally point
		x_velocity = -base_speed * rally_speed_mult
		body.rotation = PI # Left
	elif position.x < rally_pos - RALLY_X_VARIANCE:
		x_velocity = base_speed * rally_speed_mult
		body.rotation = 0 # Right
	else:
		body.rotation = PI # Left
	update_velocity(Vector2(x_velocity, 0))
	move_and_slide()

# Base logic for charging (Can be overridden by archetype)
func charge_tick():
	body.rotation = PI # Face direction of movement (Pre-slide and avoidance)
	update_velocity(Vector2(-base_speed, 0))
	move_and_slide()

# Base logic for aggro (Can be overridden by archetype)
func aggro_tick():
	if aggro_target:
		var direction = (aggro_target.position - position).normalized()
		body.rotation = direction.angle() # Face direction of movement (Pre-slide and avoidance)
		update_velocity(direction * base_speed * aggro_speed_mult)
		move_and_slide()

# ===== #

# Helper functions for movement
func update_velocity(desired_velocity: Vector2):
	if state == EnemyState.RALLYING or too_close_bodies.size() == 0:
		velocity = desired_velocity # Don't bother spacing out when rallying, or when nothing nearby
	else:
		var avoidance_vector = Vector2.ZERO
		for too_close_body in too_close_bodies:
			var direction = (position - too_close_body.position).normalized()
			avoidance_vector += direction
		avoidance_vector = avoidance_vector.normalized()
		# Enemies can not be "boosted" forwards by other enemies, only slowed down
		if avoidance_vector.x < 0:
			avoidance_vector.x = 0
		# Enemies can not be pushed offscreen vertically. Instead, push away from edge
		if position.y < 10 and avoidance_vector.y < 0:
			avoidance_vector.y = avoidance_speed / 2
		elif position.y > screen_size.y - 10 and avoidance_vector.y > 0:
			avoidance_vector.y = -avoidance_speed / 2
		velocity = desired_velocity + avoidance_vector * avoidance_speed