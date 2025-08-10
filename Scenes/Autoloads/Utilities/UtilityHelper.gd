extends Node

class_name UtilityHelper

static func CallOnTimer(f: float, c: Callable, caller: Node) -> void:
	caller.get_tree().create_timer(f).timeout.connect(c)