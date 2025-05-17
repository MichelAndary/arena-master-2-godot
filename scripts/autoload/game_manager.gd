extends Node

# Game state
enum GameState {MAIN_MENU, CHARACTER_SELECT, PLAYING, GAME_OVER}
var current_state = GameState.MAIN_MENU
var freeze_time = false

# Player data
var selected_character = "Shadow Monarch"
var player_level = 1
var current_fragments = 0  # Persistent currency
var soul_essence = 0  # In-run currency
var saved_soul_essence = 0
var player_health = 0

# Run data
var current_stage = 0
var enemies_killed = 0
var enemies_total = 20  # This will vary per stage
var run_time = 0
var stage_time = 180  # 3 minutes per stage in seconds

# Signals
signal stage_completed
signal player_died
signal enemy_killed
signal portal_opened
signal soul_essence_collected

# Scene paths
var main_menu_scene = "res://scenes/ui/main_menu.tscn"
var character_select_scene = "res://scenes/ui/character_select.tscn"
var game_scene = "res://scenes/levels/basic_arena.tscn"

# Character data
var character_scenes = {
	"Kairis": "res://scenes/characters/kairis.tscn",
	"Void Master": "res://scenes/characters/void_master.tscn",
	"Thunder Empress": "res://scenes/characters/thunder_empress.tscn"
}

# Character unlocks
var unlocked_characters = ["Kairis"]

# Scaling factors
var health_scale_per_stage = 0.2  # 20% more health per stage
var damage_scale_per_stage = 0.15  # 15% more damage per stage
var speed_scale_per_stage = 0.1   # 10% more speed per stage
var spawn_rate_scale_per_stage = 0.2  # 20% faster spawning per stage

# Base values for stage 1
var base_enemy_health = 30
var base_enemy_damage = 5
var base_enemy_speed = 100
var base_spawn_interval = 2.0
var base_enemies_per_stage = 20

# Maximum scaling factors to prevent extreme difficulty
var max_health_scale = 5.0  # Max 5x health
var max_damage_scale = 4.0  # Max 4x damage
var max_speed_scale = 2.0   # Max 2x speed
var min_spawn_interval = 0.5  # Minimum spawn time

# Player level scaling
var player_level_health_scale = 0.05  # 5% more enemy health per player level
var player_level_damage_scale = 0.05  # 5% more enemy damage per player level

func _ready():
	# Initialize game
	print("Game Manager initialized")

func start_new_game():
	# Reset run-specific variables
	current_stage = 1
	enemies_killed = 0
	soul_essence = 0
	
	# Change to playing state
	current_state = GameState.PLAYING
	
	# Load the game scene
	get_tree().change_scene_to_file(game_scene)

func complete_stage():
	current_stage += 1
	emit_signal("stage_completed")
	
	# Reset game state for next stage
	enemies_killed = 0
	
	# Award fragments (persistent currency)
	current_fragments += 5 * current_stage
	
	# Reset freeze_time flag
	freeze_time = false
	
	# Find and update enemy spawner difficulty if it exists
	var enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if enemy_spawner and enemy_spawner.has_method("update_stage_difficulty"):
		# This will be called after scene change
		call_deferred("_update_spawner_difficulty")
	
	# This would transition to next stage
	get_tree().reload_current_scene()

func _update_spawner_difficulty():
	# Wait for the scene to load
	await get_tree().process_frame
	
	# Find the spawner in the new scene
	var enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if enemy_spawner and enemy_spawner.has_method("update_stage_difficulty"):
		enemy_spawner.update_stage_difficulty()

func _deferred_scene_change():
	# Switch scenes
	get_tree().reload_current_scene()
	
	# We need to wait a tiny bit for the scene to load
	await get_tree().process_frame
	
	# Restore soul essence
	soul_essence = saved_soul_essence
	print("GameManager: Restored soul essence after stage change: " + str(soul_essence))
	
	# Force UI update
	await get_tree().process_frame
	var hud = get_tree().get_first_node_in_group("game_hud")
	if hud and hud.has_method("update_soul_essence_display"):
		hud.update_soul_essence_display()
		print("GameManager: Manually updated HUD with soul essence: " + str(soul_essence))

func game_over():
	current_state = GameState.GAME_OVER
	print("Game Over! Reached stage " + str(current_stage))
	
	# After a delay, return to main menu
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file(main_menu_scene)

func format_time(seconds):
	var minutes = seconds / 60
	var remaining_seconds = seconds % 60
	return "%d:%02d" % [minutes, remaining_seconds]

func get_scaled_enemy_health(enemy_type="small"):
	var base_health = base_enemy_health
	
	# Adjust base health by enemy type
	match enemy_type.to_lower():
		"medium":
			base_health = base_enemy_health * 2
		"large":
			base_health = base_enemy_health * 4
		"boss":
			base_health = base_enemy_health * 10
	
	# Apply stage scaling
	var stage_multiplier = 1.0 + min(health_scale_per_stage * (current_stage - 1), max_health_scale)
	
	# Apply player level scaling
	var player = get_tree().get_first_node_in_group("player")
	var player_level = 1
	if player and player.has_method("get_level"):
		player_level = player.get_level()
	
	var player_multiplier = 1.0 + player_level_health_scale * (player_level - 1)
	
	return int(base_health * stage_multiplier * player_multiplier)

func get_scaled_enemy_damage(enemy_type="small"):
	var base_dmg = base_enemy_damage
	
	# Adjust base damage by enemy type
	match enemy_type.to_lower():
		"medium":
			base_dmg = base_enemy_damage * 1.5
		"large":
			base_dmg = base_enemy_damage * 2.5
		"boss":
			base_dmg = base_enemy_damage * 5
	
	# Apply stage scaling
	var stage_multiplier = 1.0 + min(damage_scale_per_stage * (current_stage - 1), max_damage_scale)
	
	return int(base_dmg * stage_multiplier)

func get_scaled_enemy_speed(enemy_type="small"):
	var base_spd = base_enemy_speed
	
	# Adjust speed by enemy type
	match enemy_type.to_lower():
		"medium":
			base_spd = base_enemy_speed * 0.9  # Slightly slower
		"large":
			base_spd = base_enemy_speed * 0.7  # Slower
		"boss":
			base_spd = base_enemy_speed * 0.6  # Very slow
	
	# Apply stage scaling
	var stage_multiplier = 1.0 + min(speed_scale_per_stage * (current_stage - 1), max_speed_scale)
	
	return int(base_spd * stage_multiplier)

func get_scaled_spawn_interval():
	# Spawn interval decreases (gets faster) with higher stages
	var scaled_interval = base_spawn_interval / (1.0 + spawn_rate_scale_per_stage * (current_stage - 1))
	
	# Ensure minimum spawn interval
	return max(scaled_interval, min_spawn_interval)

func get_enemies_per_stage():
	# Increase enemies per stage
	return base_enemies_per_stage + (current_stage - 1) * 5
