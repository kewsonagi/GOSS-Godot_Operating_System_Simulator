extends Node2D

var collectible : bool = false

@export_enum("Menu", "Underground") var world : int

@export_category("Unlockables")
@export var gravi_boots : bool = true
@export var noclip : bool = true

func _ready():
	UnderworldGlobal.init()

	UnderworldGlobal.change_music(world)
	UnderworldGlobal.WORLD = world
	UnderworldGlobal.can_change_gravity = gravi_boots
	UnderworldGlobal.set_can_noclip(noclip)
