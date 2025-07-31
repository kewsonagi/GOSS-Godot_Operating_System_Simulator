extends Node2D

class_name BootGame

@export var mainGameScene: PackedScene
var spawnedWindow: Node = null
@export var gameData: Dictionary = {}



func StartGame() -> void:
	if(!spawnedWindow):
		print(mainGameScene.resource_path)
		spawnedWindow = mainGameScene.instantiate()#DefaultValues.spawn_window(mainGameScene.resource_path, "","", gameData,self.get_parent())
		#add_sibling(mainGameScene.instantiate())
		#queue_free()
	
func getStartScene() -> Node:
	return spawnedWindow
