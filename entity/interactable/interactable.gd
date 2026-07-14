extends StaticBody2D
class_name Interactable

@onready var level_scene := get_parent() # Only used to re-parent to level
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var init_collision_layer = collision_layer

var is_held := false

func pickup(holder: Node2D, offset: Vector2 = Vector2.ZERO) -> void:
	is_held = true
	collision_layer = 0 # Disable collision when being held (instantly, not deferred)
	reparent(holder, false)
	position = offset # Centre on holder

func drop(drop_position: Vector2) -> void:
	is_held = false
	collision_layer = init_collision_layer # Restore collision
	reparent(level_scene, false)
	position = drop_position # Theoretically, position == global_position here