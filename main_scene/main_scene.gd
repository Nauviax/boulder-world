extends Node2D

@onready var level_scene: LevelScene = $LevelScene
@onready var menu: Control = $Menu

# On load, show menu and prepare game
func _ready():
	menu.visible = true
	level_scene.prepare_game() # Rallies first wave early, but no player control or waves yet

	# !!! DEBUGGING, game starts immediately anyway
	await get_tree().create_timer(1.0).timeout
	level_scene.start_game()

# On start button pressed, hide menu and start game
func _on_start_button_pressed():
	menu.visible = false
	level_scene.start_game() # Enables player control and starts wave logic (!!! First wave should still "rally" again)