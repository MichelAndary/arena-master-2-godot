extends CharacterBody2D
class_name BaseEnemy

# Enemy stats
var enemy_name = "Base Enemy" 
var health = 30
var max_health = 30
var movement_speed = 100
var damage = 5
var value = 1  # Soul essence dropped when killed

# Enemy state
enum State {IDLE, CHASING, ATTACKING, STUNNED, DEAD}
var current_state = State.IDLE

# Target variables
var player = null
var attack_range = 60  # Increased from 50
var detection_range = 3000

# Timers
var attack_cooldown = 1.0  # 1 second between attacks
var attack_timer = 0.0
var stun_timer = 0.0

# Debug variables
var debug_mode = false

func _ready():
	# Add to the enemies group
	add_to_group("enemies")
	
	# Initialize
	enemy_name = "Enemy " + str(get_instance_id() % 1000)
	
	# Set initial state
	current_state = State.IDLE
	
	# Find player
	call_deferred("find_player")

func find_player():
	# Wait a small delay to ensure player is spawned
	await get_tree().create_timer(0.1).timeout
	
	# Try to find player by group
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		if debug_mode:
			print(enemy_name + " found player: " + player.name)
	else:
		if debug_mode:
			print(enemy_name + " couldn't find player!")

func _physics_process(delta):
	# If we don't have player reference, try to find it
	if player == null:
		find_player()
		return
		
	# State machine processing
	match current_state:
		State.IDLE:
			process_idle_state(delta)
		State.CHASING:
			process_chase_state(delta)
		State.ATTACKING:
			process_attack_state(delta)
		State.STUNNED:
			process_stunned_state(delta)
		State.DEAD:
			process_dead_state(delta)
	
	# Cooldown timers
	if attack_timer > 0:
		attack_timer -= delta
	
	if stun_timer > 0:
		stun_timer -= delta
		if stun_timer <= 0 and current_state == State.STUNNED:
			current_state = State.IDLE

func process_idle_state(delta):
	# Stop moving
	velocity = Vector2.ZERO
	
	# Check if player is in detection range
	if player and global_position.distance_to(player.global_position) < detection_range:
		if debug_mode:
			print(enemy_name + " detected player at distance " + str(global_position.distance_to(player.global_position)))
		current_state = State.CHASING

func process_chase_state(delta):
	# If player isn't valid or is too far, go back to idle
	if !player or global_position.distance_to(player.global_position) > detection_range * 1.5:
		current_state = State.IDLE
		return
	
	# Move toward player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * movement_speed
	move_and_slide()
	
	# Debug distance
	if debug_mode and Engine.get_frames_drawn() % 60 == 0:  # Once per second
		print(enemy_name + " chasing, distance to player: " + str(global_position.distance_to(player.global_position)))
	
	# Check if close enough to attack
	if global_position.distance_to(player.global_position) < attack_range:
		if debug_mode:
			print(enemy_name + " in attack range! Distance: " + str(global_position.distance_to(player.global_position)))
		current_state = State.ATTACKING

func process_attack_state(delta):
	# If player isn't valid or is too far, go back to chasing
	if !player or global_position.distance_to(player.global_position) > attack_range:
		current_state = State.CHASING
		return
	
	# Stop moving while attacking
	velocity = Vector2.ZERO
	
	# Perform attack when cooldown is ready
	if attack_timer <= 0:
		perform_attack()
		attack_timer = attack_cooldown

func process_stunned_state(delta):
	# Can't do anything while stunned
	velocity = Vector2.ZERO

func process_dead_state(delta):
	# Just in case - ensure we're not moving
	velocity = Vector2.ZERO

func perform_attack():
	if player and global_position.distance_to(player.global_position) < attack_range:
		# Double-check distance (additional safety)
		var distance = global_position.distance_to(player.global_position)
		
		if distance < attack_range:
			if debug_mode:
				print(enemy_name + " attacking! Distance: " + str(distance))
			
			# Deal damage to player
			if player.has_method("take_damage"):
				player.take_damage(damage)
				if debug_mode:
					print(enemy_name + " dealt " + str(damage) + " damage to player")
		else:
			if debug_mode:
				print(enemy_name + " tried to attack but player moved out of range!")

func take_damage(amount, source=null):
	health -= amount
	
	if debug_mode:
		print(enemy_name + " took " + str(amount) + " damage! Health: " + str(health) + "/" + str(max_health))
	
	# Check if dead
	if health <= 0:
		die(source)
	else:
		# Briefly stun
		stun_timer = 0.3
		current_state = State.STUNNED

func die(source=null):
	# Change state to dead
	current_state = State.DEAD
	
	# Notify the game manager about ONLY the kill count
	GameManager.enemies_killed += 1
	GameManager.emit_signal("enemy_killed")
	
	# Drop soul essence - ONLY way to add essence
	drop_soul_essence()
	
	# If killed by a player, notify them
	if source and source.has_method("on_enemy_killed"):
		source.on_enemy_killed(self)
	
	print(enemy_name + " has been defeated!")
	
	# Remove from game
	queue_free()

func drop_soul_essence():
	# Reference to the soul essence scene
	var soul_essence_scene = load("res://scenes/pickups/soul_essence.tscn")
	
	# Each enemy drops ONLY 1 essence with a value of 1-3
	var drop_value = randi() % 3 + 1
	
	print("Enemy " + enemy_name + " dropping 1 soul essence worth: " + str(drop_value))
	
	var soul_essence = soul_essence_scene.instantiate()
	soul_essence.position = global_position
	soul_essence.value = drop_value
	
	# Add to the scene
	get_parent().add_child(soul_essence)
