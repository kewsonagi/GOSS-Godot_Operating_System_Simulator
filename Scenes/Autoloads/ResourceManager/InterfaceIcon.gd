extends Resource

class_name  InterfaceIcon

@export var key: String = "nameID"
@export var res: Texture2D = preload("res://Art/shaded/15-file-empty.png")

func _init() -> void:
    key = "nameID"
    res = preload("res://Art/shaded/15-file-empty.png")