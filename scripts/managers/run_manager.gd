extends Node

signal run_started(combat_room: int)
signal run_ended(success: bool, elapsed_time: float)
signal combat_room_changed(combat_room: int)
signal run_stats_changed
## Fired once per run when it is over (died, cleared or quit), with the full
## stat block. JournalManager records it.
signal run_finished(summary: Dictionary)

const RESULT_CLEARED := "CLEARED"
const RESULT_DIED := "DIED"
const RESULT_QUIT := "QUIT"

## Starter objectives for the active run. Add entries here; `stat` names a key
## from get_run_stat(). Progress is computed live, so nothing else needs to
## change to add one.
const OBJECTIVES: Array[Dictionary] = [
	{"id": "kill_10", "title": "KILL 10 ZOMBIES", "stat": "kills", "target": 10},
	{"id": "clear_room_1", "title": "CLEAR ROOM 1", "stat": "room_1_cleared", "target": 1},
	{"id": "survive_120", "title": "SURVIVE 2 MINUTES", "stat": "elapsed_seconds", "target": 120},
	{"id": "headshots_3", "title": "GET 3 HEADSHOTS", "stat": "headshots", "target": 3},
]

# Lifetime zombies per room: strictly increasing, +2 a room after Room 2.
# Room 2 must match cafeteria_controller.gd MAX_LIFETIME_SPAWNS (16).
# These are totals over the room, not bodies on screen: each director still
# caps how many are alive at once.
const ZOMBIE_COUNTS: Array[int] = [
	12, 16, 18, 20, 22,
	24, 26, 28, 30, 32,
	34, 36, 38, 40, 42,
	44, 46, 48, 50, 52,
]
const TIER_HP: Array[float] = [100.0, 160.0, 250.0, 380.0]
const TIER_DAMAGE: Array[float] = [10.0, 15.0, 22.0, 30.0]
const TIER_REWARD: Array[int] = [8, 14, 22, 35]
const TIER_NAMES: Array[String] = ["Basic Infected", "Hardened Infected", "Armored / Mutated", "Elite / Bloated"]
# Room 2's authored fight is the real baseline. Rooms 3–20 climb from there
# instead of snapping back to the Room 1 bucket.
const ROOM_TWO_HEALTH := 175.0
const ROOM_TWO_DAMAGE := 17.5
const ROOM_TWO_REWARD := 12
const ROOM_TWO_MOVE_SPEED := 2.40
const ROOM_THREE_HEALTH := 195.0
const ROOM_THREE_DAMAGE := 18.5
const ROOM_THREE_REWARD := 14
const ROOM_THREE_MOVE_SPEED := 2.18
const ROOM_TWENTY_HEALTH := 380.0
const ROOM_TWENTY_DAMAGE := 30.0
const ROOM_TWENTY_REWARD := 35
const ROOM_TWENTY_MOVE_SPEED := 2.55

var run_active: bool = false
var elapsed_time: float = 0.0
var current_combat_room: int = 0
var run_kills: int = 0
var run_earnings: int = 0
## Authoritative progression for the active run. Room unlocks must survive
## streamed scene replacement/unloading.
var cleared_combat_rooms: Dictionary = {}
var run_headshots: int = 0
var run_damage_dealt: float = 0.0
var run_damage_taken: float = 0.0
var run_shots_fired: int = 0
var run_shots_hit: int = 0
var run_best_room: int = 0
var run_primary_weapon: String = ""
var run_secondary_weapon: String = ""
var _run_started_unix: int = 0
var _run_recorded := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if run_active and not get_tree().paused:
		elapsed_time += delta

func start_run(combat_room: int = 1, force_restart: bool = false) -> void:
	if run_active and not force_restart:
		if current_combat_room != combat_room:
			set_combat_room(combat_room)
		return
	if run_active:
		# A forced restart abandons the run in progress.
		_finish(RESULT_QUIT)
	elapsed_time = 0.0
	run_kills = 0
	run_earnings = 0
	cleared_combat_rooms.clear()
	_reset_combat_stats()
	_run_started_unix = int(Time.get_unix_time_from_system())
	_run_recorded = false
	run_active = true
	current_combat_room = clampi(combat_room, 1, 20)
	run_best_room = current_combat_room
	run_started.emit(current_combat_room)
	combat_room_changed.emit(current_combat_room)
	run_stats_changed.emit()

func set_combat_room(combat_room: int) -> void:
	current_combat_room = clampi(combat_room, 1, 20)
	run_best_room = maxi(run_best_room, current_combat_room)
	combat_room_changed.emit(current_combat_room)

func mark_combat_room_cleared(combat_room: int) -> void:
	var room_number := clampi(combat_room, 1, 20)
	cleared_combat_rooms[room_number] = true
	run_stats_changed.emit()

func is_combat_room_cleared(combat_room: int) -> bool:
	if combat_room <= 0:
		return true
	return bool(cleared_combat_rooms.get(clampi(combat_room, 1, 20), false))

func register_kill(reward: int) -> void:
	run_kills += 1
	run_earnings += maxi(0, reward)
	run_stats_changed.emit()

func end_run(success: bool) -> void:
	if not run_active:
		return
	run_active = false
	run_ended.emit(success, elapsed_time)
	_finish(RESULT_CLEARED if success else RESULT_DIED)


## Leaving mid-run (main menu, restart from hub). Records the run as QUIT.
func abandon_run() -> void:
	if not run_active:
		return
	run_active = false
	run_ended.emit(false, elapsed_time)
	_finish(RESULT_QUIT)


func register_shot() -> void:
	run_shots_fired += 1
	run_stats_changed.emit()


func register_hit(headshot: bool = false) -> void:
	run_shots_hit += 1
	if headshot:
		run_headshots += 1
	run_stats_changed.emit()


func register_damage_dealt(amount: float) -> void:
	run_damage_dealt += maxf(amount, 0.0)


func register_damage_taken(amount: float) -> void:
	run_damage_taken += maxf(amount, 0.0)
	run_stats_changed.emit()


func set_loadout(primary_id: String, secondary_id: String) -> void:
	run_primary_weapon = primary_id
	run_secondary_weapon = secondary_id


func get_accuracy() -> float:
	return float(run_shots_hit) / float(run_shots_fired) * 100.0 if run_shots_fired > 0 else 0.0


func get_run_stat(stat_name: String) -> float:
	match stat_name:
		"kills":
			return float(run_kills)
		"headshots":
			return float(run_headshots)
		"elapsed_seconds":
			return floorf(elapsed_time)
		"earnings":
			return float(run_earnings)
		"damage_dealt":
			return run_damage_dealt
		"accuracy":
			return get_accuracy()
	if stat_name.begins_with("room_") and stat_name.ends_with("_cleared"):
		var room := int(stat_name.trim_prefix("room_").trim_suffix("_cleared"))
		return 1.0 if run_active and is_combat_room_cleared(room) else 0.0
	return 0.0


## [{id, title, target, current, done}] for the active run. Outside a run every
## objective reads 0 / target.
func get_objectives() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for objective in OBJECTIVES:
		var target := float(objective["target"])
		var current := get_run_stat(String(objective["stat"])) if run_active else 0.0
		result.append({
			"id": objective["id"],
			"title": objective["title"],
			"target": target,
			"current": minf(current, target),
			"done": current >= target,
		})
	return result


func get_run_summary(result: String = "") -> Dictionary:
	return {
		"result": result,
		"started_unix": _run_started_unix,
		"ended_unix": int(Time.get_unix_time_from_system()),
		"time": elapsed_time,
		"room": maxi(run_best_room, current_combat_room),
		"rooms_cleared": cleared_combat_rooms.size(),
		"kills": run_kills,
		"headshots": run_headshots,
		"shots_fired": run_shots_fired,
		"shots_hit": run_shots_hit,
		"accuracy": get_accuracy(),
		"damage_dealt": int(round(run_damage_dealt)),
		"damage_taken": int(round(run_damage_taken)),
		"earnings": run_earnings,
		"weapon": run_primary_weapon,
		"secondary": run_secondary_weapon,
	}


func _finish(result: String) -> void:
	if _run_recorded:
		return
	_run_recorded = true
	run_finished.emit(get_run_summary(result))


func _reset_combat_stats() -> void:
	run_headshots = 0
	run_damage_dealt = 0.0
	run_damage_taken = 0.0
	run_shots_fired = 0
	run_shots_hit = 0
	run_best_room = 0


func reset_to_hub() -> void:
	run_active = false
	elapsed_time = 0.0
	current_combat_room = 0
	run_kills = 0
	run_earnings = 0
	cleared_combat_rooms.clear()
	_reset_combat_stats()
	run_primary_weapon = ""
	run_secondary_weapon = ""
	run_stats_changed.emit()

func get_room_config(combat_room: int) -> Dictionary:
	var room_index: int = clampi(combat_room, 1, 20)
	var tier: int = _tier_for_room(room_index)
	return {
		"combat_room": room_index,
		"physical_room": room_index + 1,
		"tier": tier + 1,
		"name": TIER_NAMES[tier],
		"zombie_count": ZOMBIE_COUNTS[room_index - 1],
		"health": _stat_for_room(room_index, "health"),
		"damage": _stat_for_room(room_index, "damage"),
		"base_reward": int(round(_stat_for_room(room_index, "reward"))),
		"move_speed": _stat_for_room(room_index, "move_speed"),
	}


func _tier_for_room(room_index: int) -> int:
	if room_index <= 2:
		return 0
	if room_index <= 5:
		return 1
	if room_index <= 10:
		return 2
	return 3


func _stat_for_room(room_index: int, stat_name: String) -> float:
	if room_index <= 1:
		match stat_name:
			"health":
				return TIER_HP[0]
			"damage":
				return TIER_DAMAGE[0]
			"reward":
				return float(TIER_REWARD[0])
			_:
				return 1.35
	if room_index == 2:
		match stat_name:
			"health":
				return ROOM_TWO_HEALTH
			"damage":
				return ROOM_TWO_DAMAGE
			"reward":
				return float(ROOM_TWO_REWARD)
			_:
				return ROOM_TWO_MOVE_SPEED
	var t: float = float(room_index - 3) / 17.0
	match stat_name:
		"health":
			return lerpf(ROOM_THREE_HEALTH, ROOM_TWENTY_HEALTH, t)
		"damage":
			return lerpf(ROOM_THREE_DAMAGE, ROOM_TWENTY_DAMAGE, t)
		"reward":
			return lerpf(float(ROOM_THREE_REWARD), float(ROOM_TWENTY_REWARD), t)
		_:
			return lerpf(ROOM_THREE_MOVE_SPEED, ROOM_TWENTY_MOVE_SPEED, t)
