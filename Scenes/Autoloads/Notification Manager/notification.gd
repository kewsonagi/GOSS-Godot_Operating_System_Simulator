extends Panel
class_name Notification

@export var mainText: RichTextLabel
@export var title: RichTextLabel
@export var background: Panel
@export var icon: TextureRect
@export var defaultDuration: float = 5.0
var clickHandler: HandleClick

signal Done
signal RightClick
signal LeftClick

func _ready() -> void:
	clickHandler = get_node_or_null("ClickHandler")
	if(clickHandler):
		clickHandler.LeftClick.connect(HandleLeftClick)
		clickHandler.RightClick.connect(HandleRightClick)

func SetNotificationText(text: String) -> void:
	mainText.text = text
func SetNotificationTitle(text: String) -> void:
	title.text = text
func SetNotificationColor(color: Color) -> void:
	background.add_theme_color_override("bg_color", color);

func BeginNoti(duration: float = defaultDuration) -> void:
	TweenAnimator.punch_in(self, 0.3)
	await get_tree().create_timer(duration-1).timeout
	TweenAnimator.fade_out(self, 0.5)
	await get_tree().create_timer(0.5).timeout

	Finished()
func Finished() -> void:
	Done.emit(self)
	queue_free()

#these are here incase we later add more context to a notification, like clicking and opening an application or making a window active etc
func HandleRightClick() -> void:
	RightClick.emit()
func HandleLeftClick() -> void:
	Finished()
	LeftClick.emit()
