extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var label: Label = $CanvasLayer/Label
@onready var activated = false


func _ready() -> void:
	label.visible = false


# add checkpoint sounds later
func _on_body_entered(body: Node2D) -> void:
	if activated: return
	
	if body.is_in_group("Player"):
		body.set_checkpoint_at_position()
		activated = true
		animation_player.play("faded_zoom")
		AudioManager.play_sound_effect(AudioManager.CHECK_POINT_SAVED)
		label.visible = true
