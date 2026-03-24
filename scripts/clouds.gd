extends ParallaxLayer

@export var cloud_speed = -20


func _process(delta: float) -> void:
	self.motion_offset.x += cloud_speed * delta
