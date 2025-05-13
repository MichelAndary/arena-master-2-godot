extends Node

var floating_damage_scene = preload("res://scenes/ui/floating_damage.tscn")

# Damage type constants
const NORMAL = 0
const CRITICAL = 1
const TAKEN = 2

func show_damage(value, position, type = NORMAL):
	# Create instance of the floating damage
	var floating_damage_scene = load("res://scenes/ui/floating_damage.tscn")
	var damage_popup = floating_damage_scene.instantiate()
	
	# Set properties
	damage_popup.damage_value = value
	damage_popup.damage_type = type
	damage_popup.position = position
	
	# Add slight random offset to prevent overlap
	damage_popup.position += Vector2(
		randf_range(-10, 10),
		randf_range(-10, 10)
	)
	
	# Add to scene
	get_tree().current_scene.add_child(damage_popup)
