extends CharacterBody2D
class_name Player

@onready var body: Node2D = $Body # Node that holds sprites
@onready var animation: AnimatedSprite2D = body.get_node("AnimatedSprite2D")

# Variable constants for player movement
const max_speed = 1024 # Max speed assuming no friction.
const acceleration = 0.1 # % of remaining speed added each tick. (Remaining being max - current)
const friction = 0.15 # % of speed lost each tick (60tps)

# Player state
var fastmode := false # !!! TEMP, controls "prepare" movement
var holding := false # True if holding an item

# Player movement
func _physics_process(delta: float) -> void:
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
	# Lerp towards input direction
	if input_dir != Vector2.ZERO:
		velocity = lerp(velocity, input_dir.normalized() * max_speed * speed_mult, acceleration)

	# Update sprite direction and animation based on velocity, input, and player state.
	body.rotation = velocity.angle()
	animation.speed_scale = speed_mult
	if holding or (animation.animation == "drop" and animation.is_playing()):
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
		holding = !holding
		if holding:
			animation.play("hold")
		else:
			animation.play("drop")

	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			fastmode = !fastmode # !!! THIS IS TEMPORARY