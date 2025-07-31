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
signal DragStart
signal DragEnd

@export var doubleClickSpeed: float = 0.2
#threashold in pixel distance
@export var dragThreashold: int = 5

var bMouseover: bool = false
var bClicked: bool = false
var fTimeClicked: float = 0
var nTimeOfClick: int = 0
var bDragging: bool = false
var vStartDragPosition: Vector2

func _on_mouse_entered() -> void:
	bMouseover = true
	HoveringStart.emit()
func _on_mouse_exited() -> void:
	bMouseover = false
	HoveringEnd.emit()

# func _process(_delta: float) -> void:
# 	if(self.visible):
# 		if(bClicked):
# 			fTimeClicked += _delta
func _process(_delta: float) -> void:
	if (visible and bClicked):
		var posChange: Vector2 = get_global_mouse_position() - vStartDragPosition;
		if(posChange.x > 5 or posChange.x < -5 or posChange.y > 5 or posChange.y < -5):
			bDragging = true
			DragStart.emit()

func _input(event: InputEvent) -> void:
	if(!self.visible):return
	if(event.is_action_pressed(&"LeftClick")):
		if(!bMouseover):
			var thisContainer: Rect2
			thisContainer.position = self.global_position
			thisContainer.size = self.size
			if(!thisContainer.has_point(get_global_mouse_position())):
				bClicked = false
				NotClicked.emit()
	elif(event.is_action_released(&"LeftClick")):
		if(bClicked):
			LeftClickRelease.emit()
		bClicked = false
		if(bDragging):
			DragEnd.emit()
		bDragging = false
	elif(event.is_action_released(&"RightClick")):
		if(bClicked):
			RightClickRelease.emit()
		if(bDragging):
			DragEnd.emit()
		bClicked = false

func _on_gui_input(event: InputEvent) -> void:
	if(bMouseover):
		if(event.is_action_pressed(&"RightClick")):
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

func HandleRightClick() -> void:
	RightClick.emit()
func HandleLeftClick() -> void:
	LeftClick.emit()