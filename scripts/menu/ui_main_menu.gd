extends Control

#@export var play_scene = PackedScene
#@export var options_scene = PackedScene

var options_scene := "res://scenes/menu/ui_options_menu.tscn"
var select_level_scene := "res://scenes/menu/ui_select_level.tscn"
@onready var play_button = $VBoxContainer/PlayButton


func _ready() -> void:
	#play_button.grab_focus()
	pass


func _on_start_button_pressed() -> void:
	# runs latest unlocked level (make sure that level 1 is unlocked)
	AudioManager.play_sound_effect(AudioManager.MENU_CLICK_2)
	ScreenTransitions.fade_transition()
	GameManager.scene_change_started.emit(GameManager.current_level)
	await ScreenTransitions.transition_halfpoint
	if GameManager.current_level != "":
		get_tree().change_scene_to_file(GameManager.current_level)


func _on_options_button_pressed() -> void:
	#release_focus()
	#options.get_node("ReturnButton").grab_focus()
	AudioManager.play_sound_effect(AudioManager.MENU_CLICK)
	var options = load(options_scene).instantiate()
	add_child(options)


func _on_quit_button_pressed() -> void:
	#AudioManager.play_sound_effect(AudioManager.MENU_CLICK)
	get_tree().quit()


func _on_select_level_button_pressed() -> void:
	AudioManager.play_sound_effect(AudioManager.MENU_CLICK)
	var select_levels = load(select_level_scene).instantiate()
	add_child(select_levels)
