extends Area2D

signal level_complete

@export_file("*.tscn") var target_level_path := ""
var congrats_scene_path = "res://scenes/menu/congrats_screen.tscn"

## show "congratulations, you have beaten the game" screen
@export var final_level:bool = false

@onready var level_complete_text: Label = $CanvasLayer/LevelComplete
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var custom_completion_sound:AudioStream

## teleport without playing any sound or level complete animation
@export var quick_tp:bool = false


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("level_complete_listeners"):
		level_complete.connect(node.on_level_complete)
	
	#var node = $"../HUD/Stopwatch"
	#level_complete.connect(node.on_level_complete)
	#node = $"../Player"
	#level_complete.connect(node.on_level_complete)
	
	level_complete_text.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		get_tree().paused = false
		# prevent retrigger
		set_deferred("monitoring", false)
		
		# this might not be the best way to go about it
		level_complete.emit()
		
		# completion wait / sound effects
		if !quick_tp:
			level_complete_text.visible = true
			if custom_completion_sound == null:
				AudioManager.play_sound_effect(AudioManager.LEVEL_COMPLETE)
			else:
				AudioManager.play_sound_effect(custom_completion_sound)
			animation_player.play("faded_zoom")
			await get_tree().create_timer(2.5).timeout
		
		#AudioManager.play_sound_effect(AudioManager.LEVEL_COMPLETE)
		#await get_tree().create_timer(2.5).timeout
		
		# transition to next level or congratulations screen
		if target_level_path != "":
			ScreenTransitions.arrow_transition()
			GameManager.scene_change_started.emit(target_level_path)
			await ScreenTransitions.transition_halfpoint
			get_tree().change_scene_to_file.call_deferred(target_level_path)
		else:
			if final_level:
				# congratulations, you have beaten the game screen
				await get_tree().create_timer(1).timeout # some extra wait
				
				ScreenTransitions.fade_transition()
				GameManager.scene_change_started.emit(congrats_scene_path)
				await ScreenTransitions.transition_halfpoint
				get_tree().change_scene_to_file.call_deferred(congrats_scene_path)
			
			# if no next level, let the player roam around
			body.enable_movement_controls()
			queue_free.call_deferred()
