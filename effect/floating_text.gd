extends Control
class_name FloatingText
# Note that this class should be created as a child of a node that is located at text spawn position. (Text position is animated relative to parent node)

@onready var label: Label = $Label

enum Type { # Different textTypes affect how text appear and move on screen
	Small, # For enemy chatter and numbers when mining or picking up parts
	Medium, # For user alerts and warnings ("You can't place that there!") (Possibly used for some menu text)
	Large, # Announcing waves and wave complete text
	SubLarge, # Accompanies wave announcements; Slightly smaller, and itallic
	GameTimer, # The same size as Medium, but contains the current time (Displayed along wave anouncements)
	GracePeriodTimer, # Counts down from specified time, and removes itself when it reaches 0 (Used between rounds)
}

# !!! Some of above comments were just wrong as well, like sizes etc

# TODO !!! Fonts (And review font sizes, may be too small now)

# Text consts
const TEXT_FADE_DURATION: float = 0.5 # Seconds needed to fade in/out
const TEXT_FADE_SPEED := 1 / TEXT_FADE_DURATION # Rate that opacity increases or decreases per second

# Text variables (!!! REPLACE SOME OF THESE WITH ACTUAL LABEL_SETTINGS VALUES !!!)
var text_type: Type = Type.Small
var text_itallic: bool = false # !!! THIS DOES NOTHING, may need to switch to richTextLabel !!!
var text_rise_speed: float = false # Pixels to rise per second
var text_fade_in: bool = false
var text_duration: int = false # Seconds in waiting state; can be 0.

# Text state
enum State { FadeIn, Waiting, FadeOut }
var text_state := State.FadeIn
var text_duration_left: float = -1 # Seconds remaining in waiting state (Other timings are based on current opacity)
enum TimerType { None, CountUp, CountDown } # Note that CountDown does not despawn until reaching 0
var text_timer_type := TimerType.None # If set, will replace current text with time
var countdown_target: int = -1 # If CountDown, timer will reach 0 at this game time (in seconds)

# On ready, prepare label
func _ready():
	# Make settings unique to this instance (!!! MAX investigate cleaner solution)
	label.label_settings = label.label_settings.duplicate()
	label.text = ""

# Set variables based on given countdown timer type. Includes hooking up to a given signal for text updates.
func set_time_text_type(type: Type, offset: Vector2, time_signal: Signal, game_seconds: int, countdown_time: int = -1):
	set_text_type(type, offset) # "Super" set text type, then prepare timer specific variables
	countdown_target = game_seconds + countdown_time # Set target time for countdown timer
	time_signal.connect(update_timer_text) # Connect to signal for updating text
	update_timer_text(int(game_seconds / 60.0), game_seconds % 60, game_seconds) # Update initial text to current time

# Set variables based on given text type.
func set_text_type(type: Type, offset: Vector2, display_value: String = ""):
	text_type = type
	match type:
		# !!! Font sizes, rise speed, etc may need to be doubled to account for larger resolution !!!
		Type.Small:
			# text_font = Comic Sans
			label.label_settings.font_size = 10
			label.label_settings.font_color = Color.BLACK
			text_itallic = false # !!! NYI
			text_rise_speed = 25
			text_fade_in = false
			text_duration = 1
		Type.Medium:
			# text_font = Times New Roman
			label.label_settings.font_size = 16
			label.label_settings.font_color = Color.BLACK
			text_itallic = false # !!! NYI
			text_rise_speed = 35
			text_fade_in = false
			text_duration = 2
		Type.Large:
			# text_font = Times New Roman
			label.label_settings.font_size = 60
			label.label_settings.font_color = Color.BLACK
			text_itallic = false # !!! NYI
			text_rise_speed = 50
			text_fade_in = true
			text_duration = 3
		Type.SubLarge:
			# text_font = Times New Roman
			label.label_settings.font_size = 30
			label.label_settings.font_color = Color.BLACK
			text_itallic = true # !!! NYI
			text_rise_speed = 50
			text_fade_in = true
			text_duration = 3
		Type.GameTimer:
			# text_font = Times New Roman
			label.label_settings.font_size = 30
			label.label_settings.font_color = Color.BLACK
			text_itallic = true # !!! NYI
			text_rise_speed = 50
			text_fade_in = true
			text_duration = 3
			text_timer_type = TimerType.CountUp
		Type.GracePeriodTimer:
			# text_font = Times New Roman
			label.label_settings.font_size = 30
			label.label_settings.font_color = Color.LIGHT_GRAY
			text_itallic = false # !!! NYI
			text_rise_speed = 0
			text_fade_in = true
			text_timer_type = TimerType.CountDown
	
	if display_value != "":
		label.text = display_value
	if text_fade_in: # Appear slightly south if fading in, to rise into position.
		label.label_settings.font_color.a = 0
		position = offset + Vector2(0, (text_rise_speed * TEXT_FADE_DURATION)) # Appear below initial spawn
		text_state = State.FadeIn
	else: # Start in position
		position = offset
		text_state = State.Waiting
	text_duration_left = text_duration # Duration waiting at full opacity

# Animate text
func _process(delta: float):
	# Skip animation for waiting countdown timers, as they need to wait for 0.
	if text_timer_type == TimerType.CountDown and text_state == State.Waiting:
		return
	# Animate position and opacity
	position.y -= text_rise_speed * delta
	match text_state:
		State.FadeIn:
			label.label_settings.font_color.a += TEXT_FADE_SPEED * delta
			if label.label_settings.font_color.a >= 1:
				text_state = State.Waiting
		State.Waiting:
			text_duration_left -= delta
			if text_duration_left <= 0:
				text_state = State.FadeOut
		State.FadeOut:
			label.label_settings.font_color.a -= TEXT_FADE_SPEED * delta 
			if label.label_settings.font_color.a <= 0:
				queue_free() # Remove text

# Update timer text based on signals
func update_timer_text(minutes: int, seconds: int, game_seconds: int):
	match text_timer_type:
		TimerType.CountUp:
			label.text = "%01d:%02d" % [minutes, seconds]
		TimerType.CountDown:
			var remaining = countdown_target - game_seconds
			label.text = "0:%02d" % [remaining]
			if remaining <= 0:
				text_state = State.FadeOut # Start fading out when countdown reaches 0
		_: # Debug error
			assert(false, "update_timer_text() called with invalid text_timer_type: " + str(text_timer_type))
