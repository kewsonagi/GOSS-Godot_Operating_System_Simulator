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
	if(!pathToIcons.ends_with("/")):
		pathToIcons = "%s/" % pathToIcons

	var  res: Resource
	var fullIconPath: String
	var fullExternalIconPath: String
	var iconFiles: PackedStringArray = DirAccess.get_files_at(pathToIcons)
	for iconFile in iconFiles:
		if(!ignoreExtensions.has(iconFile.get_extension())):
			if(iconFile.get_extension() == "import"):
				iconFile = iconFile.replace(".import", "")
			if(iconFile.get_extension() == "remap"):
				iconFile = iconFile.replace(".remap", "")
			#copy files from internal res to external user directory
			fullIconPath = "%s/%s" % [pathToIcons.get_base_dir(), iconFile]
			fullExternalIconPath = "%s/%s" % [ResourceManager.GetPathToApplicationsIcons(), iconFile]
			UtilityHelper.CopyFile(fullIconPath, fullExternalIconPath)
			#certain default resources only load from internal locations for some reason?
			res = ResourceLoader.load(fullIconPath)
			if(res):
				ResourceManager.RegisterResource(iconFile.get_basename(), res)
			#iconList[iconFile.get_basename()] = "%s/%s" % [pathToIcons.get_base_dir(), iconFile]
	
	var externalIcons: PackedStringArray = DirAccess.get_files_at(ResourceManager.GetPathToApplicationsIcons())
	for iconFile in externalIcons:
		if(!ignoreExtensions.has(iconFile.get_extension())):
			#copy files from internal res to external user directory
			fullExternalIconPath = "%s/%s" % [ResourceManager.GetPathToApplicationsIcons(), iconFile]
			#certain default resources only load from internal locations for some reason?
			var img: Image = Image.load_from_file(fullExternalIconPath)
			if(img):
				res = ImageTexture.create_from_image(img)
			if(res):
				ResourceManager.RegisterResource(iconFile.get_basename(), res)
	# for tex: Texture2D in defaultIcons:
	# 	if(!ignoreExtensions.has(tex.name.get_extension())):
	# 		if(tex):
	# 			ResourceManager.RegisterResource(tex.name.get_basename(), tex)

func PreloadExternalPacks() -> void:
	if(!DirAccess.dir_exists_absolute(ResourceManager.GetPathToPackFiles())):
		DirAccess.make_dir_recursive_absolute(ResourceManager.GetPathToPackFiles())
	var files:PackedStringArray = DirAccess.get_files_at(ResourceManager.GetPathToPackFiles())
	for file in files:
		ResourceManager.LoadPackOrMod("%s%s" % [ResourceManager.GetPathToPackFiles(),file])
