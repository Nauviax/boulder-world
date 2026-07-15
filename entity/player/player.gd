extends CharacterBody2D
class_name Player

@onready var body: Node2D = $Body # Anything that rotates with the character
@onready var animation: AnimatedSprite2D = body.get_node("AnimatedSprite2D")
@onready var interaction: Area2D = body.get_node("InteractionArea")
@onready var holdingNode: Node2D = body.get_node("HoldingNode")
@onready var pickupNode: Node2D = holdingNode.get_node("PickupOffset")

# Player movement consts
const max_speed := 1024 # Max speed assuming no friction.
const acceleration := 0.1 # % of remaining speed added each tick. (Remaining being max - current)
const friction := 0.15 # % of speed lost each tick (60tps)
const fastmode_mult = 1.5 # Speed and throw mult during fastmode

# Player throwing consts
const throw_distance := 600 # Pixels
const throw_air_time := 1.0 # Seconds
const throw_speed := throw_distance / throw_air_time

# Player state
var fastmode := false # !!! TEMP, controls "prepare" movement
var held_item: Interactable = null
var last_dir_input := Vector2.ZERO # Used for throwing direction

# Connect internal signals
func _ready() -> void:
	animation.frame_changed.connect(_on_animation_frame_changed)

# Player movement
func _physics_process(_delta: float) -> void:
	# Keyboard input
	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	# Misc calculations
	var speed_mult = fastmode_mult if fastmode else 1.0
	last_dir_input = input_dir.normalized()

	# Apply friction to current velocity (Regardless of input)
	velocity = lerp(velocity, Vector2.ZERO, friction)
	# Lerp towards input direction, and face that direction
	if input_dir != Vector2.ZERO:
		velocity = lerp(velocity, last_dir_input * max_speed * speed_mult, acceleration)
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
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"): # Space
		if held_item:
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

# Throw held item if moving. Drop held item if stationary
func drop():
	if held_item:
		animation.play("drop")
		if last_dir_input != Vector2.ZERO:
			var speed_mult = fastmode_mult if fastmode else 1.0
			held_item.throw(position + last_dir_input * throw_distance * speed_mult, throw_speed * speed_mult)
		else:
			held_item.drop(pickupNode.global_position)
		held_item = null

# Handle specific effects based on animation frames
func _on_animation_frame_changed() -> void:
	if animation.animation == "hold" and animation.frame == 1:
		if held_item:
			held_item.position = Vector2.ZERO # Center held item at end of animation
