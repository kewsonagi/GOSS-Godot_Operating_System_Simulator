extends TaskbarWidget

class_name  TimeWidget
## The time and date in the taskbar.
## Updates once every 10 seconds since string replacements can be a waste of resources.
@export var timeText: RichTextLabel
@export var dateText: RichTextLabel
@export var rotationControl: Control

func _ready() -> void:
	super._ready()	
	update_time()

func update_time() -> void:
	var date_dict: Dictionary = Time.get_datetime_dict_from_system()
	var suffix: String
	if date_dict.hour >= 12:
		date_dict.hour -= 12
		suffix = "PM"
	else:
		suffix = "AM"
		if date_dict.hour == 0:
			date_dict.hour = 12
	
	timeText.text = "[center]%02d:%02d %s" % [date_dict.hour, date_dict.minute, suffix]
	dateText.text = "[center]%02d/%02d/%d" % [date_dict.day, date_dict.month, date_dict.year]

func _on_timer_timeout() -> void:
	update_time()

func SetWidgetAnchor(anchor: E_WIDGET_ANCHOR) -> void:
	super.SetWidgetAnchor(anchor)
	if(anchor == E_WIDGET_ANCHOR.BOTTOM):
		rotationControl.rotation_degrees = 0
	elif(anchor == E_WIDGET_ANCHOR.TOP):
		rotationControl.rotation_degrees = 0
	elif(anchor == E_WIDGET_ANCHOR.LEFT):
		rotationControl.rotation_degrees = 90
	elif(anchor == E_WIDGET_ANCHOR.RIGHT):
		rotationControl.rotation_degrees = -90