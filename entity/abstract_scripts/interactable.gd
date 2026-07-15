extends StaticBody2D
class_name Interactable

@onready var level_scene := get_parent() # Only used to re-parent to level
@onready var screen_size := get_viewport_rect().size # For bouncing
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var init_collision_layer = collision_layer
@onready var init_z_index = z_index # Bonus 50 added while in flight

# Consts for modifying throw path
const throw_height_factor = 0.2 # Ratio h/d; 0.2 means height is 20% of throw distance.
const throw_scale_factor = 0.5 # % of base scale when at peak of arc

var is_held := false
var in_air := false

func pickup(holder: Node2D, offset: Vector2 = Vector2.ZERO):
	if in_air: return # Shouldn't happen, but just in case
	is_held = true
	collision_layer = 0 # Disable collision when being held (instantly, not deferred)
	reparent(holder, false)
	position = offset # Centre on holder

func drop(drop_pos: Vector2, restore_collision: bool = true):
	is_held = false
	collision_layer = init_collision_layer if restore_collision else 0
	reparent(level_scene, false)
	position = drop_pos # Theoretically, position == global_position here

# Animate from current position to target position
func throw(target_pos: Vector2, speed: float):
	if is_held:
		drop(global_position, false) # Remain intangible
	in_air = true
	collision_layer = 0 # Redundant in most cases I assume but ehhh
	z_index = init_z_index + 50
	var start_pos := position
	var distance := start_pos.distance_to(target_pos)
	var duration := distance / speed
	var arc_height := distance * throw_height_factor
	var tween := create_tween()
	tween.set_parallel(true)  # run both tweens at same time
	tween.tween_method(func(progress: float):
		# Calculate movement along arc (bouncing as needed)
		var height_offset := sin(progress * PI) * arc_height
		var next_position = start_pos.lerp(target_pos, progress) + Vector2(0, -height_offset)
		position = bounce_screen_edges(next_position)
	, 0.0, 1.0, duration)
	tween.tween_method(func(progress: float):
		# Scale based on arc progress
		var scale_factor = 1.0 + sin(progress * PI) * throw_scale_factor
		scale = Vector2(scale_factor, scale_factor)
	, 0.0, 1.0, duration)
	await tween.finished
	land()

# Called when landing, should be overridden if extra logic should run
func land():
	in_air = false
	collision_layer = init_collision_layer
	z_index = init_z_index
	pass

# Helper function to "bounce" a vector off of a screen edge
func bounce_screen_edges(next_position: Vector2) -> Vector2:
	if next_position.x < 0:
		next_position.x = -next_position.x
	elif next_position.x > screen_size.x:
		next_position.x = screen_size.x - (next_position.x - screen_size.x)
	if next_position.y < 0:
		next_position.y = -next_position.y
	elif next_position.y > screen_size.y:
		next_position.y = screen_size.y - (next_position.y - screen_size.y)
	return next_position
