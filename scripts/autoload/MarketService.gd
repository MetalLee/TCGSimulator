extends Node

const STALL_SLOT_LIMIT: int = 6
const TRANSACTION_TAX_RATE: float = 0.05
const MOCK_MARKET_LISTING_COUNT: int = 36
const NPC_BUYER_TYPES: Array[String] = [
	"NPC 新手收藏家",
	"NPC 稀有猎人",
	"NPC 富豪收藏家",
	"NPC 系列收藏家",
]
const MARKET_OFFERS: Array = [
	{
		"seller": "模拟玩家A",
		"card_id": "basic_001",
		"price": 12,
	},
	{
		"seller": "模拟玩家B",
		"card_id": "forest_016",
		"price": 48,
	},
]
const MOCK_SELLER_NAMES: Array[String] = [
	"模拟摊主 晨星",
	"模拟摊主 松影",
	"模拟摊主 齿轮",
	"模拟摊主 蓝灯",
	"模拟摊主 银页",
	"模拟摊主 木柜",
]

var _rng := RandomNumberGenerator.new()
var _mock_market_listings: Array[Dictionary] = []


func _ready() -> void:
	_rng.randomize()
	generate_mock_market_listings()


func get_market_offers() -> Array:
	return get_mock_market_listings()


func generate_mock_market_listings(count: int = MOCK_MARKET_LISTING_COUNT) -> Array:
	var cards: Array = CardDatabase.get_all_cards()
	_mock_market_listings.clear()
	if cards.is_empty():
		return []

	for index in range(count):
		var card: Dictionary = cards[_rng.randi_range(0, cards.size() - 1)] as Dictionary
		_mock_market_listings.append(_make_mock_listing(card, index))

	return get_mock_market_listings()


func get_mock_market_listings() -> Array:
	return _mock_market_listings.duplicate(true)


func purchase_mock_listing(mock_listing_id: String) -> Dictionary:
	for index in range(_mock_market_listings.size()):
		var listing: Dictionary = _mock_market_listings[index] as Dictionary
		if String(listing.get("mock_listing_id", "")) != mock_listing_id:
			continue

		return _purchase_mock_listing_at(index)

	return {
		"success": false,
		"reason": "未找到模拟上架。",
	}


func get_stall_slot_limit() -> int:
	return STALL_SLOT_LIMIT


func get_used_stall_slots() -> int:
	return GameState.stall_listings.size()


func get_free_stall_slots() -> int:
	return maxi(0, STALL_SLOT_LIMIT - get_used_stall_slots())


func get_total_listing_value() -> int:
	var total_value: int = 0
	for listing_data in GameState.stall_listings:
		var listing: Dictionary = listing_data as Dictionary
		total_value += int(listing.get("quantity", 0)) * int(listing.get("price_each", 0))

	return total_value


func get_suggested_price(card_id: String) -> int:
	var card: Dictionary = CardDatabase.get_card(card_id)
	return maxi(1, int(card.get("base_price", 1)))


func create_listing(card_id: String, quantity: int, price_each: int) -> Dictionary:
	if get_free_stall_slots() <= 0:
		return {
			"success": false,
			"reason": "摊位格子已满。",
		}

	if quantity <= 0:
		return {
			"success": false,
			"reason": "上架数量必须大于 0。",
		}

	var card: Dictionary = CardDatabase.get_card(card_id)
	if card.is_empty():
		return {
			"success": false,
			"reason": "未知卡牌。",
		}

	if GameState.get_card_count(card_id) < quantity:
		return {
			"success": false,
			"reason": "库存数量不足。",
		}

	if not GameState.remove_card(card_id, quantity):
		return {
			"success": false,
			"reason": "库存扣除失败。",
		}

	var listing: Dictionary = {
		"listing_id": _make_listing_id(),
		"card_id": card_id,
		"quantity": quantity,
		"price_each": maxi(1, price_each),
		"created_at_unix": int(Time.get_unix_time_from_system()),
	}
	GameState.stall_listings.append(listing)
	GameState.mark_achievement_progress("list_card")
	GameState.state_changed.emit()
	SaveService.save_game()
	return {
		"success": true,
		"listing": listing.duplicate(true),
	}


func cancel_listing(listing_id: String) -> Dictionary:
	for index in range(GameState.stall_listings.size()):
		var listing: Dictionary = GameState.stall_listings[index] as Dictionary
		if String(listing.get("listing_id", "")) != listing_id:
			continue

		var card_id: String = String(listing.get("card_id", ""))
		var quantity: int = int(listing.get("quantity", 0))
		GameState.stall_listings.remove_at(index)
		GameState.add_card(card_id, quantity)
		SaveService.save_game()
		return {
			"success": true,
			"listing": listing.duplicate(true),
		}

	return {
		"success": false,
		"reason": "未找到上架记录。",
	}


func simulate_buyer_tick(_listings: Array = []) -> Dictionary:
	var visitor_count: int = _rng.randi_range(3, 8)
	var sales: Array[Dictionary] = []
	var total_gross: int = 0
	var total_tax: int = 0
	var total_net: int = 0
	GameState.mark_achievement_progress("simulate_visitors")

	for visitor_index in range(visitor_count):
		if GameState.stall_listings.is_empty():
			break

		var buyer: Dictionary = _make_npc_buyer()
		var listing_index: int = _find_listing_for_buyer(buyer)
		if listing_index < 0:
			continue

		var sale: Dictionary = _complete_npc_purchase(listing_index, buyer)
		if sale.is_empty():
			continue

		sales.append(sale)
		total_gross += int(sale.get("price_each", 0))
		total_tax += int(sale.get("tax", 0))
		total_net += int(sale.get("net_income", 0))

	if not sales.is_empty():
		GameState.mark_achievement_progress("earn_sale_gold")

	SaveService.save_game()

	return {
		"visitor_count": visitor_count,
		"sales": sales,
		"total_sales": sales.size(),
		"total_gross": total_gross,
		"total_tax": total_tax,
		"total_net": total_net,
	}


func _make_listing_id() -> String:
	var unix_time: int = int(Time.get_unix_time_from_system())
	var random_part: int = _rng.randi_range(100000, 999999)
	return "listing_%d_%d" % [unix_time, random_part]


func _make_mock_listing(card: Dictionary, index: int) -> Dictionary:
	var price_multiplier: float = _roll_mock_price_multiplier()
	var base_price: int = maxi(1, int(card.get("base_price", 1)))
	var price_each: int = maxi(1, roundi(float(base_price) * price_multiplier))
	return {
		"mock_listing_id": "mock_%d_%d" % [int(Time.get_unix_time_from_system()), index],
		"seller_name": MOCK_SELLER_NAMES[_rng.randi_range(0, MOCK_SELLER_NAMES.size() - 1)],
		"card_id": String(card.get("id", "")),
		"quantity": _rng.randi_range(1, 3),
		"price_each": price_each,
		"price_multiplier": snappedf(price_multiplier, 0.01),
	}


func _roll_mock_price_multiplier() -> float:
	var band_roll: int = _rng.randi_range(0, 99)
	if band_roll < 25:
		return _rng.randf_range(0.70, 0.90)
	if band_roll < 78:
		return _rng.randf_range(0.90, 1.20)
	return _rng.randf_range(1.20, 1.80)


func _purchase_mock_listing_at(index: int) -> Dictionary:
	var listing: Dictionary = _mock_market_listings[index] as Dictionary
	var card_id: String = String(listing.get("card_id", ""))
	var card: Dictionary = CardDatabase.get_card(card_id)
	if card.is_empty():
		return {
			"success": false,
			"reason": "未知卡牌。",
		}

	var price_each: int = int(listing.get("price_each", 0))
	if not GameState.spend_coins(price_each):
		return {
			"success": false,
			"reason": "金币不足。",
		}

	var was_new: bool = not bool(GameState.collection_seen.get(card_id, false))
	GameState.add_card(card_id, 1)

	var remaining_quantity: int = int(listing.get("quantity", 0)) - 1
	if remaining_quantity <= 0:
		_mock_market_listings.remove_at(index)
	else:
		listing["quantity"] = remaining_quantity
		_mock_market_listings[index] = listing

	var transaction: Dictionary = {
		"type": "mock_market_purchase",
		"seller_name": String(listing.get("seller_name", "模拟摊主")),
		"card_id": card_id,
		"card_name": String(card.get("name", card_id)),
		"rarity": String(card.get("rarity", "")),
		"series": String(card.get("series", "")),
		"price_each": price_each,
		"was_new": was_new,
		"time_unix": int(Time.get_unix_time_from_system()),
	}
	GameState.add_transaction_log(transaction)
	GameState.mark_achievement_progress("buy_market_card")
	SaveService.save_game()

	return {
		"success": true,
		"listing": listing.duplicate(true),
		"card": card.duplicate(true),
		"was_new": was_new,
		"price_each": price_each,
	}


func _make_npc_buyer() -> Dictionary:
	var buyer_type: String = NPC_BUYER_TYPES[_rng.randi_range(0, NPC_BUYER_TYPES.size() - 1)]
	var buyer: Dictionary = {
		"type": buyer_type,
	}

	if buyer_type == "NPC 系列收藏家":
		var series_options: Array[String] = _get_series_options()
		if not series_options.is_empty():
			buyer["target_series"] = series_options[_rng.randi_range(0, series_options.size() - 1)]

	return buyer


func _get_series_options() -> Array[String]:
	var series_options: Array[String] = []
	for card_data in CardDatabase.get_all_cards():
		var card: Dictionary = card_data as Dictionary
		var series: String = String(card.get("series", ""))
		if not series.is_empty() and not series_options.has(series):
			series_options.append(series)

	return series_options


func _find_listing_for_buyer(buyer: Dictionary) -> int:
	var candidate_indices: Array[int] = []
	for index in range(GameState.stall_listings.size()):
		var listing: Dictionary = GameState.stall_listings[index] as Dictionary
		if _buyer_would_consider_listing(buyer, listing):
			candidate_indices.append(index)

	if candidate_indices.is_empty():
		return -1

	return candidate_indices[_rng.randi_range(0, candidate_indices.size() - 1)]


func _buyer_would_consider_listing(buyer: Dictionary, listing: Dictionary) -> bool:
	if int(listing.get("quantity", 0)) <= 0:
		return false

	var card_id: String = String(listing.get("card_id", ""))
	var card: Dictionary = CardDatabase.get_card(card_id)
	if card.is_empty():
		return false

	var buyer_type: String = String(buyer.get("type", ""))
	var rarity: String = String(card.get("rarity", "N"))
	var base_price: int = maxi(1, int(card.get("base_price", 1)))
	var price_each: int = int(listing.get("price_each", 0))
	var price_ratio: float = float(price_each) / float(base_price)

	if buyer_type == "NPC 新手收藏家":
		return (rarity == "N" or rarity == "R") and price_ratio < 1.2 and _rng.randf() < _get_price_sensitive_chance(price_ratio, 1.2)

	if buyer_type == "NPC 稀有猎人":
		return (rarity == "SR" or rarity == "SSR") and price_ratio < 1.3 and _rng.randf() < _get_price_sensitive_chance(price_ratio, 1.3)

	if buyer_type == "NPC 富豪收藏家":
		return (rarity == "UR" or rarity == "SSR") and price_ratio < 1.6 and _rng.randf() < (0.22 * _get_price_sensitive_chance(price_ratio, 1.6))

	if buyer_type == "NPC 系列收藏家":
		var target_series: String = String(buyer.get("target_series", ""))
		return String(card.get("series", "")) == target_series and price_ratio < 1.4 and _rng.randf() < _get_price_sensitive_chance(price_ratio, 1.4)

	return false


func _get_price_sensitive_chance(price_ratio: float, max_ratio: float) -> float:
	var normalized: float = clamp(price_ratio / max_ratio, 0.0, 1.0)
	return clamp(1.05 - normalized, 0.18, 0.95)


func _complete_npc_purchase(listing_index: int, buyer: Dictionary) -> Dictionary:
	if listing_index < 0 or listing_index >= GameState.stall_listings.size():
		return {}

	var listing: Dictionary = GameState.stall_listings[listing_index] as Dictionary
	var card_id: String = String(listing.get("card_id", ""))
	var card: Dictionary = CardDatabase.get_card(card_id)
	if card.is_empty():
		return {}

	var price_each: int = int(listing.get("price_each", 0))
	var tax: int = ceili(float(price_each) * TRANSACTION_TAX_RATE)
	var net_income: int = maxi(0, price_each - tax)
	var remaining_quantity: int = int(listing.get("quantity", 0)) - 1

	if remaining_quantity <= 0:
		GameState.stall_listings.remove_at(listing_index)
	else:
		listing["quantity"] = remaining_quantity
		GameState.stall_listings[listing_index] = listing

	GameState.add_coins(net_income)

	var sale: Dictionary = {
		"type": "npc_sale",
		"buyer_type": String(buyer.get("type", "NPC 买家")),
		"card_id": card_id,
		"card_name": String(card.get("name", card_id)),
		"rarity": String(card.get("rarity", "")),
		"series": String(card.get("series", "")),
		"price_each": price_each,
		"tax": tax,
		"net_income": net_income,
		"remaining_quantity": remaining_quantity,
		"time_unix": int(Time.get_unix_time_from_system()),
	}
	GameState.add_transaction_log(sale)
	return sale
