extends Node


class_name UtilityHelper

enum LOG_LEVEL{Debug,Info,Warning,Error}

static func CallOnTimer(f: float, c: Callable, caller: Node) -> void:
	caller.get_tree().create_timer(f).timeout.connect(c)

static func Log(s:String, level: LOG_LEVEL=LOG_LEVEL.Debug) -> void:
	if(level == LOG_LEVEL.Debug):
		print(s)
	elif(level == LOG_LEVEL.Info):
		print(s)
	elif(level == LOG_LEVEL.Warning):
		print(s)
	elif(level == LOG_LEVEL.Error):
		print(s)

static func AddInputHandler(node: Node) -> HandleClick:
	if(node):
		var handler: HandleClick = HandleClick.new()
		node.add_child(handler)
		node.move_child(handler, 0)
		return handler
	return null