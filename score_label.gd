extends Label

#using score as currency
signal score_changed(new_score)
signal dash_unlocked

var score = 0

func _on_mob_squashed():
	score += 1
	text = "credits: %s" % score
	score_changed.emit(score)
	if score==3:
		dash_unlocked.emit()

func adjust_score(amount: int) -> void:
	score += amount
	if score < 0:
		score = 0
	text = "credits: %s" % score
	score_changed.emit(score)
