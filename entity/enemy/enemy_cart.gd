extends Enemy
class_name EnemyCart

# Types of cart enemies
enum EnemyType { BASIC }
@export var enemy_type: EnemyType = EnemyType.BASIC

# Note that this enemy does NOT rotate.
func _ready():
	match enemy_type:
		EnemyType.BASIC:
			base_speed /= 2 # Half speed of base enemy
			base_health *= 3 # Triple health of base enemy
			health = base_health # Set current health to max
	animation.play("idle")

# Player detected, start shooting at player
func _on_gamesense_body_entered(player: Node2D):
	startChase(player) # !!! TEMP NOT SHOOTING YET

# Player lost, return to original state
func _on_gamesense_body_exited(_player: Node2D):
	stopChase() # !!! TEMP NOT SHOOTING YET

# I imagine this enemy will override chase to shoot at player and simply call charge tick instead of actual chase movement logic.
# !!! This enemy needs an ACTUAL idle animation, and a seperate charging animation. Likely rename others to similar, even if sprites are reused.
