extends Area2D

var value = 1  # Default value of this soul essence
var pickup_radius = 80  # How close player needs to be for automatic pickup
var magnetized = false  # If true, will move toward player
var move_speed = 300  # Speed at which it moves toward player
var player = null
var picked_up = false  # Flag to prevent multiple pickups

func _ready():
	# Add to the soul_essence group
	add_to_group("soul_essence")
	
	# Connect signal for detecting player
	body_entered.connect(_on_body_entered)
	
	# Find player
	call_deferred("find_player")
	
	# Debug print our value
	print("Soul Essence created with value: " + str(value))
	
	# Random initial push
	var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var random_force = randf_range(30, 80)
	position += random_direction * random_force
	
	# Add visual effect
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.3).from(Vector2(0, 0))

func _process(delta):
	# If player is close enough, start moving toward them
	if player and !picked_up:
		var distance = global_position.distance_to(player.global_position)
		
		if distance < pickup_radius:
			magnetized = true
		
		if magnetized:
			# Move toward player
			var direction = (player.global_position - global_position).normalized()
			position += direction * move_speed * delta
			
			# If very close, pickup
			if distance < 20:
				pickup()

func find_player():
	await get_tree().create_timer(0.1).timeout
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _on_body_entered(body):
	if body.is_in_group("player") and !picked_up:
		pickup()

func pickup():
	# Prevent double pickup
	if picked_up:
		return
	
	picked_up = true
	# Store the value being added
	var pickup_value = value
	
	# Debug print before
	print("PICKUP: Before - GameManager soul essence: " + str(GameManager.soul_essence))
	
	# Add to player's soul essence
	GameManager.soul_essence += pickup_value
	
	# Debug print after
	print("PICKUP: After - GameManager soul essence: " + str(GameManager.soul_essence) + " (added " + str(pickup_value) + ")")
	
	# Explicitly update UI by finding the HUD and calling the update function
	var hud = get_tree().get_first_node_in_group("game_hud")
	if hud and hud.has_method("update_soul_essence_display"):
		hud.update_soul_essence_display()
		print("PICKUP: Manually called HUD update")
	else:
		print("PICKUP: ERROR - HUD not found for updating")
	
	# Emit signal (this wasn't working before)
	GameManager.emit_signal("soul_essence_collected")
	
	# Play pickup effect before disappearing
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0, 0), 0.2)
	tween.tween_callback(queue_free)
