extends Control

signal shadows_summoned(selected_shadows)
signal summon_cancelled

var player = null
var available_shadows = []
var selected_shadows = []

# Update these paths to match your actual scene structure
@onready var sp_label = $SummonPanel/SPLabel if has_node("SummonPanel/SPLabel") else null
@onready var shadows_grid = $SummonPanel/ShadowsGrid if has_node("SummonPanel/ShadowsGrid") else null
@onready var summon_button = $SummonPanel/ButtonsContainer/SummonButton if has_node("SummonPanel/ButtonsContainer/SummonButton") else null
@onready var cancel_button = $SummonPanel/ButtonsContainer/CancelButton if has_node("SummonPanel/ButtonsContainer/CancelButton") else null

func _ready():
	print("SummonUI _ready called")
	
	# Debug: Check if nodes exist
	print("sp_label exists: " + str(has_node("SummonPanel/SPLabel")))
	print("shadows_grid exists: " + str(has_node("SummonPanel/ShadowsGrid")))
	print("summon_button exists: " + str(has_node("SummonPanel/ButtonsContainer/SummonButton")))
	print("cancel_button exists: " + str(has_node("SummonPanel/ButtonsContainer/CancelButton")))
	
	# Connect button signals - only if they exist
	if summon_button:
		summon_button.pressed.connect(_on_summon_pressed)
	else:
		print("ERROR: summon_button is null")
		
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	else:
		print("ERROR: cancel_button is null")
	
	# Initially hidden
	visible = false

# Function to show the UI with available shadows
func show_summon_ui(p_player, shadows):
	print("Showing summon UI")
	player = p_player
	available_shadows = shadows
	
	# Update SP display
	if player and sp_label:
		sp_label.text = "SP: " + str(player.sp_points) + "/" + str(player.sp_max)
	
	# Clear previous buttons
	if shadows_grid:
		for child in shadows_grid.get_children():
			child.queue_free()
	
		# Create buttons for each available shadow
		for i in range(available_shadows.size()):
			var shadow = available_shadows[i]
			var button = Button.new()
			button.text = "Shadow " + str(i+1) + "\nCost: 1 SP"
			button.custom_minimum_size = Vector2(120, 80)
			button.toggle_mode = true
			button.pressed.connect(_on_shadow_button_pressed.bind(i))
			shadows_grid.add_child(button)
	
	# Show the UI
	visible = true

func _on_shadow_button_pressed(index):
	print("Shadow button " + str(index) + " pressed")
	
	# For this simple test, just print something
	var shadow = available_shadows[index]
	var button = shadows_grid.get_child(index)
	
	if button.button_pressed:
		print("Selected shadow " + str(index))
		button.modulate = Color(0.7, 1.0, 0.7)  # Green tint
	else:
		print("Deselected shadow " + str(index))
		button.modulate = Color(1.0, 1.0, 1.0)  # Normal color

func _on_summon_pressed():
	print("Summon button pressed")
	emit_signal("shadows_summoned", [])  # For now, just an empty array
	visible = false  # Hide UI

func _on_cancel_pressed():
	print("Cancel button pressed")
	emit_signal("summon_cancelled")
	visible = false  # Hide UI
