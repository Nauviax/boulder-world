extends CharacterBody2D
class_name Enemy

@onready var body: Node2D = $Body # Anything that rotates with the character
@onready var animation: AnimatedSprite2D = body.get_node("AnimatedSprite2D")
@onready var above_effect_spawner: EffectSpawner = $AboveEffectSpawner

const RALLY_X_POS = 1550; # X coord that enemies try to rally at (!!! MAX TEST OVERCROUDING TOO)

# Base enemy variables; can be overridden by archetype
var base_speed: float = 40.0 # Base speed of the enemy
var chasing_speed_mult: float = 3 # Multiplier to base speed when chasing player
var base_health: int = 100 # Max health, not current health

# Enemy state (common to all enemies)
enum EnemyState { JUSTSPAWNED, RALLYING, CHARGING, CHASING, HIDING, DEAD } # !!! Investigate state machine nodes?
var state: EnemyState = EnemyState.JUSTSPAWNED # Note that JUSTSPAWNED has no behaviour.
var desired_state: EnemyState = EnemyState.JUSTSPAWNED # State to return to when losing sight of player
var chase_target: Node2D = null # Player to chase, if any
var health: int = base_health # Current health, starts at max

# Move towards rally point and wait
func startRally():
	if state == EnemyState.JUSTSPAWNED:
		state = EnemyState.RALLYING
	desired_state = EnemyState.RALLYING

# Charge towards castle
func startCharge():
	if state == EnemyState.RALLYING:
		state = EnemyState.CHARGING
	desired_state = EnemyState.CHARGING

# Start chasing the player
func startChase(target: Node2D):
	state = EnemyState.CHASING
	chase_target = target

# Stop chasing the player, return to desired state
func stopChase():
	state = desired_state
	chase_target = null

# Start hiding, often due to imminent death
func startHide():
	state = EnemyState.HIDING
	animation.play("hide")

# On tick logic for each state
func _physics_process(_delta: float) -> void:
	match state:
		EnemyState.RALLYING:
			rally_tick()
		EnemyState.CHARGING:
			charge_tick()
		EnemyState.CHASING:
			chase_tick()

# Base logic for rallying (Can be overridden by archetype)
func rally_tick():
	body.rotation = 180 # Face left
	velocity = Vector2(-base_speed, 0)
	body.rotation = 180 # Face left
	move_and_slide()

# Base logic for charging (Can be overridden by archetype)
func charge_tick():
	velocity = Vector2(-base_speed * chasing_speed_mult, 0)
	body.rotation = 180 # Face left
	move_and_slide()

# Base logic for chasing (Can be overridden by archetype)
func chase_tick():
	if chase_target:
		var direction = (chase_target.position - position).normalized()
		velocity = direction * base_speed * chasing_speed_mult
		body.rotation = velocity.angle() # Face direction of movement (Pre-slide)
		move_and_slide()