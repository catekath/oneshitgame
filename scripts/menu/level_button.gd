extends Button


@export_file var level_path
@export_file var thumb_path
@onready var texture = $TextureRect
@onready var best_time = $VBoxContainer/BestTime
@onready var coins = $VBoxContainer/Coins
@onready var lock: TextureRect = $Lock

# button grow on hover effect
var original_size := scale
var new_size := Vector2(1.1, 1.1)
var anim_duration := 0.1

# hover data
@onready var button_text = text


func _ready() -> void:
	if ResourceLoader.exists(thumb_path):
		texture.texture = load(thumb_path)
	else:
		print("Error loading resource: ", thumb_path, " doesn't exist.")
	
	best_time.visible = false
	coins.visible = false
	lock.visible = false
	
	if GameManager.level_data.has(level_path):
		if !GameManager.level_data[level_path]["unlocked"]:
			disabled = true
			lock.visible = true
			#text = ""
	else:
		# add placeholders that say empty/coming soon..
		if level_path.contains("placeholder"):
			disabled = true
			text = "Empty"
		#else
			# if it's not a placeholder, and not a level(no data), for eg. a test scene
			# it'd still work, if we add null reference checks whenever accessing level data


func _on_pressed() -> void:
	if level_path == null:
		return
	AudioManager.play_sound_effect(AudioManager.MENU_CLICK_2)
	ScreenTransitions.fade_transition()
	GameManager.scene_change_started.emit(level_path)
	await ScreenTransitions.transition_halfpoint
	get_tree().change_scene_to_file(level_path)	


func _on_mouse_entered() -> void:
	if disabled: return
	
	if GameManager.level_data.has(level_path):
		if GameManager.level_data[level_path]["completed"]:
			var time = GameManager.level_data[level_path]["best_time"]
			var milliseconds = int(fmod(time, 1) * 1000)
			var seconds = int(fmod(time, 60))
			var minutes = int(fmod(time, 3600) / 60)
			best_time.text = "%02d:%02d:%03d" % [minutes, seconds, milliseconds]
			
			$VBoxContainer/Coins/Collected.text = "%d/%d" % \
				[GameManager.level_data[level_path]["coins_collected"]\
				,GameManager.level_data[level_path]["coins_total"]]
			
			text = ""
			best_time.visible = true
			#coins.visible = true
			if GameManager.level_data[level_path]["coins_total"] != 0:
				coins.visible = true

	animate_size(new_size, anim_duration)


func _on_mouse_exited() -> void:
	if disabled: return
	
	text = button_text
	best_time.visible = false
	coins.visible = false
	
	animate_size(original_size, anim_duration)


func animate_size(final_size: Vector2, duration: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, 'scale', final_size, duration)
