extends Node2D

@onready var level_scene: LevelScene = $LevelScene
@onready var menu: Control = $Menu

# Music (!!! MAY MOVE LATER)
@onready var music_player: AudioStreamPlayer = $BackgroundMusic
const FADE_DURATION: float = 0.5 # Duration of fade-out between tracks, in seconds
var current_music_tween: Tween = null # Tween for fading between tracks

# On load, show menu and prepare game
func _ready():
	menu.visible = true
	level_scene.prepare_game() # Rallies first wave early, but no player control or waves yet

	# !!! DEBUGGING, game starts immediately anyway
	level_scene.player.control_enabled = true # !!! BAD
	await get_tree().create_timer(8.0).timeout
	level_scene.start_game()

# On start button pressed, hide menu and start game
func _on_start_button_pressed():
	menu.visible = false
	level_scene.start_game() # Enables player control and starts wave logic (!!! First wave should still "rally" again)

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