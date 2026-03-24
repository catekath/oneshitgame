extends Label


var elapsed_time:float = 0.0

# since I'm not making levels that take hours to beat
var minutes:int = 0
var seconds:int = 0
var milliseconds:int = 0


func _process(delta: float) -> void:
	elapsed_time += delta
	milliseconds = int(fmod(elapsed_time, 1) * 1000)
	seconds = int(fmod(elapsed_time, 60))
	minutes = int(fmod(elapsed_time, 3600) / 60)
	#minutes = int(elapsed_time) / 60
	text = "%02d:" % minutes + "%02d:" % seconds + "%03d" % milliseconds
	#print(elapsed_time)


func on_level_complete():
	set_process(false)
	# save completion time
	var level_name = get_tree().current_scene.get_scene_file_path()
	var saved_time = GameManager.level_data[level_name]["best_time"]
	if elapsed_time < saved_time || saved_time == 0.0:
		GameManager.level_data[level_name]["best_time"] = elapsed_time
