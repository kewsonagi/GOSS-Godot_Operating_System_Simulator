extends Control

## A window's taskbar button. Used to minimize/restore a window.
## Also shows which window is selected or minimized via colors.
@export_category("Icon Properties")
@export var texture_rect: TextureRect
@export var selected_background: TextureRect
@export var active_color: Color = Color("6de700")
@export var disabled_color: Color = Color("908a8c")

@export_category("Preview Icon Properties")
var target_window: FakeWindow
@export var hoverPreviewTexture: TextureRect
@export var previewNode: Control
var storeOldTextureRect: Texture

@export_category("Background Active State Color")
@export var activeBGPanel: Control
@export var hiddenColor: Color = Color.SLATE_GRAY
@export var maximizedColor: Color = Color.INDIAN_RED
@export var foregroundColor: Color = Color.LIGHT_YELLOW
@export var backgroundColor: Color = Color.SANDY_BROWN

var clickHandler: HandleClick

func _ready() -> void:
	target_window.minimized.connect(_on_window_minimized)
	target_window.deleted.connect(_on_window_deleted)
	target_window.selected.connect(_on_window_selected)
	target_window.maximized.connect(_on_window_maximized)
	target_window.resized.connect(_on_window_Resized)
	texture_rect.self_modulate = active_color
	storeOldTextureRect = texture_rect.texture

	clickHandler = get_node_or_null("ClickHandler")
	if(clickHandler):
		clickHandler.LeftClick.connect(HandleLeftClick)
		clickHandler.RightClick.connect(HandleRightClick)
		clickHandler.HoveringStart.connect(_on_mouse_entered)
		clickHandler.HoveringEnd.connect(_on_mouse_exited)

	activeBGPanel["theme_override_styles/panel"] = activeBGPanel["theme_override_styles/panel"].duplicate()
	SetActiveColor()

func _on_mouse_entered() -> void:
	TweenAnimator.float_bob(self, 6, .4)#(self, 1.3, 0.2)

	TweenAnimator.fade_in(previewNode, 0.3)
	previewNode.visible = true;

	if(!target_window.is_minimized):
		hoverPreviewTexture.texture = target_window.previewCaptureViewport.get_viewport().get_texture()

func _on_mouse_exited() -> void:
	TweenAnimator.float_bob(self, 6, .4)#(self, 1.3, 0.2)
	TweenAnimator.fade_out(previewNode, 0.3)
	previewNode.visible = false;

func _on_window_minimized(is_minimized: bool) -> void:
	if(!is_minimized):
		hoverPreviewTexture.texture = target_window.previewCaptureViewport.get_viewport().get_texture()

	SetActiveColor()

func SetActiveColor() -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING).set_parallel()

	if(target_window.is_minimized):
		tween.tween_property(texture_rect, "self_modulate", disabled_color, 0.25)
		tween.tween_property(activeBGPanel["theme_override_styles/panel"], "bg_color", hiddenColor, 0.25)
	elif (target_window.is_maximized):
		tween.tween_property(texture_rect, "self_modulate", active_color, 0.25)
		tween.tween_property(activeBGPanel["theme_override_styles/panel"], "bg_color", maximizedColor, 0.25)
	elif (target_window.is_selected):
		tween.tween_property(texture_rect, "self_modulate", active_color, 0.25)
		tween.tween_property(activeBGPanel["theme_override_styles/panel"], "bg_color", foregroundColor, 0.25)
	else:
		tween.tween_property(selected_background, "self_modulate:a", 0, 0.25)
		tween.tween_property(activeBGPanel["theme_override_styles/panel"], "bg_color", backgroundColor, 0.25)

func _on_window_deleted(window: FakeWindow) -> void:
	queue_free()

func _on_window_selected(selected: bool) -> void:
	SetActiveColor()

func _on_window_maximized(is_maximized: bool) -> void:
	SetActiveColor()

func _on_window_Resized() -> void:
	SetActiveColor()

func HandleLeftClick() -> void:
	if target_window.is_minimized:
		target_window.show_window()
	else:
		if(target_window.is_selected):
			target_window.hide_window()
		else:
			target_window.select_window(true)

func HandleRightClick() -> void:
	RClickMenuManager.instance.ShowMenu("Task Button", self)
	RClickMenuManager.instance.AddMenuItem("Maximize", Maximize, ResourceManager.GetResource("Maximize"))
	RClickMenuManager.instance.AddMenuItem("Hide", Minimize)
	RClickMenuManager.instance.AddMenuItem("Close", Close, ResourceManager.GetResource("Close"))

func Maximize() -> void:
	target_window.maximize_window(true)

func Minimize() -> void:
	target_window.hide_window()

func Close() -> void:
	target_window._on_close_button_pressed()
