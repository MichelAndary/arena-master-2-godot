extends CharacterBody2D
class_name BaseEnemy

# Enemy stats
var enemy_name = "Base Enemy" 
var health = 300
var max_health = 30
var movement_speed = 100
var damage = 5
var value = 1  # Soul essence dropped when killed

# Enemy state
enum State {IDLE, CHASING, ATTACKING, STUNNED, DEAD}
var current_state = State.IDLE

# Target variables
var player = null
var attack_range = 50
var detection_range = 3000

# Timers
var attack_cooldown = 1.0  # 1 second between attacks
var attack_timer = 0.0
var stun_timer = 0.0

func _ready():
	# Add to the enemies group
	add_to_group("enemies")
	
	# Try to find the player
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	
	if player == null:
		# Try to find player again
		player = get_tree().get_first_node_in_group("player")
		if player:
			print("Found player: " + player.name)
		else:
			print("Player not found!")
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
	# Check if player is in detection range
	if player and global_position.distance_to(player.global_position) < detection_range:
		current_state = State.CHASING
		return
	
	# Stand still
	velocity = Vector2.ZERO

func process_chase_state(delta):
	# If player isn't valid or is too far, go back to idle
	if !player or player.current_state == player.State.DEAD or global_position.distance_to(player.global_position) > detection_range * 1.5:
		current_state = State.IDLE
		return
	
	# Move toward player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * movement_speed
	move_and_slide()
	
	# Check if close enough to attack
	if global_position.distance_to(player.global_position) < attack_range:
		current_state = State.ATTACKING

func process_attack_state(delta):
	# If player isn't valid or is too far, go back to chasing
	if !player or player.current_state == player.State.DEAD or global_position.distance_to(player.global_position) > attack_range:
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
	if player and global_position.distance_to(player.global_position) < attack_range and player.current_state != player.State.DEAD:
		# Deal damage to player
		if player.has_method("take_damage"):
			# Print debug info
			print("Enemy attacking player!")
			print("Player position: " + str(player.global_position))
			print("Enemy position: " + str(global_position))
			print("Distance: " + str(global_position.distance_to(player.global_position)))
			
			# Deal damage
			player.take_damage(damage)
			print(enemy_name + " attacks player for " + str(damage) + " damage!")

func take_damage(amount, source=null):
	health -= amount
	
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
	
	# Notify the game manager
	GameManager.enemies_killed += 1
	GameManager.soul_essence += value
	GameManager.emit_signal("enemy_killed")
	
	# If killed by a player, notify them
	if source and source.has_method("on_enemy_killed"):
		source.on_enemy_killed(self)
	
	print(enemy_name + " has been defeated! Dropped " + str(value) + " Soul Essence.")
	
	# Remove from game
	queue_free()
