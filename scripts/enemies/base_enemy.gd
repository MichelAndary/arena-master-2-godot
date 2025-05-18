extends CharacterBody2D

# Enemy properties
var enemy_name = "Basic Enemy"
var enemy_type = "small"
var element = "neutral"

# Stats
var health = 30
var max_health = 30
var damage = 5
var defense = 0
var movement_speed = 100

# Combat
var attack_range = 50
var detection_range = 300
var attack_cooldown = 1.0
var attack_timer = 0.0
var stun_timer = 0.0

# Target
var target = null

# State machine
enum State {IDLE, CHASING, ATTACKING, STUNNED, DEAD}
var current_state = State.IDLE

# Shadow properties
var is_shadow = false
var owner_ref = null
var formation_index = 0

func _ready():
	# Add to enemies group
	add_to_group("enemies")
	
	# Initialize
	health = max_health

func _physics_process(delta):
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
	if is_shadow:
		# Shadow behavior - completely separate from enemy behavior
		shadow_behavior(delta)
	else:
		# Regular enemy behavior
		enemy_behavior(delta)

# New function for shadow behavior
func shadow_behavior(delta):
	# Step 1: Find nearest enemy to attack
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy = null
	var nearest_distance = 99999
	
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.current_state != State.DEAD:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_enemy = enemy
				nearest_distance = distance
	
	# Step 2: If found enemy within detection range, chase it
	if nearest_enemy and nearest_distance < detection_range:
		target = nearest_enemy
		
		if nearest_distance <= attack_range:
			# Close enough to attack
			current_state = State.ATTACKING
		else:
			# Chase the enemy
			var direction = (nearest_enemy.global_position - global_position).normalized()
			velocity = direction * movement_speed
			move_and_slide()
	else:
		# Step 3: No enemies, follow owner in formation
		if owner_ref and is_instance_valid(owner_ref):
			var row = formation_index / 3
			var col = formation_index % 3
			
			var offset = Vector2(
				(col - 1) * 40,
				(row + 1) * 40
			)
			
			var formation_pos = owner_ref.global_position + offset
			var distance_to_formation = global_position.distance_to(formation_pos)
			
			if distance_to_formation > 20:
				var direction = (formation_pos - global_position).normalized()
				velocity = direction * movement_speed
				move_and_slide()
			else:
				velocity = Vector2.ZERO
		else:
			velocity = Vector2.ZERO

# New function for enemy behavior
func enemy_behavior(delta):
	# Find player
	var player = get_tree().get_first_node_in_group("player")
	
	# Check if player is in detection range
	if player and global_position.distance_to(player.global_position) < detection_range:
		target = player
		current_state = State.CHASING
	else:
		velocity = Vector2.ZERO

func process_chase_state(delta):
	# If target isn't valid or is dead, go back to idle
	if !target or !is_instance_valid(target) or target.current_state == State.DEAD:
		target = null
		current_state = State.IDLE
		return
	
	# For shadows, don't chase other shadows or the player
	if is_shadow:
		if target.is_in_group("shadows") or target.is_in_group("player"):
			target = null
			current_state = State.IDLE
			return
	else:
		# For enemies, don't chase shadows
		if target.is_in_group("shadows"):
			target = null
			current_state = State.IDLE
			return
	
	# If target is too far, go back to idle
	if global_position.distance_to(target.global_position) > detection_range * 1.5:
		target = null
		current_state = State.IDLE
		return
	
	# Move toward target
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * movement_speed
	move_and_slide()
	
	# Check if close enough to attack
	if global_position.distance_to(target.global_position) < attack_range:
		current_state = State.ATTACKING

func process_attack_state(delta):
	# If target isn't valid or is too far, go back to chasing
	if !target or !is_instance_valid(target) or target.current_state == target.State.DEAD:
		target = null
		current_state = State.IDLE
		return
	
	if global_position.distance_to(target.global_position) > attack_range:
		current_state = State.CHASING
		return
	
	# Stop moving while attacking
	velocity = Vector2.ZERO
	move_and_slide()
	
	# Perform attack when cooldown is ready
	if attack_timer <= 0:
		perform_attack()
		attack_timer = attack_cooldown

func process_stunned_state(delta):
	# Can't do anything while stunned
	velocity = Vector2.ZERO
	move_and_slide()

func process_dead_state(delta):
	# Just in case - ensure we're not moving
	velocity = Vector2.ZERO
	move_and_slide()

func perform_attack():
	if !target or !is_instance_valid(target) or target.current_state == State.DEAD:
		current_state = State.CHASING
		return
	
	if is_shadow:
		# Shadow attacking enemy
		if target.is_in_group("enemies"):
			print(enemy_name + " attacks " + target.name)
			if target.has_method("take_damage"):
				target.take_damage(damage, owner_ref)
		else:
			# Shadow shouldn't attack player or other shadows
			current_state = State.IDLE
	else:
		# Enemy attacking player
		if target.is_in_group("player"):
			print(enemy_name + " attacks " + target.name)
			if target.has_method("take_damage"):
				target.take_damage(damage)
		else:
			# Enemy shouldn't attack shadows
			current_state = State.IDLE

func take_damage(amount, source=null):
	# Don't take damage if already dead
	if current_state == State.DEAD:
		return
	
	# Check if this is a shadow
	if is_shadow:
		# Shadows can only be damaged by enemies, not by player
		var sourceInPlayerGroup = source != null and source is Node and source.is_in_group("player")
		if source == null or sourceInPlayerGroup:
			print(enemy_name + " (shadow) ignored damage from player")
			return
	
	# Process damage normally
	health -= amount
	
	# Show damage number
	if get_node_or_null("/root/DamageManager") != null:
		DamageManager.show_damage(amount, global_position, DamageManager.NORMAL)
	
	print(enemy_name + " took " + str(amount) + " damage! Health: " + str(health) + "/" + str(max_health))
	
	# Check if dead
	if health <= 0:
		die(source)
	else:
		# Visual feedback
		modulate = Color(1, 0.5, 0.5)  # Flash red
		await get_tree().create_timer(0.1).timeout
		# Reset color
		if is_shadow:
			modulate = Color(0.2, 0.2, 0.2, 0.8)  # Back to shadow color
		else:
			modulate = Color(1, 1, 1)  # Normal color

func die(source=null):
	# Change state to dead
	current_state = State.DEAD
	
	# Notify the game manager
	GameManager.enemies_killed += 1
	GameManager.emit_signal("enemy_killed")
	
	# If killed by a player, notify them
	if source and source.has_method("on_enemy_killed"):
		source.on_enemy_killed(self)
	
	print(enemy_name + " has been defeated!")
	
	# Visual feedback
	modulate = Color(0.5, 0.5, 0.5, 0.5)  # Fade out
	
	# Remove from game after a delay
	await get_tree().create_timer(0.5).timeout
	queue_free()
	
func get_current_state():
	return current_state

func convert_to_shadow(owner_node):
	# Basic shadow setup
	is_shadow = true
	owner_ref = owner_node
	enemy_name = "Shadow " + enemy_name
	
	# Groups
	remove_from_group("enemies")
	add_to_group("shadows")
	
	# Appearance
	modulate = Color(0.2, 0.2, 0.2, 0.8)
	
	# Reset state
	current_state = State.IDLE
	target = null
	
	# Print final confirmation with groups
	print(enemy_name + " is now a shadow. Groups: " + str(get_groups()))
