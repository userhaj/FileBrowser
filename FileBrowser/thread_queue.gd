extends Node
class_name ThreadQueue

var _running_threads = []
var thread_queue = []
var bind_queue = []

var max_thread_count = max(2, OS.get_processor_count() * 2 )

func enqueue(call_work: Callable, callback_content:Callable):
	var thread = Thread.new()
	thread_queue.push_back(thread)
	bind_queue.push_back(_thread_return_work.bind(thread, call_work, callback_content))
	update_queue()

func _thread_return_work(thread, call_work, callback_content):
	if call_work:
		var work = call_work.call()
		var callback = callback_content.bind(work)
		call_deferred("_end_thread", thread, callback)
	else:
		call_deferred("_end_thread", thread, null)
		
func _end_thread(thread:Thread, callback: Callable):
	var thread_index = self._running_threads.find(thread)
	if thread_index >= 0:
		self._running_threads.remove_at(thread_index)
	update_queue()
	if callback:
		callback.call_deferred()
	thread.wait_to_finish()

func update_queue():
	while len(self._running_threads) < max_thread_count && len(thread_queue) > 0:
		var run_thread = thread_queue.pop_front()
		var bind_callable = bind_queue.pop_front()
		if run_thread:
			_running_threads.append(run_thread)
			run_thread.start(bind_callable)
		else:
			break
			#break


