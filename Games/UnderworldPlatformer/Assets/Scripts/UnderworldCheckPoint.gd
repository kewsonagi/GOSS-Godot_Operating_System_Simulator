extends Area2D

@onready var animatedSprite : AnimatedSprite2D = $AnimatedSprite2D
@export_enum("down", "up") var checkpoint_gravity: String = "down"

@export var gravi_boots : bool = true
@export var noclip : bool = true

func deactivate():
	animatedSprite.play("normal")

func _on_body_entered(_body):
	if animatedSprite.animation == "normal":
		$AudioStreamPlayer2D.play()

	for checkpoint in get_tree().get_nodes_in_group("Checkpoint"):
		checkpoint.deactivate()

	animatedSprite.play("activated")
	UnderworldGlobal.set_health(UnderworldGlobal.get_max_health())
	UnderworldGlobal.set_spawn_point(self.global_position, self.checkpoint_gravity)
	if !UnderworldGlobal.can_change_gravity:
		UnderworldGlobal.can_change_gravity = gravi_boots
	if !UnderworldGlobal.can_noclip:
		UnderworldGlobal.set_can_noclip(noclip)
