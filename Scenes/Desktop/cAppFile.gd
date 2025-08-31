extends BaseFile
class_name cAppFile

func _ready() -> void:
	super._ready()

	var fileLoc: String = "%s%s/%s" % [ResourceManager.GetPathToUserFiles(),szFilePath, szFileName]
	var appManifest: AppManifest = AppManager.LoadAppManifest(fileLoc)
	if(appManifest):
		fileIcon = appManifest.icon

func OpenThis() -> void:
	var filePath: String = "%s%s/%s" % [ResourceManager.GetPathToUserFiles(), szFilePath, szFileName]
	var manifest: AppManifest = AppManager.LoadAppManifest(filePath)
	if(manifest.bGame):
		AppManager.LaunchCustomApp(manifest)
	else:
		AppManager.LaunchApp(manifest.key, filePath)


func HandleRightClick() -> void:
	super.HandleRightClick()
	RClickMenuManager.instance.AddMenuItem("Open", OpenFile)
