extends Node2D

@onready var level_scene: LevelScene = $LevelScene
@onready var menu: Menu = $Menu

# Music
@onready var music_player: AudioStreamPlayer = $BackgroundMusic
const FADE_DURATION: float = 0.5 # Duration of fade-out between tracks, in seconds
var current_music_tween: Tween = null # Tween for fading between tracks

# On load, show menu and prepare game
func _ready():
	new_game_prepare()

# On first load, or game restart, prepare game and show menu
func new_game_prepare():
	menu.show_menu()
	level_scene.prepare_game() # Rallies first wave early, but no player control or waves yet

# On start button pressed, hide menu and start game. (Called from menu signal)
func new_game_start():
	menu.hide_menu()
	level_scene.start_game() # Enables player control and starts wave logic (!!! First wave should still "rally" again)

# On game over, show death menu
func game_over():
	menu.game_over_menu()

# Play the specified music track. Fades between tracks as needed.	
func play_background_music(new_track: AudioStream):
	if music_player.stream == new_track and music_player.playing:
		return # Already playing this track, do nothing
	if music_player.playing:
		# Fade out to -80 dB
		current_music_tween = create_tween()
		current_music_tween.tween_property(music_player, "volume_db", -80.0, FADE_DURATION)
		# Swap track on complete
		current_music_tween.tween_callback(func():
			music_player.stream = new_track
			music_player.volume_db = 0 # No fade-in, it sounds bad for my tracks atm.
			music_player.play()
		)
	else: # Start playing immediately
		music_player.stream = new_track
		music_player.play()
