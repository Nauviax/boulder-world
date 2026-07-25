extends StaticBody2D

# Labels need to be connected to level_scene signals via editor
@export var game_time_label: Label
@export var coin_count_label: Label

func _on_second_changed(minutes: int, seconds: int, _game_seconds: int) -> void:
	game_time_label.text = "%02d:%02d" % [minutes, seconds]

func _on_coin_count_changed(new_count: int) -> void:
	coin_count_label.text = "Coins: " + str(new_count)
