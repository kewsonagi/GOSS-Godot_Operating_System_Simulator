extends Control

## The resize drag spot in the bottom right of each window.

@export var windowToResize: FakeWindow
@export var bTopLeft: bool = false;
@export var bResizeX: bool = true;
@export var bResizeY: bool = true;
var bIsDragging: bool

var startWindowSize: Vector2
var startDragPosition: Vector2
var startWindowPosition: Vector2
@export var parentWindow: Node

signal window_resized()

func _ready() -> void:
	if(!parentWindow):
		parentWindow = get_parent()

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("LeftClick"):
		bIsDragging = true
		startDragPosition = get_global_mouse_position()
		if(windowToResize):
			startWindowSize = windowToResize.size
		else:
			startWindowSize = get_viewport_rect().size
		startWindowPosition = windowToResize.position
	elif event.is_action_released(&"LeftClick"):
			bIsDragging = false
		

func _physics_process(_delta: float) -> void:
	if bIsDragging:
		# TODO optimize this a bit?
		window_resized.emit()
		var amountChanged: Vector2 = get_global_mouse_position() - startDragPosition;
		# if Input.is_key_pressed(KEY_SHIFT):
		# 	var aspect_ratio: float = start_size.x / (start_size.y - 30)
		# 	windowToResize.size.x = start_size.x + (get_global_mouse_position().x - mouse_start_drag_position.x) * aspect_ratio
		# 	windowToResize.size.y = start_size.y + get_global_mouse_position().x - mouse_start_drag_position.x
		# else:
		# 	windowToResize.size = start_size + get_global_mouse_position() - mouse_start_drag_position
		if(!bTopLeft):
			if(bResizeX):
				windowToResize.size.x = startWindowSize.x + amountChanged.x
			if(bResizeY):
				windowToResize.size.y = startWindowSize.y + amountChanged.y
		else:
			if(bResizeX):
				windowToResize.position.x = startWindowPosition.x + amountChanged.x
				windowToResize.size.x = startWindowSize.x - amountChanged.x
			if(bResizeY):
				windowToResize.position.y = startWindowPosition.y + amountChanged.y
				windowToResize.size.y = startWindowSize.y - amountChanged.y
		windowToResize.clamp_window_inside_viewport()
