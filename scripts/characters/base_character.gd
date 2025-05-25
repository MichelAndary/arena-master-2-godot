extends CharacterBody2D
class_name BaseCharacter

# Character Stats
var character_name = "Base Character"
var health = 100
var max_health = 100
var movement_speed = 200
var base_damage = 10

# State Machine Variables
enum State {IDLE, MOVING, ATTACKING, USING_SKILL, USING_ULTIMATE, DASHING, DEAD}
var current_state = State.IDLE

# Input variables
var input_direction = Vector2.ZERO
var is_dashing = false
var dash_cooldown = 2.0  # 2 seconds cooldown
var dash_timer = 0.0
var dash_speed = 500

# Attack variables
var attack_range = 150
var attack_cooldown = 0.5
var attack_timer = 0.0
var is_attacking = false

# Skill and ultimate cooldowns
var skill_cooldown = 5.0
var skill_timer = 0.0
var ultimate_cooldown = 20.0
var ultimate_timer = 0.0

# Target
var target_enemy = null
var enemies_in_range = []

# Signals
signal health_changed(current, maximum)
signal died
signal skill_used
signal ultimate_used

func _ready():
	# Ensure player is in the player group
	add_to_group("player")
	
	# Initial setup
	update_health_display()

func _physics_process(delta):
	# State machine handling
	match current_state:
		State.IDLE:
			process_idle_state(delta)
		State.MOVING:
			process_movement_state(delta)
		State.ATTACKING:
			process_attack_state(delta)
		State.USING_SKILL:
			process_skill_state(delta)
		State.USING_ULTIMATE:
			process_ultimate_state(delta)
		State.DASHING:
			process_dash_state(delta)
		State.DEAD:
			process_dead_state(delta)
	
	# Update timers
	update_timers(delta)
	
	# Auto-attack if there are enemies in range
	if current_state != State.DEAD and current_state != State.DASHING:
		check_for_targets()
		if target_enemy and attack_timer <= 0:
			auto_attack()

func update_timers(delta):
	# Update cooldown timers
	if attack_timer > 0:
		attack_timer -= delta
	
	if dash_timer > 0:
		dash_timer -= delta
	
	if skill_timer > 0:
		skill_timer -= delta
	
	if ultimate_timer > 0:
		ultimate_timer -= delta

func process_idle_state(_delta):
	# Check for movement input
	get_input()
	if input_direction != Vector2.ZERO:
		current_state = State.MOVING
	
	# Check for ability inputs
	check_ability_inputs()

func process_movement_state(_delta):
	get_input()
	
	if input_direction == Vector2.ZERO:
		current_state = State.IDLE
		return
	
	# Apply movement
	velocity = input_direction * movement_speed
	move_and_slide()
	
	# Check for ability inputs
	check_ability_inputs()

func process_attack_state(_delta):
	# Attack logic handled in auto_attack function
	current_state = State.IDLE

func process_skill_state(_delta):
	# Will be implemented in child classes
	pass

func process_ultimate_state(_delta):
	# Will be implemented in child classes
	pass

func process_dash_state(_delta):
	# Dash logic
	velocity = input_direction.normalized() * dash_speed
	move_and_slide()
	
	# End dash after a short duration
	await get_tree().create_timer(0.2).timeout
	current_state = State.MOVING

func process_dead_state(_delta):
	# Death logic
	# Game over handling
	pass

func get_input():
	# Get movement input direction
	input_direction = Vector2.ZERO
	input_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_direction = input_direction.normalized()

func check_ability_inputs():
	# Check for dash input (Shift key)
	if Input.is_action_just_pressed("dash") and dash_timer <= 0:
		start_dash()
	
	# Check for skill input (E key)
	if Input.is_action_just_pressed("skill") and skill_timer <= 0:
		use_skill()
	
	# Check for ultimate input (Q key)
	if Input.is_action_just_pressed("ultimate") and ultimate_timer <= 0:
		use_ultimate()

func start_dash():
	if input_direction != Vector2.ZERO and current_state != State.DEAD:
		current_state = State.DASHING
		dash_timer = dash_cooldown
		# Play dash effect/animation here

func use_skill():
	# Will be implemented in child classes
	if current_state != State.DEAD:
		print("Using skill")
		current_state = State.USING_SKILL
		# Emit signal that skill was used
		emit_signal("skill_used")
		skill_timer = skill_cooldown

func use_ultimate():
	# Will be implemented in child classes
	if current_state != State.DEAD:
		print("Using ultimate")
		current_state = State.USING_ULTIMATE
		# Emit signal that ultimate was used
		emit_signal("ultimate_used")
		ultimate_timer = ultimate_cooldown

func check_for_targets():
	# Check if there are enemies in range
	var potential_targets = get_tree().get_nodes_in_group("enemies")
	enemies_in_range = []
	
	for enemy in potential_targets:
		# Skip dead enemies
		if enemy.has_method("get_current_state") and enemy.get_current_state() == enemy.State.DEAD:
			continue
			
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= attack_range:
			enemies_in_range.append(enemy)
	
	# If we have targets in range, select the closest one
	if enemies_in_range.size() > 0:
		target_enemy = enemies_in_range[0]
		for enemy in enemies_in_range:
			if global_position.distance_to(enemy.global_position) < global_position.distance_to(target_enemy.global_position):
				target_enemy = enemy
	else:
		target_enemy = null

func auto_attack():
	if target_enemy == null:
		return  # No target, do nothing
		
	if current_state == State.DEAD:
		return  # Dead character can't attack
		
	print(character_name + " attacks " + target_enemy.name)
	attack_timer = attack_cooldown
	
	# Set attacking flag
	is_attacking = true
	
	# Face toward enemy if WeaponSystem exists
	if has_node("WeaponSystem"):
		var direction = target_enemy.global_position - global_position
		if direction.x > 0:
			$WeaponSystem.scale.x = 1  # Face right
		else:
			$WeaponSystem.scale.x = -1  # Face left
	
	# Trigger attack animation
	if has_node("WeaponAnimator"):
		$WeaponAnimator.play("dagger_attack")
		await $WeaponAnimator.animation_finished
	
	# Deal damage to the enemy (only if target still exists)
	if is_instance_valid(target_enemy) and target_enemy.has_method("take_damage"):
		target_enemy.take_damage(base_damage, self)
	
	# Clear attacking flag
	is_attacking = false

func take_damage(amount):
	# Print debug info
	print(character_name + " is taking " + str(amount) + " damage!")
	
	# Show damage popup in red (taken damage)
	DamageManager.show_damage(amount, global_position, DamageManager.TAKEN)
	
	health -= amount
	print(character_name + " now has " + str(health) + "/" + str(max_health) + " health")
	
	update_health_display()
	
	if health <= 0:
		die()

func heal(amount):
	health += amount
	if health > max_health:
		health = max_health
	
	update_health_display()

func update_health_display():
	# Update UI
	emit_signal("health_changed", health, max_health)

func die():
	print(character_name + " has died!")
	current_state = State.DEAD
	emit_signal("died")
	
	# Game over
	GameManager.game_over()

func on_enemy_killed(_enemy):
	# Default behavior when an enemy is killed
	# Will be overridden in child classes
	pass 
