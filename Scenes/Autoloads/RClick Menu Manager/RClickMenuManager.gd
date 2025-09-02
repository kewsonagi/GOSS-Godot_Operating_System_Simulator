extends Panel
class_name RClickMenuManager

## An autoload to manage the context menu (right click menu)

@export var menuItem: PackedScene = preload("res://Scenes/Autoloads/RClick Menu Manager/RClickMenuOption.tscn")
@export var menuItemSeparator: PackedScene = preload("res://Scenes/Autoloads/RClick Menu Manager/RClickMenuSeparator.tscn")

@export var itemContainer: Node
var submenus: Array[Node]
var submenuTemplate: Node
@export var title: RichTextLabel
## The Control node that got right clicked.
var menuCaller: Control
var currentMenuItems: Array[RClickMenuOption]
var startSize: Vector2

static var instance: RClickMenuManager = null
signal Dismissed()

## Checks if the mouse is currently over the menu
var is_mouse_over: bool

func _ready() -> void:
	if(!instance):
		instance = self;
	else:
		queue_free()
	startSize = size + Vector2(0, 0)
	visible = false

	submenuTemplate = itemContainer.duplicate()
	submenuTemplate.visible = false

#setup the menu and list with name and caller
func ShowMenu(menuName: String, caller: Control, bgColor: Color = Color.REBECCA_PURPLE) -> void:
	self.visible = true
	size = startSize
	menuCaller = caller
	currentMenuItems.clear()
	for child: Node in itemContainer.get_children():
		child.queue_free()
	
	title.text = menuName

	global_position = get_global_mouse_position() + Vector2(-10, -10)
	clamp_inside_viewport()
	modulate.a = 0
	self_modulate = bgColor
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1, 0.15)
	is_mouse_over = true

func IsOpened() -> bool:
	return self.visible

#add new item to the menu with a callback for what to do
func AddMenuItem(itemName: String, callback: Callable, itemIcon: Texture2D=null, bgColor: Color = Color.PALE_TURQUOISE) -> void:
	self.visible = true
	var newItem: RClickMenuOption = menuItem.instantiate()
	newItem.optionText.text = itemName
	newItem.optionIcon.texture = itemIcon

	newItem.option_clicked.connect(DismissMenu)
	newItem.option_clicked.connect(callback)
	newItem.SetColor(bgColor)

	var separator: Node = menuItemSeparator.instantiate()
	itemContainer.add_child(separator)

	currentMenuItems.append(newItem)
	itemContainer.add_child(newItem)
	
	
	#add menu size to our size, resize X if new item is the largest item
	if(size.x<newItem.size.x):
		size.x = newItem.size.x
	size.y += newItem.size.y + separator.size.y

	clamp_inside_viewport()
	is_mouse_over = true

func _input(event: InputEvent) -> void:
	if(!self.visible): return

	var thisContainer: Rect2
	thisContainer.position = self.global_position
	thisContainer.size = self.size
	if(!thisContainer.has_point(get_global_mouse_position())):
		is_mouse_over = false
	else:
		is_mouse_over = true
	
	if(!is_mouse_over and event.is_pressed()):
		DismissMenu()
		return

func DismissMenu() -> void:
	if(!self.visible): return
	
	self.visible = false
	for item:RClickMenuOption in currentMenuItems:
		if(item.optionIcon):
			ResourceManager.ReturnResourceByResource(item.optionIcon.texture)
	Dismissed.emit()

func clamp_inside_viewport() -> void:
	var game_window_size: Vector2 = UtilityHelper.GetScreenRect().size
	if (size.y > game_window_size.y - 40):
		size.y = game_window_size.y - 40
	if (size.x > game_window_size.x):
		size.x = game_window_size.x
	
	global_position.y = clamp(global_position.y, 0, game_window_size.y - size.y - 40)
	global_position.x = clamp(global_position.x, 0, game_window_size.x - size.x)
