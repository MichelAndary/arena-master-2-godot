extends BaseCharacter
class_name ShadowMonarch

# Shadow Monarch specific stats
var sp_points = 20  # Shadow Points
var sp_max = 20
var intelligence = 10  # Affects shadow command chance
var shadow_list = []  # List of active shadows
var shadow_limit = 5  # Maximum number of shadows at once

@onready var weapon_animator = $WeaponAnimator
@onready var dagger_hit_area = $WeaponSystem/DaggerHolder/DaggerHitArea

# Shadow Monarch signals
signal sp_changed(current, maximum)

func _ready():
	# Override base character properties
	character_name = "Shadow Monarch"
	max_health = 120
	health = max_health
	base_damage = 15
	
	# Update UI
	update_health_display()
	update_sp_display()
	
	# Call parent ready
	super._ready()

# Connect dagger hit area signals
	if has_node("WeaponSystem/DaggerHolder/DaggerHitArea"):
		var hit_area = $WeaponSystem/DaggerHolder/DaggerHitArea
		hit_area.body_entered.connect(_on_dagger_hit_area_body_entered)

# Override skill method (E key)
func use_skill():
	if current_state != State.DEAD and skill_timer <= 0:
		print("Using Shadow Strike")
		current_state = State.USING_SKILL
		skill_timer = skill_cooldown
		
		# Shadow Strike logic - dash and damage enemies in path
		var strike_direction = input_direction
		if strike_direction == Vector2.ZERO and target_enemy:
			strike_direction = (target_enemy.global_position - global_position).normalized()
		elif strike_direction == Vector2.ZERO:
			strike_direction = Vector2.RIGHT  # Default direction if no input or target
		
		# Move in strike direction
		velocity = strike_direction * dash_speed * 1.5
		move_and_slide()
		
		# Deal damage to enemies in path
		for enemy in enemies_in_range:
			# Calculate if enemy is in the strike path
			var angle_to_enemy = abs(strike_direction.angle_to((enemy.global_position - global_position).normalized()))
			if angle_to_enemy < 0.5:  # About 30 degrees
				if enemy.has_method("take_damage"):
					enemy.take_damage(base_damage * 2, self)  # Double damage
		
		# Return to normal state
		await get_tree().create_timer(0.5).timeout
		current_state = State.IDLE

# Override ultimate method (Q key)
func use_ultimate():
	if current_state != State.DEAD and ultimate_timer <= 0:
		print("Using Command ability")
		current_state = State.USING_ULTIMATE
		ultimate_timer = ultimate_cooldown
		
		# Command logic - summon shadows around the player
		summon_shadows()
		
		# Return to normal state
		await get_tree().create_timer(1.0).timeout
		current_state = State.IDLE

func summon_shadows():
	# In a full implementation, this would open a UI for selecting shadows to summon
	# For now, just automatically summon based on SP
	
	# Try to summon up to 3 shadows at once
	var shadows_to_summon = min(3, sp_points)
	
	for i in range(shadows_to_summon):
		if shadow_list.size() < shadow_limit and sp_points > 0:
			# Spend SP
			sp_points -= 1
			
			# Add to shadow list - in a full implementation, this would instantiate a shadow entity
			shadow_list.append("Shadow_" + str(shadow_list.size() + 1))
			
			print("Summoned a shadow! SP remaining: " + str(sp_points))
	
	# Update UI
	update_sp_display()

func update_sp_display():
	# Update UI with SP values
	emit_signal("sp_changed", sp_points, sp_max)

# Override when enemy killed
func on_enemy_killed(enemy):
	# When Shadow Monarch kills an enemy, there's a chance to gain SP
	
	# Sample logic: 20% chance to gain 1 SP point
	if randf() < 0.2:
		sp_points += 1
		if sp_points > sp_max:
			sp_points = sp_max
		print("Gained 1 SP from defeated enemy. Total: " + str(sp_points))
		update_sp_display()
	
	# In a full implementation, the enemy would be added to available summons
	print("Enemy added to available summons list")

func _on_dagger_hit_area_body_entered(body):
	if body.is_in_group("enemies") and is_attacking:
		# Deal damage to the enemy
		if body.has_method("take_damage"):
			body.take_damage(base_damage, self)
			print("Dagger hit enemy: " + body.name)
