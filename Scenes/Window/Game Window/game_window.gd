extends SubViewport

## The game window, used to show games.

@export var parentWindow: FakeWindow# = $"../../.."
@export var game_pause_manager: GamePauseManager# = %"GamePauseManager"

func _ready() -> void:
	if(parentWindow.creationData.has("BootScene")):

		var gameBootloader: Node = ResourceLoader.load(parentWindow.creationData["BootScene"]).instantiate()
		if(gameBootloader is BootGame):
			add_child(gameBootloader)
			(gameBootloader as BootGame).StartGame()
			if((gameBootloader as BootGame).spawnedWindow):
				add_child((gameBootloader as BootGame).spawnedWindow)
		else:
			add_child(gameBootloader)


	parentWindow.minimized.connect(_handle_window_minimized)
	parentWindow.selected.connect(_handle_window_selected)
	
func _handle_window_minimized(is_minimized: bool) -> void:
	if game_pause_manager.is_paused:
		return
	
	if is_minimized:
		get_child(0).process_mode = Node.PROCESS_MODE_DISABLED
	else:
		get_child(0).process_mode = Node.PROCESS_MODE_INHERIT

## Disables input if the window isn't selected.
func _handle_window_selected(is_selected: bool) -> void:
	# TODO check if this wrecks performance
	if(is_selected):
		handle_input_locally = true
	
	#set_input(self, is_selected)

# WARNING recursively loops on every node in the game. Probably a bad idea.
func set_input(node: Node, can_input: bool) -> void:
	node.set_process_input(can_input)
	for n in node.get_children():
		set_input(n, can_input)
