extends BaseFile
class_name cAppFile

func _ready() -> void:
	super._ready()

	var fileLoc: String = "%s%s/%s" % [ResourceManager.GetPathToUserFiles(),szFilePath, szFileName]
	UtilityHelper.Log(fileLoc)
	var appManifest: AppManifest = AppManager.LoadAppManifest(fileLoc)
	if(appManifest):
		UtilityHelper.Log("swapping app icon for %s" % appManifest.icon)
		fileIcon = appManifest.icon

func OpenFile() -> void:
	for file: Node in selectedFiles:
		if(file and !file.is_queued_for_deletion() and file is BaseFile):
			var f: BaseFile = file
			var filePath: String = "%s%s/%s" % [ResourceManager.GetPathToUserFiles(), f.szFilePath, f.szFileName]
			if(f is cAppFile):
				var manifest: AppManifest = AppManager.LoadAppManifest(filePath)
				if(manifest.bGame):
					AppManager.LaunchCustomApp(manifest)
				else:
					AppManager.LaunchApp(manifest.key, filePath)
			else:
				AppManager.LaunchAppByExt(f.szFileName.get_extension(), filePath, true)

func HandleRightClick() -> void:
	super.HandleRightClick()
	RClickMenuManager.instance.AddMenuItem("Open", OpenFile)
