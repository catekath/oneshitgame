extends Line2D

# Note:
# Do NOT move the 0th point (mismatch with the raycast position)
# use the transform setting to change the starting point
var player_group = "Player"

## Seconds to wait before activating the laser for the first time.
## Helps to create a time difference between lasers
@export var initial_wait:float = 0.0
## the laser shines at discrete intervals
@export var discontinuous:bool = false
@export var emit_period:float = 2.0 			## in seconds
@export var cooldown_period:float = 1.0 		## in seconds

## the laser scans the area determined by the scan angle.
## (avoid making scanning lasers discontinuous)
@export var scan_mode:bool = false
## total scan angle in degrees
@export_range(0, 360) var scan_angle:int = 60
## time in seconds for one scan cycle
@export var scan_period:float = 4.0
## the direction in which the laser turns
@export var clockwise = false

@onready var raycast = $RayCast2D as RayCast2D

# variables

# if false, raycast is enabled but can't kill player
var is_laser_activated:bool = true
var elapsed_on_time:float = 0.0
var elapsed_off_time:float = 0.0
var fade_duration:float = 0.07

# fix chopped laser at collision point
var line_overlap = 1.4
var player_was_hit = false
@onready var default_laser_width = width


func _ready() -> void:
	if get_point_count() > 1:
		# p0 and p1 are vectors, so if we want a vector from p0 to p1, we do p1 - p0
		raycast.position = get_point_position(0)
		raycast.target_position = get_point_position(1) - get_point_position(0)
		
		# which is why this would've worked fine if p0 was at (0,0)
		#raycast.target_position = get_point_position
	else:
		queue_free()
		
	if initial_wait >= 0.0:
		set_physics_process(false)
		visible = false
		await get_tree().create_timer(initial_wait).timeout
		set_physics_process(true)
		visible = true


func _process(_delta: float) -> void:
	# pulsate effect
	#if randi_range(0, 4) == 3:
	width = default_laser_width + randf_range(0, 2)


func _physics_process(delta: float) -> void:
	if scan_mode == true:
		handle_scan_mode(delta)
	
	if discontinuous:
		handle_discontinuous_mode(delta)
	
	collision_check()
	
	#raycast.force_raycast_update()


func collision_check():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		var collision_point = to_local(raycast.get_collision_point())
		set_point_position(1, collision_point + collision_point.normalized() * line_overlap )
		
		if collider.is_in_group(player_group):
			if is_laser_activated && !player_was_hit:
				player_was_hit = true
				collider.die()
				AudioManager.play_sound_effect(AudioManager.LASER)
		else:
			player_was_hit = false
	else:
		# rotated raycast is the vector from p0 to new_p1 = new_p1 - p0
		set_point_position(1,\
			raycast.target_position.rotated(raycast.rotation) + get_point_position(0))
		
		#set_point_position(1, get_point_position(1).normalized() * target_position.length())
		#set_point_position(1, Vector2.DOWN.rotated(raycast.rotation) * target_position.length())


# to make laser that goes invis, is easier than working with discontinuous
# we are not making a laser that is active but goes invis, whats the point
func handle_scan_mode(delta):
	if !is_laser_activated: return
	
	if clockwise:
		if raycast.rotation <= deg_to_rad(scan_angle):
			raycast.rotation += deg_to_rad(scan_angle) * (delta / scan_period)
		else:
			raycast.rotation = 0
	else:
		if raycast.rotation >= deg_to_rad(-scan_angle):
			raycast.rotation -= deg_to_rad(scan_angle) * (delta / scan_period)
		else:
			raycast.rotation = 0


func handle_discontinuous_mode(delta):
	if is_laser_activated:
		if elapsed_on_time >= emit_period:
			elapsed_off_time = elapsed_on_time - emit_period
			elapsed_on_time = 0.0
			is_laser_activated = false
			self_modulate.a = 0
			#set_point_position(1, Vector2(0,0))
			
		elif elapsed_on_time >= emit_period - fade_duration:
			self_modulate.a -= delta / fade_duration
		#else: # elapsed time < emit_period - fade_duration
			#collision_check()
			
		elapsed_on_time += delta
	else:
		if elapsed_off_time >= cooldown_period:
			elapsed_on_time = elapsed_off_time - cooldown_period
			elapsed_off_time = 0.0
			is_laser_activated = true
			self_modulate.a = 1
			
		elif elapsed_off_time >= cooldown_period - fade_duration / 2:
			self_modulate.a += (2 * delta) / fade_duration
	
	elapsed_off_time += delta
