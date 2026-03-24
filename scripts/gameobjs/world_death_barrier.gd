extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		AudioManager.play_sound_effect(AudioManager.SPIKE)
		body.die()
