extends Node
class_name DialogManager

@export var templateDialogbox: PackedScene
static var instance: DialogManager

#dialog box/window for any simple and complex window the user needs to interact with to get info or state back from
static var dialogs: Array[DialogBox]

func _ready() -> void:
	if(!instance):
		instance = self
	else:
		queue_free()

func CreateDialogbox(title: String, pos: Vector2 = Vector2(0.5,0.5)) -> DialogBox:
	var dialog: DialogBox = DefaultValues.spawn_window(templateDialogbox.resource_path, title, "Dialog:%s" % title)#templateDialogbox.instantiate() as DialogBox
	dialog.SetTitleText(title)
	dialog.SetTitleColor(Color.CORNFLOWER_BLUE)
	if(dialog):
		dialog.SetPosition(pos)
	return dialog

func CreateOKCancelDialog(title: String, okName: String, cancelName: String, centerMessage:String, pos: Vector2=Vector2(0.5,0.4)) -> DialogBox:
	var dialog: DialogBox = DefaultValues.spawn_window(templateDialogbox.resource_path, title, "Dialog:%s" % title)#templateDialogbox.instantiate() as DialogBox
	UtilityHelper.Log("dialog made?: %s" % dialog.name)
	UtilityHelper.Log("dialog made?: %s" % dialog is FakeWindow)
	UtilityHelper.Log("dialog made?: %s" % dialog is DialogBox)
	dialog.SetTitleColor(Color.PALE_VIOLET_RED)
	dialog.SetSize(Vector2(0.2, 0.15))
	dialog.SetPosition(pos)
	dialog.AddTextField("Body", centerMessage, Vector2(0.5,0.3))
	var OKButton: Button = dialog.AddButton("OK", "OK", Vector2(0.25,0.75),(func(b:Button,id:String,d:DialogBox):
		d.dialogReturn[id] = true
		UtilityHelper.Log("Pressed: %s" % id)
		d._on_close_button_pressed()
		)
	)

	var cancelButton:Button = dialog.AddButton("Cancel", "Cancel", Vector2(0.75,0.75), (func(b:Button,id:String,d:DialogBox):
		d.dialogReturn[id] = true
		UtilityHelper.Log("Pressed: %s" % id)
		d._on_close_button_pressed()
		)
	)
	#dialog.Closed.connect(returnData)
	
	return dialog
