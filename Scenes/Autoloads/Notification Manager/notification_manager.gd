extends Control
# class_name NotificationManager
## Spawns notifications in the bottom right of the screen.
## Often used to show errors or file actions (copying, pasting).

@export var defaultNotification: PackedScene# = preload("res://Scenes/Autoloads/Notification Manager/notification.tscn")
static var notificationOffset: Vector2 = Vector2(0,0)
@export var defaultNotiSize: Vector2 = Vector2(400, 150)
static var notiList: Array[Notification]
var errorIcon: Texture2D
var warningIcon: Texture2D
var infoIcon: Texture2D
var unknownIcon: Texture2D
enum E_NOTIFICATION_TYPE {NORMAL, ERROR, WARNING, INFO, UNKNOWN}

func _ready() -> void:
	errorIcon = ResourceManager.GetResource("Error")
	warningIcon = ResourceManager.GetResource("Warning")
	infoIcon = ResourceManager.GetResource("Info")
	unknownIcon = ResourceManager.GetResource("Unknown")

func ShowNotification(text: String, type: E_NOTIFICATION_TYPE = E_NOTIFICATION_TYPE.NORMAL, title: String = "Notification", pos: Vector2 = get_viewport_rect().size, notiSize: Vector2 = defaultNotiSize) -> void:
	ShowNotificationCustom(defaultNotification, type, text, title, pos - notiSize + notificationOffset, notiSize)

func ShowNotificationCustom(notiScene: PackedScene, type: E_NOTIFICATION_TYPE, defaultText: String, title: String, pos: Vector2, notiSize: Vector2) -> void:
	var thisNotification: Notification = CreateNotification(defaultText, type, title, notiScene, pos, notiSize)
	if(thisNotification):
		StartNotification(thisNotification)

func RemoveNotification(noti: Notification) -> void:
	notificationOffset.y += noti.size.y
	notiList.erase(noti)

func CreateNotification(text: String, type: E_NOTIFICATION_TYPE = E_NOTIFICATION_TYPE.NORMAL, title: String = "Notification", notiScene: PackedScene = defaultNotification, pos: Vector2 = get_viewport_rect().size, notiSize: Vector2 = defaultNotiSize) -> Notification:
	var thisNotification: Notification = notiScene.instantiate()
	if(thisNotification):
		thisNotification.SetNotificationText(text)
		thisNotification.title.text = title;
		thisNotification.position = pos;
		thisNotification.size = notiSize;
		#connect to this notification to handle offsetting notifications so they don't stack ontop of eachother
		thisNotification.Done.connect(RemoveNotification)
		notiList.append(thisNotification)
		if(type == E_NOTIFICATION_TYPE.ERROR):
			thisNotification.icon.texture = errorIcon
			thisNotification.SetNotificationColor("#ca353e")
		elif(type == E_NOTIFICATION_TYPE.WARNING):
			thisNotification.icon.texture = warningIcon
			thisNotification.SetNotificationColor("#cab135ff")
		elif(type == E_NOTIFICATION_TYPE.INFO):
			thisNotification.icon.texture = infoIcon
			thisNotification.SetNotificationColor("#359bcaff")
		elif(type == E_NOTIFICATION_TYPE.UNKNOWN):
			thisNotification.icon.texture = unknownIcon
			thisNotification.SetNotificationColor("#4f4f4fff")
	return thisNotification

func StartNotification(noti: Notification) -> void:
	add_child(noti)
	noti.BeginNoti()
	notificationOffset.y -= noti.size.y