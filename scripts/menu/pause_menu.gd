extends Control

signal paused
signal unpaused

var options_scene := "res://scenes/menu/ui_options_menu.tscn"

func _ready() -> void:
	for node in get_tree().get_nodes_in_group("paused_unpaused_listeners"):
		paused.connect(node.on_paused)
		unpaused.connect(node.on_unpaused)
	paused.emit()


# no idea why else part is causing this error spam:
# add: Condition "p_elem->_root" is true.
# adding a small delay fixed it
func _input(_event: InputEvent) -> void:
	# toggle pause while in a level
	if Input.is_action_just_pressed("ui_cancel"):
		var options = get_node_or_null("OptionsMenu")
		if options != null:
			# options.queue_free.call_deferred()
			
			# options menu handles its own ui cancel so
			return
		else:
			await get_tree().create_timer(0.01).timeout
			_on_resume_button_pressed.call_deferred()


func _on_resume_button_pressed() -> void:
	AudioManager.play_sound_effect(AudioManager.MENU_CLICK_2)
	get_tree().paused = false
	queue_free.call_deferred()


func _on_options_button_pressed() -> void:
	AudioManager.play_sound_effect(AudioManager.MENU_CLICK)
	var options = load(options_scene).instantiate()
	add_child(options)
	# options spawns at an offset with it's center at top left
	options.position = Vector2(0, 0)


func _on_quit_to_main_menu_button_pressed() -> void:
	AudioManager.play_sound_effect(AudioManager.MENU_CLICK)
	get_tree().paused = false
	GameManager.scene_change_started.emit(GameManager.main_menu_scene)
	get_tree().change_scene_to_packed(GameManager.main_menu_scene)


func _on_tree_exiting() -> void:
	# fix the bug where the tree is paused, but the node is removed (eg. during scene transition)
	get_tree().paused = false
	unpaused.emit()
	#$"../../Player"
