extends StaticBody2D
class_name Turret

# Turrets are stationary objects that exist on level start. Ensure they are placed so that arm does not go outside of the screen.

@onready var body: Node2D = $Body # Turret body will not rotate, but child arm will
@onready var arm: Node2D = body.get_node("Arm") # Turret arm rotates in aiming direction
@onready var arm_animation: AnimatedSprite2D = arm.get_node("AnimatedSprite2D")

@onready var loaded_item_pos: Node2D = arm.get_node("LoadedItemPos") # Loaded item should be a child of this node
@onready var stored_item_pos_1: Node2D = body.get_node("StoredItemPos1") # Stored items should be children of one of these nodes
@onready var stored_item_pos_2: Node2D = body.get_node("StoredItemPos2")

@onready var enemy_detection_timer: Timer = $EnemyDetectionTimer # Timer that periodically checks for new targets
@onready var enemy_detection_area: Area2D = $EnemyDetectionArea # Area that detects enemies in range

# Turret consts
const DETECTION_TIME := 1.0 # Seconds between checking for new targets
const TARGET_Y_BIAS_MULT := 1.5 # Bias towards targets on similar Y position, as they are more likely to be in range of a throw. 1.0 is no bias, larger values bias towards similar Y
const AIM_ROTATION_SPEED := 1.0 # Speed at which turret arm rotates towards target (Note that this is not a fixed unit per second speed)
const AIM_ANGLE_TOLERANCE := 0.1 # Radians of tolerance for aiming at target before firing
const AIM_TIME := 1.5 # Seconds to aim at target before firing (Timer starts when aim is lined up with target)
const RELOAD_TIME := 1.5 # Seconds before reloading after a throw
const MAX_STORED_ITEMS := 2 # Max number of items that can be stored in turret at once

# Turret throwing consts
const THROW_SPEED := 450.0 # Pixels per second
const THROW_DAMAGE_MODIFIER = 1.0
const THROW_RADIUS_MODIFIER = 1.0

# Turret state
enum ArmState { DISABLED, MOVING, PRE_THROW, POST_THROW }
@export var arm_state: ArmState = ArmState.DISABLED # Current state of the turret arm. Initial values are DISABLED and MOVING, based on built status.
var target: Enemy = null # Target to aim at
var available_targets: Array = [] # List of targets that are in range
var loaded_item: Interactable = null # Item that is currently loaded and ready to throw
var stored_items: Array = [] # Items that are stored and ready to be loaded

# On ready, update turret based on is_active state
func _ready():
	enemy_detection_timer.wait_time = DETECTION_TIME
	if arm_state == ArmState.DISABLED:
		arm.visible = false # Hide arm if not built yet
	else:
		build() # Run all build logic

# Rotate to face target, even if no item is loaded. If no target, rotate to resting position
func _process(delta: float) -> void:
	if arm_state == ArmState.MOVING or arm_state == ArmState.PRE_THROW:
		if target != null:
			var target_offset = target.global_position - arm.global_position # Don't need normalization here
			var target_angle = target_offset.angle()
			arm.rotation = lerp_angle(arm.rotation, target_angle, delta * AIM_ROTATION_SPEED) # Smoothly rotate towards target
			# If arm is lined up with target, start aiming timer
			if arm_state == ArmState.MOVING and abs(arm.rotation - target_angle) < AIM_ANGLE_TOLERANCE:
				throw_async.call_deferred() # Start aiming and potentially throwing. Deferred to avoid blocking code.
		else:
			arm.rotation = lerp_angle(arm.rotation, 0, delta * AIM_ROTATION_SPEED) # Smoothly return to resting position

# Build the turret, enabling it to aim and throw. (Arm will become visible)
func build():
	enemy_detection_timer.start() # Start checking for new targets
	arm_state = ArmState.MOVING
	arm.visible = true
	arm_animation.play("rest")

# Throw loaded item at the target. Assumes an item is ready to be fired.
# Should be called via call_deferred, as the throwing process is asynchronous and takes time to complete.
func throw_async():
	arm_state = ArmState.PRE_THROW # Update state to avoid multiple calls to this function while aiming
	await get_tree().create_timer(AIM_TIME).timeout # Wait for aiming time to complete
	# If target is still valid, throw loaded item at it. Otherwise, clear target and get a new one.
	if is_valid_target(target):
		target.doom() # Prevent enemy from moving, and prevents other turrets from targeting it.
		arm_state = ArmState.POST_THROW # Set state to POST_THROW, locking rotation until reload_async is complete
		arm_animation.play("throw")
		loaded_item.throw(target.global_position, THROW_SPEED, self) # Throw loaded item at target
		loaded_item = null # Clear loaded item, as it has been thrown
		target = null # Clear target
		reload_async.call_deferred() # Reload after a delay. Deferred to avoid blocking code
	else: # Target is no longer valid, so just clear it and get a new target.
		target = null
		arm_state = ArmState.MOVING # Set state back to MOVING, unlocking rotation
		get_new_target()

# Delay, then reload_async turret.
# Should be called via call_deferred, normally as part of throw_async.
func reload_async():
	await get_tree().create_timer(RELOAD_TIME).timeout # Wait for throw animation to finish
	arm_state = ArmState.MOVING # Set state back to MOVING, unlocking rotation
	arm_animation.play("rest")
	# Pop oldest item from storage and move to loaded position
	if stored_items.size() > 0:
		loaded_item = stored_items.pop_front()
		loaded_item.reparent(loaded_item_pos, false)
	# Move remaining stored items to their new positions
	if stored_items.size() > 0:
		stored_items[0].reparent(stored_item_pos_1, false)
	# Not currently possible to store more than 2 items, so there will never be an item to put in pos_2
	# Attempt to get a new target. Otherwise, one will be aquired on next check.
	get_new_target() # Also doubles as a set-null if no valid targets are available

# Helper function for determining if this turret can store items
func has_room() -> bool:
	return arm_state != ArmState.DISABLED and stored_items.size() < MAX_STORED_ITEMS

# Store an item in the turret. If there is no loaded item, load it immediately. If full, returns false and does nothing.
func store_item(item: Interactable) -> bool:
	var stored_item_count := stored_items.size()
	if not has_room():
		return false # Turret is full or not active, cannot store items
	item.position = Vector2.ZERO # Reset position to avoid offset issues when reparenting
	if loaded_item == null and arm_state == ArmState.MOVING: # If no loaded item and not busy, load immediately.
		loaded_item = item # Load immediately
		loaded_item.reparent(loaded_item_pos, false)
	else:
		if stored_item_count < MAX_STORED_ITEMS:
			stored_items.append(item) # Store item
		match stored_item_count:
			0: # Count is before adding item
				item.reparent(stored_item_pos_1, false)
			1:
				item.reparent(stored_item_pos_2, false)
	return true # Success

# Periodically check for new targets. Called via timer signal.
func check_for_new_target():
	# If current target is valid, or if turret is not active, do nothing
	if (target != null and is_valid_target(target)) or arm_state == ArmState.DISABLED:
		return
	# Otherwise, get a new target
	get_new_target()

# Get a new target from available targets.
# Prefer targets that are closest, but with bias towards targets on similar Y position, treating north-more/south-more targets as further away.
# Results in further away targets being preferred if they are more in-line, leaving the closest one for the better turret.
func get_new_target():
	if not loaded_item:
		return # Cannot aim if no item is loaded
	var closest_target: Enemy = null
	if available_targets.size() > 0:
		# Find best target
		var closest_distance: float = INF
		for potential_target in available_targets:
			if not is_valid_target(potential_target):
				continue # Skip invalid targets
			var offset = position - potential_target.position # Position is fine here, both should have same parent node.
			offset.y *= TARGET_Y_BIAS_MULT # Y bias, prefer inline targets.
			var distance = offset.length()
			if distance < closest_distance:
				closest_distance = distance
				closest_target = potential_target
	# Set target to best target, or null if none found
	target = closest_target
	if target:
		target.targeted_by = weakref(self) # Mark target as being targeted by this turret

# Helper function to determine if a target is valid. Takes Variant type, as a dead enemy is not an Enemy.
func is_valid_target(enemy: Variant) -> bool:
	if not is_instance_valid(enemy) or not enemy.is_inside_tree():
		return false
	return enemy.is_valid_target_for_turret(self) # Check if target is valid for this turret

# Signal handler for enemies entering detection area
func _on_enemy_in_range(enemy: Node2D):
	available_targets.append(enemy)

# Signal handler for enemies leaving detection area
func _on_enemy_left_range(enemy: Node2D):
	available_targets.erase(enemy)
