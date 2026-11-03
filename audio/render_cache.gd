extends RefCounted
## Thread-safe store of finished renders, shared by the sfx and music players
## and filled ahead of time by a worker thread.

var _items: Dictionary[String, Variant] = {}
var _mutex := Mutex.new()


func lookup(key: String) -> Variant:
	_mutex.lock()
	var item: Variant = _items.get(key)
	_mutex.unlock()
	return item


func store(key: String, item: Variant) -> void:
	_mutex.lock()
	_items[key] = item
	_mutex.unlock()


## Returns the cached item, rendering and storing it first if needed.
func fetch(key: String, render: Callable) -> Variant:
	var item: Variant = lookup(key)
	if item == null:
		item = render.call()
		store(key, item)
	return item
