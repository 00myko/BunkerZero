extends Node

signal money_changed(balance: int)
signal money_earned(amount: int, balance: int)

var money: int = 0

func _ready() -> void:
	money = maxi(0, int(SaveManager.get_value("economy", "money", 0)))
	call_deferred("_emit_initial_balance")

func _emit_initial_balance() -> void:
	money_changed.emit(money)

func get_balance() -> int:
	return money

func add_money(amount: int) -> int:
	var safe_amount: int = maxi(0, amount)
	if safe_amount <= 0:
		return 0
	money += safe_amount
	SaveManager.set_value("economy", "money", money)
	money_earned.emit(safe_amount, money)
	money_changed.emit(money)
	return safe_amount

func award_zombie_kill(base_reward: int) -> int:
	var multiplier: float = UpgradeManager.get_earnings_multiplier()
	var final_reward: int = maxi(1, int(round(float(base_reward) * multiplier)))
	return add_money(final_reward)

func can_afford(amount: int) -> bool:
	return money >= maxi(0, amount)

func spend_money(amount: int) -> bool:
	var safe_amount: int = maxi(0, amount)
	if safe_amount <= 0 or money < safe_amount:
		return false
	money -= safe_amount
	SaveManager.set_value("economy", "money", money)
	money_changed.emit(money)
	return true
