extends Area2D

signal coin_collected


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("coin_collected_listeners"):
		coin_collected.connect(node.on_coin_collected)
	$AnimationPlayer.play("spin")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		coin_collected.emit()
		set_deferred("monitoring", false)
		AudioManager.play_sound_effect(AudioManager.COIN_COLLECT)
		$AnimationPlayer.play("collect")
		# waiting for the animation
		await get_tree().create_timer(0.5).timeout
		queue_free.call_deferred()
