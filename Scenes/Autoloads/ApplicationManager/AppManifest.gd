extends Resource

class_name  AppManifest

@export var key: String = "nameID"
@export var name: String = "app name"
@export var description: String = "app description"
@export var path: String = "res://Applications/app.tscn"
@export var icon: Texture2D = preload("res://Art/shaded/15-file-empty.png")
@export var extensionAssociations: PackedStringArray

func _init() -> void:
    key = "nameID"
    name = "app name"
    description = "app description"
    path = "res://Applications/app.tscn"
    icon = preload("res://Art/shaded/15-file-empty.png")