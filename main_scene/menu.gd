extends Container
class_name Menu

signal start_game_pressed
signal reset_game_pressed

@onready var menu_items: Container = $MenuItems
@onready var game_over_items: Container = $GameOverItems
@onready var fade: ColorRect = $BlackFade

const FADE_SPEED: float = 2.0 # Speed of a full fade in/out, in seconds
const FADE_MENU_OPACITY: float = 0.4 # Opacity of the menu background fade

var fade_tween: Tween = null # Tween for fading the background to a specific opacity

# On ready, set fade to full black and hide menu items (!!!)
func _ready():
	visible = true
	fade.color.a = 1.0
	menu_items.visible = false
	game_over_items.visible = false
	# !!! Hide specific menu items as needed

# Game load sequence, reveal menu slowly, and fade in background.
func show_menu():
	# !!! Hide game over menu, if showing. (NYI!!!)
	fade_to_opacity(1.0) # On first load, this is 0 duration. From game over, this has a delay. (!!! await this?)
	menu_items.visible = true
	game_over_items.visible = false
	# !!! fade in title title (!!! And remove from floating text)
	# Delay
	await get_tree().create_timer(1.0).timeout
	# Etc
	fade_to_opacity(FADE_MENU_OPACITY) # fade in background

# Hide menu, fade in rest of game all the way
func hide_menu():
	fade_to_opacity(0.0) # fade out background
	# !!! fade out title (!!! And remove from floating text)
	menu_items.visible = false # !!! TEMP simple solution
	# Delay
	# Etc

	# !!! TEMP DEAL WITH MENU VISIBILITY
	await get_tree().create_timer(1.0).timeout
	visible = false

# Show game over menu, fading background slightly
func game_over_menu():
	visible = true
	fade_to_opacity(FADE_MENU_OPACITY) # fade in background
	# !!! Show game over text (!!! And remove from floating text)
	menu_items.visible = false
	game_over_items.visible = true # !!! Should probably fade in, not appear
	# Delay
	# Etc

# Function to fade background to given opacity
func fade_to_opacity(target_opacity: float):
	var duration = abs(fade.color.a - target_opacity) * FADE_SPEED
	if fade_tween:
		fade_tween.kill() # Prevent previous fades from interfering with new fade
	fade_tween = create_tween()
	fade_tween.tween_property(fade, "color:a", target_opacity, duration)

func _on_play_pressed():
	start_game_pressed.emit() # Notify main scene to start game

func _on_back_to_menu_pressed():
	reset_game_pressed.emit() # Notify main scene to reset the game

func _on_fullscreen_pressed():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_exit_pressed():
	get_tree().quit()
