extends Node

class_name  DefaultResources

@export var defaultInterfaceIcons: Array[InterfaceIcon]
@export_dir var pathToIcons: String
@export var ignoreExtensions: PackedStringArray
#static var iconList: Dictionary = {}

func _ready() -> void:
	PreloadExternalPacks()
	RegisterInterfaceIcons()
	RegisterFileExtensionIcons()

func RegisterInterfaceIcons() -> void:
	for item in defaultInterfaceIcons:
		ResourceManager.RegisterResource(item.key, item.res)
func RegisterFileExtensionIcons() -> void:
	#if(iconList.is_empty()):
	var  res: Resource
	var iconFiles: PackedStringArray = DirAccess.get_files_at(pathToIcons)
	for iconFile in iconFiles:
		if(!ignoreExtensions.has(iconFile.get_extension())):
			res = ResourceLoader.load("%s/%s" % [pathToIcons.get_base_dir(), iconFile])
			if(res):
				ResourceManager.RegisterResource(iconFile.get_basename(), res)
			#iconList[iconFile.get_basename()] = "%s/%s" % [pathToIcons.get_base_dir(), iconFile]

func PreloadExternalPacks() -> void:
	var files:PackedStringArray = DirAccess.get_files_at(ResourceManager.GetPathToPackFiles())
	for file in files:
		ResourceManager.LoadPackOrMod("%s%s" % [ResourceManager.GetPathToPackFiles(),file])