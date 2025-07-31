extends SubViewport

## The game window, used to show games.

@export var parentWindow: FakeWindow
@export var pauseMenuManager: ScenePauseMenu
@export var startingUserDirectory: String = "user://files/"
var cachedResources: Array[Resource] = []

func _ready() -> void:
	parentWindow.minimized.connect(_handle_window_minimized)
	parentWindow.selected.connect(_handle_window_selected)

	if(parentWindow.creationData.has("Filename")):
		var filename: String = "%s%s" % [startingUserDirectory, (parentWindow.creationData["Filename"] as String)]
		#var rl: ResourceLoader;
		#rl.load()
		ResourceLoader.set_abort_on_missing_resources(true)
		var alreadyCopiedGodotProjectDir: bool = false

		var deps: PackedStringArray = ResourceLoader.get_dependencies(filename)
		for dep: String in deps:
			var depStr: String = dep.get_slice("::", 2)
			
			#######
			## remap directory from res:// to user://files/
			#######
			
			var redirectFilename: String = filename.get_base_dir()
			var foundGodotProjectDir: String = ""
			var foundProjectDir: bool = false
			while(!foundProjectDir):
				if(!redirectFilename.contains("user://files")):
					break
				for files in DirAccess.get_files_at(redirectFilename):
					if(files.contains(".godot")):
						#print("found project dir: %s" % redirectFilename)
						#if(!foundProjectDir):
							#for dir in DirAccess.get_directories_at(redirectFilename):
							#	CopyPasteManager.CopyAllFilesOrFolders([redirectFilename.path_join(dir)], "user://")
						foundProjectDir = true;
						foundGodotProjectDir = redirectFilename
						break
				if(!foundProjectDir):
					redirectFilename = redirectFilename.get_base_dir()
			if(!foundProjectDir):
				redirectFilename = filename.get_base_dir()
				#NotificationManager.ShowNotification("Failed to find .godot project file")
			#cachedResources.append(ResourceLoader.load(depStr.replace("res:/", redirectFilename), "", ResourceLoader.CACHE_MODE_IGNORE_DEEP))
			#######
			#######
			
		var scene: PackedScene = ResourceLoader.load(filename, "", ResourceLoader.CACHE_MODE_REUSE)
		if(scene):
			var sceneToLoad: Node = scene.instantiate()
			add_child(sceneToLoad)
		else:
			NotificationManager.ShowNotification("Unknown error loading scene file: %s" % filename, NotificationManager.E_NOTIFICATION_TYPE.UNKNOWN, "Failed to load")
	
	# WIP: Making game scene resolution not tied to screen scale
	#await get_tree().process_frame
	#$"../..".scale /= get_window().content_scale_factor
	#$"../..".size *= get_window().content_scale_factor

func _handle_window_minimized(is_minimized: bool) -> void:
	if pauseMenuManager.is_paused:
		return
	
	if is_minimized:
		get_child(0).process_mode = Node.PROCESS_MODE_DISABLED
	else:
		get_child(0).process_mode = Node.PROCESS_MODE_INHERIT

## Disables input if the window isn't selected.
func _handle_window_selected(is_selected: bool) -> void:
	# TODO check if this wrecks performance
	#handle_input_locally = false
	set_input(self, is_selected)

# WARNING recursively loops on every node in the game. Probably a bad idea.
func set_input(node: Node, can_input: bool) -> void:
	node.set_process_input(can_input)
	for n in node.get_children():
		set_input(n, can_input)
