extends Interactable
class_name Coin

signal coin_collected(coin: Coin)

const COLLECT_X_COORD := 540 # Coins dropped left of this coord will be collected. Should line up with castle wall.

# Override settled to possibly collect coin based on position
func settled():
	if position.x <= COLLECT_X_COORD:
		coin_collected.emit(self)