extends Area2D

var player_group = "Player"
@export var jump_boost = 500

# more of a boost pad, and less of a trampoline really
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(player_group):
		#body.velocity.y = -jump_boost
		var normal:Vector2 = Vector2.UP.rotated(rotation)
		# setting velocity vector opposite to normal to boost value
		body.velocity -= body.velocity.dot(normal) * normal - jump_boost * normal
		AudioManager.play_sound_effect(AudioManager.TRAMPOLINE)
