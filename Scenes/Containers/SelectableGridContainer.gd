extends Control
class_name SelectableGridContainer

## Smoothly tweens all children into place. Used in file managers.

@export_enum("Horizontal", "Vertical", "Grid") var direction: String = "Horizontal"
## How often the update function runs, in seconds. Low values are performance intensive!
@export var updateRate: float = 0.15
## The speed of the Tween animation, in seconds.
@export var animSpeed: float = 0.5
@export var gridColumbs: int = 3

@export_group("Spacing")
@export var hSpacing: int = 10
@export var vSpacing: int = 10

@export_group("Margins")
@export var leftMargin: int
@export var topMargin: int
@export var rightMargin: int
@export var bottomMargin: int

@export_group("Scrollbars")
@export var hSlideControl: HSlider
@export var hScrollControl: HScrollBar
@export var vSlideControl: VSlider
@export var vScrollControl: VScrollBar
@export var scrollSpeed: Vector2 = Vector2(1.0, 1.0)
var overflow: Vector2

## Global Tween so it doesn't create one each time the function runs
var tween: Tween
## Bool used to check if there's a cooldown or not
var nUpdateTime: int
## Global Vector2 to calculate the next position of each container child
var nNextPosition: Vector2
var nLineCount: int = 0
var largestChild: Vector2 = Vector2(0.0, 0.0)

var currentChildren: Array[Node]
var currentVisible: Array[Node]
@export var childContainer: Control
var timeSinceUpdate: float = 0
var clickHandler: HandleClick


func _ready() -> void:
	clickHandler = UtilityHelper.AddInputHandler(self) #UtilityHelper.AddInputHandler(self)#
	clickHandler.dragThreashold = 10
	clickHandler.DragStart.connect(DragBegin)
	clickHandler.DragEnd.connect(DragEnd)
	clickHandler.Dragging.connect(Dragging)

	clickHandler.LeftClickRelease.connect(LeftClickReleased)
	clickHandler.RightClickRelease.connect(RightClickReleased)
	clickHandler.MiddleButtonRelease.connect(MiddleClickReleased)
	#clickHandler.LeftClick.connect(LeftClickStart)
	#clickHandler.RightClick.connect(RightClickStart)
	#clickHandler.mouse_filter = Control.MOUSE_FILTER_IGNORE

	ShowHBar(false)
	ShowVbar(false)
	hSlideControl.drag_started.connect(ScrollStartedH)
	hSlideControl.drag_ended.connect(ScrollEndedH)
	hSlideControl.value_changed.connect(ScrollChangedH)
	vSlideControl.drag_started.connect(ScrollStartedV)
	vSlideControl.drag_ended.connect(ScrollEndedV)
	vSlideControl.value_changed.connect(ScrollChangedV)

	resized.connect(ContainerResized)

	nUpdateTime = Time.get_ticks_msec()

	currentChildren = childContainer.get_children()
	ContainerResized()
	UpdateItems()


func _physics_process(delta: float) -> void:
	timeSinceUpdate += delta
	if timeSinceUpdate > updateRate:
		timeSinceUpdate = 0
		UpdateItems()


func ContainerResized() -> void:
	#UtilityHelper.Log("container resized: %s" % size)
	childContainer.size.x = size.x - (rightMargin + leftMargin)
	childContainer.size.y = size.y - (bottomMargin + topMargin)
	if totalChildrenSize.x > childContainer.size.x:
		childContainer.size.x = totalChildrenSize.x - (rightMargin + leftMargin)
	if totalChildrenSize.y > childContainer.size.y:
		childContainer.size.y = totalChildrenSize.y - (bottomMargin + topMargin)

	hSlideControl.value = 0
	vSlideControl.value = 0

	UpdateItems()


func VisibleChildToggle(child: Control) -> void:
	if !child:
		return
	if child.visible:
		currentVisible.append(child)
	else:
		currentVisible.erase(child)


func HideChild(child: Control) -> void:
	currentVisible.erase(child)


func AddChild(child: Control) -> void:
	if !child:
		return
	currentChildren.append(child)
	childContainer.add_child(child)
	child.visibility_changed.connect(VisibleChildToggle.bind(child))


func GetChildCount() -> int:
	currentChildren = childContainer.get_children()
	return currentChildren.size()


func GetChildren() -> Array[Node]:
	currentChildren = childContainer.get_children()
	return currentChildren


func GetChild(index: int) -> Node:
	return currentChildren[index]


func ClearAll() -> void:
	currentChildren = childContainer.get_children()
	for child: Node in currentChildren:
		if child.visibility_changed.is_connected(VisibleChildToggle):
			child.visibility_changed.disconnect(VisibleChildToggle)
		child.queue_free()
	currentChildren.clear()
	currentVisible.clear()


func RemoveChild(child: Control) -> void:
	if !child:
		return
	if child.visibility_changed.is_connected(VisibleChildToggle):
		child.visibility_changed.disconnect(VisibleChildToggle)
	childContainer.remove_child(child)
	currentChildren.erase(child)


func UpdateItems() -> void:
	nNextPosition = Vector2(0, 0)
	currentChildren = childContainer.get_children()

	if direction == "Horizontal":
		UpdateHorizontal()
	elif direction == "Vertical":
		UpdateVertical()
	elif direction == "Grid":
		UpdateGrid()
		#ShowHBar(nNextPosition.x > (childContainer.size.x))
		#ShowVbar(nNextPosition.y > (childContainer.size.y))

	nUpdateTime = Time.get_ticks_msec()

	childContainer.position.y = scrollPosition.y + topMargin
	childContainer.position.x = scrollPosition.x + leftMargin

	childContainer.size.x = size.x - (rightMargin + leftMargin)
	childContainer.size.y = size.y - (bottomMargin + topMargin)
	if totalChildrenSize.x > childContainer.size.x:
		childContainer.size.x = totalChildrenSize.x - (rightMargin + leftMargin)
	if totalChildrenSize.y > childContainer.size.y:
		childContainer.size.y = totalChildrenSize.y - (bottomMargin + topMargin)

	ScrollChangedH(hScrollPositionPercent)
	ScrollChangedV(vScrollPositionPercent)


var totalChildrenSize: Vector2


func UpdateHorizontal() -> void:
	var new_line_count: int = 0
	nLineCount = 0
	totalChildrenSize = Vector2.ZERO

	for child: Node in currentChildren:
		if (nNextPosition.x + child.size.x + hSpacing) > (size.x - leftMargin - rightMargin):
			nNextPosition.x = 0
			nNextPosition.y += largestChild.y + vSpacing
			largestChild = Vector2(0.0, 0.0)

			nLineCount = new_line_count
			new_line_count = 0

		child.position = nNextPosition

		if child.size.y > largestChild.y:
			largestChild.y = child.size.y

		if nNextPosition.x + child.size.x > totalChildrenSize.x:
			totalChildrenSize.x = nNextPosition.x + child.size.x
		if nNextPosition.y + child.size.y > totalChildrenSize.y:
			totalChildrenSize.y = nNextPosition.y + child.size.y

		nNextPosition.x += child.size.x + hSpacing
		new_line_count += 1

	if nLineCount == 0:
		nLineCount = new_line_count
	ShowVbar(totalChildrenSize.y > (size.y - bottomMargin - topMargin))


func UpdateVertical() -> void:
	var new_line_count: int = 0
	nLineCount = 0

	for child: Node in currentChildren:
		if (nNextPosition.y + child.size.y + vSpacing) > (size.y - topMargin - bottomMargin):
			nNextPosition.y = 0
			nNextPosition.x += largestChild.x + hSpacing
			largestChild = Vector2(0.0, 0.0)

			nLineCount = new_line_count
			new_line_count = 0

		child.position = nNextPosition

		if child.size.x > largestChild.x:
			largestChild.x = child.size.x

		if nNextPosition.x + child.size.x > totalChildrenSize.x:
			totalChildrenSize.x = nNextPosition.x + child.size.x
		if nNextPosition.y + child.size.y > totalChildrenSize.y:
			totalChildrenSize.y = nNextPosition.y + child.size.y

		nNextPosition.y += child.size.y + vSpacing
		new_line_count += 1

	if nLineCount == 0:
		nLineCount = new_line_count
	ShowHBar(totalChildrenSize.x > (size.x - leftMargin - rightMargin))


func UpdateGrid() -> void:
	var new_line_count: int = 0
	nLineCount = 0
	hSpacing = (size.x - leftMargin - rightMargin) / gridColumbs
	totalChildrenSize.x = hSpacing * gridColumbs
	totalChildrenSize.y = currentChildren.size() / gridColumbs


	for child: Node in currentChildren:
		if (nNextPosition.x + hSpacing) > (size.x - leftMargin - rightMargin):
			nNextPosition.x = 0
			nNextPosition.y += largestChild.y + vSpacing
			largestChild = Vector2(0.0, 0.0)

			nLineCount = new_line_count
			new_line_count = 0

		child.position = nNextPosition
		child.position.x += (hSpacing*0.5-child.size.x*0.5)

		if child.size.y > largestChild.y:
			largestChild.y = child.size.y
		if child.size.x > largestChild.x:
			largestChild.x = child.size.x

		if nNextPosition.y + child.size.y > totalChildrenSize.y:
			totalChildrenSize.y = nNextPosition.y + child.size.y

		nNextPosition.x += hSpacing
		new_line_count += 1
	if nLineCount == 0:
		nLineCount = new_line_count

	ShowVbar(totalChildrenSize.y > (size.y - bottomMargin - topMargin))


func CreateTween() -> void:
	tween = self.get_tree().create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)


#region Scrolling handler functions


func ShowHBar(v: bool = true) -> void:
	if v and !hSlideControl.visible:
		if !clickHandler.ScrollingH.is_connected(MouseScrollLeftRight):
			clickHandler.ScrollingH.connect(MouseScrollLeftRight)
	else:
		if !v and hSlideControl.visible:
			if clickHandler.ScrollingH.is_connected(MouseScrollLeftRight):
				clickHandler.ScrollingH.disconnect(MouseScrollLeftRight)
	hSlideControl.visible = v
	if !v:
		hSlideControl.value = 1
	overflow.x = clamp(nNextPosition.x - childContainer.size.x, 0, childContainer.size.x)


func ShowVbar(v: bool = true) -> void:
	if v and !vSlideControl.visible:
		if !clickHandler.ScrollingV.is_connected(MouseScrollUpDown):
			clickHandler.ScrollingV.connect(MouseScrollUpDown)
	else:
		if !v and vSlideControl.visible:
			if clickHandler.ScrollingV.is_connected(MouseScrollUpDown):
				clickHandler.ScrollingV.disconnect(MouseScrollUpDown)
	vSlideControl.visible = v
	if !v:
		vSlideControl.value = 1
	overflow.y = clamp(nNextPosition.y - childContainer.size.y, 0, childContainer.size.y)


func ShouldShowHBar() -> bool:
	return totalChildrenSize.x > (size.x)


func ShouldShowVBar() -> bool:
	return totalChildrenSize.y > (size.y)


var bScrollingH: bool = false
var bScrollingV: bool = false
var scrollPosition: Vector2 = Vector2.ZERO
var hScrollPositionPercent: float = 0
var vScrollPositionPercent: float = 0


func ScrollStartedH() -> void:
	bScrollingH = true


func ScrollEndedH(valueChanged: bool) -> void:
	bScrollingH = false


func ScrollStartedV() -> void:
	bScrollingV = true


func ScrollEndedV(valueChanged: bool) -> void:
	bScrollingV = false


func ScrollChangedH(value: float) -> void:
	#if hScrollPositionPercent != value:
	#	print("scroll percent: %s, scroll Position X: %s" % [value, scrollPosition.x])
	hScrollPositionPercent = value
	if(totalChildrenSize.x > (size.x - leftMargin - rightMargin)):
		scrollPosition.x = (totalChildrenSize.x - size.x - leftMargin - rightMargin) * (hScrollPositionPercent)
	else:
		scrollPosition.x = 0
	childContainer.position.x = -scrollPosition.x + leftMargin


func ScrollChangedV(value: float) -> void:
	#if vScrollPositionPercent != value:
	#	print("scroll percent: %s, scroll Position Y: %s" % [value, scrollPosition.y])
	vScrollPositionPercent = value
	if(totalChildrenSize.y > (size.y - topMargin - bottomMargin)):
		scrollPosition.y = (totalChildrenSize.y - size.y - topMargin - bottomMargin) * (vScrollPositionPercent)
	else:
		scrollPosition.y = 0
	childContainer.position.y = -scrollPosition.y + topMargin


func MouseScrollUpDown(value: float) -> void:
	vSlideControl.value = vSlideControl.value + value * -scrollSpeed.y


func MouseScrollLeftRight(value: float) -> void:
	hSlideControl.value = hSlideControl.value + value * -scrollSpeed.x


#endregion

#region dragging behaviour function and update selection

var bDragging: bool = false
var bDraggingOld: bool = false
var vStartDragPosition: Vector2
var vEndDragPosition: Vector2
var selectedItems: Array[Node]
var selectedItemsPrev: Array[Node]
var dragRect: Rect2
signal DraggingSelection(selection: Array[Node])
signal DragSelecting(selection: Array[Node], selectionOld: Array[Node])
signal DropSelection(selection: Array[Node])
signal DraggingSelectionEnd(selection: Array[Node])
signal DraggingSelectedBegin(selection: Array[Node])
signal RightClickEnd(selection: Array[Node])
signal LeftClickEnd(selection: Array[Node])
signal MiddleClickEnd(selection: Array[Node])


func LeftClickStart() -> void:
	vStartDragPosition = get_global_mouse_position() - UtilityHelper.GetDesktopRect().position
	dragRect.position = vStartDragPosition


func RightClickStart() -> void:
	vStartDragPosition = get_global_mouse_position() - UtilityHelper.GetDesktopRect().position
	dragRect.position = vStartDragPosition


func LeftClickReleased() -> void:
	#released left click without dragging, reset everything
	if !bDragging:
		LeftClickEnd.emit(selectedItemsPrev)
		bDragging = false
		bDraggingOld = false
		selectedItems.clear()
		selectedItemsPrev.clear()


func RightClickReleased() -> void:
	#released right click without dragging, reset everything
	if !bDragging:
		RightClickEnd.emit(selectedItemsPrev)
		bDragging = false
		bDraggingOld = false
		selectedItems.clear()
		selectedItemsPrev.clear()
	else:
		RightClickEnd.emit(selectedItemsPrev)


func MiddleClickReleased() -> void:
	if !bDragging:
		return
	#released middle click without dragging, reset everything
	if !bDragging:
		MiddleClickEnd.emit(selectedItems)
		bDragging = false
		bDraggingOld = false
		selectedItems.clear()
		selectedItemsPrev.clear()


func ForceSelectItem(child: Node) -> void:
	if currentChildren.has(child):
		selectedItems.append(child)


func ForceDeSelectItem(child: Node) -> void:
	if currentChildren.has(child):
		selectedItems.erase(child)


func DragBegin() -> void:
	bDragging = true
	vStartDragPosition = get_global_mouse_position() - UtilityHelper.GetDesktopRect().position
	dragRect.position = vStartDragPosition

	if bDraggingOld: # we have a current selection
		bDraggingOld = false # are we still hovering something selected
		for child: Node in selectedItems:
			if !child or child.is_queued_for_deletion():
				break

			var childRect: Rect2
			childRect.position = child.position
			childRect.size = child.size
			if childRect.has_point(vStartDragPosition):
				bDraggingOld = true # we are starting a drag ontop a currently selected child
				DraggingSelectedBegin.emit(selectedItems)
				break
	#selectedItems.clear()


func DragEnd() -> void:
	if !bDragging:
		return
	DragSelecting.emit(selectedItems, selectedItemsPrev)
	if bDraggingOld:
		DraggingSelectionEnd.emit(selectedItemsPrev)
	if bDraggingOld and !selectedItemsPrev.is_empty():
		DropSelection.emit(selectedItemsPrev)
		await get_tree().process_frame

	bDragging = false
	vEndDragPosition = get_global_mouse_position() - UtilityHelper.GetDesktopRect().position

	selectedItems.clear()
	bDraggingOld = false

	queue_redraw()


func Dragging(deltaPosition: Vector2, deltaPositionAbsolute: Vector2) -> void:
	if !bDragging:
		DragBegin()
	if bDraggingOld: # we have a current selection
		DraggingSelection.emit(selectedItemsPrev)
		return
	queue_redraw()

	selectedItemsPrev.clear()
	selectedItemsPrev.append_array(selectedItems)
	selectedItems.clear()
	if deltaPositionAbsolute.x > 0:
		dragRect.position.x = vStartDragPosition.x
	else:
		dragRect.position.x = vStartDragPosition.x + deltaPositionAbsolute.x
	if deltaPositionAbsolute.y > 0:
		dragRect.position.y = vStartDragPosition.y
	else:
		dragRect.position.y = vStartDragPosition.y + deltaPositionAbsolute.y

	dragRect.size = abs(deltaPositionAbsolute)
	#dragRect = Rect2(vStartDragPosition, vStartDragPosition + deltaPositionAbsolute)

	for child: Node in currentChildren:
		if SelectionHasChild(child):
			selectedItems.append(child)
	DragSelecting.emit(selectedItems, selectedItemsPrev)


func SelectionHasChild(child: Node) -> bool:
	var childRect: Rect2
	childRect.position = child.position
	childRect.size = child.size

	if dragRect.intersects(childRect):
		return true
	elif dragRect.encloses(childRect):
		return true
	return false


func _draw() -> void:
	#print("drawing drag rect %s" % dragRect)
	if bDragging:
		draw_rect(dragRect, Color.BLUE_VIOLET, true)
