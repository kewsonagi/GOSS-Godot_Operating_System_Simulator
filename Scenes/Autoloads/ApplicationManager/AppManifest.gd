extends Resource

class_name  AppManifest

@export var key: String = "nameID"
@export var name: String = "app name"
@export var description: String = "app description"
@export var path: String = "res://Applications/app.tscn"
@export var icon: Texture2D = preload("res://Art/shaded/15-file-empty.png")
@export var extensionAssociations: PackedStringArray
@export var colorBGTaskbar: Color = Color.SKY_BLUE
@export var colorBGWindow: Color = Color.SKY_BLUE
@export var colorBGTitle: Color = Color.SKY_BLUE
@export_category("Window configurations")
#window position and size in percentages, represented in 0-1
@export var startWindowPlacement: Rect2 = Rect2(0.25, 0.25, 0.75, 0.75)
@export var customWindowTitle: String = name
@export var resizable: bool = true
@export var borderless: bool = false
@export var bGame: bool = false
@export var category: String = "General"

func _init() -> void:
    key = "nameID"
    name = "app name"
    description = "app description"
    path = "res://Applications/app.tscn"
    icon = preload("res://Art/shaded/15-file-empty.png")
    colorBGTaskbar = Color.SKY_BLUE
    colorBGWindow = Color.SKY_BLUE
    colorBGTitle = Color.SKY_BLUE
    startWindowPlacement = Rect2(0.25, 0.25, 0.75, 0.75)
    customWindowTitle = name
    resizable = true
    borderless = false
    bGame = false
    category = "General"