extends Control

var stage_time = 180  # 3 minutes in seconds
var time_remaining = 180
var timer_glitching = false
var next_glitch_time = 0.0
var is_currently_glitched = false
var original_timer_position = Vector2.ZERO

# References to UI elements
@onready var timer_label = $TopBarContainer/CenterInfoContainer/TimerLabel
@onready var enemy_count_label = $TopBarContainer/CenterInfoContainer/EnemyCountLabel
@onready var hp_bar = $TopBarContainer/PlayerStatsContainer/HPBar
@onready var hp_label = $TopBarContainer/PlayerStatsContainer/HPLabel
@onready var sp_bar = $TopBarContainer/PlayerStatsContainer/SPBar
@onready var sp_label = $TopBarContainer/PlayerStatsContainer/SPLabel
@onready var soul_essence_label = $TopBarContainer/PlayerStatsContainer/SoulEssenceLabel
@onready var stage_label = $TopBarContainer/CenterInfoContainer/StageLabel

func _ready():
	# Add to group for easy access
	add_to_group("game_hud")
	# Initialize UI
	time_remaining = stage_time
	update_timer_display()
	update_enemy_count()
	update_soul_essence_display()
	update_stage_display()
	
	# Connect to GameManager signals
	GameManager.connect("enemy_killed", Callable(self, "update_enemy_count"))
	GameManager.connect("enemy_killed", Callable(self, "update_soul_essence_display"))
	GameManager.connect("stage_completed", Callable(self, "update_stage_display"))

func _process(delta):
	# Update timer only if time isn't frozen
	if !GameManager.freeze_time:
		if time_remaining > 0:
			time_remaining -= delta
			if time_remaining <= 0:
				time_remaining = 0
				on_timer_expired()
		update_timer_display()
	
	# Handle timer glitch effect if active
	if timer_glitching:
		update_timer_glitch(delta)

func update_timer_display():
	timer_label.text = "Time: " + GameManager.format_time(int(time_remaining))

func update_enemy_count():
	enemy_count_label.text = "Enemies: " + str(GameManager.enemies_killed) + "/" + str(GameManager.enemies_total)

func connect_player_signals(player):
	# Connect health and SP signals from player
	if player.has_signal("health_changed"):
		if not player.health_changed.is_connected(Callable(self, "update_health_display")):
			player.health_changed.connect(Callable(self, "update_health_display"))
	
	if player is Kairis and player.has_signal("sp_changed"):
		if not player.sp_changed.is_connected(Callable(self, "update_sp_display")):
			player.sp_changed.connect(Callable(self, "update_sp_display"))
	
	# Initial update
	update_health_display(player.health, player.max_health)
	if player is Kairis:
		update_sp_display(player.sp_points, player.sp_max)

func update_health_display(current, maximum):
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "HP: " + str(current) + "/" + str(maximum)

func update_sp_display(current, maximum):
	sp_bar.max_value = maximum
	sp_bar.value = current
	sp_label.text = "SP: " + str(current) + "/" + str(maximum)
	
func update_soul_essence_display():
	var value_to_display = int(GameManager.soul_essence)
	soul_essence_label.text = "Soul Essence: " + str(value_to_display)
	print("HUD: Updated soul essence display to: " + str(value_to_display))

func update_stage_display():
	stage_label.text = "Stage: " + str(GameManager.current_stage)

func on_timer_expired():
	print("Time's up! Opening portal...")
	
	# Open portal even if enemies remain
	var enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if enemy_spawner and enemy_spawner.has_method("open_portal"):
		enemy_spawner.open_portal()
	else:
		# Fallback if no spawner found
		await get_tree().create_timer(3.0).timeout
		GameManager.complete_stage()

func start_timer_glitch_effect():
	timer_glitching = true
	is_currently_glitched = false
	next_glitch_time = randf_range(0.1, 0.8) # First glitch happens soon
	
	# Store original properties

	original_timer_position = timer_label.position

# Add this function for updating the glitch
func update_timer_glitch(delta):
	next_glitch_time -= delta
	
	if next_glitch_time <= 0:
		# Toggle glitch state
		is_currently_glitched = !is_currently_glitched
		
		if is_currently_glitched:
			# Apply glitch effect
			# Shift position slightly
			#var position_offset = Vector2(randf_range(-3, 3), randf_range(-3, 3))
			#timer_label.position = original_timer_position + position_offset
			
			# Apply color distortion
			var color_distort = randf_range(0.7, 1.0)
			timer_label.add_theme_color_override("font_color", Color(1.0, color_distort, color_distort))
			
			# Maybe skew or apply other transforms
			timer_label.rotation_degrees = randf_range(-2, 2)
			
			# Set shorter duration for glitch state
			next_glitch_time = randf_range(0.05, 0.2)
		else:
			# Return to normal
			timer_label.position = original_timer_position
			timer_label.remove_theme_color_override("font_color")
			timer_label.rotation_degrees = 0
			
			# Set longer duration for normal state
			next_glitch_time = randf_range(0.3, 0.8)
