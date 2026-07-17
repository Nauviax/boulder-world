extends Interactable # StaticBody2D
class_name Boulder

@export var explosion_scene: PackedScene

# Type of boulder, determines color and landing effects
enum Type { BASIC, RED, GREEN, BLUE, YELLOW }
var _type: Type = Type.BASIC
@export var type: Type:
	get:
		return _type
	set(value):
		_type = value
		if is_node_ready():
			update_type()

@onready var body: Node2D = $Body
@onready var sprite: Sprite2D = body.get_node("Sprite2D")

# Base explosion stats, later modified by boulder type and thrower stats
const BASE_EXPLOSION_DAMAGE: float = 100 # Damage dealt to enemies when boulder lands, enough to kill a basic enemy
const BASE_EXPLOSION_RADIUS: float = 100.0 # Radius of the explosion effect when boulder lands

# Boulder stats, based on type
var explode_on_land: bool = true # Whether the boulder explodes on landing at all
var explosion_damage: float = BASE_EXPLOSION_DAMAGE
var explosion_radius: float = BASE_EXPLOSION_RADIUS
var explosions_this_throw: int = -1 # Track how many explosions have occurred for this throw, as specific boulders may re-throw

func _ready() -> void:
	update_type()

# Called automatically on type update, or on ready.
func update_type() -> void:
	match _type:
		Type.BASIC:
			sprite.modulate = Color.DARK_GRAY
		Type.RED: # Larger explosion radius and damage
			sprite.modulate = Color.ORANGE_RED
			explosion_damage = BASE_EXPLOSION_DAMAGE * 1.5
			explosion_radius = BASE_EXPLOSION_RADIUS * 1.5
		Type.GREEN: # No explosion (Mostly for debug !!!)
			sprite.modulate = Color.GREEN
			explode_on_land = false # Green boulders do not explode on landing (!!! MAY BE TEMP)
		Type.BLUE: # Very large radius, but low damage. Very large stun duration. (!!! NYI)
			sprite.modulate = Color.AQUA
		Type.YELLOW: # Bouncy, re-throws on landing multiple times
			sprite.modulate = Color.YELLOW

# Clear explosion count on pickup or load(!!! LOAD NYI)
func pickup(holder: Node2D, offset: Vector2 = Vector2.ZERO):
	super.pickup(holder, offset)
	explosions_this_throw = 0

func load(): # !!! NYI
	# super.load() !!!
	explosions_this_throw = 0

# Override landing logic to spawn explosions
func land():
	super.land() # Perform base landing logic first
	if explode_on_land:
		explosions_this_throw += 1
		var explosion: Explosion = explosion_scene.instantiate() as Explosion
		explosion.position = position
		explosion.explosion_damage = explosion_damage * last_thrower.THROW_DAMAGE_MODIFIER
		explosion.explosion_radius = explosion_radius * last_thrower.THROW_RADIUS_MODIFIER
		if type == Type.YELLOW: # Yellow boulders re-throw on landing, up to 3 times
			explosion.explosion_damage /= explosions_this_throw # Reduce damage for re-throws (1.0, 0.5, 0.33)
			explosion.explosion_radius /= explosions_this_throw # Reduce radius for re-throws
			if explosions_this_throw < 3:
				rethrow(0.33, 0.33, false) # Re-throw at 1/3 distance and speed, in same direction
		level_scene.add_child(explosion)
