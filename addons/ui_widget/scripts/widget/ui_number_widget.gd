@tool
class_name UINumberWidget
extends UIWidget

var h_slider: HSlider
var spin_box: SpinBox
var label: Label

@export var min_value: float = 0
@export var max_value: float = 100
@export var step: float = 0.1

func _ready() -> void:
	scene = preload("../../scenes/widget/ui_number_widget.tscn")
	value = 0
	h_slider = get_node("UINumberWidget/HBoxContainer/HSlider") as HSlider
	spin_box = get_node("UINumberWidget/HBoxContainer/SpinBox") as SpinBox
	label = get_node("UINumberWidget/HBoxContainer/Label") as Label

	label.text = view_name

	h_slider.value_changed.connect(_set_value)
	h_slider.min_value = min_value
	h_slider.max_value = max_value
	h_slider.step = step
	h_slider.value = _get_value()

	spin_box.value_changed.connect(_set_value)
	spin_box.min_value = min_value
	spin_box.max_value = max_value
	spin_box.step = step
	spin_box.value = _get_value()
	super._ready()

func _on_view_name_changed(v) -> void:
	if !label: return
	label.text = v