extends Node

class_name  DefaultResources

@export var defaultInterfaceIcons: InterfaceIconPack
@export_dir var pathToIcons: String
@export var ignoreExtensions: PackedStringArray
#static var iconList: Dictionary = {}

func _ready() -> void:
	ResourceManager.CreateDefaultPaths()
	PreloadExternalPacks()
	RegisterInterfaceIcons()
	RegisterFileExtensionIcons()

func RegisterInterfaceIcons() -> void:
	for item in defaultInterfaceIcons.pack:
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
	if(!DirAccess.dir_exists_absolute(ResourceManager.GetPathToPackFiles())):
		DirAccess.make_dir_recursive_absolute(ResourceManager.GetPathToPackFiles())
	var files:PackedStringArray = DirAccess.get_files_at(ResourceManager.GetPathToPackFiles())
	for file in files:
		ResourceManager.LoadPackOrMod("%s%s" % [ResourceManager.GetPathToPackFiles(),file])
