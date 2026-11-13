extends Node2D
class_name Explosion

@onready var sprite: Sprite2D = $Sprite2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_area_shape: CircleShape2D = damage_area.get_node("CollisionShape2D").shape

const EXPLOSION_DURATION: float = 0.75 # Duration of the explosion effect in seconds (Repeated for each DoT instance)
const SPRITE_SCALE_FACTOR: float = 4.0 / 100.0 # Scale factor for the explosion sprite (!!! TEMP, should scale better and automatically ideally)

var explosion_color: Color
var explosion_damage: float = 100.0 # Enough to kill a basic enemy
var explosion_radius: float = 100.0
var explosion_extra_stun: float = 0.0 # Extra stun duration applied in addition to damage-stun, based on their base_stun_duration
var explosion_count: float = 1 # DoT explosions stick around

# Onready, get all colliding bodies in the damage area and apply damage to them
func _ready():
	damage_area_shape.radius = explosion_radius
	sprite.modulate = explosion_color
	sprite.scale = Vector2(SPRITE_SCALE_FACTOR, SPRITE_SCALE_FACTOR) * explosion_radius
	await get_tree().physics_frame # Wait for physics to update (twice) and get colliding bodies
	await get_tree().physics_frame # !!! MAX investigate if there is better way (Wait for a diff signal? Don't use _ready()? !!!)
	var explosions_left = explosion_count
	while explosions_left > 0:
		var colliding_bodies = damage_area.get_overlapping_bodies()
		for body in colliding_bodies:
			body.apply_damage(explosion_damage, explosion_extra_stun) # Area should only contain damagable bodies
		explosions_left -= 1
		if (explosions_left <= 0):
			damage_area.monitoring = false # Finished with area
		await get_tree().create_timer(EXPLOSION_DURATION).timeout
	# Schedule the explosion to be removed at end of explosion
	queue_free()
