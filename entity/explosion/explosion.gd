extends Node2D
class_name Explosion

@onready var sprite: Sprite2D = $Sprite2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_area_shape: CircleShape2D = damage_area.get_node("CollisionShape2D").shape

const EXPLOSION_DURATION: float = 0.75 # Duration of the explosion effect in seconds
const SPRITE_SCALE_FACTOR: float = 4.0 / 100.0 # Scale factor for the explosion sprite (!!! TEMP, should scale better and automatically ideally)

var explosion_damage: float = 100.0 # Enough to kill a basic enemy
var explosion_radius: float = 100.0
var explosion_extra_stun: float = 0.0 # Extra stun duration applied in addition to damage-stun, based on their base_stun_duration

# Onready, get all colliding bodies in the damage area and apply damage to them
func _ready():
	damage_area_shape.radius = explosion_radius
	sprite.scale = Vector2(SPRITE_SCALE_FACTOR, SPRITE_SCALE_FACTOR) * explosion_radius
	await get_tree().physics_frame # Wait for physics to update (twice) and get colliding bodies
	await get_tree().physics_frame # !!! MAX investigate if there is better way (Wait for a diff signal? Don't use _ready()? !!!)
	var colliding_bodies = damage_area.get_overlapping_bodies()
	for body in colliding_bodies:
		body.apply_damage(explosion_damage, explosion_extra_stun) # Area should only contain damagable bodies
	damage_area.monitoring = false # Finished with area
	# Schedule the explosion to be removed after the duration
	await get_tree().create_timer(EXPLOSION_DURATION).timeout
	queue_free()
