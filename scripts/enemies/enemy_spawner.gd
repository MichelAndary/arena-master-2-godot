extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0  # Time between spawns
@export var max_enemies: int = 20  # Maximum enemies at once
@export var max_total_enemies: int = 20  # Total enemies to spawn for the stage

var spawn_timer = 0.0
var enemies_spawned = 0
var active_enemies = 0
var signal_connected = false

func _ready():
	# Add to group for easy access
	add_to_group("enemy_spawner")
	# Set the total number of enemies for this stage
	GameManager.enemies_total = max_total_enemies
	
	# Set scaling based on current stage
	update_stage_difficulty()
	
	# Reset enemies_killed to ensure it starts from 0 for this stage
	GameManager.enemies_killed = 0
	
	# Connect to enemy_killed signal to track active enemies
	# IMPORTANT: Only connect once to avoid recursive calls
	if !signal_connected:
		GameManager.connect("enemy_killed", Callable(self, "_on_enemy_killed"))
		signal_connected = true

func _process(delta):
	# If we've spawned all enemies, just return
	if enemies_spawned >= max_total_enemies:
		return
	
	# If we have max active enemies, don't spawn more yet
	if active_enemies >= max_enemies:
		return
	
	# Update timer and spawn if ready
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0
		spawn_enemy()

func spawn_enemy():
	# Only spawn if we haven't reached the total
	if enemies_spawned >= max_total_enemies:
		return
	
	# Create enemy instance
	var enemy = enemy_scene.instantiate()
	
	# Determine enemy type based on stage progression
	var enemy_type = determine_enemy_type()
	
	# Set visual appearance based on type
	if enemy.has_node("Sprite"):
		var enemy_sprite = enemy.get_node("Sprite")
		# Adjust size and color based on type
		match enemy_type:
			"small":
				enemy_sprite.scale = Vector2(1.0, 1.0)
				enemy_sprite.modulate = Color(1.0, 0.2, 0.2)  # Red
			"medium":
				enemy_sprite.scale = Vector2(1.3, 1.3)
				enemy_sprite.modulate = Color(1.0, 0.6, 0.2)  # Orange
			"large":
				enemy_sprite.scale = Vector2(1.6, 1.6)
				enemy_sprite.modulate = Color(0.7, 0.2, 0.7)  # Purple
			"boss":
				enemy_sprite.scale = Vector2(2.0, 2.0)
				enemy_sprite.modulate = Color(0.9, 0.9, 0.2)  # Yellow
	
	# Apply scaled stats
	enemy.max_health = GameManager.get_scaled_enemy_health(enemy_type)
	enemy.health = enemy.max_health
	enemy.damage = GameManager.get_scaled_enemy_damage(enemy_type)
	enemy.movement_speed = GameManager.get_scaled_enemy_speed(enemy_type)
	
	# Update enemy name to reflect type
	enemy.enemy_name = enemy_type.capitalize() + " Enemy"
	
	# Set behavior based on type
	match enemy_type:
		"small":
			# Fast but weak
			enemy.movement_speed *= 1.2
		"medium":
			# Balanced
			pass
		"large":
			# More health, slower
			enemy.max_health *= 1.1
			enemy.health = enemy.max_health
		"boss":
			# Special behavior for bosses
			enemy.attack_range *= 1.5  # Longer attack range
			# You could also set custom properties for special attacks
	
	# Set random position on the edge of the screen
	var viewport_size = get_viewport_rect().size
	var spawn_position = Vector2.ZERO
	
	# Choose random side of the screen
	var side = randi() % 4
	match side:
		0: # Top
			spawn_position = Vector2(randf_range(0, viewport_size.x), 0)
		1: # Right
			spawn_position = Vector2(viewport_size.x, randf_range(0, viewport_size.y))
		2: # Bottom
			spawn_position = Vector2(randf_range(0, viewport_size.x), viewport_size.y)
		3: # Left
			spawn_position = Vector2(0, randf_range(0, viewport_size.y))
	
	# Set enemy position
	enemy.global_position = spawn_position
	
	# Add enemy to the scene
	add_child(enemy)
	
	# Update counters
	enemies_spawned += 1
	active_enemies += 1
	
	

func _on_enemy_killed():
	active_enemies -= 1
	
	# Check if all enemies are killed
	if enemies_spawned >= max_total_enemies and active_enemies <= 0:
		# All enemies defeated, open portal
		print("All enemies defeated! Opening portal...")
		
		# We need to give a slight delay to ensure the last enemy's
		# soul essence has been created before we try to collect it
		await get_tree().create_timer(0.5).timeout
		
		 # Freeze time - add this line
		GameManager.freeze_time = true
		
		# Apply glitch effect to timer - add this line
		var hud = get_tree().get_first_node_in_group("game_hud")
		if hud and hud.has_method("start_timer_glitch_effect"):
			hud.start_timer_glitch_effect()
		
		open_portal()

func open_portal():
	print("All enemies defeated! Opening portals...")
	
	# Collect 50% of uncollected soul essence
	collect_remaining_essence()
	
	# Determine which portals to spawn
	var spawn_shop = randf() < 0.15  # 15% chance
	var spawn_challenge = randf() < 0.10  # 10% chance
	
	# Use absolute coordinates for a 1920x1080 stage
	var stage_width = 1920
	var stage_height = 1080
	
	# Create a reference to the level node (or main scene node)
	var level_node = get_tree().current_scene
	
	# Main portal - CENTER-NORTH position (always spawns)
	var main_portal = load("res://scenes/portals/portal.tscn").instantiate()
	main_portal.portal_type = main_portal.PortalType.NEXT_STAGE
	# Position it in the center-top area
	main_portal.position = Vector2(stage_width / 2, 200)
	level_node.add_child(main_portal)
	main_portal.activate()
	
	# Shop portal - WEST position (chance-based)
	if spawn_shop:
		var shop_portal = load("res://scenes/portals/portal.tscn").instantiate()
		shop_portal.portal_type = shop_portal.PortalType.SHOP
		# Position it on the left side, center-height
		shop_portal.position = Vector2(200, stage_height / 2)
		level_node.add_child(shop_portal)
		shop_portal.activate()
	
	# Challenge portal - EAST position (chance-based)
	if spawn_challenge:
		var challenge_portal = load("res://scenes/portals/portal.tscn").instantiate()
		challenge_portal.portal_type = challenge_portal.PortalType.CHALLENGE
		# Position it on the right side, center-height
		challenge_portal.position = Vector2(stage_width - 200, stage_height / 2)
		level_node.add_child(challenge_portal)
		challenge_portal.activate()

func collect_remaining_essence():
	# Find all soul essence items in the scene
	var essence_items = get_tree().get_nodes_in_group("soul_essence")
	var total_collected = 0
	
	# Get player reference
	var player = get_tree().get_first_node_in_group("player")
	
	# For each item, collect 50% of its value and magnetize
	for item in essence_items:
		# Calculate 50% value
		var half_value = ceil(item.value / 2.0)  # Round up to nearest integer
		total_collected += half_value
		
		# Update item's value to the reduced amount
		item.value = half_value
		
		# Find player if not already found
		if player and not item.player:
			item.player = player
		
		# Set to magnetized - move quickly to player
		item.magnetized = true
		item.move_speed = 300  # Make them move faster than normal pickup
		
		print("Soul essence item magnetized with value: " + str(half_value))
	
	print("Total soul essence to be collected: " + str(total_collected))
	print("===DEBUG===")
	print("Total soul essence to be collected: " + str(total_collected))
	print("Current GameManager.soul_essence before collection: " + str(GameManager.soul_essence))
	print("===========")

func update_stage_difficulty():
	# Update spawning parameters based on current stage
	spawn_interval = GameManager.get_scaled_spawn_interval()
	max_total_enemies = GameManager.get_enemies_per_stage()
	
	# Update GameManager's enemies_total
	GameManager.enemies_total = max_total_enemies
	
	print("Stage " + str(GameManager.current_stage) + " difficulty: " +
		  "Spawn interval: " + str(spawn_interval) + ", " +
		  "Total enemies: " + str(max_total_enemies))

# New function to determine enemy type based on stage
func determine_enemy_type():
	# Simple implementation - increase chance of stronger enemies in later stages
	var chance = randf()
	
	# Stage-based probabilities
	var medium_chance = min(0.1 + (GameManager.current_stage - 1) * 0.05, 0.4)
	var large_chance = min(0.05 + (GameManager.current_stage - 1) * 0.03, 0.2)
	
	if GameManager.current_stage >= 10 and chance < 0.05:
		return "boss"  # Rare boss chance in later stages
	elif chance < large_chance:
		return "large"
	elif chance < large_chance + medium_chance:
		return "medium" 
	else:
		return "small"
