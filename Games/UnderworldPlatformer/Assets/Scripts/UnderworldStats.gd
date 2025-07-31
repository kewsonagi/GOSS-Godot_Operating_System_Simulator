extends Node2D

func _process(_delta):
	$Coins2.text = str(UnderworldGlobal.CURRENCY)
	$Collectibles2.text = str(UnderworldGlobal.collectibles_got.size()) + "/5"
