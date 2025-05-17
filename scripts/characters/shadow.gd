extends Node2D

# Shadow properties
var enemy_type = ""
var health = 30
var max_health = 30
var damage = 5
var attack_range = 60
var follow_range = 150
var detection_range = 250
var move_speed = 100

var owner_ref = null  # Reference to the player that summoned this
var target = null     # Current target to attack
var attack_cooldown = 1.0
var attack_timer = 0.0

enum State {IDLE, FOLLOWING, ATTACKING}
var current_state = State.IDLE

var formation_index = 0  # Position in formation
var formation_spacing = 40  # Distance between shadows
var formation_row_size = 3  # Max shadows per row
var desired_position = Vector2.ZERO  # Where this shadow should be in formation

#collision-related variables
var collision_radius = 15  # Radius for collision detection
var avoid_force = 1.5      # Strength of avoidance behavior
var other_shadows = []     # Reference to other shadows

func _ready():
	# Add to shadows group
	add_to_group("shadows")
	
	# Setup collision and area detection
	setup_collision()
	
	# Set name
	name = "Shadow_" + enemy_type
	
	 # Add a small shadow effect
	modulate.a = 0.8  # Semi-transparent
	
	# Spawn animation
	scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	# Get all existing shadows to avoid
	call_deferred("update_shadow_references")
	
func update_shadow_references():
	# Wait a frame to ensure all shadows are in the scene
	await get_tree().process_frame
	
	# Update references to other shadows
	other_shadows = get_tree().get_nodes_in_group("shadows")
	other_shadows.erase(self)  # Remove self from list

func setup_collision():
	# Create area for detecting enemies
	var detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	add_child(detection_area)
	
	# Add collision shape
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = detection_range
	collision_shape.shape = circle_shape
	detection_area.add_child(collision_shape)
	
	# Connect signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

func _process(delta):
	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta
	
	# State machine
	match current_state:
		State.IDLE:
			process_idle_state(delta)
		State.FOLLOWING:
			process_following_state(delta)
		State.ATTACKING:
			process_attacking_state(delta)
	
	# Update shadow references occasionally
	if Engine.get_frames_drawn() % 60 == 0:  # Every ~1 second
		update_shadow_references()

func process_idle_state(delta):
	# If we have a target, start attacking
	if target and is_instance_valid(target):
		current_state = State.ATTACKING
		return
	
	# If we have an owner and we're too far, start following
	if owner_ref and is_instance_valid(owner_ref):
		var distance = global_position.distance_to(owner_ref.global_position)
		if distance > follow_range:
			current_state = State.FOLLOWING

func process_following_state(delta):
	# If we found a target, attack it
	if target and is_instance_valid(target):
		current_state = State.ATTACKING
		return
	
		# If we have an owner, follow in formation
	if owner_ref and is_instance_valid(owner_ref):
		# Calculate desired position in formation
		update_formation_position()
		
		# Calculate direction to move
		var direction = (desired_position - global_position).normalized()
		
		# Apply separation force to avoid other shadows
		var separation = calculate_separation()
		
		# Combine movement and separation
		var movement = (direction + separation * avoid_force).normalized()
		
		# Calculate distance to desired position
		var distance = global_position.distance_to(desired_position)
		
		if distance <= 10 and separation.length() < 0.1:
			# We're close enough to our position and not being pushed, go idle
			current_state = State.IDLE
			return
		
		# Move toward formation position with avoidance
		position += movement * move_speed * delta
	else:
		# No owner, just stay idle
		current_state = State.IDLE

func process_attacking_state(delta):
	# If target is gone, go back to following
	if !target or !is_instance_valid(target):
		target = find_nearest_enemy()
		if !target:
			current_state = State.FOLLOWING
			return
	
	# Calculate direction to target
	var direction = Vector2.ZERO
	
	# Move toward target if not in range
	var distance = global_position.distance_to(target.global_position)
	if distance > attack_range:
		direction = (target.global_position - global_position).normalized()
	
	# Apply separation force to avoid other shadows
	var separation = calculate_separation()
	
	# Combine movement and separation
	var movement = (direction + separation * avoid_force).normalized()
	
	# Only apply movement if we're not at attack range or if being pushed by other shadows
	if distance > attack_range || separation.length() > 0.1:
		position += movement * move_speed * delta
	
	# In range, attack if cooldown is ready
	if distance <= attack_range && attack_timer <= 0:
		attack_target()
		attack_timer = attack_cooldown

func attack_target():
	if target and is_instance_valid(target):
		print(enemy_type + " shadow attacks " + target.name)
		
		# Deal damage
		if target.has_method("take_damage"):
			target.take_damage(damage, owner_ref)
			
			# Visual feedback
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest = null
	var min_distance = 9999999
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < detection_range and distance < min_distance:
			nearest = enemy
			min_distance = distance
	
	return nearest

func _on_detection_area_body_entered(body):
	if body.is_in_group("enemies") and (!target or !is_instance_valid(target)):
		target = body
		current_state = State.ATTACKING

func _on_detection_area_body_exited(body):
	if body == target:
		target = find_nearest_enemy()
		if !target:
			current_state = State.FOLLOWING

func take_damage(amount):
	health -= amount
	print(enemy_type + " shadow took " + str(amount) + " damage")
	
	if health <= 0:
		die()

func die():
	print(enemy_type + " shadow has died")
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.5)
	tween.tween_callback(queue_free)

func update_formation_position():
	if owner_ref and is_instance_valid(owner_ref):
		# Check if enemies are nearby to determine formation type
		var enemies = get_tree().get_nodes_in_group("enemies")
		var combat_mode = false
		var nearest_enemy = null
		
		for enemy in enemies:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < detection_range:
				combat_mode = true
				if nearest_enemy == null or distance < global_position.distance_to(nearest_enemy.global_position):
					nearest_enemy = enemy
		
		var offset = Vector2.ZERO
		
		if combat_mode and nearest_enemy:
			# Combat formation - spread out facing the enemy
			var enemy_dir = (nearest_enemy.global_position - owner_ref.global_position).normalized()
			var perpendicular = Vector2(-enemy_dir.y, enemy_dir.x)
			
			# Spread out perpendicular to enemy direction
			offset = perpendicular * (formation_index - (owner_ref.shadow_list.size()-1)/2.0) * formation_spacing
			
			# Add a forward component to form a semicircle
			offset += enemy_dir * 60
		else:
			# Standard following formation (circular or grid)
			var angle = (formation_index / float(max(1, owner_ref.shadow_list.size()-1))) * TAU
			var radius = min(60 + owner_ref.shadow_list.size() * 5, 120)
			offset = Vector2(cos(angle) * radius, sin(angle) * radius)
		
		# Set desired position
		desired_position = owner_ref.global_position + offset

# Function to calculate separation force
func calculate_separation():
	var separation_force = Vector2.ZERO
	var too_close_count = 0
	
	# Check distance to other shadows
	for shadow in other_shadows:
		if is_instance_valid(shadow):
			var distance = global_position.distance_to(shadow.global_position)
			var min_distance = collision_radius + shadow.collision_radius
			
			if distance < min_distance:
				# Too close, calculate repulsion force
				var pushback = global_position - shadow.global_position
				if pushback.length() > 0:  # Prevent zero division
					pushback = pushback.normalized()
					# Force is stronger when closer
					var force = (min_distance - distance) / min_distance
					separation_force += pushback * force
					too_close_count += 1
	
	# Average the force if we found any
	if too_close_count > 0:
		separation_force /= too_close_count
	
	return separation_force
