extends Control

func _ready():
	# Connect button signals
	$ButtonContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$ButtonContainer/UpgradesButton.pressed.connect(_on_upgrades_button_pressed)
	$ButtonContainer/OptionsButton.pressed.connect(_on_options_button_pressed)
	$ButtonContainer/QuitButton.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	print("Start Game pressed - changing to character select")
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")
	
func _on_upgrades_button_pressed():
	print("Upgrades pressed")
	# We'll implement this later
	
func _on_options_button_pressed():
	print("Options pressed")
	# We'll implement this later
	
func _on_quit_button_pressed():
	print("Quit pressed")
	get_tree().quit()
