extends BaseCharacter
class_name Kairis

# Kairis specific stats
var sp_points = 20  # Shadow Points
var sp_max = 20
var intelligence = 10  # Affects shadow command chance
var shadow_list = []  # List of active shadows
var shadow_limit = 5  # Maximum number of shadows at once

@onready var weapon_animator = $WeaponAnimator
@onready var dagger_hit_area = $WeaponSystem/DaggerHolder/DaggerHitArea

#Skill
var skill_dash_speed = 800
var skill_dash_distance = 350  # Maximum dash distance
var is_skill_dashing = false
var is_invulnerable = false
var dash_rect_width = 60  # Width of the dash attack rectangle
var dash_path_start = Vector2.ZERO  # Start position of dash
var dash_path_end = Vector2.ZERO    # End position of dash
var dash_path_visible = false       # Whether to draw the path

# Kairis signals
signal sp_changed(current, maximum)

func _ready():
	# Override base character properties
	character_name = "Kairis"
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
	if current_state != State.DEAD and skill_timer <= 0 and !is_skill_dashing:
		print("Using Shadow Strike")
		
		# Get mouse position in world coordinates
		var mouse_pos = get_global_mouse_position()
		
		# Calculate dash direction and target
		var dash_direction = (mouse_pos - global_position).normalized()
		var dash_target = global_position + (dash_direction * min(global_position.distance_to(mouse_pos), skill_dash_distance))
		
		# Set up dash path for drawing
		dash_path_start = global_position
		dash_path_end = dash_target
		dash_path_visible = true
		
		# Force redraw to show path
		queue_redraw()
		
		# Wait briefly to show the dash path
		await get_tree().create_timer(0.15).timeout
		
		# Start dash
		current_state = State.USING_SKILL
		skill_timer = skill_cooldown
		is_skill_dashing = true
		is_invulnerable = true
		
		# Store initial position for damage calculation
		var start_pos = global_position
		
		# Make character semi-transparent during dash
		modulate.a = 0.5
		
		# Perform the dash
		var tween = create_tween()
		tween.tween_property(self, "global_position", dash_target, 0.2)
		tween.tween_callback(func(): _finish_skill_dash())
		
		# Damage enemies in the path
		await get_tree().process_frame  # Wait a frame to ensure tween starts
		_damage_enemies_in_rectangle(start_pos, dash_target)

# Override the _draw method to draw the dash path
func _draw():
	if dash_path_visible:
		var direction = (dash_path_end - dash_path_start).normalized()
		var length = dash_path_start.distance_to(dash_path_end)
		
		# Calculate rectangle corners (in local coordinates)
		var perp = Vector2(-direction.y, direction.x) * (dash_rect_width/2)
		var start_to_local = dash_path_start - global_position
		var end_to_local = dash_path_end - global_position
		
		var points = [
			start_to_local + perp,  # Top-left
			end_to_local + perp,    # Top-right
			end_to_local - perp,    # Bottom-right
			start_to_local - perp   # Bottom-left
		]
		
		# Draw filled rectangle
		draw_colored_polygon(points, Color(1, 0, 0, 0.5))

# Function to damage enemies in the rectangular path
func _damage_enemies_in_rectangle(start_pos, end_pos):
	# Get all enemies in the scene
	var enemies = get_tree().get_nodes_in_group("enemies")
	var direction = (end_pos - start_pos).normalized()
	var dash_length = start_pos.distance_to(end_pos)
	var half_width = dash_rect_width / 2
	
	# Perpendicular vector to the dash direction
	var perp = Vector2(-direction.y, direction.x)
	
	# For debugging
	print("Checking enemies in dash rectangle from " + str(start_pos) + " to " + str(end_pos))
	
	# Check each enemy
	for enemy in enemies:
		var enemy_pos = enemy.global_position
		
		# Vector from start to enemy
		var to_enemy = enemy_pos - start_pos
		
		# Project onto dash direction
		var proj_along = to_enemy.dot(direction)
		
		# Check if within dash length
		if proj_along >= 0 and proj_along <= dash_length:
			# Project onto perpendicular direction
			var proj_perp = abs(to_enemy.dot(perp))
			
			# Check if within rectangle width
			if proj_perp <= half_width:
				if enemy.has_method("take_damage"):
					enemy.take_damage(base_damage * 2, self)
					print("Shadow Strike hit " + enemy.name)

# Function to clean up after dash
func _finish_skill_dash():
	is_skill_dashing = false
	is_invulnerable = false
	modulate.a = 1.0  # Restore opacity
	current_state = State.IDLE
	
	# Hide dash path
	dash_path_visible = false
	queue_redraw()

# Override take_damage to check for invulnerability
func take_damage(amount):
	if is_invulnerable:
		print("Attack blocked - invulnerable during skill!")
		return
		
	# Call parent implementation
	super.take_damage(amount)
	
	
	
	

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
