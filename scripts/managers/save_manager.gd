extends Node

const SAVE_PATH: String = "user://zombie_bunker_progress.cfg"

var _config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	_load()

func _load() -> void:
	var err: Error = _config.load(SAVE_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("Could not load progression save: %s" % error_string(err))

func get_value(section: String, key: String, default_value: Variant) -> Variant:
	return _config.get_value(section, key, default_value)

func set_value(section: String, key: String, value: Variant, save_now: bool = true) -> void:
	_config.set_value(section, key, value)
	if save_now:
		save()

func get_keys(section: String) -> PackedStringArray:
	if not _config.has_section(section):
		return PackedStringArray()
	return _config.get_section_keys(section)

func erase_value(section: String, key: String, save_now: bool = true) -> void:
	if _config.has_section_key(section, key):
		_config.erase_section_key(section, key)
		if save_now:
			save()

func save() -> void:
	var err: Error = _config.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save progression: %s" % error_string(err))

func reset_all_progress() -> void:
	_config = ConfigFile.new()
	save()
