extends AudioStreamPlayer2D

const PRESS_START = 0.108
const PRESS_LENGTH = 0.1

const RELEASE_START = 0.075
const RELEASE_LENGTH = 0.1

func play_press():
	stop()
	play()
	await get_tree().process_frame
	seek(PRESS_START)
	await get_tree().create_timer(PRESS_LENGTH).timeout
	stop()

func play_release():
	stop()
	play()
	await get_tree().process_frame
	seek(RELEASE_START)
	await get_tree().create_timer(RELEASE_LENGTH).timeout
	stop()
