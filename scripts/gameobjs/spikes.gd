extends Area2D

var player_group = "Player"

# not detecting area2d (falling spikes ignored)
func _on_body_entered(body: Node2D) -> void:
		#if body.has_method("die"):
		#body.die()
	
	# using class method
	if body.is_in_group(player_group):
		AudioManager.play_sound_effect(AudioManager.SPIKE)
		body.die()

# Note: spikes.tscn is the base scene other spike scenes derive from (except falling_spike)
