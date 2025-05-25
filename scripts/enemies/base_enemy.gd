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
var detection_range = 9999
var attack_cooldown = 1.0
var attack_timer = 0.0
var stun_timer = 0.0

# Targeting behavior
var target_priority = "closest"
var push_through_others = false
var charge_speed_multiplier = 1.0
var effective_detection_range = 300.0

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
func shadow_behavior(_delta):
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
func enemy_behavior(_delta):
	# Set detection range (use override if specified, otherwise use default)
	if effective_detection_range <= 9999:
		effective_detection_range = detection_range
	
	var potential_targets = []
	
	# Gather targets based on priority
	match target_priority:
		"player_only":
			var player = get_tree().get_first_node_in_group("player")
			if player:
				potential_targets.append(player)
		"shadows_only":
			potential_targets = get_tree().get_nodes_in_group("shadows")
		"closest":
			var player = get_tree().get_first_node_in_group("player")
			if player:
				potential_targets.append(player)
			potential_targets.append_array(get_tree().get_nodes_in_group("shadows"))
	
	# Find the closest valid target
	var closest_target = null
	var closest_distance = 99999
	
	for potential_target in potential_targets:
		if is_instance_valid(potential_target):
			# For shadows, check if they're actually alive
			var is_target_alive = true
			if potential_target.has_method("get_current_state"):
				is_target_alive = potential_target.get_current_state() != State.DEAD
			
			if is_target_alive:
				var distance = global_position.distance_to(potential_target.global_position)
				if distance < effective_detection_range and distance < closest_distance:
					closest_target = potential_target
					closest_distance = distance
	
	# Set target and chase
	if closest_target:
		target = closest_target
		current_state = State.CHASING
	else:
		target = null
		velocity = Vector2.ZERO

func process_chase_state(_delta):
	# Always re-evaluate closest target (Brotato style)
	enemy_behavior(_delta)
	
	if !target or !is_instance_valid(target):
		current_state = State.IDLE
		return
	
	# Move toward target
	var direction = (target.global_position - global_position).normalized()
	var current_speed = movement_speed * charge_speed_multiplier
	
	# Apply separation only if enemy can't push through others
	if not push_through_others:
		var separation = Vector2.ZERO
		var entities = get_tree().get_nodes_in_group("enemies")
		var sep_count = 0
		
		for entity in entities:
			if entity != self:
				var dist = global_position.distance_to(entity.global_position)
				if dist < 90:
					separation += global_position - entity.global_position
					sep_count += 1
		
		if sep_count > 0:
			separation = separation.normalized() * 1
			direction = (direction + separation).normalized()
	
	velocity = direction * current_speed
	move_and_slide()
	
	# Check if close enough to attack
	if global_position.distance_to(target.global_position) < attack_range:
		current_state = State.ATTACKING
	
	


func process_attack_state(_delta):
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

func process_stunned_state(_delta):
	# Can't do anything while stunned
	velocity = Vector2.ZERO
	move_and_slide()

func process_dead_state(_delta):
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
			if target.has_method("take_damage"):
				target.take_damage(damage, owner_ref)
		else:
			# Shadow shouldn't attack player or other shadows
			current_state = State.IDLE
	else:
		# Enemy attacking player OR shadows
		if target.is_in_group("player") or target.is_in_group("shadows"):
			if target.has_method("take_damage"):
				target.take_damage(damage)
		else:
			# Enemy shouldn't attack other enemies
			current_state = State.IDLE

func take_damage(amount, source=null):
	# Don't take damage if already dead
	if current_state == State.DEAD:
		return
	
	# Check if this is a shadow
	#if is_shadow:
		# Shadows can only be damaged by enemies, not by player
		#var sourceInPlayerGroup = source != null and source is Node and source.is_in_group("player")
		#if source == null or sourceInPlayerGroup:
			#print(enemy_name + " (shadow) ignored damage from player")
			#return
	
	# Process damage normally
	health -= amount
	
	# Show damage number
	if get_node_or_null("/root/DamageManager") != null:
		DamageManager.show_damage(amount, global_position, DamageManager.NORMAL)
	
	
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
	
	# If this is a shadow, notify the owner and add to dead list
	if is_shadow and owner_ref and is_instance_valid(owner_ref):
		# Find the shadow data that corresponds to this shadow
		var shadow_data = null
		for available_shadow in owner_ref.available_shadows:
			if available_shadow.enemy_type == enemy_name.replace("Shadow ", ""):
				shadow_data = available_shadow
				break
		
		# Add to dead shadows list so it can't be resummoned
		if shadow_data:
			owner_ref.dead_shadows.append(shadow_data)
		
		# Remove from owner's shadow list
		owner_ref.remove_shadow(self)
	else:
		# Regular enemy death
		GameManager.enemies_killed += 1
		GameManager.emit_signal("enemy_killed")
	
	# If killed by a player, notify them
	if source and source.has_method("on_enemy_killed"):
		source.on_enemy_killed(self)
	
	# Spawn soul essence only for regular enemies, not shadows
	if not is_shadow:
		var soul_essence_scene = load("res://scenes/pickups/soul_essence.tscn")
		if soul_essence_scene:
			var soul = soul_essence_scene.instantiate()
			soul.value = 1  # Basic value
			soul.global_position = global_position
			get_tree().current_scene.call_deferred("add_child", soul)
	
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
	
	# Change collision layer/mask for shadows
	collision_layer = 4  # Layer 3 (Shadows)
	collision_mask = 2   # Only collide with enemies (Layer 2)
	
	# IMPORTANT: Make sure we're removed from enemies group
	if is_in_group("enemies"):
		remove_from_group("enemies")
		print(enemy_name + " removed from 'enemies' group")
	
	# IMPORTANT: Make sure we're in shadows group
	if not is_in_group("shadows"):
		add_to_group("shadows")
		print(enemy_name + " added to 'shadows' group")
	
	# Appearance
	modulate = Color(0.2, 0.2, 0.2, 0.8)
	
	# Reset state
	current_state = State.IDLE
	target = null
	
	# Debug print
	print(enemy_name + " is now a shadow. Groups: " + str(get_groups()))
