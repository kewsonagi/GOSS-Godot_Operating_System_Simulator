extends Panel
class_name RClickMenuManager

## An autoload to manage the context menu (right click menu)

@export var menuItem: PackedScene = preload("res://Scenes/Autoloads/RClick Menu Manager/RClickMenuOption.tscn")
@export var menuItemSeparator: PackedScene = preload("res://Scenes/Autoloads/RClick Menu Manager/RClickMenuSeparator.tscn")

@export var itemContainer: Node
@export var title: RichTextLabel
## The Control node that got right clicked.
var menuCaller: Control
var currentMenuItems: Array[RClickMenuOption]
var startSize: Vector2

static var instance: RClickMenuManager = null
signal Dismissed()

## Checks if the mouse is currently over the menu
var is_mouse_over: bool

## Used as a cooldown for not spawning the right click menu dozens of times per second
var is_shown_recently: bool

func _ready() -> void:
	if(!instance):
		instance = self;
	else:
		queue_free()
	startSize = size + Vector2(0, 0)
	visible = false

#setup the menu and list with name and caller
func ShowMenu(menuName: String, caller: Control) -> void:
	self.visible = true
	size = startSize
	menuCaller = caller
	currentMenuItems.clear()
	for child: Node in itemContainer.get_children():
		child.queue_free()
	
	title.text = menuName

	global_position = get_global_mouse_position() + Vector2(10, 15)
	clamp_inside_viewport()
	modulate.a = 0
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1, 0.15)

#add new item to the menu with a callback for what to do
func AddMenuItem(itemName: String, callback: Callable, itemIcon: Texture2D=null) -> void:
	self.visible = true
	var newItem: RClickMenuOption = menuItem.instantiate()
	newItem.optionText.text = itemName
	newItem.optionIcon.texture = itemIcon

	newItem.option_clicked.connect(callback)
	newItem.option_clicked.connect(DismissMenu)

	var separator: Node = menuItemSeparator.instantiate()
	itemContainer.add_child(separator)

	currentMenuItems.append(newItem)
	itemContainer.add_child(newItem)
	
	
	#add menu size to our size, resize X if new item is the largest item
	if(size.x<newItem.size.x):
		size.x = newItem.size.x
	size.y += newItem.size.y + separator.size.y

	clamp_inside_viewport()


func _input(event: InputEvent) -> void:
	if(event.is_action_pressed(&"LeftClick")):
		if(self.visible and !is_mouse_over):
			var thisContainer: Rect2
			thisContainer.position = self.global_position
			thisContainer.size = self.size
			if(!thisContainer.has_point(get_global_mouse_position())):
				await get_tree().process_frame
				DismissMenu()
			#HideMenu()
	# if event is InputEventMouseButton and event.is_pressed():
	# 	if event.button_index == 1 and self.visible:
	# 		HideMenu()

func DismissMenu() -> void:
	var tween: Tween = create_tween()
	await tween.tween_property(self, "modulate:a", 0, 0.10).finished
	if modulate.a == 0:
		self.visible = false
	for item:RClickMenuOption in currentMenuItems:
		if(item.optionIcon):
			ResourceManager.ReturnResourceByResource(item.optionIcon.texture)
	Dismissed.emit()

func _on_mouse_entered() -> void:
	is_mouse_over = true

func _on_mouse_exited() -> void:
	is_mouse_over = false

func play_cooldown() -> void:
	is_shown_recently = true
	await get_tree().create_timer(0.1).timeout
	is_shown_recently = false

func clamp_inside_viewport() -> void:
	var game_window_size: Vector2 = get_viewport_rect().size
	if (size.y > game_window_size.y - 40):
		size.y = game_window_size.y - 40
	if (size.x > game_window_size.x):
		size.x = game_window_size.x
	
	global_position.y = clamp(global_position.y, 0, game_window_size.y - size.y - 40)
	global_position.x = clamp(global_position.x, 0, game_window_size.x - size.x)
