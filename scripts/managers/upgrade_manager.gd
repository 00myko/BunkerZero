extends Node

signal upgrades_changed

const WEAPON_COSTS: Array[int] = [400, 900, 1800, 3500, 6500]
const EARNINGS_COSTS: Array[int] = [500, 1200, 2500, 5000, 9000]
const SURVIVOR_COSTS: Array[int] = [600, 1400, 2800, 5200, 9000]
const EARNINGS_MULTIPLIERS: Array[float] = [1.0, 1.25, 1.50, 1.85, 2.25, 2.75]
const PISTOL_DAMAGE_BY_LEVEL: Array[float] = [25.0, 29.0, 33.0, 40.0, 50.0, 65.0]
const HEALTH_BONUS_BY_LEVEL: Array[float] = [0.0, 20.0, 40.0, 70.0, 110.0, 160.0]

var weapon_level: int = 0
var earnings_level: int = 0
var survivor_level: int = 0

func _ready() -> void:
	weapon_level = clampi(int(SaveManager.get_value("upgrades", "weapon_level", 0)), 0, 5)
	earnings_level = clampi(int(SaveManager.get_value("upgrades", "earnings_level", 0)), 0, 5)
	survivor_level = clampi(int(SaveManager.get_value("upgrades", "survivor_level", 0)), 0, 5)

func get_earnings_multiplier() -> float:
	return EARNINGS_MULTIPLIERS[earnings_level]

func get_pistol_damage() -> float:
	return PISTOL_DAMAGE_BY_LEVEL[weapon_level]


func get_weapon_damage(weapon_id: String = "pistol") -> float:
	var pistol_damage := get_pistol_damage()
	if weapon_id == "uzi":
		# Early spray. Weaker than the SMG; it wins on rate, not chunk.
		return pistol_damage * 0.52
	if weapon_id == "shotgun":
		# 4.0x pistol: 100 at tier 0 if the pattern connects. One-shots Room 1,
		# two-taps Room 2, then needs upgrades against 250–380 HP elites.
		return pistol_damage * 4.0
	match weapon_id:
		"sawnoffs":
			# Panic double. Wider, weaker per barrel than the single sawn-off.
			return pistol_damage * 2.10
		"sawnoff":
			# Tighter two-shot. Both barrels still below a clean pump blast.
			return pistol_damage * 2.70
		"crossbow":
			# 90 body / 180 head at tier 0. Room 1 body is two bolts; heads delete.
			return pistol_damage * 3.60
		"crossbow_bash":
			return pistol_damage * 0.80
		"knife":
			return pistol_damage * 1.40
		"knife_stab":
			return pistol_damage * 2.20
		"minigun":
			return pistol_damage * 0.48
		"smg":
			# Mid spray. Harder hit, slower cycle than the Uzi.
			return pistol_damage * 0.78
		"lmg":
			# Heavy bullet, not an SMG with a bigger mag.
			return pistol_damage * 0.68
		"grenade_launcher":
			# 110 splash at tier 0. One-shots Room 1 in the blast, two-taps Room 2+.
			return pistol_damage * 4.40
	return pistol_damage

func get_health_bonus() -> float:
	return HEALTH_BONUS_BY_LEVEL[survivor_level]

func get_next_cost(upgrade_type: String) -> int:
	var level: int = 0
	var costs: Array[int] = []
	match upgrade_type:
		"weapon":
			level = weapon_level
			costs = WEAPON_COSTS
		"earnings":
			level = earnings_level
			costs = EARNINGS_COSTS
		"survivor":
			level = survivor_level
			costs = SURVIVOR_COSTS
		_:
			return -1
	if level >= costs.size():
		return -1
	return costs[level]

func purchase(upgrade_type: String) -> bool:
	var cost: int = get_next_cost(upgrade_type)
	if cost < 0 or not EconomyManager.spend_money(cost):
		return false
	match upgrade_type:
		"weapon":
			weapon_level += 1
		"earnings":
			earnings_level += 1
		"survivor":
			survivor_level += 1
	SaveManager.set_value("upgrades", "weapon_level", weapon_level, false)
	SaveManager.set_value("upgrades", "earnings_level", earnings_level, false)
	SaveManager.set_value("upgrades", "survivor_level", survivor_level, false)
	SaveManager.save()
	upgrades_changed.emit()
	return true
