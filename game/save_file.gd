extends RefCounted
## The player's save, user://bitshift.cfg: the best score and the settings.
## Every write reloads the file first, so one section never wipes another.

const PATH := "user://bitshift.cfg"


static func read(section: String, key: String, fallback: Variant) -> Variant:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return fallback
	return cfg.get_value(section, key, fallback)


static func write(section: String, key: String, value: Variant) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value(section, key, value)
	cfg.save(PATH)
