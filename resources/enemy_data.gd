extends Resource
class_name EnemyData

# Basic Information
@export var name: String = "Enemy"
@export var enemy_type: String = "small"  # small, medium, large, boss
@export var element: String = "neutral"  # fire, water, earth, etc.

# Stats
@export var max_health: int = 30
@export var damage: int = 5
@export var defense: int = 0
@export var movement_speed: float = 100.0

# Behavior
@export var attack_range: float = 50.0
@export var detection_range: float = 300.0

# Targeting behavior
@export var target_priority: String = "closest"  # "closest", "player_only", "shadows_only"
@export var detection_range_override: float = -1  # -1 uses default, otherwise overrides
@export var push_through_others: bool = false  # Can push other entities aside
@export var charge_speed_multiplier: float = 1.0  # Speed multiplier when charging

# Visuals
@export var color: Color = Color.RED
@export var scale_modifier: Vector2 = Vector2(1, 1)
@export var scene_path: String = "res://scenes/enemies/BasicEnemy.tscn"

# Shadow Properties (add these near the end of the file)
@export var shadow_name: String = ""  # If different from regular name
@export var shadow_color: Color = Color(0.2, 0.2, 0.2, 0.8)  # Dark shadow color
@export var shadow_health_modifier: float = 0.8  # 80% of original health
@export var shadow_damage_modifier: float = 1.2  # 120% of original damage
@export var shadow_speed_modifier: float = 1.0  # Same speed

# Shadow Properties
@export var sp_cost: int = 1  # SP cost to summon as shadow
