extends Node
class_name WidgetManager

# static var instance: ResourceManager = null
@export_dir var pathToWidgets: String
@export var defaultWidgets: Array[WidgetConfig]
static var registeredWidgets: Dictionary#reg by app name, appList index
static var widgetsList: Array[WidgetConfig]
static var instance: WidgetManager = null
static var registeredNames: PackedStringArray = []

func _ready() -> void:
	if(instance == null):
		instance = self
		RegisterBuiltinWidgets()

func RegisterBuiltinWidgets() -> void:
	if(!pathToWidgets.ends_with("/")):
		pathToWidgets = "%s/" % pathToWidgets
	# pathToWidgets = UtilityHelper.GlobalizePath(pathToWidgets)

	var  res: WidgetConfig
	var fullIconPath: String
	var fullExternalIconPath: String
	var apps: PackedStringArray = DirAccess.get_files_at(pathToWidgets)
	for app in apps:
		if(app.get_extension() == "import"):
			app = app.replace(".import", "")
		if(app.get_extension() == "remap"):
			app = app.replace(".remap", "")

		if(app.get_extension() == "tres" or app.get_extension() == "res"):#default resource extension for apps
			fullIconPath = "%s/%s" % [pathToWidgets.get_base_dir(), app]
			fullExternalIconPath = "%s/%s" % [ResourceManager.GetPathToWidgets(), app]
			UtilityHelper.CopyFile(fullIconPath, fullExternalIconPath)
			#res = ResourceLoader.load("%s/%s" % [pathToWidgets.get_base_dir(), app])
			res = WidgetManager.LoadWidgetConfig(fullIconPath)
			if(res):
				WidgetManager.RegisterWidget(res.key, res)
	#load external widgets that may have been added as a mod, pck, etc	
	var externalapps: PackedStringArray = DirAccess.get_files_at(ResourceManager.GetPathToWidgets())
	for app in externalapps:
		if(app.get_extension() == "tres" or app.get_extension() == "res"):#default resource extension for apps
			fullExternalIconPath = "%s/%s" % [ResourceManager.GetPathToWidgets(), app]
			#res = ResourceLoader.load("%s/%s" % [pathToWidgets.get_base_dir(), app])
			res = WidgetManager.LoadWidgetConfig(fullExternalIconPath)
			res.path = ProjectSettings.globalize_path(res.path)

			if(res):
				WidgetManager.RegisterWidget(res.key, res)
	# for app: WidgetConfig in defaultWidgets:
	# 	WidgetManager.RegisterWidget(app.key, app)

static func LoadWidgetConfig(filepath:String) -> WidgetConfig:
	var  res: Resource = ResourceLoader.load(filepath)
	var app: WidgetConfig
	if(res and res is WidgetConfig):
		app = res as WidgetConfig
	return app

static func GetWidgetsRegisteredList() -> PackedStringArray:
	return registeredNames

static func RegisterWidget(key: String, resource: WidgetConfig) -> void:
	if (!registeredWidgets.has(key)):
		registeredNames.append(key)
		#if this item is already registered under a different name, assign it that index and dont make a new one
		widgetsList.append(resource)
		registeredWidgets[key] = widgetsList.size() - 1
		# if resource.extensionAssociations and !resource.extensionAssociations.is_empty():
		# 	for ext: String in resource.extensionAssociations:
		# 		ResourceManager.RegisterResource(ext, resource.icon)

static func LaunchWindowWidget(appName: String, filepath: String, fallbackToOS: bool = true) -> Node:#window created
	if(registeredWidgets.has(appName)):
		var app: WidgetConfig = widgetsList[registeredWidgets[appName]]
		#if(FileAccess.file_exists(app.path)):
		return CreateWidgetWindow(app, filepath)
			
	if(fallbackToOS):
		OS.shell_open(filepath)
	return null

static func CreateWidget(appName: String) -> BaseWidget:
	if(registeredWidgets.has(appName)):
		var conf: WidgetConfig = widgetsList[registeredWidgets[appName]]
		#if(FileAccess.file_exists(conf.path)):
		var scene: PackedScene = ResourceLoader.load(conf.path) as PackedScene
		if(scene):
			var widget: BaseWidget = scene.instantiate() as BaseWidget
			if(widget):
				widget.SetConfig(conf)
				return widget
	return null

static func GetWidget(appName: String) -> BaseWidget:
	return CreateWidget(appName)

static func LaunchCustomWindowWidget(app:WidgetConfig) -> Node:#window created
	var filepath: String = app.path
	var appData: Dictionary = {"Filename":filepath,"manifest":app}
	var window: FakeWindow = Desktop.instance.SpawnGameWindow(app.path, app.path.get_file(), filepath, appData)
	if(window):
		WidgetManager.SetupWindowWidget(window, app)
		window.SetID("%s:%s" % [app.name, filepath])

		Desktop.instance.AddWindowToTaskbar(window, app.colorBGTaskbar, window.titlebarIcon.icon)
		return window
	return null

static func SetupWindowWidget(window: FakeWindow, app: WidgetConfig) -> FakeWindow:
	if(window):
		window.titlebarIcon.icon = app.icon
		if(!app.customWindowTitle.is_empty()):
			window.titleText.text = app.customWindowTitle
		# window.position.x = app.startWindowPlacement.position.x * DefaultValues.get_window().size.x
		# window.position.y = app.startWindowPlacement.position.y * DefaultValues.get_window().size.y
		# window.size.x = app.startWindowPlacement.size.x * DefaultValues.get_window().size.x - window.position.x
		# window.size.y = app.startWindowPlacement.size.y * DefaultValues.get_window().size.y - window.position.y

		window.position.x = app.startWindowPlacement.position.x * UtilityHelper.GetDesktopRect().size.x + UtilityHelper.GetDesktopRect().position.x
		window.position.y = app.startWindowPlacement.position.y * UtilityHelper.GetDesktopRect().size.y + UtilityHelper.GetDesktopRect().position.y
		window.size.x = app.startWindowPlacement.size.x * UtilityHelper.GetDesktopRect().size.x - window.position.x
		window.size.y = app.startWindowPlacement.size.y * UtilityHelper.GetDesktopRect().size.y - window.position.y


		window.SetWindowResizeable(app.resizable)
		window.SetBorderless(app.borderless)
	return window

static func CreateWidgetWindow(app: WidgetConfig, filepath: String) -> Node:
	var appData: Dictionary = {"Filename":filepath,"manifest":app}
	var window: FakeWindow = Desktop.instance.SpawnWindow(app.path, app.path.get_file(), filepath, appData)
	if(window):
		WidgetManager.SetupWindowWidget(window, app)
		window.SetID("%s:%s" % [app.name, filepath])

		Desktop.instance.AddWindowToTaskbar(window, app.colorBGTaskbar, window.titlebarIcon.icon)
		return window
	return null

static func GetWidgetIcon(appName: String) -> Texture2D:
	if(registeredWidgets.has(appName)):
		var app: WidgetConfig = widgetsList[registeredWidgets[appName]]
		return app.icon
	return null

static func GetAppIconByLocation(filepath: String) -> Texture2D:
	var app: WidgetConfig = WidgetManager.LoadWidgetConfig(filepath)
	return app.icon

static func GetPathToWidgets() -> String:
	return ProjectSettings.globalize_path("user://widgets/")
