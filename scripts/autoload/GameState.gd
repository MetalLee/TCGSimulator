extends Node

signal state_changed

const STARTING_COINS: int = 300
const STARTING_PACK_ID: String = "basic_pack"
const STARTING_PACK_COUNT: int = 3
const MAX_TRANSACTION_LOG: int = 30

var coins: int = STARTING_COINS
var last_claim_time_unix: int = 0
var owned_packs: Dictionary = {}
var owned_cards: Dictionary = {}
var collection_seen: Dictionary = {}
var stall_listings: Array = []
var transaction_log: Array = []
var tutorial_seen: bool = false
var achievement_progress: Dictionary = {}
var claimed_achievement_rewards: Dictionary = {}


func new_game() -> void:
	coins = STARTING_COINS
	last_claim_time_unix = int(Time.get_unix_time_from_system())
	owned_packs = {
		STARTING_PACK_ID: STARTING_PACK_COUNT,
	}
	owned_cards = {}
	collection_seen = {}
	stall_listings = []
	transaction_log = []
	tutorial_seen = false
	achievement_progress = {}
	claimed_achievement_rewards = {}
	state_changed.emit()


func add_coins(amount: int) -> void:
	if amount <= 0:
		return

	coins += amount
	state_changed.emit()


func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true

	if coins < amount:
		return false

	coins -= amount
	state_changed.emit()
	return true


func add_pack(pack_id: String, count: int) -> void:
	if pack_id.is_empty() or count <= 0:
		return

	owned_packs[pack_id] = int(owned_packs.get(pack_id, 0)) + count
	state_changed.emit()


func remove_pack(pack_id: String, count: int) -> bool:
	if pack_id.is_empty() or count <= 0:
		return true

	var current_count: int = int(owned_packs.get(pack_id, 0))
	if current_count < count:
		return false

	var next_count: int = current_count - count
	if next_count <= 0:
		owned_packs.erase(pack_id)
	else:
		owned_packs[pack_id] = next_count

	state_changed.emit()
	return true


func add_card(card_id: String, count: int) -> void:
	if card_id.is_empty() or count <= 0:
		return

	owned_cards[card_id] = int(owned_cards.get(card_id, 0)) + count
	collection_seen[card_id] = true
	state_changed.emit()


func remove_card(card_id: String, count: int) -> bool:
	if card_id.is_empty() or count <= 0:
		return true

	var current_count: int = get_card_count(card_id)
	if current_count < count:
		return false

	var next_count: int = current_count - count
	if next_count <= 0:
		owned_cards.erase(card_id)
	else:
		owned_cards[card_id] = next_count

	state_changed.emit()
	return true


func get_card_count(card_id: String) -> int:
	return int(owned_cards.get(card_id, 0))


func get_collection_completion() -> float:
	var total_cards: int = CardDatabase.get_total_cards()
	if total_cards <= 0:
		return 0.0

	var seen_count: int = 0
	for card_id in collection_seen.keys():
		if bool(collection_seen.get(card_id, false)):
			seen_count += 1

	return float(seen_count) / float(total_cards)


func add_transaction_log(entry: Dictionary) -> void:
	var log_entry: Dictionary = entry.duplicate(true)
	if not log_entry.has("time_unix"):
		log_entry["time_unix"] = int(Time.get_unix_time_from_system())

	transaction_log.push_front(log_entry)
	if transaction_log.size() > MAX_TRANSACTION_LOG:
		transaction_log.resize(MAX_TRANSACTION_LOG)

	state_changed.emit()


func set_tutorial_seen(value: bool) -> void:
	tutorial_seen = value
	state_changed.emit()


func mark_achievement_progress(achievement_id: String) -> void:
	if achievement_id.is_empty() or bool(achievement_progress.get(achievement_id, false)):
		return

	achievement_progress[achievement_id] = true
	state_changed.emit()


func is_achievement_progress_marked(achievement_id: String) -> bool:
	return bool(achievement_progress.get(achievement_id, false))


func mark_achievement_reward_claimed(achievement_id: String) -> bool:
	if achievement_id.is_empty() or bool(claimed_achievement_rewards.get(achievement_id, false)):
		return false

	claimed_achievement_rewards[achievement_id] = true
	state_changed.emit()
	return true


func is_achievement_reward_claimed(achievement_id: String) -> bool:
	return bool(claimed_achievement_rewards.get(achievement_id, false))


func get_seen_card_count() -> int:
	var seen_count: int = 0
	for card_id in collection_seen.keys():
		if bool(collection_seen.get(card_id, false)):
			seen_count += 1

	return seen_count


func set_last_claim_time_unix(value: int) -> void:
	last_claim_time_unix = maxi(0, value)
	state_changed.emit()


func to_save_data() -> Dictionary:
	return {
		"coins": coins,
		"last_claim_time_unix": last_claim_time_unix,
		"owned_packs": owned_packs,
		"owned_cards": owned_cards,
		"collection_seen": collection_seen,
		"stall_listings": stall_listings,
		"transaction_log": transaction_log,
		"tutorial_seen": tutorial_seen,
		"achievement_progress": achievement_progress,
		"claimed_achievement_rewards": claimed_achievement_rewards,
	}


func load_from_data(data: Dictionary) -> void:
	coins = int(data.get("coins", STARTING_COINS))
	last_claim_time_unix = int(data.get("last_claim_time_unix", int(Time.get_unix_time_from_system())))
	owned_packs = _normalize_count_dictionary(data.get("owned_packs", {}))
	owned_cards = _normalize_count_dictionary(data.get("owned_cards", {}))
	collection_seen = _normalize_bool_dictionary(data.get("collection_seen", {}))
	stall_listings = _normalize_array(data.get("stall_listings", []))
	transaction_log = _normalize_array(data.get("transaction_log", []))
	tutorial_seen = bool(data.get("tutorial_seen", false))
	achievement_progress = _normalize_bool_dictionary(data.get("achievement_progress", {}))
	claimed_achievement_rewards = _normalize_bool_dictionary(data.get("claimed_achievement_rewards", {}))
	state_changed.emit()


func _normalize_count_dictionary(value: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return normalized

	var source: Dictionary = value as Dictionary
	for key in source.keys():
		var item_id: String = String(key)
		var count: int = int(source.get(key, 0))
		if not item_id.is_empty() and count > 0:
			normalized[item_id] = count

	return normalized


func _normalize_bool_dictionary(value: Variant) -> Dictionary:
	var normalized: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return normalized

	var source: Dictionary = value as Dictionary
	for key in source.keys():
		var item_id: String = String(key)
		if not item_id.is_empty():
			normalized[item_id] = bool(source.get(key, false))

	return normalized


func _normalize_array(value: Variant) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []

	var source: Array = value as Array
	return source.duplicate(true)
