extends CanvasLayer

var pause_menu_scene = preload("res://scenes/menu/pause_menu.tscn")
#var temp_node = null
@onready var player = $"../Player"
@onready var level_name = $LevelName
@onready var collected_label = $Coins/Collected

# using HUD to store the total collected coins
@onready var current_scene = get_tree().get_current_scene()
var total_coins = 0
var collected_coins = 0


func _ready() -> void:
	# fetching data
	if GameManager.level_data.has(current_scene.scene_file_path):
		total_coins = GameManager.level_data[current_scene.scene_file_path]["coins_total"]
		collected_label.text = "%d/%d" % [collected_coins, total_coins]
		#if total_coins == 0:
			#$Coins.visible = false
		
		if GameManager.level_data[current_scene.scene_file_path]["name"] != "":
			level_name.text = GameManager.level_data[current_scene.scene_file_path]["name"]
		else:
			# gets name from the scene root (make sure it's always capitalized)
			level_name.text = current_scene.name.replace('_', ' ')


func _input(_event: InputEvent) -> void:
	# toggle pause with esc while in a level
	if Input.is_action_just_pressed("ui_cancel"):
		if ScreenTransitions.is_screen_transitioning:
			return
		if player.is_dead:
			return
		
		# levels instead of levels/level to allow pause for other scenes in levels folder
		if get_tree().get_current_scene().scene_file_path.contains("res://scenes/levels/"):
			if !get_tree().paused:
				get_tree().paused = true
				#get_tree().set_deferred("paused", true)
				add_child(pause_menu_scene.instantiate())
				#temp_node = pause_menu_scene.instantiate()
				#add_child(temp_node)
			
			# this code will not run unless process set to always
			# so, esc only works to pause the game, does not unpause it
			else:
				print("therefore, this should never print")
				get_tree().paused = false
				#get_tree().set_deferred("paused", false)
				#if temp_node:
					#remove_child(temp_node)


# save count to level data
func on_coin_collected():
	collected_coins += 1
	
	# update HUD
	collected_label.text = "%d/%d" % [collected_coins, total_coins]


func on_level_complete():
	var path = current_scene.scene_file_path
	if GameManager.level_data[path]["coins_collected"] < collected_coins:
		GameManager.level_data[path]["coins_collected"] = collected_coins
