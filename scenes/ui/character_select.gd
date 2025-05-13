extends Control

var selected_character = "Kairis"
var unlocked_characters = ["Kairis"] # Start with only Kairis unlocked

func _ready():
	# Connect character slot buttons
	for i in range(1, 8): # For 7 character slots
		var slot = get_node("MainLayout/CharacterSelectionBar/CharacterSlots/CharacterSlot" + str(i))
		if slot:
			slot.pressed.connect(_on_character_slot_pressed.bind(i))
	
	# Connect action buttons
	$MainLayout/ActionButtons/BackButton.pressed.connect(_on_back_button_pressed)
	$MainLayout/ActionButtons/StartButton.pressed.connect(_on_start_button_pressed)
	
	# Initialize with Kairis selected
	update_character_display("Kairis")
	
	# Set initial visual state of character slots
	update_character_slots()

func update_character_display(character_name):
	selected_character = character_name
	
	# Update character description based on selected character
	match character_name:
		"Kairis":
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(0).text = "Kairis can command shadows of fallen enemies."
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(1).text = "Lore: A mysterious warrior who gained the power to control darkness."
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(2).text = "Pros: Strong army building, scaling power over time."
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(3).text = "Cons: Weaker early game, requires careful SP management."
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(4).text = "Special: Command ability lets you summon defeated enemies."
			
		"Void Master":
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(0).text = "The Void Master manipulates space and creates barriers."
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(1).text = "Lore: A prodigy who mastered spatial manipulation techniques."
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(2).text = "Pros: Strong defense, area control, counter-attacks."
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(3).text = "Cons: Limited offensive power, higher skill ceiling."
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(4).text = "Special: Domain Expansion creates a zone of controlled space."
		
		"Thunder Empress":
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(0).text = "The Thunder Empress wields lightning and energy restoration."
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(1).text = "Lore: A royal who harnessed the power of lightning storms."
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(2).text = "Pros: High burst damage, mobility, chain attacks."
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(3).text = "Cons: Low health, vulnerable when abilities on cooldown."
			$MainLayout/CharacterInfoSection/CharacterDescription.get_child(4).text = "Special: Lightning strikes that chain between enemies."
			
		_:
			# Default for new or unimplemented characters
			for i in range(5):
				$MainLayout/CharacterInfoSection/CharacterDescription.get_child(i).text = "Character information not available."

func update_character_slots():
	# Character slot 1 is always Kairis for now
	var slot1 = $MainLayout/CharacterSelectionBar/CharacterSlots/CharacterSlot1
	slot1.text = "Kairis"
	
	# Other slots would be populated from save data or unlocked characters
	# For now, they're mostly placeholder/locked
	
	var slot2 = $MainLayout/CharacterSelectionBar/CharacterSlots/CharacterSlot2
	slot2.text = "Void Master"
	slot2.disabled = !("Void Master" in unlocked_characters)
	
	var slot3 = $MainLayout/CharacterSelectionBar/CharacterSlots/CharacterSlot3
	slot3.text = "Thunder Empress"
	slot3.disabled = !("Thunder Empress" in unlocked_characters)
	
	# Remaining slots are empty/locked placeholders
	for i in range(4, 8):
		var slot = get_node("MainLayout/CharacterSelectionBar/CharacterSlots/CharacterSlot" + str(i))
		if slot:
			slot.text = "???"
			slot.disabled = true

func _on_character_slot_pressed(slot_number):
	var character_name = ""
	match slot_number:
		1: character_name = "Kairis"
		2: character_name = "Void Master"
		3: character_name = "Thunder Empress"
	
	if character_name != "" and character_name in unlocked_characters:
		update_character_display(character_name)
		print("Selected character: " + character_name)

func _on_back_button_pressed():
	print("Back to main menu")
	# Change scene to main menu
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_start_button_pressed():
	print("Starting game with character: " + selected_character)
	
	# Save selected character to GameManager
	GameManager.selected_character = selected_character
	
	# Start new game
	GameManager.start_new_game()
