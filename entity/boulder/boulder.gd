extends Interactable # StaticBody2D
class_name Boulder

signal create_explosion(position: Vector2, damage: float, radius: float)

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
var explosion_extra_stun: float = 0.0 # Extra stun duration applied in addition to damage-stun, based on their base_stun_duration
var explosions_this_throw: int = -1 # Track how many explosions have occurred for this throw, as specific boulders may re-throw

func _ready():
	update_type()

# Called automatically on type update, or on ready.
func update_type():
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
		Type.BLUE: # Very large radius, but no damage. Very large stun duration.
			sprite.modulate = Color.AQUA
			explosion_damage = 0.0
			explosion_radius = BASE_EXPLOSION_RADIUS * 3.0
			explosion_extra_stun = 5.0 # !!! May want to make this explosion blue?
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
		var calculated_damage = explosion_damage * last_thrower.THROW_DAMAGE_MODIFIER
		var calculated_radius = explosion_radius * last_thrower.THROW_RADIUS_MODIFIER
		var calculated_extra_stun = explosion_extra_stun * last_thrower.THROW_DAMAGE_MODIFIER
		if type == Type.YELLOW: # Yellow boulders re-throw on landing, up to 3 times
			calculated_damage /= explosions_this_throw # Reduce damage for re-throws (1.0, 0.5, 0.33)
			calculated_radius /= explosions_this_throw # Reduce radius for re-throws
			if explosions_this_throw < 3:
				rethrow(0.33, 0.33, false) # Re-throw at 1/3 distance and speed, in same direction
		create_explosion.emit(position, calculated_damage, calculated_radius, calculated_extra_stun)
