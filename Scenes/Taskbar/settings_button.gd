extends Button

## The settings menu in the start menu. Just spawns the settings menu.
@export var settingsPanel: PackedScene = preload("res://Scenes/Window/Settings Window/settings_window.tscn")
@export var taskbarButton: PackedScene = preload("res://Scenes/Taskbar/taskbar_button.tscn")

func _on_pressed() -> void:
	var window: FakeWindow
	#window = settingsPanel.instantiate()#load("res://Scenes/Window/Settings Window/settings_window.tscn").instantiate()
	window = DefaultValues.spawn_window(settingsPanel.resource_path, "Settings Menu", "Settings Menu")
	#window.title_text = "[center]Settings Menu"
	#get_tree().current_scene.add_child(window)
	
	var taskbar_button: Control = taskbarButton.instantiate()#load("res://Scenes/Taskbar/taskbar_button.tscn").instantiate()
	taskbar_button.target_window = window
	taskbar_button.active_color = Color.WHITE
	taskbar_button.get_node("TextureMargin/TextureRect").texture = icon
	get_tree().get_first_node_in_group("taskbar_buttons").add_child(taskbar_button)
