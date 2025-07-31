extends Node2D

@onready var output: Label = $Output

var result: String

func apply(key: String):
	var is_arithmetic = key == 'x' or key == '+' or key == '-' or key == '÷'
	var is_num = "0123456789".contains(key) or key == "."  # include decimal point

	if is_arithmetic:
		result += " " + key + " "
	elif is_num:
		result += key
	elif key == "C":
		result = ""
	elif key == "=":
		result = evaluate_expression()
	
	output.text = result

func evaluate_expression():
	var expression = result.replace("x", "*").replace("÷", "/")
	var expr = Expression.new()
	var err = expr.parse(expression)
	if err == OK:
		var value = expr.execute()
		return str(value)
	else:
		return "Err"
