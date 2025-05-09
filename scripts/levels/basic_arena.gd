extends Node2D

var player = null

func _ready():
	# Spawn player
	spawn_player()

func spawn_player():
	# Get the character scene based on GameManager's selected character
	var character_scene_path = GameManager.character_scenes[GameManager.selected_character]
	var character_scene = load(character_scene_path)
	
	if character_scene:
		# Instance the character
		player = character_scene.instantiate()
		
		# Set position to center of screen or at spawn point if available
		var spawn_position = Vector2(get_viewport_rect().size / 2)
		var spawn_points = get_tree().get_nodes_in_group("player_spawn")
		if spawn_points.size() > 0:
			spawn_position = spawn_points[0].global_position
			
		player.global_position = spawn_position
		
		# Add player to scene
		add_child(player)
		
		# Connect player to HUD
		var hud = $GameUI/HUD
		if hud and hud.has_method("connect_player_signals"):
			hud.connect_player_signals(player)
		
		print("Player spawned: " + GameManager.selected_character)
