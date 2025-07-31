extends Area2D

@export var value: String = "0"

@onready var calculator: Node2D = $".."
@onready var sprite = $AnimatedSprite2D
@onready var label = $Label
@onready var sfx: AudioStreamPlayer2D = $Sfx

var is_hovered = false
var is_pressed = false
var label_start_position: Vector2

func _ready():
	label.text = value
	label_start_position = label.position
	sprite.play('default')

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.is_action_pressed("LeftClick"):
			if event.pressed:
				if is_hovered:
					sprite.play("pressed")
					label.set_position(label_start_position + Vector2(0, 1))
					sfx.play_press()
					is_pressed = true
			else:
				if is_pressed:
					sprite.play("default")
					label.set_position(label_start_position)
					sfx.play_release()
					is_pressed = false
					if is_hovered:
						_on_button_clicked()

func _on_mouse_entered():
	is_hovered = true

func _on_mouse_exited():
	is_hovered = false
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		sprite.play("default")
		label.set_position(label_start_position)

func _on_button_clicked():
	calculator.apply(value)
