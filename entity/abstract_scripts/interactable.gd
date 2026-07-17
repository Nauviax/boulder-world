extends StaticBody2D
class_name Interactable

@onready var level_scene := get_parent() # Only used to re-parent to level
@onready var screen_size := get_viewport_rect().size # For bouncing
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var init_collision_layer = collision_layer
@onready var init_z_index = z_index # Bonus 50 added while in flight

# Consts for modifying throw path
const THROW_HEIGHT_FACTOR = 0.2 # Ratio h/d; 0.2 means height is 20% of throw distance.
const THROW_SCALE_FACTOR = 0.5 # % of base scale when at peak of arc
const THROW_INVALID_LAND_LAYER = 128 # Collision layer 8, for static objects that should cause a re-throw if landed on (Castle, etc)

var is_held := false
var in_air := false
var last_thrower: Node2D = null # Used to get thrower stats, if needed
var last_throw_target: Vector2 = Vector2.ZERO # For re-throwing, if needed
var last_throw_vector: Vector2 = Vector2.ZERO # For re-throwing, if needed
var last_throw_speed: float = 0.0 # For re-throwing, if needed

func pickup(holder: Node2D, offset: Vector2 = Vector2.ZERO):
	if in_air: return # Shouldn't happen, but just in case
	is_held = true
	collision_layer = 0 # Disable collision when being held (instantly, not deferred)
	reparent(holder, false)
	position = offset # Centre on holder

# For dropping, pass global_position to ensure pos is not relative to holder
func drop(drop_pos: Vector2, restore_collision: bool = true):
	is_held = false
	collision_layer = init_collision_layer if restore_collision else 0
	reparent(level_scene, false)
	position = drop_pos # Theoretically, position == global_position here

# Animate from current position to target position
func throw(target_pos: Vector2, speed: float, thrower: Node2D):
	if is_held:
		drop(global_position, false) # Remain intangible (global)
	in_air = true
	last_thrower = thrower
	last_throw_target = target_pos
	last_throw_vector = target_pos - position
	last_throw_speed = speed
	collision_layer = 0 # Redundant in most cases I assume but ehhh
	z_index = init_z_index + 50
	var start_pos := position
	var distance := start_pos.distance_to(target_pos)
	var duration := distance / speed
	var arc_height := distance * THROW_HEIGHT_FACTOR
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
		var scale_factor = 1.0 + sin(progress * PI) * THROW_SCALE_FACTOR
		scale = Vector2(scale_factor, scale_factor)
	, 0.0, 1.0, duration)
	await tween.finished
	# Check for re-throw if inside a static object
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = position
	parameters.collision_mask = THROW_INVALID_LAND_LAYER
	var results = get_world_2d().direct_space_state.intersect_point(parameters, 1)
	if not results.is_empty():
		rethrow(0.5, 0.5, true) # Re-throw at half distance and half speed, in same direction
	else:
		land()

# Called when landing, should be overridden if extra logic should run
func land():
	in_air = false
	collision_layer = init_collision_layer
	z_index = init_z_index

# Calculate a new position to throw to, based on last throw
func rethrow(distance_mult: float, speed_mult: float, use_horizontal_offset: bool):
	var new_target_vector := last_throw_vector * distance_mult
	var horisontal_offset := 10 if use_horizontal_offset else 0 # Add a small horizontal offset to avoid landing in same spot
	if last_throw_target.x > screen_size.x or last_throw_target.x < 0:
		new_target_vector.x = -new_target_vector.x # Momentum was inverted
	if last_throw_target.y > screen_size.y or last_throw_target.y < 0:
		new_target_vector.y = -new_target_vector.y # Momentum was inverted
	throw(position + new_target_vector + Vector2(horisontal_offset, 0), last_throw_speed * speed_mult + horisontal_offset, last_thrower) # Bouncy, in same direction.

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
