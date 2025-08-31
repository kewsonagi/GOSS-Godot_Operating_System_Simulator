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

func RegisterBuiltinApps() -> void:
	pathToApps = "%s/" % pathToApps
	var  res: AppManifest
	var apps: PackedStringArray = DirAccess.get_files_at(pathToApps)
	for app in apps:
		if(app.get_extension() == "tres" or app.get_extension() == "res"):#default resource extension for apps
			#res = ResourceLoader.load("%s/%s" % [pathToApps.get_base_dir(), app])
			res = AppManager.LoadAppManifest("%s/%s" % [pathToApps.get_base_dir(), app])
			if(res):
				AppManager.RegisterApp(app.get_file().get_basename(), res as AppManifest)

static func LoadAppManifest(filepath:String) -> AppManifest:
	var  res: Resource = ResourceLoader.load(filepath)
	var app: AppManifest
	if(res and res is AppManifest):
		app = res as AppManifest
	return app


static func RegisterApp(key: String, resource: AppManifest) -> void:
	if (!registeredApps.has(key)):
		#if this item is already registered under a different name, assign it that index and dont make a new one
		appsList.append(resource)
		registeredApps[key] = appsList.size() - 1
		if resource.extensionAssociations and !resource.extensionAssociations.is_empty():
			for ext: String in resource.extensionAssociations:
				registeredAppsByExtension[ext] = appsList.size() - 1
				ResourceManager.RegisterResource(ext, resource.icon)

static func LaunchApp(appName: String, filepath: String, fallbackToOS: bool = true) -> Node:#window created
	if(registeredApps.has(appName)):
		var app: AppManifest = appsList[registeredApps[appName]]
		if(FileAccess.file_exists(app.path)):
			return CreateAppWindow(app, filepath)
			
	if(fallbackToOS):
		OS.shell_open(filepath)
	return null

static func LaunchCustomApp(app:AppManifest) -> Node:#window created
	var filepath: String = app.path
	var appData: Dictionary = {"Filename":filepath,"manifest":app}
	var window: FakeWindow = Desktop.instance.SpawnGameWindow(app.path, app.path.get_file(), filepath, appData)
	if(window):
		AppManager.SetupWindow(window, app)
		window.SetID("%s:%s" % [app.name, filepath])

		Desktop.instance.AddWindowToTaskbar(window, app.colorBGTaskbar, window.titlebarIcon.icon)
		return window
	return null

static func LaunchAppByExt(ext: String, filepath: String, fallbackToOS: bool = true) -> Node:#window created
	if(registeredAppsByExtension.has(ext)):
		var app: AppManifest = appsList[registeredAppsByExtension[ext]]
		if(FileAccess.file_exists(app.path)):
			return CreateAppWindow(app, filepath)
			
	if(fallbackToOS):
		UtilityHelper.Log("falling back to OS level open: %s" % filepath)
		OS.shell_open(filepath)
	return null

static func SetupWindow(window: FakeWindow, app: AppManifest) -> FakeWindow:
	if(window):
		window.titlebarIcon.icon = app.icon
		if(!app.customWindowTitle.is_empty()):
			window.titleText.text = app.customWindowTitle
		window.position.x = app.startWindowPlacement.position.x * UtilityHelper.GetDesktopRect().size.x + UtilityHelper.GetDesktopRect().position.x
		window.position.y = app.startWindowPlacement.position.y * UtilityHelper.GetDesktopRect().size.y + UtilityHelper.GetDesktopRect().position.y
		window.size.x = app.startWindowPlacement.size.x * UtilityHelper.GetDesktopRect().size.x - window.position.x
		window.size.y = app.startWindowPlacement.size.y * UtilityHelper.GetDesktopRect().size.y - window.position.y
		window.SetWindowResizeable(app.resizable)
		window.SetBorderless(app.borderless)
	return window

static func CreateAppWindow(app: AppManifest, filepath: String) -> Node:
	var appData: Dictionary = {"Filename":filepath,"manifest":app}
	var window: FakeWindow = Desktop.instance.SpawnWindow(app.path, app.path.get_file(), filepath, appData)
	if(window):
		AppManager.SetupWindow(window, app)
		window.SetID("%s:%s" % [app.name, filepath])

		Desktop.instance.AddWindowToTaskbar(window, app.colorBGTaskbar, window.titlebarIcon.icon)
		return window
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

static func GetAppIconByLocation(filepath: String) -> Texture2D:
	var app: AppManifest = AppManager.LoadAppManifest(filepath)
	return app.icon

static func GetPathToApps() -> String:
	return ProjectSettings.globalize_path("user://apps/")
