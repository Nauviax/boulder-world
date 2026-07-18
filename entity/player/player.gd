extends CharacterBody2D
class_name Player

signal player_died

@onready var body: Node2D = $Body # Anything that rotates with the character
@onready var animation: AnimatedSprite2D = body.get_node("AnimatedSprite2D")
@onready var interaction: Area2D = body.get_node("InteractionArea")
@onready var holdingNode: Node2D = body.get_node("HoldingNode")
@onready var pickupNode: Node2D = holdingNode.get_node("PickupOffset")
@onready var above_effect_spawner: EffectSpawner = $AboveEffectSpawner
@onready var back_effect_spawner: EffectSpawner = body.get_node("BackEffectSpawner")

# Player movement consts
const MAX_SPEED := 1024 # Max speed assuming no FRICTION.
const ACCELERATION := 0.1 # % of remaining speed added each tick. (Remaining being max - current)
const FRICTION := 0.15 # % of speed lost each tick (60tps)
const FASTMODE_MULT = 1.5 # Speed and throw mult during fastmode
const BASE_STUN_DURATION := 1.0 # Base stun duration. Player doesn't take damage, so this is only for stun-specific effects.

# Player throwing consts
const THROW_DISTANCE := 500.0 # Pixels
const THROW_SPEED := 450.0 # Pixels per second
const THROW_DAMAGE_MODIFIER = 0.5 # Player throw stats are worse than a turret
const THROW_RADIUS_MODIFIER = 0.75

# Player misc consts
const HEALTH := 10 # Player "health". Player dies whenever it takes more than this amount of damage, otherwise it is ignored

# Player state
var control_enabled := false # Whether the player currently responds to input
var fastmode := false # !!! TEMP, controls "prepare" movement
var held_item: Interactable = null
var last_dir_input := Vector2.ZERO # Used for throwing direction

# Connect internal signals
func _ready():
	animation.frame_changed.connect(_on_animation_frame_changed)

# Player movement
func _physics_process(_delta: float):
	# Keyboard input
	var input_dir: Vector2 = Vector2.ZERO
	if control_enabled: # Only respond to input if player is in control
		if Input.is_action_pressed("move_up"):
			input_dir.y -= 1
		if Input.is_action_pressed("move_down"):
			input_dir.y += 1
		if Input.is_action_pressed("move_left"):
			input_dir.x -= 1
		if Input.is_action_pressed("move_right"):
			input_dir.x += 1

	# Misc calculations
	var speed_mult = FASTMODE_MULT if fastmode else 1.0
	last_dir_input = input_dir.normalized()

	# Apply FRICTION to current velocity (Regardless of input)
	velocity = lerp(velocity, Vector2.ZERO, FRICTION)
	# Lerp towards input direction, and face that direction
	if input_dir != Vector2.ZERO:
		velocity = lerp(velocity, last_dir_input * MAX_SPEED * speed_mult, ACCELERATION)
		body.rotation = velocity.angle() # Only rotate if movement input exists

	# Update animation based on player state
	animation.speed_scale = speed_mult
	if held_item or (animation.animation == "drop" and animation.is_playing()):
		pass # Do not animate walking while holding an item (Or still dropping it)
	else:
		if input_dir == Vector2.ZERO:
			if animation.animation != "idle":
				animation.play("idle")
		else:
			if animation.animation != "walk":
				animation.play("walk")

	# Finish movement
	move_and_slide()

# Player input controls (non-movement)
func _input(event: InputEvent):
	if not control_enabled:
		return # Ignore input if player is not in control
	if event.is_action_pressed("interact"): # Space
		if held_item:
			# Throw held item if moving. Drop held item if stationary
			if last_dir_input != Vector2.ZERO:
				throw()
			else:
				drop()
		else:
			# Check for items in reach
			var bodies: Array = interaction.get_overlapping_bodies()
			if bodies.size() > 0:
				pickup(bodies[0]) # May not be closest. (This is fine)

	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			fastmode = !fastmode # !!! THIS IS TEMPORARY

# Pick up an item
func pickup(item: Interactable):
	if !held_item:
		held_item = item
		animation.play("hold")
		held_item.pickup(holdingNode, pickupNode.position)

# Drop held item
func drop():
	if held_item:
		animation.play("drop")
		held_item.drop(pickupNode.global_position)
		held_item = null

# Throw held item in direction of last movement input
func throw():
	if held_item:
		animation.play("drop")
		var speed_mult = FASTMODE_MULT if fastmode else 1.0
		held_item.throw(position + last_dir_input * THROW_DISTANCE * speed_mult, THROW_SPEED * speed_mult, self)
		held_item = null

# Handle specific effects based on animation frames
func _on_animation_frame_changed():
	if animation.animation == "hold" and animation.frame == 1:
		if held_item:
			held_item.position = Vector2.ZERO # Center held item at end of animation

# ===== #

# On damage, die if damage exceeds health const. Otherwise just apply stun as needed.
func apply_damage(damage: int, extra_stun: float = 0.0):
	if damage >= HEALTH:
		drop() # Drop held item, if any
		control_enabled = false
		player_died.emit()
	elif extra_stun > 0.0:
		# Simple stun, don't bother with accounting for multiple hits.
		control_enabled = false
		await get_tree().create_timer(extra_stun * BASE_STUN_DURATION).timeout
		control_enabled = true
