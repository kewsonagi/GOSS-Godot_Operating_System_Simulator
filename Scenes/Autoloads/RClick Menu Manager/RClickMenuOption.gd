extends Panel
class_name RClickMenuOption

@export var optionText: RichTextLabel
@export var optionIcon: TextureRect
@export var colorControl: Control

signal option_clicked()

func _ready() -> void:
	var clickHandler: HandleClick = get_node_or_null("ClickHandler")
	if(clickHandler):
		clickHandler.LeftClickRelease.connect(ItemClicked)
		clickHandler.HoveringStart.connect(HoverStart)
		clickHandler.HoveringEnd.connect(HoverEnd)

func HoverStart() -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "self_modulate:a", 1, 0.2)

func HoverEnd() -> void:
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "self_modulate:a", 0.4, 0.2)

func ItemClicked() -> void:
	option_clicked.emit()

func SetColor(c: Color) -> void:
	self_modulate = c
	self_modulate.a = 0.4