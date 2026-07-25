extends Node2D
class_name EffectSpawner

# Create some sprite or text that rises up and can fade in or out
@export var floating_text_scene: PackedScene
# @export var floating_sprite_scene: FloatingSprite !!!

# Create a cloud particle that
# @export var particle_scene: Particle !!!

# enum FloatingSpriteType { ALERT } # !!! THIS MAY MOVE TO FLOATING SPRITE
# enum ParticleType { ALERT } # !!! THIS MAY MOVE TO PARTICLE

# Spawn a floating text at or offset from this node's position
func create_floating_text(type: FloatingText.Type, display_value: Variant, offset: Vector2 = Vector2.ZERO):
	var floating_text: FloatingText = floating_text_scene.instantiate()
	add_child(floating_text)
	floating_text.set_text_type(type, offset, display_value)

# Spawn a floating timer text at or offset from this node's position, connected to a given signal for updates
func create_floating_game_timer(time_signal: Signal, game_seconds: int, offset: Vector2 = Vector2.ZERO):
	var floating_text: FloatingText = floating_text_scene.instantiate()
	add_child(floating_text)
	floating_text.set_time_text_type(FloatingText.Type.GameTimer, offset, time_signal, game_seconds)

# Spawn a floating timer text at or offset from this node's position, connected to a given signal for updates
func create_floating_countdown(time_signal: Signal, game_seconds: int, countdown_time: int, offset: Vector2 = Vector2.ZERO):
	var floating_text: FloatingText = floating_text_scene.instantiate()
	add_child(floating_text)
	floating_text.set_time_text_type(FloatingText.Type.GracePeriodTimer, offset, time_signal, game_seconds, countdown_time)