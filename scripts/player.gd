extends CharacterBody2D
#class_name Player

signal player_died
signal player_respawn

@onready var enable_debug_controls = GameManager.enable_debug_controls
var enable_god_mode = false
var enable_no_clip = false
@onready var default_z_index = z_index

#var enable_infinite_jump = false

var disable_physics:bool = false
@onready var spawn_position = Vector2(position.x, position.y)
@onready var checkpoint_position:Vector2 = spawn_position

## for stair/obstacle stepping
@onready var raycast_step_top = $StepTop as RayCast2D
@onready var raycast_step_bottom = $StepBottom as RayCast2D
@onready var raycast_obstacle_height = $StepMeasure as RayCast2D

## max height of an obstacle that the player can step up on
@export var max_step_height = 8.0
var step_tp_factor = 40
var step_tp_offset = 0.2

# miscellaneous
#@export var push_force = 500.0

# physics
@export var gravity = 980
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_move_speed_ground = 140
@export var max_move_speed_air = 250.0
@export var max_jump_velocity = -300.0
@export var max_drop_velocity = 500.0
#@export var scratch_down_speed = 25.0

@export var acceleration_air_h = 250
@export var acceleration_ground_h = 2500

## Note: Only applied when there is no user input.
@export var friction = 3125
## Note: Only applied when there is no user input. 
## has direct impact on velocity clamping while in air
@export var air_resistance = 250

## x times faster deceleration during change of direction
@export var turn_decel_factor = 10

## factor by which horizontal velocity exponentially decays
## while player is in air, and move key isn't held
#@export var velocity_decay_air_h = 0.96

@onready var coyote_timer = $CoyoteTimer as Timer
@onready var jump_buffer = $JumpBuffer as Timer

# becomes idle after a few seconds of inactivity
@onready var idle_timer = $IdleTimer as Timer
var is_idle

# pushing a moveable item
var is_pushing_item = false


# prevent die function from re-triggering while it's ongoing
var is_dead = false

# disable player movement controls (move, jump, etc..)
var is_movement_disabled = false
var is_jump_disabled = false
var is_jump_key_held #notimplemented
var was_on_floor = false
var was_on_wall = false

var move_direction = 0
var last_move_direction_h = 0
var is_horizontally_flipped = false

# appearance
@onready var animation_player = $AnimationPlayer as AnimationPlayer
@onready var player_sprite = $Sprite2D as Sprite2D

@export var default_color = Color(1.0, 1.0, 1.0)
@export var damage_color = Color(0.76, 0.24, 0.24)

@onready var particles_jump = $JumpParticles as Node2D
@onready var particles_turn_ground = $TurnParticlesGround as Node2D
@onready var death_particles = $DeathParticles as Node2D
@onready var torch = $Torch

# might be better to add the sound players to the items themselves
# and disable any interaction and wait queue free on destroy
@onready var step_sound_player: AudioStreamPlayer = $StepSoundPlayer
@onready var def_pitch_scale = step_sound_player.get_pitch_scale()

# literals
var stand_animation:String = "standing"
var run_animation:String = "run"

var idle1_animation:String = "idle1"
var idle2_animation:String = "idle2"
var idle3_animation:String = "idle3"
var idle4_animation:String = "idle4"

var jump_action:String = "move_jump"
var move_left_action:String = "move_left"
var move_right_action:String = "move_right"

# basic state machine (not really)
enum STATES {
	ON_GROUND,
	IN_AIR,
	#ON_WALL,
}
var current_state
var previous_state


func _ready() -> void:
	# cat should be slightly above the ground when it spawns
	current_state = STATES.IN_AIR
	raycast_step_top.position.y = -max_step_height


func _on_idle_timer_timeout() -> void:
	is_idle = true


func _process(delta: float) -> void:
	player_sprite.flip_h = true if is_horizontally_flipped else false
	
	#print(current_state, "-", randi())
	match current_state:
		STATES.ON_GROUND:
			handle_ground_state_animation(delta)
		STATES.IN_AIR:
			# there is no jump animation, trick the player
			animation_player.set_speed_scale(0.25)
			animation_player.play(run_animation)


func handle_ground_state_animation(_delta):
	animation_player.set_speed_scale(1)
	
	if abs(velocity.x) > 0:
		animation_player.play(run_animation)
	elif is_idle:
		# when player becomes idle (expect stand -> idle)
		if animation_player.assigned_animation == stand_animation:
			animation_player.set_current_animation(idle1_animation)
		
		# play idle animations at random
		var rand_anim = randi()%100
		if !animation_player.is_playing():
			if rand_anim < 30:
				animation_player.play(idle1_animation)
			elif rand_anim >= 30 && rand_anim < 90:
				animation_player.play(idle2_animation)
			elif rand_anim >= 90 && rand_anim < 95:
				animation_player.play(idle3_animation)
			elif rand_anim >= 95 && rand_anim < 100:
				animation_player.play(idle4_animation)
	elif is_pushing_item:
		animation_player.set_speed_scale(0.4)
	else:
		animation_player.play(stand_animation)


func push_movable_items():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("MoveableItem") && collision.get_normal().dot(Vector2(0,1)) == 0:
			is_pushing_item = true
		else:
			is_pushing_item = false


func _physics_process(delta: float) -> void:
	move_direction = Input.get_axis(move_left_action, move_right_action)
	# Input.get_vector()
	
	handle_inputs() # also no clip movement
	if disable_physics == true: return
	
	if is_movement_disabled: 
		move_direction = 0
	
	# update flip state (0 move_direction represents no change) 
	if move_direction:
		is_horizontally_flipped = true if move_direction < 0 else false
	
	raycast_step_top.rotation_degrees = 180 if is_horizontally_flipped else 0
	raycast_step_bottom.rotation_degrees = 180 if is_horizontally_flipped else 0
	
	# handle movement
	match current_state:
		# on floor / coyote period
		STATES.ON_GROUND:
			handle_ground_state_physics(delta)
		STATES.IN_AIR:
			handle_air_state_physics(delta)
		#STATES.ON_WALL:
	
	# land on surface (detect type using raycast)
	if !was_on_floor && is_on_floor():
		AudioManager.play_sound_effect(AudioManager.LAND_DEFAULT)
	# play walk sound
	elif abs(velocity.x) > 50.0 && is_on_floor():
		if not step_sound_player.is_playing():
			step_sound_player.play()
	# slow down if pushing object
	if is_pushing_item:
		step_sound_player.set_pitch_scale(0.7)
	else:
		step_sound_player.set_pitch_scale(def_pitch_scale)

	# keeping track of current info for the next iteration
	was_on_floor = is_on_floor()
	was_on_wall = is_on_wall()
	last_move_direction_h = move_direction
	previous_state = current_state
	
	# results are different before and after
	#print(velocity.x)
	move_and_slide()
	#print(velocity.x)
	
	# check and push moveable items
	# could've done this before move and slide but why?
	push_movable_items()
	#apply_push_force()


func handle_inputs():
	if Input.is_action_just_pressed("restart_level"):
		if is_dead: return
		ScreenTransitions.fade_transition()
		await ScreenTransitions.transition_halfpoint
		if get_tree().current_scene != null:
			get_tree().reload_current_scene.call_deferred()
	
	# some cheats for testing (one frame delay ofcourse)
	if enable_debug_controls:
		debug_controls()
	
	# handle controls while no clipping
	if enable_no_clip:
		var move_by_pixels = 5
		if Input.is_action_pressed("move_up"):
			position.y -= move_by_pixels
		if Input.is_action_pressed("move_down"):
			position.y += move_by_pixels
		if Input.is_action_pressed("move_left"):
			position.x -= move_by_pixels
		if Input.is_action_pressed("move_right"):
			position.x += move_by_pixels


func debug_controls():
	# Reset player position for testing: press 4
	if Input.is_action_just_pressed("debug_teleport_to_spawn"):
		position = spawn_position
		print("Player was teleported to level spawn.")
		
	# toggle god mode
	if Input.is_action_just_pressed("debug_toggle_godmode"):
		enable_god_mode = !enable_god_mode
		if enable_god_mode:
			print("God mode enabled.")
		else:
			print("God mode disabled.")
	
	if Input.is_action_just_pressed("debug_toggle_disable_movement"):
		if is_movement_disabled:
			enable_movement_controls()
			print("Movement controls enabled.")
		else:
			disable_movement_controls()
			print("Movement controls disabled.")
	
	# toggle no clip
	if Input.is_action_just_pressed("debug_toggle_noclip"):
		enable_no_clip = !enable_no_clip
		disable_physics = !disable_physics
		if enable_no_clip:
			print("No clip enabled.")
			z_index = 5
		else:
			print("No clip disabled.")
			z_index = default_z_index


func handle_ground_state_physics(delta):
	# landed on / left the floor in the previous move call
	if ( was_on_floor != is_on_floor() ) && !is_on_floor():
		coyote_timer.start()
	
	if !is_on_floor() && coyote_timer.is_stopped():
		current_state = STATES.IN_AIR
	elif Input.is_action_just_pressed(jump_action) || !jump_buffer.is_stopped():
		current_state = STATES.IN_AIR
		jump()
	
	# horizontal movement
	if move_direction == 0:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		#velocity.x += acceleration_ground_h * delta * move_direction
		#velocity.x = clamp(velocity.x, -max_move_speed_ground, max_move_speed_ground)
		
		if move_direction * velocity.x >= 0:
			velocity.x += acceleration_ground_h * delta * move_direction
			if abs(velocity.x) > max_move_speed_ground:
				velocity.x = move_toward(velocity.x, max_move_speed_ground * move_direction, friction * delta)
				
			# stair stepping
			if raycast_step_bottom.is_colliding() && !raycast_step_top.is_colliding():
				if !was_on_wall:
					raycast_obstacle_height.position.y = raycast_step_bottom.position.y
				
				raycast_obstacle_height.position.y -= step_tp_factor * delta
				if !raycast_obstacle_height.is_colliding():
					position.y += raycast_obstacle_height.position.y - step_tp_offset
				
				# fix double jump coyote bug
				#current_state = STATES.IN_AIR
			
		else:
			velocity.x = move_toward(velocity.x, 0, turn_decel_factor * friction * delta)

		# particles (cutting)
		if move_direction != last_move_direction_h && velocity.y == 0:
			particles_turn_ground.emitting = true
			particles_turn_ground.scale.x = 1 * move_direction
	
	# idle check
	if velocity.x == 0 && velocity.y == 0 && current_state == STATES.ON_GROUND:
		if idle_timer.is_stopped() && !is_idle:
			idle_timer.start()
	else:
		idle_timer.stop()
		is_idle = false


func handle_air_state_physics(delta):
	if previous_state == STATES.ON_GROUND:
		idle_timer.stop()
		is_idle = false
		
	if Input.is_action_just_released(jump_action):
		is_jump_key_held = false
	elif Input.is_action_just_pressed(jump_action):
		jump_buffer.start()
	
	# one frame delay in any action. no movement update (negligible)
	if is_on_floor():
		is_jump_key_held = false
		current_state = STATES.ON_GROUND
	
	#elif is_on_wall_only() && velocity.y >= 0 && Input.is_action_pressed(jump_action):
		#current_state = STATES.ON_WALL
	else:
		if velocity.y < max_drop_velocity:
			velocity.y += gravity * delta
		
		# horizontal movement
		if move_direction == 0:
			#velocity.x *= velocity_decay_air_h
			velocity.x = move_toward(velocity.x, 0, air_resistance * delta)
		else:
			#velocity.x += acceleration_air_h * delta * move_direction
			#velocity.x = clamp(velocity.x, -max_move_speed_air, max_move_speed_air)
			
			if move_direction * velocity.x >= 0:
				velocity.x += acceleration_air_h * delta * move_direction
				if abs(velocity.x) > max_move_speed_air:
					velocity.x = move_toward(velocity.x, move_direction * max_move_speed_air, air_resistance * delta)
			else:
				velocity.x = move_toward(velocity.x, 0, turn_decel_factor * air_resistance * delta)


#func handle_wall_state_physics(delta):
		## scratching down a wall (while holding space)
	#if Input.is_action_pressed(jump_action):
		#velocity.y += gravity * delta
		#velocity.y = clampf(velocity.y, max_jump_velocity, scratch_down_speed)
		##velocity.x = -get_wall_normal().x * max_move_speed_air # not slip off
	#else:
		#velocity.x = get_wall_normal().x * max_move_speed_air
		#velocity.y = max_jump_velocity
		#move_direction = get_wall_normal().x
		#current_state = STATES.IN_AIR

#if is_on_wall_only():
# if was on wall and release space (becomes walljump) within a walljump timer


#func apply_push_force(delta):
	#for i in get_slide_collision_count():
		#var collision = get_slide_collision(i)
		#var collider = collision.get_collider()
		#if collider is RigidBody2D:
			##collider.apply_central_impulse(-collision.get_normal() * push_force)
			#collider.apply_central_force(-collision.get_normal() * push_force)


func jump() -> void:
	if is_jump_disabled:
		return
	
	
	# if randi_range(0,2) == 1 && is_on_floor():
	if is_on_floor():
		particles_jump.emitting = true
	
	# trampoline superjump fix
	velocity.y = max_jump_velocity
	#if randi_range(1,2) == 2:
	AudioManager.play_sound_effect(AudioManager.JUMP)
	
	jump_buffer.stop()
	is_jump_key_held = true


func die():
	if enable_god_mode:
		return
	
	# so that the player doesn't die again while dying
	if is_dead:
		return
	else:
		is_dead = true
	#print(get_tree().current_scene.name)
	
	# damage effect, and death particles
	player_sprite.modulate = damage_color
	death_particles.emitting = true
	await get_tree().create_timer(0.1).timeout
	player_sprite.visible = false
	
	# let the laser go through player
	$CollisionShape2D.set_deferred("disabled", true)
	
	# after the 0.1 second delay, death overlaps the transition
	# and collision is already disabled
	player_died.emit()
	
	# particles remain for a while
	torch.visible = false
	disable_physics = true
	await get_tree().create_timer(0.1).timeout
	death_particles.emitting = false
	
	# respawn/wait time
	await get_tree().create_timer(0.3).timeout
	
	# may have been a better idea to simply reload the scene on death
	# this causes some complications (eg. stuck on a level state)
	respawn_player_at_checkpoint()
	
	# play death transition
	ScreenTransitions.wipe_transition()
	await ScreenTransitions.transition_halfpoint
	
	# reset player only or reload the scene instead
	#get_tree().reload_current_scene.call_deferred()
	#return
	
	# fixes the bug where the collisionshape is still seemingly active while disabled
	# and activates area2d's and falling spikes etc. to die again eg. after falling through a tilemap
	await get_tree().create_timer(0.01).timeout # not needed now
	$CollisionShape2D.set_deferred("disabled", false)
	
	player_sprite.modulate = default_color
	player_sprite.visible = true
	torch.visible = true
	is_dead = false
	
	disable_physics = false
	
	# fix debug conflicts
	if enable_no_clip: disable_physics = true


func set_checkpoint_at_position():
	checkpoint_position = position


# to how it was at the beginnning of the scene
func respawn_player_at_checkpoint():
	current_state = STATES.IN_AIR
	#position = spawn_position
	velocity = Vector2(0, 0)
	position = checkpoint_position
	
	$DefaultCamera2D.reset_smoothing()
	player_respawn.emit()


func disable_movement_controls():
	is_movement_disabled = true
	is_jump_disabled = true


func enable_movement_controls():
	is_movement_disabled = false
	is_jump_disabled = false


func on_level_complete():
	disable_movement_controls()
	
	# save level_data to file when player completes a level
	var level_name = get_tree().current_scene.get_scene_file_path()
	GameManager.level_data[level_name]["completed"] = true
	
	var level_to_unlock = GameManager.level_data[level_name]["unlocks"]
	if level_to_unlock != "":
		GameManager.level_data[level_to_unlock]["unlocked"] = true
	GameManager.save_level_data_to_file.call_deferred()
