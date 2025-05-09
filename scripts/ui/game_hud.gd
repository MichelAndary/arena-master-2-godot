extends Control

var stage_time = 180  # 3 minutes in seconds
var time_remaining = 180

# References to UI elements
@onready var timer_label = $TopBarContainer/CenterInfoContainer/TimerLabel
@onready var enemy_count_label = $TopBarContainer/CenterInfoContainer/EnemyCountLabel
@onready var hp_bar = $TopBarContainer/PlayerStatsContainer/HPBar
@onready var hp_label = $TopBarContainer/PlayerStatsContainer/HPLabel
@onready var sp_bar = $TopBarContainer/PlayerStatsContainer/SPBar
@onready var sp_label = $TopBarContainer/PlayerStatsContainer/SPLabel

func _ready():
	# Initialize UI
	time_remaining = stage_time
	update_timer_display()
	update_enemy_count()
	
	# Connect to GameManager signals
	GameManager.connect("enemy_killed", Callable(self, "update_enemy_count"))

func _process(delta):
	# Update timer
	if time_remaining > 0:
		time_remaining -= delta
		if time_remaining <= 0:
			time_remaining = 0
			on_timer_expired()
		update_timer_display()

func update_timer_display():
	timer_label.text = "Time: " + GameManager.format_time(int(time_remaining))

func update_enemy_count():
	enemy_count_label.text = "Enemies: " + str(GameManager.enemies_killed) + "/" + str(GameManager.enemies_total)

func connect_player_signals(player):
	# Connect health and SP signals from player
	if player.has_signal("health_changed"):
		player.connect("health_changed", Callable(self, "update_health_display"))
	
	if player is ShadowMonarch and player.has_signal("sp_changed"):
		player.connect("sp_changed", Callable(self, "update_sp_display"))
	
	# Initial update
	update_health_display(player.health, player.max_health)
	if player is ShadowMonarch:
		update_sp_display(player.sp_points, player.sp_max)

func update_health_display(current, maximum):
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "HP: " + str(current) + "/" + str(maximum)

func update_sp_display(current, maximum):
	sp_bar.max_value = maximum
	sp_bar.value = current
	sp_label.text = "SP: " + str(current) + "/" + str(maximum)

func on_timer_expired():
	print("Time's up! Opening portal...")
	
	# In a full implementation, this would spawn a portal
	# For now, just complete the stage after a short delay
	await get_tree().create_timer(3.0).timeout
	GameManager.complete_stage()
