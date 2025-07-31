extends CanvasLayer
class_name BootSplash

## The boot splash animation that's shown when GodotOS is opened or powered off.
## It uses a CanvasGroup with 2D nodes for masking, hence why it adjusts scale manually.

@export var quit_animation: bool
@export var bootBackground: Sprite2D
@export var bootImage: Sprite2D
@export var bootImageShadow: Sprite2D
@export var timeLength: float = 0.5
@export var scaleBegin: Vector2 = Vector2(2,2)
@export var scaleEnd: Vector2 = Vector2(2,2)
#@export var bootSound: AudioSample

func _ready() -> void:
	visible = true
	scale /= get_window().content_scale_factor
	var window_size: Vector2 = DisplayServer.window_get_size() as Vector2
	bootBackground.global_position = window_size / 2
	bootImage.global_position = window_size / 2
	bootImageShadow.global_position = window_size / 2

	if quit_animation:
		play_quit_animation()
	else:
		play_animation()

func play_animation() -> void:
	bootImage.scale = scaleBegin;
	bootImageShadow.scale = scaleBegin;

	TweenAnimator.fade_out(bootBackground, timeLength)
	TweenAnimator.disappear(bootBackground, timeLength)
	TweenAnimator.fade_out(bootImage, timeLength*1.5)
	TweenAnimator.fade_out(bootImageShadow, timeLength*1.5)
	TweenAnimator.float_bob(bootImage, 10, timeLength/8.0)
	TweenAnimator.float_bob(bootImageShadow, 10, timeLength/8.0)
	TweenAnimator.wiggle_scale(bootImage, 0.1, timeLength)
	TweenAnimator.wiggle_scale(bootImageShadow, 0.1, timeLength)
	await get_tree().create_timer(timeLength).timeout
	await get_tree().create_timer(timeLength/2.0).timeout
	
	queue_free()

func play_quit_animation() -> void:
	bootImage.scale = scaleBegin;
	bootImageShadow.scale = scaleBegin;
	TweenAnimator.fade_out(bootBackground, timeLength)
	TweenAnimator.disappear(bootBackground, timeLength)
	TweenAnimator.float_bob(bootImage, 10, timeLength/8.0)
	TweenAnimator.float_bob(bootImageShadow, 10, timeLength/8.0)
	TweenAnimator.fade_out(bootImage, timeLength*1.5)
	TweenAnimator.fade_out(bootImageShadow, timeLength*1.5)
	
	await get_tree().create_timer(timeLength).timeout
	
	get_tree().quit()
