extends Node

func _ready():
	# Set up direct damage test with a timer
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2.0
	timer.timeout.connect(test_damage)
	timer.start()

func test_damage():
	print("\n--- DAMAGE TEST ---")
	
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		print("Found player: " + player.name)
		
		# Test if player has take_damage method
		if player.has_method("take_damage"):
			print("Player has take_damage method!")
			
			# Try to call take_damage directly
			print("Calling player.take_damage(10)")
			player.take_damage(10)
		else:
			print("ERROR: Player does NOT have take_damage method!")
	else:
		print("ERROR: No player found in the 'player' group!")
	
	print("--- END TEST ---\n")
