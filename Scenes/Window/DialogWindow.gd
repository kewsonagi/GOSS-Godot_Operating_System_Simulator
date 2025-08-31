extends FakeWindow
class_name DialogBox

#dialog box/window for any simple and complex window the user needs to interact with to get info or state back from
#default callbacks set the ID you give for each control in the returned dictionary to the new values of the controls
#for buttons that is true/false
var dialogReturn: Dictionary = {"Confirm":true, "Cancel":false}

@export var controlContainer: Control

@export var templateButton: Button
@export var templateColorPicker: ColorPickerButton
@export var templateCheckbox: CheckBox
@export var templateInputField: LineEdit
@export var templateTextField: RichTextLabel
@export var templateRangeH: Range
@export var templateRangeV: Range
@export var templateOptionButton: OptionButton
@export var templateList: ItemList
var controls: Array[Control]

func _ready() -> void:
	super._ready()
	#controlContainer.size = size
	#controlContainer.size.y -= top_bar.size.y

signal Closed(dataDictionary: Dictionary)

func GetReturnData() -> Dictionary:
	return dialogReturn

func _on_close_button_pressed() -> void:
	Closed.emit(dialogReturn)

	super._on_close_button_pressed()

#position in screen percentage 0-1
func SetPosition(pos: Vector2) -> void:
	position.x = DefaultValues.get_window().size.x*pos.x - size.x*0.5
	position.y = DefaultValues.get_window().size.y*pos.y - size.y*0.5

#size in screen percentage 0-1
func SetSize(s: Vector2) -> void:
	size.x = DefaultValues.get_window().size.x*s.x
	size.y = DefaultValues.get_window().size.y*s.y
	#controlContainer.size = size
	#controlContainer.size.y -= top_bar.size.y

func SetSizePixelPerfect(s: Vector2) -> void:
	position.x += size.x*0.5
	position.y += size.y*0.5
	size = s
	position.x -= size.x*0.5
	position.y -= size.y*0.5

	#controlContainer.size = size
	#controlContainer.size.y -= top_bar.size.y
func SetPositionPixelPerfect(pos: Vector2) -> void:
	position.x = pos.x - size.x*0.5
	position.y = pos.y - size.y*0.5

func SetControlPosition(b:Control, pos: Vector2) -> void:
	b.position.x = (pos.x*(size.x-startMarginLeft-controlContainer.offset_left) - (b.size.x*0.5))
	b.position.y = (pos.y*(size.y-startMarginTop-controlContainer.offset_top) - (b.size.y*0.5))

func AddButton(id: String, buttonName: String="OK", pos: Vector2=Vector2(0.5,0.5), dismissWindow:bool=false, pressedCallback: Callable=ButtonPressed, icon: Texture2D=null) -> Control:
	var button: Button = templateButton.duplicate()
	button.visible = true
	controlContainer.add_child(button)
	button.text = buttonName
	print("container size: ", controlContainer.size)

	if(pressedCallback):
		button.pressed.connect(pressedCallback.bind(button,id,self))
	if(icon):
		button.icon = icon
	if(dismissWindow):
		button.pressed.connect(_on_close_button_pressed)

	dialogReturn[id] = false

	SetControlPosition(button, pos)
	controls.append(button)
	return button

func AddColorPicker(id: String, buttonName: String="", defaultColor:Color=Color.LAVENDER_BLUSH, pos: Vector2=Vector2(0.5,0.5), dismissWindow:bool=false, changedCallback: Callable=ColorPickerPressed, createdCallback: Callable=ColorPickerCreated, closedCallback: Callable=ColorPickerClosed, icon: Texture2D=null) -> Control:
	var button: ColorPickerButton = templateColorPicker.duplicate()
	button.visible = true
	controlContainer.add_child(button)
	button.text = buttonName
	if(icon):
		button.icon = icon

	button.color = defaultColor

	button.color_changed.connect(changedCallback.bind(button,id,self))
	button.picker_created.connect(createdCallback.bind(button,id,self))
	button.popup_closed.connect(closedCallback.bind(button,id,self))
	if(dismissWindow):
		button.popup_closed.connect(_on_close_button_pressed)

	dialogReturn[id] = defaultColor

	SetControlPosition(button, pos)

	controls.append(button)
	return button

func AddCheckbox(id: String, buttonName: String="", pos: Vector2=Vector2(0.5,0.5), toggleCallback: Callable=ButtonToggled, defaultOn:bool = false, icon: Texture2D=null) -> Control:
	var button: CheckBox = templateCheckbox.duplicate()
	button.visible = true
	controlContainer.add_child(button)
	button.text = buttonName
	button.button_pressed = defaultOn
	if(icon):
		button.icon = icon

	button.toggled.connect(toggleCallback.bind(button,id,self))

	dialogReturn[id] = button.button_pressed

	SetControlPosition(button, pos)
	controls.append(button)
	return button

func AddInputField(id: String, defaultText:String="Placement text", pos: Vector2=Vector2(0.5,0.5), textSubmittedCallback: Callable=InputFieldSubmitted, textChangedCallback: Callable=InputFieldChanged, icon: Texture2D=null) -> Control:
	var button: LineEdit = templateInputField.duplicate()
	button.visible = true
	controlContainer.add_child(button)
	button.placeholder_text = defaultText
	button.text = defaultText
	#button.text = buttonName
	if(icon):
		button.icon = icon

	button.text_submitted.connect(textSubmittedCallback.bind(button,id,self))
	button.text_changed.connect(textChangedCallback.bind(button,id,self))
	
	dialogReturn[id] = button.text


	SetControlPosition(button, pos)
	controls.append(button)
	return button

func AddTextField(id: String, defaultText: String="Dialog", pos: Vector2=Vector2(0.5,0.5), icon: Texture2D=null) -> Control:
	var button: RichTextLabel = templateTextField.duplicate()
	button.visible = true
	controlContainer.add_child(button)
	button.text = defaultText
	if(icon):
		button.icon = icon

	# button.text_submitted.connect(textSubmittedCallback.bind(button,id,self))
	# button.text_changed.connect(textChangedCallback.bind(button,id,self))

	dialogReturn[id] = button.text


	SetControlPosition(button, pos)
	controls.append(button)
	return button

func AddOptionsButton(id: String, buttonName: String="", optionItems:PackedStringArray=["first"], defaultSelected:int=0, pos: Vector2=Vector2(0.5,0.5), optionSelectedCallback: Callable=OptionItemSelected, icon: Texture2D=null) -> Control:
	var button: OptionButton = templateOptionButton.duplicate()
	button.visible = true
	controlContainer.add_child(button)
	button.text = buttonName

	if(optionItems and !optionItems.is_empty()):
		for item:String in optionItems:
			button.add_item(item)
		button.selected = defaultSelected
		dialogReturn[id] = optionItems[defaultSelected]
	
	if(icon):
		button.icon = icon
	button.item_selected.connect(optionSelectedCallback.bind(button,optionItems,id,self))

	SetControlPosition(button, pos)
	controls.append(button)
	return button

func AddRangeField(id: String, vertical:bool=false, buttonName: String="", pos: Vector2=Vector2(0.5,0.5), minVal:float=0, maxVal:float=1, defaultVal:float=0, changedCallback: Callable=RangeChanged, icon: Texture2D=null) -> Control:
	var button: Range
	if(vertical):
		button = templateRangeV.duplicate()
	else:
		button = templateRangeH.duplicate()
	button.visible = true
	controlContainer.add_child(button)
	button.text = buttonName
	if(icon):
		button.icon = icon
	
	button.min_value = minVal
	button.max_value = maxVal
	button.value = defaultVal

	dialogReturn[id] = defaultVal

	button.value_changed.connect(changedCallback.bind(button,id,self))


	SetControlPosition(button, pos)
	controls.append(button)
	return button

func ButtonPressed(b: Button, id: String, dialog: DialogBox) -> void:
	dialog.dialogReturn[id] = true
	return
func ButtonToggled(toggled: bool, b: Button, id: String, dialog: DialogBox) -> void:
	dialog.dialogReturn[id] = toggled
	return
func InputFieldSubmitted(value: String, field: LineEdit, id: String, dialog: DialogBox) -> void:
	dialog.dialogReturn[id] = value
	return
func InputFieldChanged(value: String, field: LineEdit, id: String, dialog: DialogBox) -> void:
	dialog.dialogReturn[id] = value
	return
func InputTextFieldChanged(value: String, textField: RichTextLabel, id: String, dialog: DialogBox) -> void:
	dialog.dialogReturn[id] = value
	return
func InputTextFieldSubmitted(value: String, textField: RichTextLabel, id: String, dialog: DialogBox) -> void:
	dialog.dialogReturn[id] = value
	return
func ColorPickerCreated(b: ColorPickerButton, id: String, dialog: DialogBox) -> void:
	dialog.dialogReturn["%sCreated" % id] = true
	return
func ColorPickerPressed(c:Color, b: ColorPickerButton, id: String, dialog: DialogBox) -> void:
	dialog.dialogReturn[id] = c
	return
func ColorPickerClosed(b: ColorPickerButton, id: String, dialog: DialogBox) -> void:
	dialog.dialogReturn["%sClosed" % id] = true
	return
func RangeChanged(value: float, b: Range, id: String, dialog: DialogBox) -> void:
	dialog.dialogReturn[id] = value
	return
func OptionItemSelected(index:int, optionItems:PackedStringArray,id: String, dialog: DialogBox) -> void:
	dialog.dialogReturn[id] = optionItems[index]
	return
