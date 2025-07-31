extends Node
class_name ScenePauseMenu

## A generic pause manager for games in GodotOS.
## When you press ui_cancel, it pauses or unpauses.

## NOTE: This node disabled by default but gets enabled by start menu option
## if the generic pause menu bool is enabled there.

@export var pauseScene: PackedScene
@export var gameWindow: Node
@export var parentWindow: FakeWindow

var bPaused: bool
var currentPauseScreen: CanvasLayer

func _input(event: InputEvent) -> void:
	if !parentWindow.is_selected:
		return
	
	if event.is_action_pressed("pause_game"):
		toggle_pause()

## Pauses and adds the pause screen as a child to the game scene.
## The reason for this is so the pause screen scales with the viewport.
func toggle_pause() -> void:
	if !gameWindow or gameWindow.get_child_count() == 0:
		NotificationManager.ShowNotification("Error: No scene to pause?", NotificationManager.E_NOTIFICATION_TYPE.ERROR, "No Scene Found")
		return
	
	var game_scene: Node = gameWindow.get_child(0)
	
	if bPaused:
		game_scene.process_mode = Node.PROCESS_MODE_INHERIT
		if currentPauseScreen != null:
			currentPauseScreen.queue_free()
	else:
		game_scene.process_mode = Node.PROCESS_MODE_DISABLED
		var pause_screen: CanvasLayer = pauseScene.instantiate()
		game_scene.add_child(pause_screen)
		currentPauseScreen = pause_screen
	
	bPaused = !bPaused
