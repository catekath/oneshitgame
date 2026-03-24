extends Control

@onready var game_slider: HSlider = $VBoxContainer2/GridContainer/GameSlider
@onready var music_slider: HSlider = $VBoxContainer2/GridContainer/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer2/GridContainer/SFXSlider


func _ready() -> void:
	if get_parent().name != "PauseMenu":
		$BackgroundGlitch.visible = true
		#$ColorRect.visible = true
	
	var game_bus := AudioServer.get_bus_index("Master")
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	game_slider.value = db_to_linear(AudioServer.get_bus_volume_db(game_bus))
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus))


func _input(_event: InputEvent) -> void:
	# toggle pause while in a level
	if Input.is_action_just_pressed("ui_cancel"):
		queue_free.call_deferred()


func _on_return_button_pressed() -> void:
	AudioManager.play_sound_effect(AudioManager.MENU_CLICK)
	call_deferred("queue_free")


func _on_game_slider_value_changed(value: float) -> void:
	var game_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(game_bus, linear_to_db(value))
	AudioServer.set_bus_mute(game_bus, value < 0.02)


func _on_music_slider_value_changed(value: float) -> void:
	var music_bus := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(music_bus, linear_to_db(value))
	AudioServer.set_bus_mute(music_bus, value < 0.02)
	AudioManager.music_slider_value_changed.emit()


func _on_sfx_slider_value_changed(value: float) -> void:
	var sfx_bus := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(value))
	AudioServer.set_bus_mute(sfx_bus, value < 0.02)
