extends Node

const CARDS_PATH: String = "res://data/cards.json"
const PACKS_PATH: String = "res://data/packs.json"

var _cards: Array = []
var _packs: Array = []
var _cards_by_id: Dictionary = {}
var _cards_by_series: Dictionary = {}
var _cards_by_rarity: Dictionary = {}
var _packs_by_id: Dictionary = {}


func _ready() -> void:
	load_cards()
	load_packs()


func load_cards() -> bool:
	var loaded_cards: Array = _load_json_array(CARDS_PATH, "cards")

	_cards.clear()
	_cards_by_id.clear()
	_cards_by_series.clear()
	_cards_by_rarity.clear()

	for card_data in loaded_cards:
		if typeof(card_data) != TYPE_DICTIONARY:
			push_warning("CardDatabase skipped a non-dictionary card entry.")
			continue

		var card := (card_data as Dictionary).duplicate(true)
		var card_id := String(card.get("id", ""))
		if card_id.is_empty():
			push_warning("CardDatabase skipped a card without id.")
			continue

		var series := String(card.get("series", ""))
		var rarity := String(card.get("rarity", ""))

		_cards.append(card)
		_cards_by_id[card_id] = card
		_add_to_index(_cards_by_series, series, card)
		_add_to_index(_cards_by_rarity, rarity, card)

	return not _cards.is_empty()


func load_packs() -> bool:
	var loaded_packs: Array = _load_json_array(PACKS_PATH, "packs")

	_packs.clear()
	_packs_by_id.clear()

	for pack_data in loaded_packs:
		if typeof(pack_data) != TYPE_DICTIONARY:
			push_warning("CardDatabase skipped a non-dictionary pack entry.")
			continue

		var pack := (pack_data as Dictionary).duplicate(true)
		var pack_id := String(pack.get("id", ""))
		if pack_id.is_empty():
			push_warning("CardDatabase skipped a pack without id.")
			continue

		_packs.append(pack)
		_packs_by_id[pack_id] = pack

	return not _packs.is_empty()


func get_card(card_id: String) -> Dictionary:
	var card := _cards_by_id.get(card_id, {}) as Dictionary
	return card.duplicate(true)


func get_all_cards() -> Array:
	return _cards.duplicate(true)


func get_cards_by_series(series: String) -> Array:
	return _get_indexed_cards(_cards_by_series, series)


func get_cards_by_rarity(rarity: String) -> Array:
	return _get_indexed_cards(_cards_by_rarity, rarity)


func get_pack(pack_id: String) -> Dictionary:
	var pack := _packs_by_id.get(pack_id, {}) as Dictionary
	return pack.duplicate(true)


func get_all_packs() -> Array:
	return _packs.duplicate(true)


func get_total_cards() -> int:
	return _cards.size()


func get_total_packs() -> int:
	return _packs.size()


func _load_json_array(path: String, resource_name: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("CardDatabase could not find %s data at %s." % [resource_name, path])
		return []

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CardDatabase could not open %s data at %s." % [resource_name, path])
		return []

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("CardDatabase expected %s data to be a JSON array." % resource_name)
		return []

	return parsed as Array


func _add_to_index(index: Dictionary, key: String, card: Dictionary) -> void:
	if key.is_empty():
		return

	if not index.has(key):
		index[key] = []

	var cards_for_key := index[key] as Array
	cards_for_key.append(card)


func _get_indexed_cards(index: Dictionary, key: String) -> Array:
	var cards := index.get(key, []) as Array
	return cards.duplicate(true)
