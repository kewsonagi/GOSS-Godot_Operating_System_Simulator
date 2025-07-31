@tool
extends EditorPlugin


#region INFO ===================================================================
"""
Author:  ClumsyInker@yahoo.com
Summary: This pluging contains custom syntax highlighting for .log files. It is
		 looking for lines of the following form:
			[SYS-CRT] HH:MM:SS.### <NODE_NAME>.<FUNC_NAME>: <LOG_MESSAGE>
			[ENT-CRT/ERR/WRN/ALR/NFO/DBG] HH:MM:SS.### <NODE_NAME>.<FUNC_NAME>: <LOG_MESSAGE>
			[CMP-NFO] HH:MM:SS.### <NODE_NAME>.<FUNC_NAME>: <LOG_MESSAGE>

		 The text within square brackets '[' and ']' consists of 2 parts - 
		 Category & Level. The categories are "ENT", "CMP", and "SYS" (entity,
		 component, system). The levels are "CRT", "ERR", "WRN", "ALR", "NFO",
		 and "DBG" (critical, error, warning, alert, info, debug).
		
		 The highlight colors can be customized via the constants.
"""
#endregion ================================================================ INFO


#region GLOBALS ================================================================
# signals ----------------------------------------------------------------------
# ---------------------------------------------------------------------- signals

# enumerators (enum) -----------------------------------------------------------
# ----------------------------------------------------------- enumerators (enum)

# constants --------------------------------------------------------------------
const CLR_CRT = { "color": Color.RED }
const CLR_WRN = { "color": Color.ORANGE }
const CLR_ALR = { "color": Color.GOLD }
const CLR_NFO = { "color": Color.MEDIUM_TURQUOISE }
const CLR_DBG = { "color": Color.GREEN }
const CLR_WHT = { "color": Color.WHITE }
const CLR_TIME = { "color": Color.MEDIUM_VIOLET_RED }
const CLR_NODE = { "color": Color.CADET_BLUE }
const CLR_FUNC = { "color": Color.DARK_ORCHID }
# -------------------------------------------------------------------- constants

# @exports ---------------------------------------------------------------------
# --------------------------------------------------------------------- @exports

# public variables -------------------------------------------------------------
# ------------------------------------------------------------- public variables

# private variables ------------------------------------------------------------
var _log_highlighter : LogHighlighter
# ------------------------------------------------------------ private variables

# @onready variables -----------------------------------------------------------
# ----------------------------------------------------------- @onready variables
#endregion ============================================================= GLOBALS


#region EVENTS =================================================================
func _enter_tree() -> void:
	_log_highlighter = LogHighlighter.new()
	var script_editor = EditorInterface.get_script_editor()
	script_editor.register_syntax_highlighter(_log_highlighter)


func _exit_tree() -> void:
	if is_instance_valid(_log_highlighter):
		var script_editor = EditorInterface.get_script_editor()
		script_editor.unregister_syntax_highlighter(_log_highlighter)
		_log_highlighter = null
#endregion ============================================================== EVENTS


#region SIGNAL HANDLERS ========================================================
#endregion ===================================================== SIGNAL HANDLERS


#region FUNCTIONS ==============================================================
func get_class_name() -> String: return "PluginEditorLog"
#endregion =========================================================== FUNCTIONS


#region CLASSES ================================================================
class LogHighlighter extends EditorSyntaxHighlighter:
	func _get_name() -> String:
		return "Log"
	
	
	func _get_supported_languages() -> PackedStringArray:
		return ["log"]
	
	
	func _get_line_syntax_highlighting(line: int) -> Dictionary:
		var color_map : Dictionary = {}
		var text_editor : TextEdit = get_text_edit()
		var text : String = text_editor.get_line(line)
		
		# highlight log levels to quickly read severity of messages
		for code in ["CRT", "ERR", "WRN", "ALR", "NFO", "DBG"]:
			var col : int = text.find(code)
			if col == -1:
				continue
			match code:
				"CRT", "ERR":
					color_map[col] = CLR_CRT
				"WRN":
					color_map[col] = CLR_WRN
				"ALR":
					color_map[col] = CLR_ALR
				"NFO":
					color_map[col] = CLR_NFO
				"DBG":
					color_map[col] = CLR_DBG
			color_map[col + len(code)] = CLR_WHT
		
		# highlight timecode
		var time : int = text.find(":")
		color_map[time - 2] = CLR_TIME
		color_map[time + 10] = CLR_WHT
		
		# highlight node name
		color_map[time + 11] = CLR_NODE
		var per : int = text.find(".", time + 11)
		color_map[per] = CLR_WHT
		
		# highlight function name
		color_map[per + 1] = CLR_FUNC
		var colon : int = text.find(":", per + 1)
		color_map[colon] = CLR_WHT
		
		return color_map
#endregion ============================================================= CLASSES
