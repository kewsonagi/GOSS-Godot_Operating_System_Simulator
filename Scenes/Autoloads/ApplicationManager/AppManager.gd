extends Node
class_name AppManager

# static var instance: ResourceManager = null
@export_dir var pathToApps: String
static var registeredApps: Dictionary#reg by app name, appList index
static var registeredAppsByExtension: Dictionary#reg by extension, appList index
static var appsList: Array[AppManifest]
static var instance: AppManager = null

func _ready() -> void:
	if(instance == null):
		instance = self
		RegisterBuiltinApps()
		print("registering apps")

func RegisterBuiltinApps() -> void:
	pathToApps = "%s/" % pathToApps
	var  res: Resource
	var apps: PackedStringArray = DirAccess.get_files_at(pathToApps)
	for app in apps:
		if(app.get_file().get_extension() == "tres"):#default resource extension for apps
			print("trying to register app: %s" % app)
			res = ResourceLoader.load("%s/%s" % [pathToApps.get_base_dir(), app])
			if(res and res is AppManifest):
				print("registering app: %s" % (res as AppManifest).path)
				AppManager.RegisterApp(app.get_file().get_basename(), res as AppManifest)


static func RegisterApp(key: String, resource: AppManifest) -> void:
	if (!registeredApps.has(key)):
		print("registering %s" % key)
		print(resource.path)
		#if this item is already registered under a different name, assign it that index and dont make a new one
		appsList.append(resource)
		registeredApps[key] = appsList.size() - 1
		for ext: String in resource.extensionAssociations:
			registeredAppsByExtension[ext] = appsList.size() - 1
			ResourceManager.RegisterResource(ext, resource.icon)

static func LaunchApp(appName: String, filepath: String, fallbackToOS: bool = true) -> Node:#window created
	if(registeredApps.has(appName)):
		var app: AppManifest = appsList[registeredApps[appName]]
		if(FileAccess.file_exists(app.path)):
			var appData: Dictionary = {"Filename":filepath,"manifest":app}
			var window: FakeWindow = DefaultValues.spawn_window(app.path, appName, filepath, appData)
			if(window):
				window.titlebarIcon.icon = app.icon
				DefaultValues.AddWindowToTaskbar(window, Color.BLUE_VIOLET, window.titlebarIcon.icon)
				return window
			
		if(fallbackToOS):
			OS.shell_open(app.path)
	return null

static func LaunchAppByExt(ext: String, filepath: String, fallbackToOS: bool = true) -> Node:#window created
	if(registeredAppsByExtension.has(ext)):
		var app: AppManifest = appsList[registeredAppsByExtension[ext]]
		if(FileAccess.file_exists(app.path)):
			var appData: Dictionary = {"Filename":filepath,"manifest":app}
			var window: FakeWindow = DefaultValues.spawn_window(app.path, app.path.get_file(), filepath, appData)
			if(window):
				window.titlebarIcon.icon = app.icon
				DefaultValues.AddWindowToTaskbar(window, Color.BLUE_VIOLET, window.titlebarIcon.icon)
				return window
			
		if(fallbackToOS):
			OS.shell_open(app.path)
	return null

static func GetAppIconByExt(ext: String) -> Texture2D:
	if(registeredAppsByExtension.has(ext)):
		var app: AppManifest = appsList[registeredAppsByExtension[ext]]
		return app.icon
	return null
static func GetAppIcon(appName: String) -> Texture2D:
	if(registeredApps.has(appName)):
		var app: AppManifest = appsList[registeredApps[appName]]
		return app.icon
	return null

static func GetPathToApps() -> String:
	return ProjectSettings.globalize_path("user://apps/")
