extends CharacterBody2D

var player_group = "Player"
var movable_item_group = "MovableItem"

var is_getting_pushed = false
var pushed_in_direction = 0
@export var move_speed = 3000.0
@export var friction = 50

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var move_sound_player: AudioStreamPlayer = $MoveSoundPlayer
var was_on_floor = true

## physics is disabled if blocks falls below this height.
## (positive y is down)
@export var min_height = 1000

@export var reset_at_player_respawn = false
@onready var initial_position = position


func _ready() -> void:
	var player = get_tree().current_scene.get_node("Player")
	player.player_respawn.connect(_on_player_respawn)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		
		if position.y > min_height:
			visible = false
			set_physics_process(false)
	
	if is_getting_pushed:
		velocity.x = pushed_in_direction * delta * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, friction)
	
	move_and_slide()

	# velocity is 0 after move_and_slide if object is not moving
	# however, not necessarily so before.
	if abs(velocity.x) > 0.0:
		if !move_sound_player.is_playing():
			move_sound_player.play()
	else:
		move_sound_player.stop()
	
	if !was_on_floor && is_on_floor():
		AudioManager.play_sound_effect(AudioManager.WOOD_BOX_DROP)
	
	was_on_floor = is_on_floor()


func _on_left_push_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group(player_group):
		pushed_in_direction = 1
		is_getting_pushed = true


func _on_left_push_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group(player_group):
		pushed_in_direction = 0
		is_getting_pushed = false


func _on_right_push_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group(player_group):
		pushed_in_direction = -1
		is_getting_pushed = true


func _on_right_push_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group(player_group):
		pushed_in_direction = 0
		is_getting_pushed = false


func _on_player_respawn():
	if reset_at_player_respawn:
		velocity = Vector2(0,0)
		position = initial_position
		visible = true
		set_physics_process(true)
