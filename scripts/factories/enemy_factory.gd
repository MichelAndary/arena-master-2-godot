extends Node

# Dictionary to store preloaded enemy scenes
var enemy_scenes = {}

# Dictionary to store enemy data resources
var enemy_data_resources = {}

func _ready():
	# Preload enemy data resources
	preload_enemy_data()

func preload_enemy_data():
	# Load all enemy data resources from the resources/enemies directory
	var dir = DirAccess.open("res://resources/enemies")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var resource_path = "res://resources/enemies/" + file_name
				var resource = load(resource_path)
				
				if resource is EnemyData:
					enemy_data_resources[file_name.get_basename()] = resource
					print("Loaded enemy data: " + file_name)
					
					# Preload the enemy scene if specified
					if resource.scene_path != "":
						enemy_scenes[file_name.get_basename()] = load(resource.scene_path)
			
			file_name = dir.get_next()

# Create an enemy instance from the specified enemy data resource
func create_enemy(enemy_id: String):
	if not enemy_data_resources.has(enemy_id):
		print("ERROR: Enemy data not found for ID: " + enemy_id)
		return null
	
	var data = enemy_data_resources[enemy_id]
	
	# Load the scene if not already preloaded
	var scene
	if enemy_scenes.has(enemy_id):
		scene = enemy_scenes[enemy_id]
	else:
		if data.scene_path != "":
			scene = load(data.scene_path)
			enemy_scenes[enemy_id] = scene
		else:
			print("ERROR: No scene path specified for enemy: " + enemy_id)
			return null
	
	# Instance the enemy
	var enemy_instance = scene.instantiate()
	
	# Configure the enemy with the data
	configure_enemy(enemy_instance, data)
	
	return enemy_instance

# Apply the data properties to the enemy instance
func configure_enemy(enemy: Node, data: EnemyData):
	# Set basic properties
	enemy.enemy_name = data.name
	
	# Set stats
	enemy.max_health = data.max_health
	enemy.health = data.max_health
	enemy.damage = data.damage
	enemy.movement_speed = data.movement_speed
	enemy.attack_range = data.attack_range
	enemy.detection_range = data.detection_range
	
	# Apply visual properties if the enemy has a Sprite node
	if enemy.has_node("Sprite"):
		enemy.get_node("Sprite").modulate = data.color
		enemy.get_node("Sprite").scale = data.scale_modifier
	
	return enemy

func create_shadow(enemy_id, owner_node):
	print("Creating shadow from enemy ID: " + enemy_id)
	
	if not enemy_data_resources.has(enemy_id):
		print("ERROR: Enemy data not found for ID: " + enemy_id)
		return null
	
	var data = enemy_data_resources[enemy_id]
	print("Found enemy data: " + data.name)
	
	# Load the enemy scene
	var scene
	if enemy_scenes.has(enemy_id):
		scene = enemy_scenes[enemy_id]
	else:
		if data.scene_path == "":
			print("ERROR: No scene path specified for enemy: " + enemy_id)
			return null
			
		print("Loading scene from path: " + data.scene_path)
		scene = load(data.scene_path)
		enemy_scenes[enemy_id] = scene
	
	# Instance the scene
	var shadow = scene.instantiate()
	print("Instantiated shadow from scene")
	
	# Configure basic enemy properties
	configure_enemy(shadow, data)
	
	# Apply shadow-specific modifications
	print("Converting to shadow...")
	shadow.convert_to_shadow(owner_node)
	
		# After converting to shadow, explicitly check and fix groups
	print("Shadow groups before: " + str(shadow.get_groups()))
	if shadow.is_in_group("enemies"):
		shadow.remove_from_group("enemies")
		print("Removed from enemies group")
	
	if not shadow.is_in_group("shadows"):
		shadow.add_to_group("shadows")
		print("Added to shadows group")
	
	print("Shadow groups after: " + str(shadow.get_groups()))
	
	return shadow

func configure_shadow(shadow: Node, data: EnemyData, owner_node):
	# First, configure like a normal enemy
	configure_enemy(shadow, data)
	
	# Then convert to shadow mode
	if shadow.has_method("convert_to_shadow"):
		shadow.convert_to_shadow(owner_node)
	# After converting to shadow, explicitly check and fix groups
	print("Shadow groups before: " + str(shadow.get_groups()))
	if shadow.is_in_group("enemies"):
		shadow.remove_from_group("enemies")
		print("Removed from enemies group")

	if not shadow.is_in_group("shadows"):
		shadow.add_to_group("shadows")
		print("Added to shadows group")

	print("Shadow groups after: " + str(shadow.get_groups()))
	# Set stats with modifiers
	shadow.max_health = int(data.max_health * data.shadow_health_modifier)
	shadow.health = shadow.max_health
	shadow.damage = int(data.damage * data.shadow_damage_modifier)
	shadow.movement_speed = data.movement_speed * data.shadow_speed_modifier
	
	return shadow
