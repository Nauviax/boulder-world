extends Enemy
class_name EnemyBasic

# Types of basic enemies
enum EnemyType { BASIC, FAST }
@export var enemy_type: EnemyType = EnemyType.BASIC

const basic_animation_frames := preload("res://entity/enemy/enemy_basic_purple_frames.tres")
const fast_animation_frames := preload("res://entity/enemy/enemy_basic_red_frames.tres")

# Prepare enemy
func _ready():
	match enemy_type:
		EnemyType.BASIC:
			animation.sprite_frames = basic_animation_frames
		EnemyType.FAST:
			animation.sprite_frames = fast_animation_frames
			base_speed *= 1.75
	animation.play("idle")

	# !!! DEBUGGING BELOW

	if enemy_type != EnemyType.BASIC:
		return # Only debug for basic enemy type

	var delay := 1.2

	above_effect_spawner.create_floating_text(FloatingText.TextType.Small, "TEST MESSAGE SMALL")
	await get_tree().create_timer(delay).timeout

	above_effect_spawner.create_floating_text(FloatingText.TextType.Medium, "MEDIUM")
	await get_tree().create_timer(delay).timeout

	above_effect_spawner.create_floating_text(FloatingText.TextType.Large, "LARGE")
	await get_tree().create_timer(delay).timeout

	above_effect_spawner.create_floating_text(FloatingText.TextType.SubLarge, "Sub Large")
	await get_tree().create_timer(delay).timeout

	above_effect_spawner.create_floating_text(FloatingText.TextType.ExtraLarge, "EXTRA LARGE", Vector2(-564, 0))
	await get_tree().create_timer(delay).timeout

	above_effect_spawner.create_floating_text(FloatingText.TextType.SubExtraLarge, "Sub Extra", Vector2(-164, 0))
	await get_tree().create_timer(delay).timeout

	above_effect_spawner.create_floating_text(FloatingText.TextType.GameTimer, 0)
	await get_tree().create_timer(delay).timeout

	above_effect_spawner.create_floating_text(FloatingText.TextType.GracePeriodTimer, 70, Vector2(0, -64))
	await get_tree().create_timer(delay).timeout

	above_effect_spawner.create_floating_text(FloatingText.TextType.WaveTimer, 45, Vector2(164, 0))
	await get_tree().create_timer(delay).timeout

	above_effect_spawner.create_floating_text(FloatingText.TextType.SubWaveTimer, "WAVE TEXT", Vector2(364, 0))

	while true:
		await get_tree().create_timer(delay).timeout
		above_effect_spawner.create_floating_text(FloatingText.TextType.Small, "TEST MESSAGE SMALL REPEATING")

# Player detected, start charging towards player
func _on_player_detected(player: Node2D):
	startAggro(player)

# Player lost, return to original state
func _on_player_lost(_player: Node2D):
	stopAggro()

# Something is too close, add body to list
func _new_too_close_body(too_close_body: Node2D):
	if too_close_body == self or too_close_body in too_close_bodies:
		return
	too_close_bodies.append(too_close_body)

# Something is no longer too close, remove body from list
func _remove_too_close_body(too_close_body: Node2D):
	if too_close_body in too_close_bodies:
		too_close_bodies.erase(too_close_body)
