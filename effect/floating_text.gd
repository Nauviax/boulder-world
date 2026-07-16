extends Control
class_name FloatingText
# Note that this class should be created as a child of a node that is located at text spawn position. (Text position is animated relative to parent node)

@onready var label: Label = $Label

enum TextType { # Different textTypes affect how text appear and move on screen (THIS IS BASED ON OLD CODE, REVIEW !!!)
	Small, # For enemy chatter and numbers when mining or picking up parts (Comic Sans)
	Medium, # For user alerts and warnings ("You can't place that there!") (Possibly used for some menu text)
	Large, # For menu text and announcing waves
	SubLarge, # Accompanies wave announcements, Slightly smaller, and itallic
	ExtraLarge, # Title and Game over title (Doesn't move/despawn) (White) (!!! MOVE THIS TO MENU UI NOT FLOATING TEXT)
	SubExtraLarge, # Accompanies Title and Game over text, Slightly smaller (Doesn't move/despawn) (White)
	# !!! Look into special casing the below items
	GameTimer, # The same size as Medium, but contains the current time (Displayed along wave anouncements)
	GracePeriodTimer, # Counts down from specified time, and removes itself when it reaches 0 (Used between rounds)
	# The below two may want to be part of castle and NOT here. (!!!)
	WaveTimer, # Permanent text that displays how long the current round has been going for. Is also white (One should always exist on lower castle)
	SubWaveTimer # Appears below WaveTimer, and appears the same as WaveTimer, but shows text instead
}

# !!! Anything listed as "Permanent" likely needs to just be UI and not "floating text" !!!
# !!! This whole class will want a rework to reduce types above. (Merge some?)
# !!! Some of above comments were just wrong as well, like sizes etc

# TODO !!! Fonts

# Text consts
const TEXT_FADE_DURATION: float = 0.5 # Seconds needed to fade in/out
const TEXT_FADE_SPEED := 1 / TEXT_FADE_DURATION # Rate that opacity increases or decreases per second

# Text variables (!!! REPLACE SOME OF THESE WITH ACTUAL LABEL VALUES !!!)
var text_type: TextType = TextType.Small
var text_itallic: bool = false # !!! THIS DOES NOTHING, may need to switch to richTextLabel !!!
var text_rise_speed: float = false # Pixels to rise per second
var text_fade_in: bool = false
var text_duration: int = false # Seconds in waiting state; can be 0.
var text_is_permanent: bool = false # Text does not fade out on it's own. (Except for countdown timers)

# Text state
enum TextState { FadeIn, Waiting, FadeOut }
var text_state := TextState.FadeIn
var text_duration_left: float = -1 # Seconds remaining in waiting state (Rest are based on current opacity)
enum TimerType { None, CountUp, CountDown }
var text_timer_type := TimerType.None # If set, will replace current text with time
var text_timer_time: float = -1 # Seconds that this text is displaying (If used)

# On ready, prepare label
func _ready():
	# Make settings unique to this instance (!!! MAX investigate cleaner solution)
	label.label_settings = label.label_settings.duplicate()
	# Clear text and position/size (Fix centering)
	label.text = ""

# Set variables based on given text type. Display value is either string or float as appropriate for type.
func set_text_type(type: TextType, display_value: Variant, offset: Vector2):
	if typeof(display_value) == TYPE_STRING:
		label.text = display_value
	else:
		text_timer_time = display_value
	text_type = type
	match type:
		# !!! Font sizes, rise speed, etc may need to be doubled to account for larger resolution !!!
		TextType.Small:
			# text_font = Comic Sans
			label.label_settings.font_size = 10
			label.label_settings.font_color = Color.BLACK
			text_itallic = false # !!! NYI
			text_rise_speed = 25
			text_fade_in = false
			text_duration = 1
		TextType.Medium:
			# text_font = Times New Roman
			label.label_settings.font_size = 16
			label.label_settings.font_color = Color.BLACK
			text_itallic = false # !!! NYI
			text_rise_speed = 35
			text_fade_in = false
			text_duration = 2
		TextType.Large:
			# text_font = Times New Roman
			label.label_settings.font_size = 60
			label.label_settings.font_color = Color.BLACK
			text_itallic = false # !!! NYI
			text_rise_speed = 50
			text_fade_in = true
			text_duration = 3
		TextType.SubLarge:
			# text_font = Times New Roman
			label.label_settings.font_size = 30
			label.label_settings.font_color = Color.BLACK
			text_itallic = true # !!! NYI
			text_rise_speed = 50
			text_fade_in = true
			text_duration = 3
		TextType.ExtraLarge:
			# text_font = Times New Roman
			label.label_settings.font_size = 80
			label.label_settings.font_color = Color.WHITE
			text_itallic = false # !!! NYI
			text_rise_speed = 0
			text_fade_in = true
			text_is_permanent = true
		TextType.SubExtraLarge:
			# text_font = Times New Roman
			label.label_settings.font_size = 40
			label.label_settings.font_color = Color.WHITE
			text_itallic = false # !!! NYI
			text_rise_speed = 0
			text_fade_in = false
			text_is_permanent = true
		TextType.GameTimer:
			# text_font = Times New Roman
			label.label_settings.font_size = 30
			label.label_settings.font_color = Color.BLACK
			text_itallic = false # !!! NYI
			text_rise_speed = 50
			text_fade_in = false
			text_duration = 3
			text_timer_type = TimerType.CountUp
			text_timer_time = display_value
		TextType.GracePeriodTimer:
			# text_font = Times New Roman
			label.label_settings.font_size = 30
			label.label_settings.font_color = Color.LIGHT_GRAY
			text_itallic = false # !!! NYI
			text_rise_speed = 0
			text_fade_in = true
			text_is_permanent = true
			text_timer_type = TimerType.CountDown
			text_timer_time = display_value
		TextType.WaveTimer: # !!! TEMP ?
			# text_font = Times New Roman
			label.label_settings.font_size = 30
			label.label_settings.font_color = Color.WHITE
			text_itallic = false # !!! NYI
			text_rise_speed = 0
			text_fade_in = false
			text_is_permanent = true
			text_timer_type = TimerType.CountUp
			text_timer_time = display_value
		TextType.SubWaveTimer: # !!! TEMP ?
			# text_font = Times New Roman
			label.label_settings.font_size = 30
			label.label_settings.font_color = Color.WHITE
			text_itallic = false # !!! NYI
			text_rise_speed = 0
			text_fade_in = false
			text_is_permanent = true
	if text_fade_in:
		label.label_settings.font_color.a = 0
		position = offset + Vector2(0, (text_rise_speed * TEXT_FADE_DURATION)) # Appear below initial spawn
		text_state = TextState.FadeIn
	else:
		position = offset
		text_state = TextState.Waiting
	text_duration_left = text_duration

# Animate text, and update timers
func _process(delta: float):
	# Update timer amounts
	if text_timer_type != TimerType.None:
		text_timer_time += delta if text_timer_type == TimerType.CountUp else -delta
		var rounded_time: int = ceil(text_timer_time)
		@warning_ignore("integer_division") # Intended here
		label.text = "%d:%02d" % [rounded_time / 60, rounded_time % 60]
		if text_timer_time < 0:
			text_state = TextState.FadeOut
	# Do not animate once waiting if permanent
	if text_is_permanent and text_state == TextState.Waiting:
		return
	# Animate position and opacity
	position.y -= text_rise_speed * delta
	match text_state:
		TextState.FadeIn:
			label.label_settings.font_color.a += TEXT_FADE_SPEED * delta
			if label.label_settings.font_color.a >= 1:
				text_state = TextState.Waiting
		TextState.Waiting:
			text_duration_left -= delta
			if text_duration_left <= 0:
				text_state = TextState.FadeOut
		TextState.FadeOut:
			label.label_settings.font_color.a -= TEXT_FADE_SPEED * delta 
			if label.label_settings.font_color.a <= 0:
				queue_free() # Remove text
