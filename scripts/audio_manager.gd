extends Node

signal music_slider_value_changed

const MENU_MUSIC:AudioStream = preload("res://assets/sounds/Forgotten Lullaby Synth Loop.mp3")
const MENU_CLICK:AudioStream = preload("res://assets/sounds/click_001.ogg")
const MENU_CLICK_2:AudioStream = preload("res://assets/sounds/click_002.ogg")
const COIN_COLLECT:AudioStream = preload("res://assets/sounds/coin_collect.mp3")
const JUMP:AudioStream = preload("res://assets/sounds/jump.mp3")
const LEVEL_COMPLETE:AudioStream = preload("res://assets/sounds/yay-6120.mp3")
const SPIKE:AudioStream = preload("res://assets/sounds/spike.mp3")
const FALLING_SPIKE:AudioStream = preload("res://assets/sounds/falling_spike.mp3")
const TRAMPOLINE:AudioStream = preload("res://assets/sounds/trampoline.mp3")
const LASER:AudioStream = preload("res://assets/sounds/laser2.mp3")
const LAND_DEFAULT:AudioStream = preload("res://assets/sounds/land.mp3")
const WOOD_BOX_DROP:AudioStream = preload("res://assets/sounds/wood_box_drop.mp3")
const CHECK_POINT_SAVED:AudioStream = preload("res://assets/sounds/checkpoint.mp3")

const SFX_BUS:String = "SFX"
const MUSIC_BUS:String = "Music"

@onready var audio_players: Node = $AudioPlayers
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var ambient_player: AudioStreamPlayer = $AmbientPlayer

@onready var music_bus_index = AudioServer.get_bus_index("Music")
@onready var sfx_bus_index = AudioServer.get_bus_index("SFX")
@onready var master_bus_index = AudioServer.get_bus_index("Master")

# set default values for the sliders
# a value of 1 is 0 db
var def_game_vol = 1.0
var def_sfx_vol = 1.0
var def_music_vol = 0.5

# these buses allow us to change vol separate from the ui sliders, or audioplayer's volume_db
# this allows us to define different volume or effects for each level's music/ambient 
@onready var ambient_bus_index = AudioServer.get_bus_index("Ambient")
var def_ambient_vol = 1.0

# if scenes are changed back to back too fast by some nerd
# if this value is true, a previous call is waiting for fade_out animation
var is_waiting_for_animation:bool = false


func _ready() -> void:
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(def_game_vol))
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(def_music_vol))
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(def_sfx_vol))
	AudioServer.set_bus_volume_db(ambient_bus_index, linear_to_db(def_ambient_vol))
	
	music_slider_value_changed.connect(on_music_slider_value_changed)
	
	# when loading first scene
	on_scene_changed()


func play_sound_effect(sound):
	for stream_player:AudioStreamPlayer in audio_players.get_children():
		if not stream_player.is_playing():
			stream_player.stream = sound
			stream_player.bus = SFX_BUS
			stream_player.play()
			break


func play_music(sound):
	if music_player.stream == sound && music_player.is_playing(): return
	music_player.stream = sound
	music_player.play()


# either rain sound for ambient, or some wind sound/city ambient
# i.e. not handling it in rain particles script
func play_ambient(sound):
	if ambient_player.stream == sound && ambient_player.is_playing(): return
	ambient_player.stream = sound
	ambient_player.play()


# fade out music when switched b/w level & menu
func on_scene_change_started(scene):
	if scene == null: return
	
	var scene_path
	if scene is String:
		scene_path = scene
	else: # is PackedScene
		scene_path = scene.resource_path
	
	# we emit the signal before we actually change the scene
	var cur_scene_path = get_tree().current_scene.scene_file_path
	
	# should be menu.tscn but no need for now
	if cur_scene_path.contains("menu") && scene_path.contains("level")\
	|| cur_scene_path.contains("level") && scene_path.contains("menu"):
		animation_player.play("fade_out")
	
	# check if our scene has fully changed
	while(get_tree().current_scene.scene_file_path != scene_path):
		await get_tree().create_timer(0.05).timeout
		#print("waiting ", randi_range(1,20))
	on_scene_changed()


func on_scene_changed():
	if is_waiting_for_animation: return
	
	is_waiting_for_animation = true
	if animation_player.is_playing():
		await animation_player.animation_finished
		# this line was causing problems with setting volume_db few lines down
		#animation_player.play("RESET")
	is_waiting_for_animation = false
	
	var scene = get_tree().current_scene
	if scene == null: return
	
	if scene.name.contains("Level"):
		var song_path = GameManager.level_data[scene.scene_file_path]["level_song"]
		if song_path != "":
			var song = load(song_path) as AudioStream
			if song != music_player.stream:
				play_music(song)
			
			var song_vol:float = GameManager.level_data[scene.scene_file_path]["song_volume"]
			if song_vol != 0.0:
				music_player.volume_db = linear_to_db(song_vol)
			else:
				music_player.volume_db = linear_to_db(1)
		else:
			music_player.stop()
			
		var ambient_path = GameManager.level_data[scene.scene_file_path]["level_ambient"]
		if ambient_path != "":
			var ambient = load(ambient_path) as AudioStream
			if ambient != ambient_player.stream:
				play_ambient(ambient)
			
			var ambient_vol:float = GameManager.level_data[scene.scene_file_path]["ambient_volume"]
			if ambient_vol != 0.0:
				ambient_player.volume_db = linear_to_db(ambient_vol)
			else:
				ambient_player.volume_db = linear_to_db(1)
		else:
			ambient_player.stop()

	elif scene.name == "MainMenu":
		music_player.volume_db = linear_to_db(1)
		play_music(MENU_MUSIC)
	elif scene.name == "CongratsScreen":
		music_player.volume_db = linear_to_db(1)
		var end_screen_music = \
			load("res://assets/sounds/Forgotten Lullaby Music Box Loop.mp3") as AudioStream
		play_music(end_screen_music)


func on_paused():
	AudioServer.set_bus_effect_enabled(music_bus_index, 0, true)


func on_unpaused():
	AudioServer.set_bus_effect_enabled(music_bus_index, 0, false)


# louder music = quieter ambient, and vice versa
func on_music_slider_value_changed():
	if ambient_player.is_playing() && music_player.is_playing():
		var music_db = AudioServer.get_bus_volume_db(music_bus_index)
		AudioServer.set_bus_volume_db(ambient_bus_index, linear_to_db(1 - db_to_linear(music_db)))
	else:
		AudioServer.set_bus_volume_db(ambient_bus_index, linear_to_db(1))
