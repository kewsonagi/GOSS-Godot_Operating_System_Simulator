extends BaseFile
class_name cAppFile

func _ready() -> void:
	super._ready()

func OpenFile() -> void:
	for file: Node in selectedFiles:
		if(file and !file.is_queued_for_deletion() and file is BaseFile):
			var f: BaseFile = file
			var filePath: String = "%s%s/%s" % [ResourceManager.GetPathToUserFiles(), f.szFilePath, f.szFileName]
			if(f is cAppFile):
				var manifest: AppManifest = AppManager.LoadAppManifest(filePath)
				AppManager.LaunchCustomApp(manifest)
			else:
				AppManager.LaunchAppByExt(f.szFileName.get_extension(), filePath, true)

func HandleRightClick() -> void:
	super.HandleRightClick()
	RClickMenuManager.instance.AddMenuItem("Open", OpenFile)
