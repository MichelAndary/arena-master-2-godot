extends Node2D

enum PortalType { NEXT_STAGE, SHOP, CHALLENGE }

@export var portal_type: PortalType = PortalType.NEXT_STAGE
var active = false

func _ready():
	# Set visual appearance based on type
	match portal_type:
		PortalType.NEXT_STAGE:
			$Sprite2D.modulate = Color.BLUE
		PortalType.SHOP:
			$Sprite2D.modulate = Color.YELLOW
		PortalType.CHALLENGE:
			$Sprite2D.modulate = Color.PURPLE
	
	# Initially not active
	visible = false
	$Area2D/CollisionShape2D.disabled = true
	
	# Connect to area entered signal
	$Area2D.body_entered.connect(_on_body_entered)

func activate():
	visible = true
	active = true
	$Area2D/CollisionShape2D.disabled = false
	
	# Create activation effect
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.5).from(Vector2(0, 0))

func _on_body_entered(body):
	if active and body.is_in_group("player"):
		# Save player health
		GameManager.player_health = body.health
		# Handle portal based on type
		match portal_type:
			PortalType.NEXT_STAGE:
				print("Next stage portal entered")
				GameManager.complete_stage()
			PortalType.SHOP:
				print("Shop portal entered")
				# TODO: Implement shop scene transition
			PortalType.CHALLENGE:
				print("Challenge portal entered")
				# TODO: Implement challenge scene
