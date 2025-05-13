extends Node2D

enum DamageType { NORMAL, CRITICAL, TAKEN }

var damage_value = 0
var damage_type = DamageType.NORMAL
var velocity = Vector2(0, -80)  # Initial upward movement
var fade_time = 1.0  # Time in seconds for the text to fade out

func _ready():
	# Set the label text
	$DamageLabel.text = str(damage_value)
	
	# Set color based on damage type
	match damage_type:
		DamageType.NORMAL:
			$DamageLabel.add_theme_color_override("font_color", Color.WHITE)
		DamageType.CRITICAL:
			$DamageLabel.add_theme_color_override("font_color", Color.YELLOW)
			$DamageLabel.scale = Vector2(1.2, 1.2)  # Make critical hits slightly larger
		DamageType.TAKEN:
			$DamageLabel.add_theme_color_override("font_color", Color.RED)
	
	# Start the fade and movement animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, -40), fade_time)
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free).set_delay(fade_time)

func _process(delta):
	# Add a small horizontal drift
	position.x += sin(Time.get_ticks_msec() * 0.01) * delta * 10
