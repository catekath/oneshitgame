extends GPUParticles2D

var current_camera
var camera_position
var last_camera_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	on_camera_update()

	camera_position = current_camera.get_screen_center_position()
	last_camera_position = camera_position


# fixing rain bunching effect (also not using _process)
func _physics_process(delta: float) -> void:
	camera_position = current_camera.get_screen_center_position()
	var camera_velocity_y = (camera_position.y - last_camera_position.y) / delta
	
	#camera_velocity_y < 0 (camera going up)
	if camera_velocity_y > 0:
		amount_ratio = 1 / pow(1.01, abs(camera_velocity_y))
	else:
		amount_ratio = 1
	#print(camera_velocity_y, ", ", amount_ratio)
	
	global_position.x = camera_position.x
	global_position.y = camera_position.y
	
	camera_position = current_camera.get_screen_center_position()
	last_camera_position = camera_position

# signal not yet added
func on_camera_update():
	current_camera = get_viewport().get_camera_2d()
