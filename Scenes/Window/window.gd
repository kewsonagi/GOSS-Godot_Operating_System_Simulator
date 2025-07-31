extends Panel
class_name FakeWindow

## The base class for each window. Handles moving, resizing, minimizing, etc.
static var num_of_windows: int

@export_category("Title Bar")
@export var top_bar: Panel
@export var maximizeButton: Button
var maximize_icon: Texture2D# = load("res://Art/shaded/37-plus-sign.png")
var unmaximize_icon: Texture2D# = load("res://Art/Icons/shrink.png")
@export var minimizeButton: Button
@export var closeButton: Button
var minimizeIcon: Texture2D
var closeIcon: Texture2D
@export var titleText: RichTextLabel
@export var titlebarIcon: Button

var title_text: String

@export_category("Resize Properties")
var old_unmaximized_position: Vector2
var old_unmaximized_size: Vector2
@export var resizeBorderWidth: float
@export var resizeBorderHeight: float
var bDraggingResize: bool = false;
var viewportToCheck: Viewport

@export_category("Dragging properties")
var mouseClicked: bool
var leftClick: bool
var rightClick: bool
var timeOfClick: int
@export var doubleClickThreashold: float = 0.5

var scrolled: bool
var amountScrolledVerticle: float
var amountScrolledHorizontal: float

var draggingStart: bool
var draggingEnd: bool
var dragging: bool
var windowMouseDragOffset: Vector2
var start_drag_position: Vector2
var mouse_start_drag_position: Vector2


@export_category("Window Properties")
@export var marginContainer: MarginContainer
@export var transitionsNode: Control
@export var minWindowSize: Vector2 = Vector2(50,50)
@export var taskbarSize: float = 60
var startPanelColorAlpha: float
var startMarginLeft: float
var startMarginRight: float
var startMarginTop: float
var startMarginBottom: float

var is_dragging: bool
var is_being_deleted: bool
var is_minimized: bool
var is_selected: bool
var is_maximized: bool
var windowID: String
var windowOpened: bool = true
var startShadowSize: int

var creationData: Dictionary

@export_category("Preview Window Properties")
@export var previewCaptureViewport: SubViewport

@export_category("Save Settings")
var saveFileName: String = "window_settings"
static var windowSaveFile: IndieBlueprintSavedGame
var windowSavePosKey: String
var windowSaveSizeKey: String
var windowSaveMaximizedKey: String
var windowOpenedKey: String

#region signals and initialization of data

signal minimized(is_minimized: bool)
signal selected(is_selected: bool)
signal maximized(is_maximized: bool)
signal deleted(window: FakeWindow)

func SetData(data: Dictionary) -> void:
	creationData = data;
	
#set window ID and initialize any window specific key/value pairs for saving settings
func SetID(id:String) -> void:
	windowID = id
	windowSavePosKey = "%s%s" % [windowID, "pos"]
	windowSaveSizeKey = "%s%s" % [windowID, "size"]
	windowSaveMaximizedKey = "%s%s" % [windowID, "maximized"]
	windowOpenedKey = "%s%s" % [windowID, "opened"]

	#save section
	if(!windowSaveFile):return

	if(windowSaveFile.data.has(windowSaveSizeKey)):
		position = windowSaveFile.data[windowSavePosKey]
		size = windowSaveFile.data[windowSaveSizeKey]
		if(windowSaveFile.data.has(windowSaveMaximizedKey)):
			is_maximized = windowSaveFile.data[windowSaveMaximizedKey]
		if(is_maximized):
			is_maximized = false #mark it not maximized so it doesnt minimize on load instead
		clamp_window_inside_viewport()#just incase a window gets loaded to an offscreen position

func _ready() -> void:
	windowOpened = true
	viewportToCheck = get_tree().root.get_viewport()
	# Duplicate theme override so values can be set without affecting other windows
	self["theme_override_styles/panel"] = self["theme_override_styles/panel"].duplicate()
	top_bar["theme_override_styles/panel"] = top_bar["theme_override_styles/panel"].duplicate()
	startPanelColorAlpha = self["theme_override_styles/panel"]["bg_color"].a
	startShadowSize = self["theme_override_styles/panel"]["shadow_size"]

	startMarginLeft = marginContainer["theme_override_constants/margin_left"]
	startMarginRight = marginContainer["theme_override_constants/margin_right"]
	startMarginTop = marginContainer["theme_override_constants/margin_top"]
	startMarginBottom = marginContainer["theme_override_constants/margin_bottom"]

	num_of_windows += 1
	select_window(false)
	
	viewportToCheck.size_changed.connect(_on_viewport_size_changed)
	UIAnimation.animate_pop(self)
	TweenAnimator.fade_in(self, 0.2)
	maximize_icon = ResourceManager.GetResource("Plus")
	unmaximize_icon = ResourceManager.GetResource("WindowRestore")
	minimizeIcon = ResourceManager.GetResource("Minus")
	closeIcon = ResourceManager.GetResource("Close")
	if(minimizeButton):
		minimizeButton.icon = minimizeIcon
	if(closeButton):
		closeButton.icon = closeIcon
	
	saveFileName = IndieBlueprintSavedGame.clean_filename(saveFileName)
	if(!windowSaveFile):
		if(!IndieBlueprintSaveManager.save_filename_exists(saveFileName)):
			windowSaveFile = IndieBlueprintSaveManager.create_new_save(saveFileName)
		else:
			windowSaveFile = IndieBlueprintSaveManager.load_savegame(saveFileName)
			if(!windowSaveFile):
				windowSaveFile = IndieBlueprintSaveManager.create_new_save(saveFileName)
	
	SetID(windowID)

func SaveWindowState() -> void:
	windowSaveFile.data[windowSavePosKey] = position
	windowSaveFile.data[windowSaveSizeKey] = size
	windowSaveFile.data[windowSaveMaximizedKey] = is_maximized
	windowSaveFile.data[windowOpenedKey] = true
	windowSaveFile.write_savegame();


#endregion
#region processing inputs

func _process(_delta: float) -> void:
	if is_dragging:
		var mouseChangeInPosition: Vector2 = get_global_mouse_position() - mouse_start_drag_position;
		if(mouseChangeInPosition.x > 5 or mouseChangeInPosition.x < -5 or mouseChangeInPosition.y > 5 or mouseChangeInPosition.y < -5):
			#moved enough to un-maximize window(restore)
			if(is_maximized):
				size = old_unmaximized_size
				windowSaveFile.data[windowSaveSizeKey] = size

				maximize_window(false)
				#self.resized.emit()
				global_position = get_global_mouse_position() - Vector2(size.x/2.0, 20)
				
				start_drag_position = global_position
				mouse_start_drag_position = get_global_mouse_position()
				windowMouseDragOffset = mouse_start_drag_position - start_drag_position
				
		global_position = get_global_mouse_position() - windowMouseDragOffset

		clamp_window_inside_viewport()
		windowSaveFile.data[windowSavePosKey] = position
	
	if(bDraggingResize):
		HandleResize()

#clicked inside the window itself
func _gui_input(event: InputEvent) -> void:
	if(event.is_action_pressed(&"LeftClick")):
		if(!is_selected):
			select_window(true)

		if(!leftClick):#just started left click
			mouseClicked = true
			leftClick = true
		
		bDraggingResize = ClickedResizeWindowArea()
		if(bDraggingResize):
			start_drag_position = global_position
			mouse_start_drag_position = get_global_mouse_position()
			windowMouseDragOffset = mouse_start_drag_position - start_drag_position

	if(event.is_action_pressed(&"RightClick")):
		if(!is_selected):
			select_window(true)

		if(!rightClick):#just started right click
			mouseClicked = true
			rightClick = true;

	if(event.is_action_released(&"LeftClick") or event.is_action_released(&"RightClick")):#released hold/click buttons
		mouseClicked = false
		leftClick = false;
		rightClick = false;
		bDraggingResize = false;

#clicked inside the window titlebar
func _on_top_bar_gui_input(event: InputEvent) -> void:
	if(event.is_action_pressed(&"LeftClick")):
		var timeSinceLastClick:float = float(Time.get_ticks_msec() - timeOfClick)/1000.0
		if(timeSinceLastClick < doubleClickThreashold):
				#passed the double click check
				#toggle maximizing the window
			maximize_window()
		timeOfClick = Time.get_ticks_msec()
		if(!is_dragging):#if we just clicked the title bar, select it
			is_dragging = true
			select_window(true)
			start_drag_position = global_position
			mouse_start_drag_position = get_global_mouse_position()
			windowMouseDragOffset = mouse_start_drag_position - start_drag_position
	if(event.is_action_released(&"LeftClick")):
		is_dragging = false

#endregion
#region handling interface interactions

func _on_close_button_pressed() -> void:
	if is_being_deleted:
		return
	
	windowOpened = false;
	
	if GlobalValues.selected_window == self:
		GlobalValues.selected_window = null
	
	SaveWindowState()
	
	deleted.emit(self)
	num_of_windows -= 1
	is_being_deleted = true
	TweenAnimator.creep_out(self, 0.3)
	TweenAnimator.fade_out(self, 0.3)
	await get_tree().create_timer(0.3).timeout
	
	queue_free()

func _on_minimize_button_pressed() -> void:
	hide_window()

func _on_maximize_button_pressed() -> void:
	maximize_window()

func _exit_tree() -> void:
	#_on_close_button_pressed()
	SaveWindowState()

func _on_top_bar_mouse_entered() -> void:
	pass # Replace with function body.

func _on_top_bar_mouse_exited() -> void:
	pass # Replace with function body.


#endregion

#region internal funtion handling

var minimizeOP: Operation

#minimize window
func hide_window() -> void:
	if is_minimized:
		return
	minimized.emit(is_minimized)
	
	deselect_window()
	is_minimized = true

	# minimizeOP = Op.sequence(
	# 	Op.node_move2D(Vector2(0, 0), 0.0),
	# 	Op.parallel(
	# 		Op.node_scale2D(Vector2(1.0, 0.0), 1.0),
	# 		Op.node_move2D(Vector2(0, -800), 1.0),
	# 		Op.node_modulate(Color(1, 1, 1, 0), 1.0)),
	# 	Op.wait(1.0),
	# 	Op.node_visible(false)
	# ).set_target(self)
	
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0, 0.5)
	await get_tree().create_timer(0.5).timeout
	
	if !is_selected:
		visible = false
#restore window from minimize
func show_window() -> void:
	if !is_minimized:
		return
	
	is_minimized = false
	
	visible = true
	#TweenAnimator.fade_in(self, 0.3)
	#var tween: Tween = create_tween()
	#tween.set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_IN_OUT)
	#tween.set_parallel(true)
	#tween.tween_property(self, "modulate:a", 1, 0.5)
	select_window(true)
	minimized.emit(is_minimized)
	await get_tree().create_timer(0.5).timeout

#makes window active
func select_window(play_fade_animation: bool) -> void:
	if is_selected:
		return
	
	is_selected = true
	selected.emit(true)
	GlobalValues.selected_window = self
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SPRING)
	tween.tween_property(self["theme_override_styles/panel"], "shadow_size", startShadowSize, 0.25)
	tween.tween_property(self, "modulate:a", 1, 0.5)
	
	# Move in front of all other windows (+2 to ignore wallpaper and bg color)
	get_parent().move_child(self, num_of_windows + 2)
	
	deselect_other_windows()

#deselected window fade out a bit
func deselect_window() -> void:
	if !is_selected:
		return
	
	is_selected = false
	selected.emit(false)
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "modulate:a", 0.85, 0.5)
	tween.tween_property(self["theme_override_styles/panel"], "shadow_size", 0, 0.25)

func deselect_other_windows() -> void:
	for window in get_tree().get_nodes_in_group("window"):
		if window == self:
			continue
		window.deselect_window()


func clamp_window_inside_viewport() -> void:
	if(viewportToCheck):
		var game_window_size: Vector2 = viewportToCheck.get_visible_rect().size
		#not bigger than the godot window
		if (size.y > game_window_size.y - 40):
			size.y = game_window_size.y - 40
		if (size.x > game_window_size.x):
			size.x = game_window_size.x
		
		size.y = clamp(size.y, minWindowSize.y, game_window_size.y-taskbarSize)
		size.x = clamp(size.x, minWindowSize.x, game_window_size.x)

		#position is somewhere inside the window
		#but make sure there is atleast the min window size available so it can still be selected and moved
		global_position.y = clamp(global_position.y, 0, game_window_size.y-60-minWindowSize.y)
		global_position.x = clamp(global_position.x, -size.x+minWindowSize.x, game_window_size.x-minWindowSize.x)

func _on_viewport_size_changed() -> void:
	if is_maximized:
		if(viewportToCheck):
			var new_size: Vector2 = viewportToCheck.get_visible_rect().size
			new_size.y -= 60 #Because taskbar
			global_position = Vector2.ZERO
			size = new_size
	
	clamp_window_inside_viewport()



func maximize_window(animatePos: bool = true) -> void:
	select_window(true)
	if is_maximized:
		is_maximized = !is_maximized
		maximizeButton.icon = maximize_icon
		
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		if(animatePos):
			tween.tween_property(self, "global_position", old_unmaximized_position, 0.35)
		else:
			global_position = old_unmaximized_position
			
		tween.tween_property(self["theme_override_styles/panel"], "bg_color:a", startPanelColorAlpha, 0.35)
		await tween.tween_property(self, "size", old_unmaximized_size, 0.35).finished

		marginContainer["theme_override_constants/margin_left"] = startMarginLeft
		marginContainer["theme_override_constants/margin_right"] = startMarginRight
		marginContainer["theme_override_constants/margin_top"] = startMarginTop
		marginContainer["theme_override_constants/margin_bottom"] = startMarginBottom
		
		#resizeButton.window_resized.emit()
	else:
		is_maximized = !is_maximized
		maximizeButton.icon = unmaximize_icon
		windowSaveFile.data[windowSaveMaximizedKey] = is_maximized
		
		old_unmaximized_position = global_position
		old_unmaximized_size = size

		marginContainer["theme_override_constants/margin_left"] = 0
		marginContainer["theme_override_constants/margin_right"] = 0
		marginContainer["theme_override_constants/margin_top"] = 0
		marginContainer["theme_override_constants/margin_bottom"] = 0
		
		if(viewportToCheck):
			var new_size: Vector2 = viewportToCheck.get_visible_rect().size
			new_size.y -= 40 #Because taskbar
		
			var tween: Tween = create_tween()
			tween.set_parallel(true)
			tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			if(animatePos):
				tween.tween_property(self, "global_position", Vector2.ZERO, 0.35)
			else:
				global_position = Vector2.ZERO
			tween.tween_property(self["theme_override_styles/panel"], "bg_color:a", startPanelColorAlpha, 0.35)
			await tween.tween_property(self, "size", new_size, 0.35).finished
		
		#resizeButton.window_resized.emit()
	maximized.emit(is_maximized)

func GetSize() -> Vector2:
	return size;

func GetPosition() -> Vector2:
	return position;

func MoveWindow(newPos: Vector2) -> void:
	global_position = newPos;
	old_unmaximized_position = global_position;
	if is_maximized:
		is_maximized = !is_maximized
		maximizeButton.icon = maximize_icon
	clamp_window_inside_viewport()

#resize window width/height, bottom right corner
func ResizeWindow(newSize: Vector2) -> void:
	size = newSize;
	old_unmaximized_size = size
	if is_maximized:
		is_maximized = !is_maximized
		maximizeButton.icon = maximize_icon

func ClickedResizeWindowArea() -> bool:
	if(get_global_mouse_position().x > global_position.x+size.x-resizeBorderWidth and get_global_mouse_position().x < global_position.x + size.x + resizeBorderWidth):
		if(get_global_mouse_position().y > global_position.y + size.x - resizeBorderHeight and get_global_mouse_position().y < global_position.y + size.y + resizeBorderHeight):
			return true
	return false
func HandleResize() -> void:
	var mouseChangeInPosition: Vector2 = get_global_mouse_position() - mouse_start_drag_position;
	if(bDraggingResize):
		size += mouseChangeInPosition


#endregion
