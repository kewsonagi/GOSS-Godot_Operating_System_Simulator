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

func CreateOKCancelDialog(title: String, okName: String, cancelName: String, centerMessage:String="", pos: Vector2=Vector2(0.5,0.4)) -> DialogBox:
	var dialog: DialogBox = DefaultValues.spawn_window(templateDialogbox.resource_path, title, "Dialog:%s" % title)#templateDialogbox.instantiate() as DialogBox
	dialog.SetTitleColor(Color.MEDIUM_VIOLET_RED)
	dialog.SetSize(Vector2(0.2, 0.15))
	dialog.SetPosition(pos)
	var textField:RichTextLabel = dialog.AddTextField("Body", centerMessage, Vector2(0.5,0.3))
	#textField.size.x=dialog.size.x
	#textField.position.x = 0
	
	dialog.AddButton(okName,okName, Vector2(0.25,0.7), true)
	dialog.AddButton(cancelName,cancelName, Vector2(0.75,0.7), true)
	#dialog.Closed.connect(returnData)
	
	return dialog


func CreateInputDialog(title: String, okName: String, cancelName: String, inputFieldID:String="Name",inputField:String="Name", centerMessage:String="", pos: Vector2=Vector2(0.5,0.4)) -> DialogBox:
	var dialog: DialogBox = DefaultValues.spawn_window(templateDialogbox.resource_path, title, "Dialog:%s" % title)#templateDialogbox.instantiate() as DialogBox
	dialog.SetTitleColor(Color.MEDIUM_VIOLET_RED)
	dialog.SetSize(Vector2(0.2, 0.15))
	dialog.SetPosition(pos)
	var textField:RichTextLabel = dialog.AddTextField("Body", centerMessage, Vector2(0.5,0.1))
	#textField.size.x=dialog.size.x
	#textField.position.x = 0

	dialog.AddInputField(inputFieldID,inputField,Vector2(0.5,0.45))
	dialog.AddButton(okName,okName, Vector2(0.25,0.7), true)
	dialog.AddButton(cancelName,cancelName, Vector2(0.75,0.7), true)
	#dialog.Closed.connect(returnData)
	
	return dialog

func CreateInputDialogWithLabel(title: String, okName: String, cancelName: String, inputFieldID:String="Name", inputField:String="Name", inputLabel:String="Name: ", centerMessage:String="", pos: Vector2=Vector2(0.5,0.4)) -> DialogBox:
	var dialog: DialogBox = DefaultValues.spawn_window(templateDialogbox.resource_path, title, "Dialog:%s" % title)#templateDialogbox.instantiate() as DialogBox
	dialog.SetTitleColor(Color.MEDIUM_VIOLET_RED)
	dialog.SetSize(Vector2(0.2, 0.15))
	dialog.SetPosition(pos)
	var textField:RichTextLabel = dialog.AddTextField("Body", centerMessage, Vector2(0.5,0.0))
	textField.position.y+=textField.size.y*0.5
	#textField.size.x=dialog.size.x
	#textField.position.x = 0
	textField = dialog.AddTextField("%slabelName", inputLabel, Vector2(0.5,0.45))
	#textField.position.x=0
	textField.position.y-=textField.size.y
	dialog.AddInputField(inputFieldID,inputField,Vector2(0.6,0.45))
	dialog.AddButton(okName,okName, Vector2(0.25,0.7), true)
	dialog.AddButton(cancelName,cancelName, Vector2(0.75,0.7), true)

	return dialog