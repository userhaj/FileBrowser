class_name ThreadQueue
extends Node
## A queue for work with a callback of returned value.
##
## Maximizes work against available processors, uses callback_content to return value.

var _running_threads = []
var thread_queue = []
var bind_queue = []

var max_thread_count = max(2, OS.get_processor_count())

# Creating a new thread is expensive, initial thread creation is best at load time
var _available_threads = range(max_thread_count).map(func(_a): return Thread.new())


# Add Callable a queue. callback_content must take single argument of call_work return type
func enqueue(call_work: Callable, callback_content:Callable):
	var thread = _available_threads.pop_front()
	thread_queue.push_back(thread)
	bind_queue.push_back(_thread_return_work.bind(thread, call_work, callback_content))
	_update_queue()
	_available_threads.append(Thread.new())

func clear():
	thread_queue.clear()
	bind_queue.clear()

# Runs work, then calls cleanup methods
func _thread_return_work(thread, call_work: Callable, callback_content):
	# Work may be null/stale, validate before calling
	if call_work and call_work.is_valid():
		var work = call_work.call()
		var callback = callback_content.bind(work)
		_end_thread.call_deferred(thread, callback)
	else:
		_end_thread.call_deferred(thread, null)

# Called upon end of work; removes thread from queue
func _end_thread(thread:Thread, callback):
	var thread_index = self._running_threads.find(thread)
	if thread_index >= 0:
		self._running_threads.remove_at(thread_index)
	_update_queue()
	if callback:
		callback.call_deferred()
	thread.wait_to_finish()

# Called upon addition or subtraction to queue; starts next thread
func _update_queue():
	while len(self._running_threads) < max_thread_count && len(thread_queue) > 0:
		var run_thread = thread_queue.pop_front()
		var bind_callable = bind_queue.pop_front()
		if run_thread:
			_running_threads.append(run_thread)
			run_thread.start(bind_callable)
		else:
			break
