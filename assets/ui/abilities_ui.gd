# scripts/ui/abilities_ui.gd
extends Control

@onready var skill_overlay = $AbilitiesContainer/SkillButton/CooldownOverlay
@onready var skill_label = $AbilitiesContainer/SkillButton/CooldownLabel
@onready var ultimate_overlay = $AbilitiesContainer/UltimateButton/CooldownOverlay
@onready var ultimate_label = $AbilitiesContainer/UltimateButton/CooldownLabel
@onready var portrait = $AbilitiesContainer/CharacterPortrait

var player = null
var skill_cooldown = 0.0
var ultimate_cooldown = 0.0
var skill_max_cooldown = 5.0  # Default values
var ultimate_max_cooldown = 20.0

# Add these textures for creative visuals
var skill_textures = {
	"Kairis": preload("res://assets/ui/in_game/kairis_skill_frame.png")
}
var ultimate_textures = {
	"Kairis": preload("res://assets/ui/in_game/kairis_ultimate_frame.png")
}
var portrait_textures = {
	"Kairis": preload("res://assets/ui/in_game/kairis_portrait_frame.png")
}

func _ready():
	# Initially hide cooldown elements
	skill_overlay.visible = false
	ultimate_overlay.visible = false
	skill_label.text = ""
	ultimate_label.text = ""
	
	# Connect to player when available
	call_deferred("find_player")

func find_player():
	await get_tree().create_timer(0.1).timeout
	player = get_tree().get_first_node_in_group("player")
	if player:
		# Set up textures based on player character
		var character_name = player.character_name
		if character_name in skill_textures:
			$AbilitiesContainer/SkillButton.texture = skill_textures[character_name]
		if character_name in ultimate_textures:
			$AbilitiesContainer/UltimateButton.texture = ultimate_textures[character_name]
		if character_name in portrait_textures:
			portrait.texture = portrait_textures[character_name]
		
		# Get cooldown values from player
		skill_max_cooldown = player.skill_cooldown
		ultimate_max_cooldown = player.ultimate_cooldown

func _process(delta):
	if player:
		# Update cooldown timers from player
		skill_cooldown = player.skill_timer
		ultimate_cooldown = player.ultimate_timer
		
		# Update skill cooldown display
		if skill_cooldown > 0:
			skill_overlay.visible = true
			
			# Create a radial fill effect for cooldown
			var cooldown_ratio = skill_cooldown / skill_max_cooldown
			skill_overlay.material.set_shader_parameter("progress", 1.0 - cooldown_ratio)
			
			# Only show text for cooldowns > 1 second
			if skill_cooldown > 1.0:
				skill_label.text = str(ceil(skill_cooldown))
			else:
				skill_label.text = ""
		else:
			skill_overlay.visible = false
			skill_label.text = ""
		
		# Update ultimate cooldown display
		if ultimate_cooldown > 0:
			ultimate_overlay.visible = true
			
			# Create a radial fill effect for cooldown
			var cooldown_ratio = ultimate_cooldown / ultimate_max_cooldown
			ultimate_overlay.material.set_shader_parameter("progress", 1.0 - cooldown_ratio)
			
			# Show timer text
			if ultimate_cooldown > 1.0:
				ultimate_label.text = str(ceil(ultimate_cooldown))
			else:
				ultimate_label.text = ""
		else:
			ultimate_overlay.visible = false
			ultimate_label.text = ""


# Connect these signals from the player for animations
func connect_player_signals():
	if player:
		if player.has_signal("skill_used"):
			player.skill_used.connect(_on_skill_used)
		if player.has_signal("ultimate_used"):
			player.ultimate_used.connect(_on_ultimate_used)

func _on_skill_used():
	# Create a flash effect
	var flash_tween = create_tween()
	flash_tween.tween_property($AbilitiesContainer/SkillButton, "modulate", Color(2, 2, 2, 1), 0.1)
	flash_tween.tween_property($AbilitiesContainer/SkillButton, "modulate", Color(1, 1, 1, 1), 0.1)

func _on_ultimate_used():
	# Create a flash effect
	var flash_tween = create_tween()
	flash_tween.tween_property($AbilitiesContainer/UltimateButton, "modulate", Color(2, 2, 2, 1), 0.1)
	flash_tween.tween_property($AbilitiesContainer/UltimateButton, "modulate", Color(1, 1, 1, 1), 0.1)
