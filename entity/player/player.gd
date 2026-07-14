extends CharacterBody2D
class_name Player

@onready var body: Node2D = $Body # Anything that rotates with the character
@onready var animation: AnimatedSprite2D = body.get_node("AnimatedSprite2D")
@onready var interaction: Area2D = body.get_node("InteractionArea")
@onready var holdingNode: Node2D = body.get_node("HoldingNode")
@onready var pickupNode: Node2D = holdingNode.get_node("PickupOffset")

# Variable constants for player movement
const max_speed = 1024 # Max speed assuming no friction.
const acceleration = 0.1 # % of remaining speed added each tick. (Remaining being max - current)
const friction = 0.15 # % of speed lost each tick (60tps)

# Player state
var fastmode := false # !!! TEMP, controls "prepare" movement
var heldItem: Interactable = null

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
	var speed_mult = 2 if fastmode else 1

	# Apply friction to current velocity (Regardless of input)
	velocity = lerp(velocity, Vector2.ZERO, friction)
	# Lerp towards input direction, and face that direction
	if input_dir != Vector2.ZERO:
		velocity = lerp(velocity, input_dir.normalized() * max_speed * speed_mult, acceleration)
		body.rotation = velocity.angle() # Only rotate if movement input exists

	# Update animation based on player state
	animation.speed_scale = speed_mult
	if heldItem or (animation.animation == "drop" and animation.is_playing()):
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
		if heldItem:
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
	if !heldItem:
		heldItem = item
		animation.play("hold")
		heldItem.pickup(holdingNode, pickupNode.position)

# Drop current item
func drop():
	if heldItem:
		animation.play("drop")
		heldItem.drop(pickupNode.global_position)
		heldItem = null

# Handle specific effects based on animation frames
func _on_animation_frame_changed() -> void:
	if animation.animation == "hold" and animation.frame == 1:
		if heldItem:
			heldItem.position = Vector2.ZERO # Center held item at end of animation