extends Node

const PACK_PRICE: int = 60
const RARITY_ORDER: Array[String] = ["N", "R", "SR", "SSR", "UR"]
const IDLE_REWARD_INTERVAL_SECONDS: int = 1800
const MAX_IDLE_REWARD_SECONDS: int = 8 * 60 * 60
const IDLE_PACK_ID: String = "basic_pack"
const IDLE_COINS_PER_INTERVAL: int = 5

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func can_buy_pack(coins: int) -> bool:
	return coins >= PACK_PRICE


func get_pack_price() -> int:
	return PACK_PRICE


func get_idle_pack_count(elapsed_seconds: int) -> int:
	# MVP formula: every 30 minutes of offline time grants one pack.
	return maxi(0, floori(float(elapsed_seconds) / float(IDLE_REWARD_INTERVAL_SECONDS)))


func get_pending_idle_rewards() -> Dictionary:
	var current_time_unix: int = int(Time.get_unix_time_from_system())
	var elapsed_seconds: int = maxi(0, current_time_unix - GameState.last_claim_time_unix)
	var claimable_seconds: int = mini(elapsed_seconds, MAX_IDLE_REWARD_SECONDS)
	var claimable_intervals: int = get_idle_pack_count(claimable_seconds)
	var packs: Dictionary = {}
	if claimable_intervals > 0:
		packs[IDLE_PACK_ID] = claimable_intervals

	return {
		"elapsed_seconds": claimable_seconds,
		"claimable_intervals": claimable_intervals,
		"packs": packs,
		"coins": claimable_intervals * IDLE_COINS_PER_INTERVAL,
	}


func claim_idle_rewards() -> Dictionary:
	var rewards: Dictionary = get_pending_idle_rewards()
	var claimable_intervals: int = int(rewards.get("claimable_intervals", 0))
	if claimable_intervals <= 0:
		return rewards

	var packs: Dictionary = rewards.get("packs", {}) as Dictionary
	for pack_id in packs.keys():
		GameState.add_pack(String(pack_id), int(packs.get(pack_id, 0)))

	GameState.add_coins(int(rewards.get("coins", 0)))
	GameState.set_last_claim_time_unix(int(Time.get_unix_time_from_system()))
	GameState.mark_achievement_progress("claim_idle_reward")
	SaveService.save_game()
	return rewards


func buy_pack(pack_id: String) -> Dictionary:
	var pack: Dictionary = CardDatabase.get_pack(pack_id)
	if pack.is_empty():
		return {
			"success": false,
			"reason": "未知卡包。",
		}

	var price: int = int(pack.get("price", PACK_PRICE))
	if not GameState.spend_coins(price):
		return {
			"success": false,
			"reason": "金币不足。",
		}

	GameState.add_pack(pack_id, 1)
	SaveService.save_game()
	return {
		"success": true,
		"pack_id": pack_id,
		"price": price,
	}


func open_pack(pack_id: String) -> Dictionary:
	var pack: Dictionary = CardDatabase.get_pack(pack_id)
	if pack.is_empty():
		return {
			"success": false,
			"reason": "未知卡包。",
			"results": [],
		}

	if int(GameState.owned_packs.get(pack_id, 0)) <= 0:
		return {
			"success": false,
			"reason": "没有可打开的卡包。",
			"results": [],
		}

	var cards_per_pack: int = int(pack.get("cards_per_pack", 0))
	if cards_per_pack <= 0:
		return {
			"success": false,
			"reason": "卡包配置无效。",
			"results": [],
		}

	var selected_cards: Array[Dictionary] = []
	var rolled_rarities: Array[String] = []
	for draw_index in range(cards_per_pack):
		var rolled_rarity: String = _roll_rarity(pack)
		var selected_card: Dictionary = _pick_card_for_pack(pack, rolled_rarity)
		if selected_card.is_empty():
			return {
				"success": false,
				"reason": "没有可抽取的卡牌。",
				"results": [],
			}

		selected_cards.append(selected_card)
		rolled_rarities.append(rolled_rarity)

	if not GameState.remove_pack(pack_id, 1):
		return {
			"success": false,
			"reason": "卡包数量不足。",
			"results": [],
		}

	var results: Array[Dictionary] = []
	for card_index in range(selected_cards.size()):
		var card: Dictionary = selected_cards[card_index].duplicate(true)
		var card_id: String = String(card.get("id", ""))
		var was_new: bool = not bool(GameState.collection_seen.get(card_id, false))
		GameState.add_card(card_id, 1)
		card["was_new"] = was_new
		card["owned_count"] = GameState.get_card_count(card_id)
		card["rolled_rarity"] = rolled_rarities[card_index]
		results.append(card)

	GameState.mark_achievement_progress("open_pack")
	SaveService.save_game()
	return {
		"success": true,
		"pack_id": pack_id,
		"results": results,
	}


func get_card_sell_price(card_data: Dictionary) -> int:
	return int(card_data.get("base_price", 5))


func _roll_rarity(pack: Dictionary) -> String:
	var rates: Dictionary = pack.get("rarity_rates", {}) as Dictionary
	var total_weight: float = 0.0
	for rarity in RARITY_ORDER:
		total_weight += float(rates.get(rarity, 0.0))

	if total_weight <= 0.0:
		return RARITY_ORDER[0]

	var roll: float = _rng.randf_range(0.0, total_weight)
	var cursor: float = 0.0
	for rarity in RARITY_ORDER:
		cursor += float(rates.get(rarity, 0.0))
		if roll <= cursor:
			return rarity

	return RARITY_ORDER[0]


func _pick_card_for_pack(pack: Dictionary, rolled_rarity: String) -> Dictionary:
	var rarity_index: int = RARITY_ORDER.find(rolled_rarity)
	if rarity_index < 0:
		rarity_index = 0

	var allowed_series: Array = _get_allowed_series(pack)
	for index in range(rarity_index, -1, -1):
		var rarity: String = RARITY_ORDER[index]
		var candidates: Array[Dictionary] = _get_candidate_cards(allowed_series, rarity)
		if not candidates.is_empty():
			var selected_index: int = _rng.randi_range(0, candidates.size() - 1)
			return candidates[selected_index].duplicate(true)

	return {}


func _get_allowed_series(pack: Dictionary) -> Array:
	var allowed_series_value: Variant = pack.get("allowed_series", [])
	if typeof(allowed_series_value) != TYPE_ARRAY:
		return []

	var allowed_series: Array = allowed_series_value as Array
	return allowed_series.duplicate(true)


func _get_candidate_cards(allowed_series: Array, rarity: String) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	if allowed_series.is_empty():
		for card_data in CardDatabase.get_cards_by_rarity(rarity):
			var card: Dictionary = card_data as Dictionary
			candidates.append(card)
		return candidates

	for series_value in allowed_series:
		var series: String = String(series_value)
		for card_data in CardDatabase.get_cards_by_series(series):
			var card: Dictionary = card_data as Dictionary
			if String(card.get("rarity", "")) == rarity:
				candidates.append(card)

	return candidates
