extends Node

signal scene_change_started(scene)

var main_menu_scene = preload("res://scenes/menu/ui_main_menu.tscn")
var current_level:String = ""
var save_path = "user://player_data.save"

# default_level_data is defined at the end of the script
var level_data:Dictionary = {}

var enable_debug_controls = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	scene_change_started.connect(AudioManager.on_scene_change_started)

	# load level data from previous save file
	if FileAccess.file_exists(save_path):
		var save = FileAccess.open(save_path, FileAccess.READ)
		var json_string = save.get_line()
		var json = JSON.new()
		json.parse(json_string)
		level_data = json.get_data()
		save.close()
		print("Loaded level data from save file.")
		
		# update loaded level data with new default level data
		for key in default_level_data:
			if not level_data.has(key):
				level_data[key] = default_level_data[key]
			else:
				# modify entries that can be ovewritten
				for entry in level_data[key]:
					if entry in ["best_time", "unlocked", "completed", "coins_collected"]:
						continue
					else:
						level_data[key][entry] = default_level_data[key][entry]
	else:
		# load default level data
		level_data = default_level_data
		#save_level_data_to_file()
		print("No save file found, loaded default level data.")
	
	# set current level to the last unlocked level
	for key in level_data:
		if level_data[key]["unlocked"] == true:
			current_level = key
	#print("Current level set to ", current_level)
	
	#var root = get_tree().get_root()
	#current_scene = root.get_child(root.get_child_count() - 1)
	#var main_node = get_tree().root.get_node("Main")

	#Input.set_custom_mouse_cursor(cursor_image, Input.CURSOR_ARROW, Vector2(64, 64))


func save_level_data_to_file():
	var save = FileAccess.open(save_path, FileAccess.WRITE)
	var json_string = JSON.stringify(level_data)
	save.store_line(json_string)
	print("Saved level data.")


func _input(_event: InputEvent) -> void:
	 # Toggle fullscreen on F11 press
	if Input.is_action_just_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# HUD gets name from the scene root if not provided
# song/ambient volume is set to max if not non-zero
var default_level_data:Dictionary = {
	"res://scenes/levels/level_01.tscn":{
		"name": "Getting Started",
		"best_time": 0.0,
		"unlocked": true,
		"unlocks": "res://scenes/levels/level_02.tscn",
		"completed": false,
		"coins_collected": 0,
		"coins_total": 1,
		"level_song": "res://assets/sounds/synthwavehouse.ogg",
		"level_ambient": "res://assets/sounds/rooftop_rain.mp3",
		"song_volume": 0.0,
		"ambient_volume": 0.25
	},
	"res://scenes/levels/level_02.tscn":{
		"name": "Moving Platforms",
		"best_time": 0.0,
		"unlocked": false,
		"unlocks": "res://scenes/levels/level_03.tscn",
		"completed": false,
		"coins_collected": 0,
		"coins_total": 2,
		"level_song": "res://assets/sounds/synthwavehouse.ogg",
		"level_ambient": "res://assets/sounds/building-rooftops-ambient-76133.mp3",
		"song_volume": 0.0,
		"ambient_volume": 0.25
	},
		"res://scenes/levels/level_03.tscn":{
		"name": "Lasers",
		"best_time": 0.0,
		"unlocked": false,
		"unlocks": "res://scenes/levels/level_04.tscn",
		"completed": false,
		"coins_collected": 0,
		"coins_total": 2,
		"level_song": "res://assets/sounds/synthwavehouse.ogg",
		"level_ambient": "res://assets/sounds/rooftop_rain.mp3",
		"song_volume": 0.0,
		"ambient_volume": 0.25
	},
	"res://scenes/levels/level_04.tscn":{
		"name": "Falling Spikes",
		"best_time": 0.0,
		"unlocked": false,
		"unlocks": "res://scenes/levels/level_05.tscn",
		"completed": false,
		"coins_collected": 0,
		"coins_total": 1,
		"level_song": "res://assets/sounds/caller.mp3",
		"level_ambient": "res://assets/sounds/building-rooftops-ambient-76133.mp3",
		"song_volume": 0.0,
		"ambient_volume": 0.25
	},
	"res://scenes/levels/level_05.tscn":{
		"name": "Trampolines",
		"best_time": 0.0,
		"unlocked": false,
		"unlocks": "res://scenes/levels/level_06.tscn",
		"completed": false,
		"coins_collected": 0,
		"coins_total": 1,
		"level_song": "res://assets/sounds/caller.mp3",
		"level_ambient": "res://assets/sounds/building-rooftops-ambient-76133.mp3",
		"song_volume": 0.0,
		"ambient_volume": 0.25
	},
		"res://scenes/levels/level_06.tscn":{
		"name": "Movable blocks",
		"best_time": 0.0,
		"unlocked": false,
		"unlocks": "",
		"completed": false,
		"coins_collected": 0,
		"coins_total": 2,
		"level_song": "res://assets/sounds/DOS-88 – Far Away.mp3",
		"level_ambient": "res://assets/sounds/rooftop_rain.mp3",
		"song_volume": 0.0,
		"ambient_volume": 0.25
	}
}
