extends Panel

## A start menu option. Currently only used to spawn game windows and nothing else.

## Path to the game scene
@export var game_scene: String
@export var gameScene: PackedScene

## Title shown in start menu option (added at runtime).
@export var title_text: String

## Description shown in start menu option (added at runtime).
@export var description_text: String
@export var programIcon: Texture2D

## Whether or not the scene should be instantiated inside a game window or outside one.
## (You probably want this on, but it's great if you want to make your own custom window or behavior)
@export var spawn_inside_window: bool = true

## Whether to use a simple pause menu or not (spawned by pressing ESC or P)
@export var use_generic_pause_menu: bool

var is_mouse_over: bool
@export var gameData: Dictionary = {}
@export var MenuTitle: RichTextLabel
@export var MenuDescription: RichTextLabel
@export var MenuIcon: TextureRect

@export var backgroundPanel: Panel
@export var taskbarIcon: TextureRect

func _ready() -> void:
	backgroundPanel.visible = false
	MenuTitle.text = "[center]%s" % title_text
	#MenuDescription.text = "[center]%s" % description_text
	MenuDescription.visible = false;
	if(programIcon):
		MenuIcon.texture = programIcon

func _gui_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.button_index == 1 and event.is_pressed():
	if(event.is_action_pressed(&"LeftClick") or event.is_action_pressed(&"RightClick")):
		if spawn_inside_window:
			spawn_window()
		else:
			spawn_outside_window()

func _on_mouse_entered() -> void:
	is_mouse_over = true
	backgroundPanel.visible = true
	TweenAnimator.glow_pulse(self, 0.1, 0.2, 0.3)
	# var tween: Tween = create_tween()
	# tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	# tween.tween_property(backgroundPanel, "modulate:a", 1, 0.2)

func _on_mouse_exited() -> void:
	is_mouse_over = false
	TweenAnimator.glow_pulse(self, 0.1, 0.2, 0.3)

	# var tween: Tween = create_tween()
	# tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	# await tween.tween_property(backgroundPanel, "modulate:a", 0, 0.2).finished
	if !is_mouse_over:
		backgroundPanel.visible = false

# TODO find a better way than copying this from desktop_folder.gd
func spawn_window() -> void:
	print("spawn regular game window inside itself")
	var window: FakeWindow
	if(gameScene):
		window = DefaultValues.spawn_game_window(gameScene.resource_path, title_text, gameScene.resource_path.get_basename(), gameData,null)
	else:
		window = DefaultValues.spawn_game_window(game_scene, title_text, game_scene.get_basename(), gameData,null)
	#var window: FakeWindow
	#window = load("res://Scenes/Window/Game Window/game_window.tscn").instantiate()
	#window.get_node("%Game Window").add_child(load(game_scene).instantiate())
	
	if use_generic_pause_menu:
		window.get_node("%GamePauseManager").process_mode = Node.PROCESS_MODE_INHERIT
	
	DefaultValues.AddWindowToTaskbar(window, Color.CRIMSON, taskbarIcon.texture)
	#taskbar_button.active_color = $"HBoxContainer/MarginContainer/TextureRect".modulate
	

func spawn_outside_window() -> void:
	print("spawn game outside of window")
	var windowParent:Node = $/root/Control;
	var window: FakeWindow
	if(gameScene):
		window = DefaultValues.spawn_window(gameScene.resource_path,title_text, gameScene.resource_path.get_basename(), gameData, windowParent)
	else:
		window = DefaultValues.spawn_window(game_scene, title_text, game_scene.get_basename(), gameData, windowParent)
	DefaultValues.AddWindowToTaskbar(window, Color.CRIMSON, taskbarIcon.texture)
	#$/root/Control.add_child(load(game_scene).instantiate())
