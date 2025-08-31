extends Control
class_name HandleClick

signal RightClick
signal RightClickRelease
signal LeftClick
signal LeftClickRelease
signal HoveringStart
signal HoveringEnd
signal DoubleClick
signal NotClicked
signal NotClickedRelease
signal DragStart
signal DragEnd
signal Dragging(dragDistDelta: Vector2, dragDistanceAbsolute: Vector2)
signal ScrollingV(delta: float)
signal ScrollingH(delta: float)
signal BackButtonPressed
signal ForwardButtonPressed
signal MiddleButtonPressed
signal MiddleButtonRelease

@export var doubleClickSpeed: float = 0.2
#threashold in pixel distance
@export var dragThreashold: int = 5

var bMouseover: bool = false
var bClicked: bool = false
var fTimeClicked: float = 0
var nTimeOfClick: int = 0
var bDragging: bool = false
var vStartDragPosition: Vector2
var vLastDragPosition: Vector2
var bLMB: bool
var bRMB: bool
var bMMB: bool

var scrollUp: bool = false
var scrollDown: bool = false
var scrollLeft: bool = false
var scrollRight: bool = false

func _on_mouse_entered_parent() -> void:
	bMouseover = true
	HoveringStart.emit()
func _on_mouse_exited_parent() -> void:
	bMouseover = false
	HoveringEnd.emit()
	scrollUp = false
	scrollDown = false
	scrollLeft = false
	scrollRight = false

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if(get_parent()):
		get_parent_control().mouse_entered.connect(_on_mouse_entered_parent)
		get_parent_control().mouse_exited.connect(_on_mouse_exited_parent)
		get_parent_control().gui_input.connect(_on_gui_input_parent)

func _physics_process(_delta: float) -> void:
	if(!visible):return

	if (bClicked):
		var posChange: Vector2 = get_global_mouse_position() - vStartDragPosition;
		if(bDragging):
			Dragging.emit((get_global_mouse_position() - vLastDragPosition) * _delta, posChange)
			vLastDragPosition = get_global_mouse_position()
			return
		if(posChange.x > dragThreashold or posChange.x < -dragThreashold or posChange.y > dragThreashold or posChange.y < -dragThreashold):
			bDragging = true
			vStartDragPosition = get_global_mouse_position()
			vLastDragPosition = vStartDragPosition
			DragStart.emit()

func _input(event: InputEvent) -> void:
	if(!self.visible):return
	
	# if(!bMouseover):
	# 	if(self.get_global_rect().has_point(get_global_mouse_position())):
	# 		bMouseover = true
	# 		HoveringStart.emit()
	# else:
	# 	if(!self.get_global_rect().has_point(get_global_mouse_position())):
	# 		bMouseover = false
	# 		HoveringEnd.emit()
	# 		scrollUp = false
	# 		scrollDown = false
	# 		scrollLeft = false
	# 		scrollRight = false
	
	# ##########################
	# ##########################
	# ## old ongui events
	# if(bMouseover):
	# 	if(event.is_action_pressed(&"RightClick")):
	# 		vStartDragPosition = get_global_mouse_position()
	# 		vLastDragPosition = vStartDragPosition
	# 		HandleRightClick()
	# 		bClicked = true
	# 	elif(event.is_action_pressed(&"LeftClick")):
	# 		fTimeClicked = float(Time.get_ticks_msec() - nTimeOfClick) / 1000.0
	# 		if(fTimeClicked<doubleClickSpeed*1.5):
	# 			DoubleClick.emit()
	# 		else:
	# 			HandleLeftClick()
	# 		fTimeClicked = 0
	# 		nTimeOfClick = Time.get_ticks_msec()
	# 		bClicked = true
	# 		vStartDragPosition = get_global_mouse_position()
	# 		vLastDragPosition = vStartDragPosition
	# 	elif(event.is_action_pressed(&"MiddleMouse")):
	# 		bClicked = true
	# 		MiddleButtonPressed.emit()
	# 	elif(event.is_action_pressed(&"MouseBack")):
	# 		BackButtonPressed.emit()
	# 	elif(event.is_action_pressed(&"MouseForward")):
	# 		ForwardButtonPressed.emit()
	##########################
	##########################
	
	scrollUp = false
	scrollDown = false
	scrollLeft = false
	scrollRight = false
	if(event is InputEventMouseButton):
		var mouseEvent: InputEventMouseButton = event as InputEventMouseButton
		if(mouseEvent.button_index == MOUSE_BUTTON_LEFT):
			bLMB = true
		if(mouseEvent.button_index == MOUSE_BUTTON_RIGHT):
			bRMB = true
		if(mouseEvent.button_index == MOUSE_BUTTON_MIDDLE):
			bMMB = true
		
	if(event.is_action_pressed(&"LeftClick")):
		if(!bMouseover):
			vStartDragPosition = get_global_mouse_position()
			vLastDragPosition = vStartDragPosition
			
			if(!self.get_global_rect().has_point(get_global_mouse_position())):
				bClicked = false
				NotClicked.emit()
	elif(event.is_action_released(&"LeftClick")):
		if(!bMouseover):
			vStartDragPosition = get_global_mouse_position()
			vLastDragPosition = vStartDragPosition
			if(!self.get_global_rect().has_point(get_global_mouse_position())):
				bClicked = false
				NotClickedRelease.emit()
		if(bClicked):
			LeftClickRelease.emit()
		bClicked = false
		if(bDragging):
			DragEnd.emit()
		bDragging = false
		bLMB = false
		bRMB = false
		bMMB = false
	elif(event.is_action_released(&"RightClick")):
		if(!bMouseover):
			vStartDragPosition = get_global_mouse_position()
			vLastDragPosition = vStartDragPosition
			if(!self.get_global_rect().has_point(get_global_mouse_position())):
				bClicked = false
				NotClickedRelease.emit()
		if(bClicked):
			RightClickRelease.emit()
		if(bDragging):
			DragEnd.emit()
		bClicked = false
		bLMB = false
		bRMB = false
		bMMB = false
	elif(event.is_action_released(&"MiddleMouse")):
		if(bClicked):
			MiddleButtonRelease.emit()
		if(bDragging):
			DragEnd.emit()
		bClicked = false
		bLMB = false
		bRMB = false
		bMMB = false
	if(event is InputEventMouseButton):
		var mouseEvent: InputEventMouseButton = event as InputEventMouseButton
		if(mouseEvent.button_index == MOUSE_BUTTON_WHEEL_UP):
			scrollUp = true
			ScrollingV.emit(1*get_process_delta_time());
		if(mouseEvent.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			scrollDown = true
			ScrollingV.emit(-1*get_process_delta_time());
		if(mouseEvent.button_index == MOUSE_BUTTON_WHEEL_RIGHT):
			scrollRight = true
			ScrollingH.emit(1*get_process_delta_time());
		if(mouseEvent.button_index == MOUSE_BUTTON_WHEEL_LEFT):
			scrollLeft = true
			ScrollingH.emit(-1*get_process_delta_time());
	#if(event is InputEventJoypadMotion)

func _on_gui_input_parent(event: InputEvent) -> void:
	if(bMouseover):
		if(event.is_action_pressed(&"RightClick")):
			vStartDragPosition = get_global_mouse_position()
			vLastDragPosition = vStartDragPosition
			HandleRightClick()
			bClicked = true
		elif(event.is_action_pressed(&"LeftClick")):
			fTimeClicked = float(Time.get_ticks_msec() - nTimeOfClick) / 1000.0
			if(fTimeClicked<doubleClickSpeed*1.5):
				DoubleClick.emit()
			else:
				HandleLeftClick()
			fTimeClicked = 0
			nTimeOfClick = Time.get_ticks_msec()
			bClicked = true
			vStartDragPosition = get_global_mouse_position()
			vLastDragPosition = vStartDragPosition
		elif(event.is_action_pressed(&"MiddleMouse")):
			bClicked = true
			MiddleButtonPressed.emit()
		elif(event.is_action_pressed(&"MouseBack")):
			BackButtonPressed.emit()
		elif(event.is_action_pressed(&"MouseForward")):
			ForwardButtonPressed.emit()

func HandleRightClick() -> void:
	RightClick.emit()
func HandleLeftClick() -> void:
	LeftClick.emit()
