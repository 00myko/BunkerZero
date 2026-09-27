extends Node

## Survivor profile + run journal. Every finished run (died, cleared or quit)
## becomes one entry, newest first, capped so the save file stays small.
## Career totals live separately so they survive the cap.

signal journal_changed
signal display_name_changed(display_name: String)

const PROFILE_SECTION := "profile"
const JOURNAL_SECTION := "journal"
const DEFAULT_NAME := "SURVIVOR"
const MAX_NAME_LENGTH := 16
const MAX_RUNS := 30

var _name_filter := RegEx.new()


func _ready() -> void:
	_name_filter.compile("[^A-Z0-9_]")
	if not RunManager.run_finished.is_connected(record_run):
		RunManager.run_finished.connect(record_run)


func get_display_name() -> String:
	var stored := String(SaveManager.get_value(PROFILE_SECTION, "display_name", DEFAULT_NAME))
	var clean := sanitize_name(stored)
	return clean if not clean.is_empty() else DEFAULT_NAME


## Uppercase A-Z, 0-9 and underscore only, max 16 characters.
func sanitize_name(raw: String) -> String:
	var upper := raw.strip_edges().to_upper().replace(" ", "_")
	return _name_filter.sub(upper, "", true).substr(0, MAX_NAME_LENGTH)


func set_display_name(raw: String) -> String:
	var clean := sanitize_name(raw)
	if clean.is_empty():
		clean = DEFAULT_NAME
	SaveManager.set_value(PROFILE_SECTION, "display_name", clean)
	display_name_changed.emit(clean)
	return clean


func get_runs() -> Array:
	var runs: Variant = SaveManager.get_value(JOURNAL_SECTION, "runs", [])
	return (runs as Array).duplicate(true) if runs is Array else []


func get_career() -> Dictionary:
	var career: Variant = SaveManager.get_value(JOURNAL_SECTION, "career", {})
	var result: Dictionary = {
		"runs": 0, "best_room": 0, "kills": 0, "headshots": 0,
		"best_accuracy": 0.0, "longest_time": 0.0, "earnings": 0,
	}
	if career is Dictionary:
		result.merge(career as Dictionary, true)
	return result


func record_run(summary: Dictionary) -> void:
	# A run with no time and nothing done (e.g. quitting the instant it began)
	# is noise, not a game.
	if float(summary.get("time", 0.0)) < 1.0 and int(summary.get("kills", 0)) == 0:
		return
	var entry := summary.duplicate(true)
	entry["name"] = get_display_name()
	var runs := get_runs()
	runs.push_front(entry)
	while runs.size() > MAX_RUNS:
		runs.pop_back()
	var career := get_career()
	career["runs"] = int(career["runs"]) + 1
	career["best_room"] = maxi(int(career["best_room"]), int(entry.get("room", 0)))
	career["kills"] = int(career["kills"]) + int(entry.get("kills", 0))
	career["headshots"] = int(career["headshots"]) + int(entry.get("headshots", 0))
	if int(entry.get("shots_fired", 0)) >= 10:
		# Ignore two-shot runs so a lucky 100% does not stick forever.
		career["best_accuracy"] = maxf(float(career["best_accuracy"]), float(entry.get("accuracy", 0.0)))
	career["longest_time"] = maxf(float(career["longest_time"]), float(entry.get("time", 0.0)))
	career["earnings"] = int(career["earnings"]) + int(entry.get("earnings", 0))
	SaveManager.set_value(JOURNAL_SECTION, "runs", runs, false)
	SaveManager.set_value(JOURNAL_SECTION, "career", career, true)
	journal_changed.emit()
