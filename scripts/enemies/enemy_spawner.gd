extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 2.0  # Time between spawns
@export var max_enemies: int = 20  # Maximum enemies at once
@export var max_total_enemies: int = 20  # Total enemies to spawn for the stage

var spawn_timer = 0.0
var enemies_spawned = 0
var active_enemies = 0

func _ready():
	# Set the total number of enemies for this stage
	GameManager.enemies_total = max_total_enemies
	
	# Connect to enemy_killed signal to track active enemies
	GameManager.connect("enemy_killed", Callable(self, "_on_enemy_killed"))

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
		open_portal()

func open_portal():
	# In a full implementation, this would spawn a portal entity
	# For now, just notify the game that the stage is completed
	print("Portal opened! Stage complete.")
	
	# Wait a bit and then complete stage
	await get_tree().create_timer(3.0).timeout
	GameManager.complete_stage()
