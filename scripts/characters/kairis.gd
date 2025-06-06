extends BaseCharacter
class_name Kairis

# Create a Shadow data class to store enemy info
class ShadowData:
	var unique_id = ""    # Unique identifier for this specific shadow
	var enemy_id = ""     # Reference to the enemy data resource
	var enemy_type = ""
	var max_health = 0
	var damage = 0
	var sp_cost = 1
	
	func _init(uid, id, type, health, dmg, cost=1):
		unique_id = uid
		enemy_id = id
		enemy_type = type
		max_health = health
		damage = dmg
		sp_cost = cost
	func is_equal(other):
		# Two shadow data objects are considered equal if their properties match
		return enemy_type == other.enemy_type and \
		max_health == other.max_health and \
		damage == other.damage and \
		sp_cost == other.sp_cost
		unique_id == other.unique_id

# Kairis specific stats
var sp_points = 20  # Shadow Points
var sp_max = 20
var intelligence = 10  # Affects shadow command chance
var shadow_list = []  # List of active shadows
var shadow_limit = 8  # Maximum number of shadows at once
var dead_shadows = []  # List of shadow data that died and can't be resummoned
var recently_hit_enemies = []
var shadow_id_counter = 0

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

#Ultimate
var available_shadows = []
var max_available_shadows = 8  # Maximum number we'll track
var summon_ui_scene = preload("res://scenes/ui/summon_ui.tscn")
var summon_ui = null
var summoned_shadows = []  # List of shadow data that has already been summoned

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
		
	# Create and add the summon UI
	summon_ui = summon_ui_scene.instantiate()
	summon_ui.visible = false  # Start hidden
	
	# Connect signals from the UI - IMPORTANT
	summon_ui.connect("shadows_summoned", Callable(self, "_on_shadows_summoned"))
	summon_ui.connect("summon_cancelled", Callable(self, "_on_summon_cancelled"))
	
	# Add to a CanvasLayer to ensure it appears on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10  # High layer number to be on top
	canvas_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(canvas_layer)
	canvas_layer.add_child(summon_ui)

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
		current_state = State.USING_ULTIMATE
		
		# Check shadow limit
		var can_summon = shadow_limit - shadow_list.size()
		if can_summon <= 0:
			print("Shadow limit reached!")
			ultimate_timer = ultimate_cooldown
			current_state = State.IDLE
			return
		
		# Filter out only the permanently dead shadows (by unique ID)
		var available_for_summon = []
		for shadow in available_shadows:
			var is_dead = false
			for dead_shadow in dead_shadows:
				if dead_shadow.unique_id == shadow.unique_id:
					is_dead = true
					break
			
			if not is_dead:
				available_for_summon.append(shadow)
		
		if available_for_summon.size() > 0:
			summon_ui.show_summon_ui(self, available_for_summon)  # Back to 2 parameters
		else:
			print("No shadows available to summon!")
			ultimate_timer = ultimate_cooldown
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
	emit_signal("sp_changed", sp_points, sp_max)

# Override when enemy killed
func on_enemy_killed(enemy):
	# Original implementation for SP gain
	if randf() < 0.2:
		sp_points += 1
		if sp_points > sp_max:
			sp_points = sp_max
		print("Gained 1 SP from defeated enemy. Total: " + str(sp_points))
		update_sp_display()
	
	print("Processing enemy for shadow data: " + enemy.name)
	
	# Create unique shadow data
	var shadow_cost = 1
	var enemy_name = ""
	if enemy.get("enemy_name") != null:
		enemy_name = enemy.enemy_name
	else:
		enemy_name = enemy.name
		
	var enemy_id = "small_enemy"
	
	# Determine cost based on enemy type
	if "medium" in enemy_name.to_lower():
		shadow_cost = 3
		enemy_id = "medium_enemy"
	elif "large" in enemy_name.to_lower() or "boss" in enemy_name.to_lower():
		shadow_cost = 5
		enemy_id = "large_enemy"
	
	# Get enemy stats
	var enemy_health = enemy.get("max_health") if enemy.get("max_health") != null else 30
	var enemy_damage = enemy.get("damage") if enemy.get("damage") != null else 5
	
	# Create shadow with unique ID
	shadow_id_counter += 1
	var unique_shadow_id = enemy_name + "_" + str(shadow_id_counter)
	
	var shadow = ShadowData.new(
		unique_shadow_id,    # Unique ID
		enemy_id,            # Enemy resource ID
		enemy_name,          # Enemy type name
		enemy_health,        # Health
		enemy_damage,        # Damage
		shadow_cost          # SP cost
	)
	
	available_shadows.append(shadow)
	print("Added shadow: " + unique_shadow_id + " (Cost: " + str(shadow_cost) + " SP). Total available: " + str(available_shadows.size()))
	
	# Keep list at maximum size
	if available_shadows.size() > max_available_shadows:
		available_shadows.remove_at(0)

func _on_dagger_hit_area_body_entered(body):
	# Only deal damage if we're actually attacking and haven't hit this enemy yet
	if body.is_in_group("enemies") and is_attacking and !recently_hit_enemies.has(body):
		# Add to recently hit list
		recently_hit_enemies.append(body)
		
		# Clear the list after a short delay
		get_tree().create_timer(0.2).timeout.connect(func(): recently_hit_enemies.clear())
		
		# Deal damage to the enemy
		if body.has_method("take_damage"):
			body.take_damage(base_damage, self)


func _on_shadows_summoned(selected_shadows):
	print("Shadows summoned signal received with " + str(selected_shadows.size()) + " shadows")
	
	if selected_shadows.size() == 0:
		print("No shadows selected")
		current_state = State.IDLE
		return
	
	# Check if summoning would exceed limit
	var would_exceed_limit = shadow_list.size() + selected_shadows.size() > shadow_limit
	if would_exceed_limit:
		print("Cannot summon " + str(selected_shadows.size()) + " shadows - would exceed limit of " + str(shadow_limit))
		current_state = State.IDLE
		return
	
	# Apply cooldown
	ultimate_timer = ultimate_cooldown
	
	# Calculate total SP cost and check if enough SP
	var total_sp_cost = 0
	for shadow in selected_shadows:
		total_sp_cost += shadow.sp_cost
	
	if sp_points < total_sp_cost:
		print("Not enough SP to summon selected shadows")
		current_state = State.IDLE
		return
	
	# Deduct SP
	sp_points -= total_sp_cost
	if sp_points < 0:
		sp_points = 0
	
	# Update UI
	emit_signal("sp_changed", sp_points, sp_max)
	
	# Summon the selected shadows
	for shadow in selected_shadows:
		spawn_shadow(shadow)
	
	# Return to normal state
	current_state = State.IDLE

# Handle cancellation
func _on_summon_cancelled():
	print("Shadow summoning cancelled")
	
	# Apply cooldown anyway
	ultimate_timer = ultimate_cooldown
	
	# Return to normal state
	current_state = State.IDLE

# Spawn a shadow entity from the data
func spawn_shadow(shadow_data):
	print("Spawning shadow: " + shadow_data.enemy_type)
	
	# Create shadow using the factory
	var shadow = EnemyFactory.create_shadow(shadow_data.enemy_id, self)
	
	if shadow == null:
		print("ERROR: Failed to create shadow!")
		return
	
	# Set formation index
	shadow.formation_index = shadow_list.size()
	
	# Position shadow near player
	var row = shadow.formation_index / 3
	var col = shadow.formation_index % 3
	
	var offset = Vector2(
		(col - 1) * 40,
		(row + 1) * 40
	)
	
	shadow.global_position = global_position + offset
	shadow.current_state = shadow.State.IDLE  # Force idle state initially
	
	# Add to scene - use different parent to avoid issues
	get_tree().current_scene.add_child(shadow)
	
	# Make sure shadow is not in enemies group after adding to scene
	if shadow.is_in_group("enemies"):
		shadow.remove_from_group("enemies")
		print("Removed shadow from enemies group after scene addition")

# Verify groups again
	print("Shadow final groups: " + str(shadow.get_groups()))
	
	# Add to shadow list
	shadow_list.append(shadow)
	
	print("Shadow spawned with groups: " + str(shadow.get_groups()))

func remove_shadow(shadow):
	if shadow_list.has(shadow):
		# Get index of the shadow
		var idx = shadow_list.find(shadow)
		
		# Remove from list
		shadow_list.erase(shadow)
		
		# Update formation indices for all shadows after this one
		for i in range(idx, shadow_list.size()):
			shadow_list[i].formation_index = i
		
		print("Shadow removed from list, remaining: " + str(shadow_list.size()))

func get_facing_direction():
	# Return the direction the player is currently facing/moving
	if input_direction != Vector2.ZERO:
		return input_direction.normalized()
	else:
		# Default facing right if not moving
		return Vector2.RIGHT

func reset_summoned_shadows():
	summoned_shadows.clear()
	print("Reset summoned shadows list for new level")

func perform_shadow_entrance():
	# Skip if no shadows
	if shadow_list.size() == 0:
		return
	
	print("Shadows performing entrance animation")
	
	# Create a simple visual effect at player position
	var effect_position = global_position
	
	# Have shadows bow one by one
	for shadow in shadow_list:
		if is_instance_valid(shadow):
			# Animate a bow
			var tween = create_tween()
			tween.tween_property(shadow, "rotation_degrees", 30, 0.3)
			tween.tween_property(shadow, "rotation_degrees", 0, 0.3)
			
			# Small delay between each shadow
			await get_tree().create_timer(0.1).timeout
	
	# After bowing, scatter slightly
	for shadow in shadow_list:
		if is_instance_valid(shadow):
			var random_offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
			var tween = create_tween()
			tween.tween_property(shadow, "position", shadow.position + random_offset, 0.5)

func save_shadow_data():
	var shadow_data = []
	for shadow in shadow_list:
		if is_instance_valid(shadow):
			var data = {
				"unique_id": shadow.enemy_name,  # Use the shadow's name as ID
				"enemy_type": shadow.enemy_name.replace("Shadow ", ""),
				"health": shadow.health,
				"max_health": shadow.max_health,
				"damage": shadow.damage
				"sp_cost": 1
			}
			shadow_data.append(data)
	return shadow_data

func restore_shadow_data(shadow_data_array):
	# Clear existing shadows
	shadow_list.clear()
	
	# Wait a moment for the scene to be ready
	await get_tree().create_timer(0.1).timeout
	
	# Recreate shadows from saved data
	for data in shadow_data_array:
		# Find matching shadow in available_shadows
		for available_shadow in available_shadows:
			if available_shadow.enemy_type == data.enemy_type:
				# Spawn this shadow
				spawn_shadow(available_shadow)
				break
