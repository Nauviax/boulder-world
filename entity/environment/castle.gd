extends StaticBody2D

# Labels need to be connected to level_scene signals via editor
@export var lives_count_label_temp: Label # !!! This will be hearts later!
@export var game_time_label: Label
@export var coin_count_label: Label

func _on_lives_count_changed(lives: int) -> void:
	lives_count_label_temp.text = "Lives: " + str(lives)

func _on_second_changed(minutes: int, seconds: int, _game_seconds: int) -> void:
	game_time_label.text = "%02d:%02d" % [minutes, seconds]

func _on_coin_count_changed(new_count: int) -> void:
	coin_count_label.text = "Coins: " + str(new_count)

func _on_enemy_detection_area_body_entered(body: Node2D) -> void:
	if body is Enemy:
		body.call_deferred("reached_wall") # Damage wall and die. Deferred to make Godot physics happy
