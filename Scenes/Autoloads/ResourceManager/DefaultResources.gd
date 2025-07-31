extends Node

class_name  DefaultResources

@export var defaultInterfaceIcons: Array[InterfaceIcon]

func _ready() -> void:
	RegisterInterfaceIcons()

func RegisterInterfaceIcons() -> void:
	for item in defaultInterfaceIcons:
		ResourceManager.RegisterResource(item.key, item.res)
