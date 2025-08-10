extends Node

# Exports
@export_enum("Low","Normal","High") var thread_priority: String = "Normal"
@export var print_debug_info: bool = false

# Thread Status
# 0 - Running
# 1 - Finished

# Internal Variables
var _thread_ptr: Array[Thread] = []
var _thread_status: Array[int] = []
var _thread_uid: Array[int] = []
var _thread_uid_index: int = 1
var _thread_mutex: Mutex = Mutex.new()

## Blocks the thread until all workers finished (and all <result> Callables are called).
func force() -> void: # This was not tested
	while true:
		_thread_mutex.lock()
		if _thread_status.size() < 1:
			_thread_mutex.unlock()
			break
		_thread_mutex.unlock()

## Starts the loading <path>. After its done, calls <result>.
## The <result> Callable must have two arguments (path: String, res: Resource).
func threadload(path: String, result: Callable) -> void:
	var t: Thread = Thread.new()
	
	# Update Variable
	_thread_mutex.lock()
	_thread_ptr.push_back(t)
	_thread_status.push_back(0)
	var uid: int = _thread_uid_index
	_thread_uid.push_back(uid)
	_thread_uid_index += 1
	_thread_mutex.unlock()
	
	# Launch Thread
	var priority: int
	if thread_priority == "Low":
		priority = Thread.PRIORITY_LOW
	elif thread_priority == "Normal":
		priority = Thread.PRIORITY_NORMAL
	else:
		priority = Thread.PRIORITY_HIGH
	t.start(_thread_func.bind(path,result,uid),priority)

## INTERNAL SCRIPT FUNCTION! 
## DO NOT CALL DIRECTLY!
func _thread_func(path: String, result: Callable, uid: int) -> void:
	var res: Resource = ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_REUSE)
	
	_thread_mutex.lock()
	var i: int = _thread_uid.find(uid)
	_thread_status[i] = 1
	_thread_mutex.unlock()
	
	result.call_deferred(path, res)
	_clean_thread.call_deferred(uid)
	if print_debug_info:
		print("Thread ", path, " with UID ", uid ," is done.")

## INTERNAL SCRIPT FUNCTION! 
## DO NOT CALL DIRECTLY!
func _clean_thread(uid: int) -> void:
	_thread_mutex.lock()
	var i: int = _thread_uid.find(uid)
	var t: Thread = _thread_ptr[i]
	t.wait_to_finish()
	_thread_status.pop_at(i)
	_thread_ptr.pop_at(i)
	_thread_uid.pop_at(i)
	_thread_mutex.unlock() 
	if print_debug_info:
		print("Thread with UID ", uid, " is freed.")
