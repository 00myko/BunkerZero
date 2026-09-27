extends Node

## Data-driven hub upgrades. Everything the three hub tables show or sell is a
## row in one of the tables below:
##   * WEAPONS   – one dict per gun (append a dict to add a gun to the board).
##   * SURVIVOR  – one dict per vitals row.
##   * ZOMBIE_TYPES – one dict per payout row (append to add a zombie type).
## Ranks persist in SaveManager under [upgrades]. Gameplay reads the upgraded
## stats through the get_weapon_* getters; nothing here knows about the UI.

signal upgrades_changed

const MAX_RANK := 5
## Pistol body shot at damage rank 0. Every gun's damage is a multiple of it.
const BASE_DAMAGE := 25.0

# ------------------------------------------------------------------ weapons

## Board order. "listed": false keeps melee / alt-attack damage profiles out
## of the weapon board while still using the same damage pipeline.
## reserve = rounds carried on top of the first magazine.
## mag_step / reserve_step = what one rank of that track adds (0 = track n/a).
## reload_time = seconds shown on the board (per shell for "per_shell" guns).
const WEAPONS: Array[Dictionary] = [
	{"id": "pistol", "name": "PISTOL", "subtitle": "9MM SERVICE PISTOL", "damage": 1.0,
		"mag": 8, "reserve": 112, "interval": 0.26, "reload_time": 2.22, "mag_step": 1, "reserve_step": 8},
	{"id": "uzi", "name": "UZI", "subtitle": "COMPACT MACHINE PISTOL", "damage": 0.52,
		"mag": 24, "reserve": 168, "interval": 0.065, "reload_time": 2.03, "mag_step": 2, "reserve_step": 24},
	{"id": "smg", "name": "SMG", "subtitle": "9MM SUBMACHINE GUN", "damage": 0.78,
		"mag": 28, "reserve": 112, "interval": 0.092, "reload_time": 2.43, "mag_step": 2, "reserve_step": 28},
	{"id": "shotgun", "name": "SHOTGUN", "subtitle": "12 GAUGE PUMP", "damage": 4.0,
		"mag": 6, "reserve": 36, "interval": 1.12, "reload_time": 0.58, "per_shell": true, "mag_step": 1, "reserve_step": 4},
	{"id": "sawnoffs", "name": "SAWN-OFFS", "subtitle": "TWIN SAWN-OFF PAIR", "damage": 2.10,
		"mag": 2, "reserve": 16, "interval": 0.38, "reload_time": 1.87, "mag_step": 0, "reserve_step": 2},
	{"id": "sawnoff", "name": "SAWN-OFF", "subtitle": "DOUBLE-BARREL SAWN-OFF", "damage": 2.70,
		"mag": 2, "reserve": 20, "interval": 0.46, "reload_time": 2.90, "mag_step": 0, "reserve_step": 2},
	{"id": "lmg", "name": "LMG", "subtitle": "BELT-FED LIGHT MACHINE GUN", "damage": 0.68,
		"mag": 50, "reserve": 100, "interval": 0.100, "reload_time": 5.73, "mag_step": 2, "reserve_step": 25},
	{"id": "crossbow", "name": "CROSSBOW", "subtitle": "HEAVY BOLT CROSSBOW", "damage": 3.60,
		"mag": 1, "reserve": 13, "interval": 0.37, "reload_time": 2.93, "mag_step": 0, "reserve_step": 2},
	{"id": "grenade_launcher", "name": "GRENADE LAUNCHER", "subtitle": "40MM REVOLVER LAUNCHER", "damage": 4.40,
		"mag": 6, "reserve": 6, "interval": 0.95, "reload_time": 6.63, "mag_step": 1, "reserve_step": 1},
	{"id": "minigun", "name": "MINIGUN", "subtitle": "ROTARY CANNON", "damage": 0.48,
		"mag": 100, "reserve": 100, "interval": 0.050, "reload_time": 2.24, "mag_step": 2, "reserve_step": 50},
	# Reserved board slots: fill in stats (and a viewmodel in player.gd) to add.
	# {"id": "ar", "name": "ASSAULT RIFLE", ...},
	# {"id": "dmr", "name": "DMR", ...},
	# Not on the board: melee and alt attacks share the damage pipeline only.
	{"id": "knife", "name": "KNIFE", "listed": false, "damage": 1.40, "mag": 1, "reserve": 0, "interval": 0.58},
	{"id": "knife_stab", "listed": false, "damage": 2.20, "upgrades_from": "knife"},
	{"id": "crossbow_bash", "listed": false, "damage": 0.80, "upgrades_from": "crossbow"},
]

## Upgrade tracks, board order. Ranks 0..MAX_RANK per gun per track.
const TRACKS: Array[Dictionary] = [
	{"id": "damage", "name": "DAMAGE", "price_scale": 1.15},
	{"id": "mag", "name": "MAG SIZE", "price_scale": 1.0},
	{"id": "rate", "name": "FIRE RATE", "price_scale": 0.85},
	{"id": "reload", "name": "RELOAD SPEED", "price_scale": 0.85},
	{"id": "reserve", "name": "RESERVE AMMO", "price_scale": 0.8},
]
const WEAPON_TRACK_PRICES: Array[int] = [300, 700, 1400, 2800, 5000]
## Challenge caps: a maxed loadout must still need magazines in Room 20.
const DAMAGE_SCALE: Array[float] = [1.0, 1.10, 1.21, 1.32, 1.44, 1.55]
const INTERVAL_SCALE: Array[float] = [1.0, 0.97, 0.94, 0.91, 0.88, 0.85]
const RELOAD_SCALE: Array[float] = [1.0, 0.96, 0.92, 0.88, 0.84, 0.80]

# ------------------------------------------------------------------ survivor

## "values" has MAX_RANK + 1 entries (rank 0..5). Locked rows stay visible.
## "live": false = stored and shown, but no combat system reads it yet
## (there are no medkits in combat; the board says so instead of faking one).
const SURVIVOR: Array[Dictionary] = [
	{"id": "max_health", "name": "MAX HEALTH", "icon": "icon_heart.svg", "unlocked": true, "live": true,
		"values": [100.0, 120.0, 140.0, 170.0, 210.0, 260.0], "format": "%d HP"},
	{"id": "medkit_heal", "name": "MEDKIT HEAL", "icon": "icon_cross.svg", "unlocked": true, "live": false,
		"values": [25.0, 32.0, 40.0, 55.0, 70.0, 85.0], "format": "+%d"},
	{"id": "medkit_carry", "name": "MEDKIT CARRY", "icon": "icon_cross.svg", "unlocked": true, "live": false,
		"values": [1.0, 2.0, 3.0, 4.0, 5.0, 6.0], "format": "%d KITS"},
	{"id": "throwables", "name": "THROWABLES", "unlocked": false},
	{"id": "stamina", "name": "STAMINA", "unlocked": false},
]
const SURVIVOR_PRICES: Array[int] = [600, 1400, 2800, 5200, 9000]

# ------------------------------------------------------------------ payout

const PAYOUT_MULTIPLIERS: Array[float] = [1.0, 1.25, 1.50, 1.85, 2.25, 2.75]
const PAYOUT_PRICES: Array[int] = [500, 1200, 2500, 5000, 9000]
## Payout rows. base_reward matches RunManager.TIER_REWARD; add a type here.
const ZOMBIE_TYPES: Array[Dictionary] = [
	{"id": "basic", "name": "BASIC", "base_reward": 8, "unlocked": true},
	{"id": "hardened", "name": "HARDENED", "base_reward": 14, "unlocked": true},
	{"id": "armored", "name": "ARMORED", "base_reward": 22, "unlocked": true},
	{"id": "elite", "name": "ELITE", "base_reward": 35, "unlocked": true},
	{"id": "locked_1", "name": "LOCKED", "base_reward": 0, "unlocked": false},
	{"id": "locked_2", "name": "LOCKED", "base_reward": 0, "unlocked": false},
	{"id": "locked_3", "name": "LOCKED", "base_reward": 0, "unlocked": false},
]

const SAVE_SECTION := "upgrades"

## rank storage: "weapon/<id>/<track>", "survivor/<row>", "payout"
var _ranks: Dictionary = {}

# Compatibility for readers that predate per-gun ranks (pause dashboard).
var weapon_level: int:
	get:
		var primary := String(RunManager.run_primary_weapon)
		return get_weapon_tier(primary if not primary.is_empty() else "pistol")
var survivor_level: int:
	get:
		return get_survivor_rank("max_health")
var earnings_level: int:
	get:
		return get_payout_rank()


func _ready() -> void:
	for key in SaveManager.get_keys(SAVE_SECTION):
		if key.contains("/"):
			_ranks[key] = clampi(int(SaveManager.get_value(SAVE_SECTION, key, 0)), 0, MAX_RANK)
	_migrate_legacy_levels()


## Old saves kept one global level per table. Carry them over once.
func _migrate_legacy_levels() -> void:
	var migrated := false
	for legacy in [["weapon_level", "weapon/pistol/damage"], ["survivor_level", "survivor/max_health"], ["earnings_level", "payout"]]:
		var old := int(SaveManager.get_value(SAVE_SECTION, legacy[0], -1))
		if old < 0:
			continue
		if not _ranks.has(legacy[1]):
			_ranks[legacy[1]] = clampi(old, 0, MAX_RANK)
			SaveManager.set_value(SAVE_SECTION, legacy[1], _ranks[legacy[1]], false)
		SaveManager.erase_value(SAVE_SECTION, legacy[0], false)
		migrated = true
	if migrated:
		SaveManager.save()


func _rank(key: String) -> int:
	return int(_ranks.get(key, 0))


func _set_rank(key: String, value: int) -> void:
	_ranks[key] = clampi(value, 0, MAX_RANK)
	SaveManager.set_value(SAVE_SECTION, key, _ranks[key], true)
	upgrades_changed.emit()


# ------------------------------------------------------------------ weapon data

func get_weapon(weapon_id: String) -> Dictionary:
	for entry in WEAPONS:
		if entry["id"] == weapon_id:
			return entry
	return {}


func listed_weapons() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in WEAPONS:
		if bool(entry.get("listed", true)):
			out.append(entry)
	return out


## Ranks are bought on the gun itself; alt attacks inherit from their parent.
func _rank_owner(weapon_id: String) -> String:
	return String(get_weapon(weapon_id).get("upgrades_from", weapon_id))


func get_weapon_rank(weapon_id: String, track_id: String) -> int:
	return _rank("weapon/%s/%s" % [_rank_owner(weapon_id), track_id])


func is_track_available(weapon_id: String, track_id: String) -> bool:
	var entry := get_weapon(weapon_id)
	match track_id:
		"mag":
			return int(entry.get("mag_step", 0)) > 0
		"reserve":
			return int(entry.get("reserve_step", 0)) > 0
	return not entry.is_empty()


## Average rank over the tracks the gun can take (dashboard "LEVEL n").
func get_weapon_tier(weapon_id: String) -> int:
	var total := 0
	var count := 0
	for track in TRACKS:
		if is_track_available(weapon_id, track["id"]):
			total += get_weapon_rank(weapon_id, track["id"])
			count += 1
	return int(floor(float(total) / maxf(count, 1)))


func get_pistol_damage() -> float:
	return get_weapon_damage("pistol")


func get_weapon_damage(weapon_id: String = "pistol") -> float:
	var entry := get_weapon(weapon_id)
	var mult := float(entry.get("damage", 1.0))
	return BASE_DAMAGE * mult * DAMAGE_SCALE[get_weapon_rank(weapon_id, "damage")]


## Magazine: +mag_step per rank, always below double the stock magazine.
func get_weapon_mag(weapon_id: String) -> int:
	var entry := get_weapon(weapon_id)
	var base := int(entry.get("mag", 8))
	var grown := base + int(entry.get("mag_step", 0)) * get_weapon_rank(weapon_id, "mag")
	return mini(grown, maxi(base, base * 2 - 1))


func get_weapon_shot_interval(weapon_id: String) -> float:
	var entry := get_weapon(weapon_id)
	return float(entry.get("interval", 0.26)) * INTERVAL_SCALE[get_weapon_rank(weapon_id, "rate")]


## Multiply reload clip time by this (and play the clip 1/scale faster).
func get_weapon_reload_scale(weapon_id: String) -> float:
	return RELOAD_SCALE[get_weapon_rank(weapon_id, "reload")]


func get_weapon_reload_time(weapon_id: String) -> float:
	return float(get_weapon(weapon_id).get("reload_time", 0.0)) * get_weapon_reload_scale(weapon_id)


## {"mag": rounds loaded, "reserve": rounds carried} for a fresh pickup/refill.
func get_weapon_starting_ammo(weapon_id: String) -> Dictionary:
	var entry := get_weapon(weapon_id)
	var reserve := int(entry.get("reserve", 0)) + int(entry.get("reserve_step", 0)) * get_weapon_rank(weapon_id, "reserve")
	return {"mag": get_weapon_mag(weapon_id), "reserve": reserve}


## Display value of a stat at a given rank (board "current -> next").
func get_weapon_stat_at(weapon_id: String, track_id: String, rank: int) -> float:
	var entry := get_weapon(weapon_id)
	rank = clampi(rank, 0, MAX_RANK)
	match track_id:
		"damage":
			return BASE_DAMAGE * float(entry.get("damage", 1.0)) * DAMAGE_SCALE[rank]
		"mag":
			var base := int(entry.get("mag", 8))
			return float(mini(base + int(entry.get("mag_step", 0)) * rank, maxi(base, base * 2 - 1)))
		"rate":
			return 60.0 / (float(entry.get("interval", 0.26)) * INTERVAL_SCALE[rank])
		"reload":
			return float(entry.get("reload_time", 0.0)) * RELOAD_SCALE[rank]
		"reserve":
			return float(int(entry.get("reserve", 0)) + int(entry.get("reserve_step", 0)) * rank)
	return 0.0


func get_weapon_track_cost(weapon_id: String, track_id: String) -> int:
	if not is_track_available(weapon_id, track_id):
		return -1
	var rank := get_weapon_rank(weapon_id, track_id)
	if rank >= MAX_RANK:
		return -1
	var scale := 1.0
	for track in TRACKS:
		if track["id"] == track_id:
			scale = float(track["price_scale"])
	return int(round(WEAPON_TRACK_PRICES[rank] * scale / 50.0)) * 50


func purchase_weapon_track(weapon_id: String, track_id: String) -> bool:
	var cost := get_weapon_track_cost(weapon_id, track_id)
	if cost < 0 or not EconomyManager.spend_money(cost):
		return false
	_set_rank("weapon/%s/%s" % [weapon_id, track_id], get_weapon_rank(weapon_id, track_id) + 1)
	return true

# ------------------------------------------------------------------ survivor

func get_survivor_row(row_id: String) -> Dictionary:
	for entry in SURVIVOR:
		if entry["id"] == row_id:
			return entry
	return {}


func get_survivor_rank(row_id: String) -> int:
	return _rank("survivor/%s" % row_id)


func get_survivor_value(row_id: String, rank: int = -1) -> float:
	var row := get_survivor_row(row_id)
	var values: Array = row.get("values", [])
	if values.is_empty():
		return 0.0
	if rank < 0:
		rank = get_survivor_rank(row_id)
	return float(values[clampi(rank, 0, values.size() - 1)])


func get_health_bonus() -> float:
	return get_survivor_value("max_health") - get_survivor_value("max_health", 0)


func get_survivor_cost(row_id: String) -> int:
	var row := get_survivor_row(row_id)
	if not bool(row.get("unlocked", false)):
		return -1
	var rank := get_survivor_rank(row_id)
	return -1 if rank >= MAX_RANK else SURVIVOR_PRICES[rank]


func purchase_survivor(row_id: String) -> bool:
	var cost := get_survivor_cost(row_id)
	if cost < 0 or not EconomyManager.spend_money(cost):
		return false
	_set_rank("survivor/%s" % row_id, get_survivor_rank(row_id) + 1)
	return true

# ------------------------------------------------------------------ payout

func get_payout_rank() -> int:
	return _rank("payout")


func get_earnings_multiplier() -> float:
	return PAYOUT_MULTIPLIERS[get_payout_rank()]


func get_zombie_reward(type_id: String) -> int:
	for entry in ZOMBIE_TYPES:
		if entry["id"] == type_id:
			return int(round(float(entry["base_reward"]) * get_earnings_multiplier()))
	return 0


func get_payout_cost() -> int:
	var rank := get_payout_rank()
	return -1 if rank >= MAX_RANK else PAYOUT_PRICES[rank]


func purchase_payout() -> bool:
	var cost := get_payout_cost()
	if cost < 0 or not EconomyManager.spend_money(cost):
		return false
	_set_rank("payout", get_payout_rank() + 1)
	return true
