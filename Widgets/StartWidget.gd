extends TaskbarWidget

## The start menu in the taskbar. Handles showing and hiding the start menu.
class_name  StartWidget


@export var startMenu: Control
@export var shutdownSplash: PackedScene = preload("res://Scenes/Main/Boot Splash/boot_splash.tscn")

func _ready() -> void:
	super._ready()

	clickHandler.LeftClick.connect(HandleLeftClick)

func HandleRightClick() -> void:
	super.HandleRightClick()
	RClickMenuManager.instance.AddMenuItem("Shutdown", Shutdown, ResourceManager.GetResource("Shutdown"), Color.RED)

func HandleLeftClick() -> void:
	#show all apps list
	var appsList: Array[AppManifest] = AppManager.GetListOfAppsAvailable()
	
	RClickMenuManager.instance.ShowMenu("App/Games list", self)
	for app: AppManifest in appsList:
		RClickMenuManager.instance.AddMenuItem(app.name, func() -> void:
			AppManager.LaunchApp(app.key, ResourceManager.GetPathToUserFiles()),
			ResourceManager.GetResource("Start"), Color.SPRING_GREEN)
	

func Shutdown() -> void:
	var splashscreen: BootSplash = shutdownSplash.instantiate()
	if(splashscreen):
		get_tree().root.add_child(splashscreen)


func _on_mouse_entered() -> void:
	TweenAnimator.spotlight_on(self, 1)#(self, 1.3, 0.2)
	TweenAnimator.heartbeat(self, 0.1, 0.5)#(self, 1.3, 0.2)

func _on_mouse_exited() -> void:
	TweenAnimator.spotlight_off(self, 1)
	TweenAnimator.heartbeat(self, 0.1, 0.5)#(self, 1.3, 0.2)


func show_start_menu() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(startMenu, "position:y", -startMenu.size.y, 0.3).from(-50)

func hide_start_menu() -> void:
	# Called from clicking on desktop
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(startMenu, "position:y", 50, 0.3)