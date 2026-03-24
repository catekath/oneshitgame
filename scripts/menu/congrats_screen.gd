extends Control


func _on_return_button_pressed() -> void:
	AudioManager.play_sound_effect(AudioManager.MENU_CLICK)
	GameManager.scene_change_started.emit(GameManager.main_menu_scene)
	get_tree().change_scene_to_packed.call_deferred(GameManager.main_menu_scene)
