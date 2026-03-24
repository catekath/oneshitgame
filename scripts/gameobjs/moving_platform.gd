extends Path2D

## time taken for one animation cycle
@export var duration = 1.0
## use for closed paths
@export var loop: bool = false

@onready var animation = $AnimationPlayer as AnimationPlayer
@onready var path = $PathFollow2D as PathFollow2D
var animation_name = "move"

@export var reset_at_player_respawn = false


# make sure to only move the platform using transform
# and the initial curve points should be at origin
func _ready() -> void:
	var player = get_tree().current_scene.get_node("Player")
	player.player_respawn.connect(_on_player_respawn)
	
	if not loop:
		# because 2 is the duration of our move animation
		animation.speed_scale = 2/duration
		animation.play(animation_name)
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	path.progress_ratio += delta / duration


func _on_player_respawn():
	if !reset_at_player_respawn: return
	
	animation.stop()
	path.progress_ratio = 0
	
	if not loop:
		animation.play(animation_name)
