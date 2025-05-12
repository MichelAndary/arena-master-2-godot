extends Area2D

var value = 1  # Default value of this soul essence
var pickup_radius = 80  # How close player needs to be for automatic pickup
var magnetized = false  # If true, will move toward player
var move_speed = 200  # Speed at which it moves toward player
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
	if picked_up:
		return
		
	picked_up = true
	
	# Store the value to display
	var essence_value = value
	
	# Get current total before adding
	var before_total = GameManager.soul_essence
	
	# Add to player's soul essence
	GameManager.soul_essence += essence_value
	
	# Get new total
	var after_total = GameManager.soul_essence
	
	# Notify UI
	GameManager.emit_signal("soul_essence_collected")
	
	# Print debug info
	print("Picked up " + str(essence_value) + " Soul Essence! Before: " + str(before_total) + ", After: " + str(after_total))
	
	# Play pickup effect before disappearing
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0, 0), 0.2)
	tween.tween_callback(queue_free)
