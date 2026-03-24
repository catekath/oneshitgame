extends Node2D

# this scene is NOT being used as main now
func _ready() -> void:
	get_tree().change_scene_to_packed.call_deferred(GameManager.main_menu_scene)
