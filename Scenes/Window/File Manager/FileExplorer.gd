extends FakeWindow
class_name FileExplorer

#dialog box/window for any simple and complex window the user needs to interact with to get info or state back from
#default callbacks set the ID you give for each control in the returned dictionary to the new values of the controls
#for buttons that is true/false
@export var fileManager: FileManagerWindow
@export var addressBarInput: LineEdit

var dirHistory: Array[String]
var clickHandler: HandleClick

func _ready() -> void:
	super._ready()
	#controlContainer.size = size
	#controlContainer.size.y -= top_bar.size.y
	if(!clickHandler):
		clickHandler = UtilityHelper.AddInputHandler(self)
	
	addressBarInput.text_submitted.connect(ChangedFileAddress)
	fileManager.ChangedDirectory.connect(ChangedDirectory)
	fileManager.BackButtonPressed.connect(HitBack)

func ChangedFileAddress(newAddress: String) -> void:
	fileManager.GotoAddressAbsolute(newAddress)

func ChangedDirectory(newAddress: String) -> void:
	dirHistory.append(newAddress)

func HitBack() -> void:
	if(dirHistory.size()>0):
		dirHistory.pop_back()