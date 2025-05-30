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
		# Check if signal is already connected before connecting
		if !summon_button.pressed.is_connected(_on_summon_pressed):
			summon_button.pressed.connect(_on_summon_pressed)
	else:
		print("ERROR: summon_button is null")
		
	if cancel_button:
		# Check if signal is already connected before connecting
		if !cancel_button.pressed.is_connected(_on_cancel_pressed):
			cancel_button.pressed.connect(_on_cancel_pressed)
	else:
		print("ERROR: cancel_button is null")
	
	# Set process mode to allow processing when paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
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
	
	# Pause the game - ADD THIS
	get_tree().paused = true
	
func _on_shadow_button_pressed(index):
	print("Shadow button " + str(index) + " pressed")
	
	# Make sure we have valid index
	if index < 0 or index >= available_shadows.size():
		print("Invalid shadow index: " + str(index))
		return
	
	# Get the shadow and button
	var shadow = available_shadows[index]
	var button = shadows_grid.get_child(index)
	
	# Toggle selection
	if button.button_pressed:
		# Trying to select this shadow
		var total_cost = get_total_selected_cost() + shadow.sp_cost
		var would_exceed_limit = selected_shadows.size() + 1 > (player.shadow_limit - player.shadow_list.size())
		
		# Check SP first
		if player and player.get("sp_points") != null and total_cost > player.sp_points:
			button.button_pressed = false
			show_warning("Not enough SP!")
			return
		
		# Check shadow limit
		if would_exceed_limit:
			button.button_pressed = false
			var available_slots = player.shadow_limit - player.shadow_list.size()
			show_warning("Shadow limit! Can only summon " + str(available_slots) + " more shadows.")
			return
		
		# Selection is valid
		selected_shadows.append(shadow)
		button.modulate = Color(0.7, 1.0, 0.7)  # Green tint
		print("Selected shadow: " + shadow.enemy_type)
		
	else:
		# Deselecting shadow
		selected_shadows.erase(shadow)
		button.modulate = Color(1.0, 1.0, 1.0)  # Normal color
		print("Deselected shadow: " + shadow.enemy_type)
	
	# Update the display to show current selection status
	update_selection_display()

func show_warning(message):
	print("WARNING: " + message)
	# Flash the SP label red to show warning
	if sp_label:
		var original_color = sp_label.get_theme_color("font_color")
		sp_label.add_theme_color_override("font_color", Color.RED)
		sp_label.text = message
		
		# Reset after 2 seconds
		await get_tree().create_timer(2.0).timeout
		sp_label.remove_theme_color_override("font_color")
		update_selection_display()

func update_selection_display():
	if player and sp_label:
		var available_slots = player.shadow_limit - player.shadow_list.size()
		var selected_count = selected_shadows.size()
		sp_label.text = "SP: " + str(player.sp_points) + "/" + str(player.sp_max) + " | Selected: " + str(selected_count) + "/" + str(available_slots)

func _on_summon_pressed():
	print("Summon button pressed with " + str(selected_shadows.size()) + " shadows selected")
	
	# Emit signal with the selected shadows
	emit_signal("shadows_summoned", selected_shadows)
	
	# Hide UI
	visible = false
	
	# Unpause the game - ADD THIS
	get_tree().paused = false
	
	# Clear selections for next time
	selected_shadows.clear()

func _on_cancel_pressed():
	print("Cancel button pressed")
	
	# Emit signal
	emit_signal("summon_cancelled")
	
	# Hide UI
	visible = false
	
	# Unpause the game - ADD THIS
	get_tree().paused = false
	
	# Clear selections for next time
	selected_shadows.clear()
	
func get_total_selected_cost():
	var total = 0
	for shadow in selected_shadows:
		total += shadow.sp_cost
	return total
