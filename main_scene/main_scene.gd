extends Node2D

@onready var level_scene: LevelScene = $LevelScene
@onready var menu: Control = $Menu

# On load, show menu and prepare game
func _ready() -> void:
	menu.visible = true
	level_scene.prepare_game()

	# !!! DEBUGGING, game starts immediately anyway
	level_scene.start_game()

# On start button pressed, hide menu and start game
func _on_start_button_pressed() -> void:
	menu.visible = false
	level_scene.start_game()