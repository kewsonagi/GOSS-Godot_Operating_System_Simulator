extends BaseFile
class_name cPackFile

func _ready() -> void:
	super._ready()

#cycle through all selected files to open
func OpenFile() -> void:
	for file: Node in selectedFiles:
		if(file and !file.is_queued_for_deletion() and file is BaseFile):
			var f: BaseFile = file
			HandleOpen(f)

#do the open functionality only on our filetype
func HandleOpen(f: BaseFile) -> void:
	#var filePath: String = "%s%s/%s" % [ResourceManager.GetPathToUserFiles(), f.szFilePath, f.szFileName]
	var filePath: String = UtilityHelper.GetCleanFileString(ResourceManager.GetPathToUserFiles(), f.szFilePath, f.szFileName)
	if(f is cPackFile):
		var dialog: DialogBox = DialogManager.instance.CreateOKCancelDialog("Import?", "Yes", "No", "Import pack file for later")
		dialog.Closed.connect((func(d: Dictionary, copyPath: String) -> void:
			if(d["Yes"]):
				DirAccess.copy_absolute(copyPath, "%s%s" % [ResourceManager.GetPathToPackFiles(), copyPath.get_file()])
			).bind(filePath)
		)
	else:
		AppManager.LaunchAppByExt(f.szFileName.get_extension(), filePath, true)

func HandleRightClick() -> void:
	super.HandleRightClick()
	RClickMenuManager.instance.AddMenuItem("Open", OpenFile)
