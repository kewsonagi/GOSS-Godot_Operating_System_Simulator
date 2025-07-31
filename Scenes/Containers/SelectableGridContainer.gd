extends Control
class_name SelectableGridContainer

## Smoothly tweens all children into place. Used in file managers.

@export_enum("Horizontal", "Vertical", "Grid") var direction: String = "Horizontal"
## How often the update function runs, in seconds. Low values are performance intensive!
@export var updateRate: float = 0.15
## The speed of the Tween animation, in seconds.
@export var animSpeed: float = 0.5

@export_group("Spacing")
@export var hSpacing: int = 10
@export var vSpacing: int = 10

@export_group("Margins")
@export var leftMargin: int
@export var topMargin: int
@export var rightMargin: int
@export var bottomMargin: int

## Global Tween so it doesn't create one each time the function runs
var tween: Tween
## Bool used to check if there's a cooldown or not
var nUpdateTime: int
## Global Vector2 to calculate the next position of each container child
var nNextPosition: Vector2
var nLineCount: int = 0

var currentChildren: Array[Node]
var currentVisible: Array[Node]
@export var childContainer: Control

func _ready() -> void:
	# childContainer = Control.new()
	# childContainer.position = position + Vector2(leftMargin, topMargin)
	# childContainer.size = size - Vector2(rightMargin, bottomMargin)
	# add_child(childContainer)
	
	nUpdateTime = Time.get_ticks_msec()

	currentChildren = childContainer.get_children()
	# I don't know why but having a container parent forces this node's size to be (0, 0) in the first frame
	UpdateItems()

func VisibleChildToggle(child: Control) -> void:
	if(!child):return
	if(child.visible):
		currentVisible.append(child)
	else:
		currentVisible.erase(child)

func HideChild(child: Control) -> void:
	currentVisible.erase(child)

func AddChild(child: Control) -> void:
	if(!child):return
	#currentChildren.append(child)
	childContainer.add_child(child)
	child.visibility_changed.connect(VisibleChildToggle.bind(child))

func GetChildCount() -> int:
	return currentChildren.size()

func GetChildren() -> Array[Node]:
	return currentChildren

func GetChild(index: int) -> Node:
	return currentChildren[index]

func ClearAll() -> void:
	currentChildren = childContainer.get_children()
	for child: Node in currentChildren:
		child.queue_free()
	currentChildren.clear()
	
	
func RemoveChild(child: Control) -> void:
	if(!child):return
	if(child.visibility_changed.is_connected(VisibleChildToggle)):
		child.visibility_changed.disconnect(VisibleChildToggle)
	childContainer.remove_child(child)
	#currentChildren.erase(child)


func UpdateItems() -> void:
	if (float(Time.get_ticks_msec() - nUpdateTime) / 1000.0) < updateRate:
		return
	
	nNextPosition = Vector2(0, 0)
	if tween:
		tween.kill()
	
	if direction == "Horizontal":
		UpdateHorizontal()
	elif direction == "Vertical":
		UpdateVerticle()
	elif(direction == "Grid"):
		UpdateGrid()

	nUpdateTime = Time.get_ticks_msec()

func UpdateHorizontal() -> void:
	var new_line_count: int = 0
	nLineCount = 0

	var biggestChild: int = 0
	
	currentChildren = childContainer.get_children()
	for child: Node in currentChildren:
		#if !(child is BaseFile):
		#	continue
		
		if nNextPosition.x + child.size.x > size.x:
			nNextPosition.x = 0
			nNextPosition.y += biggestChild + vSpacing
			biggestChild = 0

			nLineCount = new_line_count
			new_line_count = 0
			
		if child.position != nNextPosition:
			if tween == null or !tween.is_running():
				CreateTween()
			#child.position = nNextPosition

			tween.tween_property(child, "position", nNextPosition, animSpeed)
			#tween.tween_property(child, "position", next_position, animation_speed)
		
		if child.size.y > biggestChild:
			biggestChild = child.size.y
		
		nNextPosition.x += child.size.x + hSpacing
		new_line_count += 1
	
	if nLineCount == 0:
		nLineCount = new_line_count
	# if get_parent() is ScrollContainer:
	# 	if next_position.y + tallest_child > get_parent().size.y:
	# 		custom_minimum_size.y = next_position.y + tallest_child + down_margin
	# 	else:
	# 		custom_minimum_size.y = start_min_size.y
	

func UpdateVerticle() -> void:
	var new_line_count: int = 0
	nLineCount = 0

	var biggestChild: int = 0
	currentChildren = childContainer.get_children()
	for child: Node in currentChildren:
		#if !(child is BaseFile):
		#	continue
		
		if nNextPosition.y + child.size.y > size.y:
			nNextPosition.y = 0
			nNextPosition.x += biggestChild + hSpacing
			biggestChild = 0

			nLineCount = new_line_count
			new_line_count = 0
			
		if child.position != nNextPosition:
			if tween == null or !tween.is_running():
				CreateTween()
			#child.position = nNextPosition

			tween.tween_property(child, "position", nNextPosition, animSpeed)
		
		if child.size.x > biggestChild:
			biggestChild = child.size.x
		
		nNextPosition.y += child.size.y + vSpacing
		new_line_count += 1
	
	if nLineCount == 0:
		nLineCount = new_line_count
	# if get_parent() is ScrollContainer:
	# 	if next_position.x + longest_child > get_parent().size.x:
	# 		custom_minimum_size.x = next_position.x + longest_child + right_margin
	# 	else:
	# 		custom_minimum_size.x = start_min_size.x

func UpdateGrid() -> void:
	var biggestChildH: int = 0
	var biggestChildV: int = 0
	
	currentChildren = childContainer.get_children()
	for child: Node in currentChildren:
		#if !(child is BaseFile):
		#	continue
		
		if nNextPosition.x + child.size.x > size.x:
			nNextPosition.x = 0
			nNextPosition.y += biggestChildV + vSpacing

			biggestChildV = 0
			biggestChildH = 0
			
		if child.position != nNextPosition:
			if tween == null or !tween.is_running():
				CreateTween()
			child.self_modulate.a = 0
			tween.tween_property(child, "self_modulate:a", 1, animSpeed)
			#tween.tween_property(child, "position", next_position, animation_speed)
			child.position = nNextPosition
		
		if child.size.y > biggestChildV:
			biggestChildV = child.size.y
		if child.size.x > biggestChildH:
			biggestChildH = child.size.x
		
		nNextPosition.x += child.size.x + hSpacing
	

func CreateTween() -> void:
	tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
