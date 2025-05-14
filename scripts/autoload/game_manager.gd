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
	# Save the current soul essence before scene change
	saved_soul_essence = soul_essence
	print("GameManager: Saved soul essence before stage change: " + str(saved_soul_essence))
	
	# Rest of the existing function...
	current_stage += 1
	emit_signal("stage_completed")
	freeze_time = false
	enemies_killed = 0
	current_fragments += 5 * current_stage
	
	# This is critical - we need to delay the scene change slightly
	# to ensure our saved value persists
	call_deferred("_deferred_scene_change")

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
