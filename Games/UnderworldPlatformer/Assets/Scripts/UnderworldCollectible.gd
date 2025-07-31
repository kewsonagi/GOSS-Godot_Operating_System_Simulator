extends Area2D

@export var level : String
var active : bool = true

func _ready():
	for i in UnderworldGlobal.collectibles_got:
		if i == level:
			queue_free()

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if active:
			$AudioStreamPlayer.play()
			UnderworldGlobal.CURRENT_LEVEL_CURRENCY += 1
			get_tree().get_first_node_in_group("Level").collectible = true
			var collectibe_alreay_got : bool = false
			for i in UnderworldGlobal.collectibles_got:
				if i == level:
					collectibe_alreay_got = true
			if !collectibe_alreay_got:
				UnderworldGlobal.collectibles_got.push_back(level)
				UnderworldGlobal.save_game()
		active = false
		$CollectibleSprite.visible = false

func _on_audio_stream_player_finished():
	queue_free()
