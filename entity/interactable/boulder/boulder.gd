extends Interactable # StaticBody2D
class_name Boulder

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

func _ready() -> void:
	update_type()

func update_type() -> void:
	match _type:
		Type.BASIC:
			sprite.modulate = Color.DARK_GRAY
		Type.RED:
			sprite.modulate = Color.ORANGE_RED
		Type.GREEN:
			sprite.modulate = Color.GREEN
		Type.BLUE:
			sprite.modulate = Color.AQUA
		Type.YELLOW:
			sprite.modulate = Color.YELLOW
