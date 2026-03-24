extends CanvasLayer

signal transition_halfpoint
signal transition_complete

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var is_screen_transitioning = false

@onready var color_rect_2: ColorRect = $ColorRect2
@onready var color_rect_3: ColorRect = $ColorRect3


func _ready() -> void:
	color_rect.visible = false
	color_rect_2.visible = false
	color_rect_3.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)
	#animation_player.speed_scale = 1.5
	transition_complete.connect(_on_transition_complete)


func fade_transition() -> void:
	is_screen_transitioning = true
	color_rect.visible = true
	animation_player.play("fade_exit")


func wipe_transition() -> void:
	is_screen_transitioning = true
	color_rect.visible = true
	animation_player.play("wipe_exit")


func arrow_transition() -> void:
	is_screen_transitioning = true
	color_rect_2.visible = true
	color_rect_3.visible = true
	animation_player.play("arrow_exit")


# hoping only 1 animation plays at a time
func _on_animation_finished(animation_name):
	if animation_name == "fade_exit":
		transition_halfpoint.emit()
		animation_player.play("fade_enter")
	elif animation_name == "wipe_exit":
		transition_halfpoint.emit()
		animation_player.play("wipe_enter")
	elif animation_name == "arrow_exit":
		transition_halfpoint.emit()
		animation_player.play("arrow_enter")
	elif animation_name.contains("enter"):
		# need not know what enter animation
		animation_player.play("RESET")
		color_rect.visible = false
		color_rect_2.visible = false
		color_rect_3.visible = false
		transition_complete.emit()


func _on_transition_complete():
	is_screen_transitioning = false
