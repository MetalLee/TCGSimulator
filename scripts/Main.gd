extends Control

const PAGE_CONFIG: Array = [
	{
		"id": "dashboard",
		"button_path": "RootMargin/Layout/NavigationPanel/NavigationMargin/Navigation/DashboardButton",
		"panel_path": "RootMargin/Layout/PagePanel/PageMargin/PageStack/DashboardPanel",
	},
	{
		"id": "packs",
		"button_path": "RootMargin/Layout/NavigationPanel/NavigationMargin/Navigation/PacksButton",
		"panel_path": "RootMargin/Layout/PagePanel/PageMargin/PageStack/PacksPanel",
	},
	{
		"id": "collection",
		"button_path": "RootMargin/Layout/NavigationPanel/NavigationMargin/Navigation/CollectionButton",
		"panel_path": "RootMargin/Layout/PagePanel/PageMargin/PageStack/CollectionPanel",
	},
	{
		"id": "inventory",
		"button_path": "RootMargin/Layout/NavigationPanel/NavigationMargin/Navigation/InventoryButton",
		"panel_path": "RootMargin/Layout/PagePanel/PageMargin/PageStack/InventoryPanel",
	},
	{
		"id": "stall",
		"button_path": "RootMargin/Layout/NavigationPanel/NavigationMargin/Navigation/StallButton",
		"panel_path": "RootMargin/Layout/PagePanel/PageMargin/PageStack/StallPanel",
	},
	{
		"id": "market",
		"button_path": "RootMargin/Layout/NavigationPanel/NavigationMargin/Navigation/MarketButton",
		"panel_path": "RootMargin/Layout/PagePanel/PageMargin/PageStack/MarketPanel",
	},
	{
		"id": "debug",
		"button_path": "RootMargin/Layout/NavigationPanel/NavigationMargin/Navigation/DebugButton",
		"panel_path": "RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel",
	},
]
const TUTORIAL_MESSAGES: Array[String] = [
	"欢迎！你经营着一个小小的线上卡牌摊位。",
	"领取挂机奖励可以获得卡包。",
	"打开卡包可以收集卡牌。",
	"重复卡可以上架到你的摊位。",
	"访客可能会购买你的卡牌，并支付金币。",
	"金币可以用来购买更多卡包，或者购买缺失卡牌。",
]
const ACHIEVEMENTS: Array = [
	{
		"id": "claim_idle_reward",
		"title": "领取挂机奖励",
		"hint": "下一步：在仪表盘领取挂机奖励，拿到更多卡包。",
		"reward_type": "pack",
		"reward_amount": 1,
	},
	{
		"id": "open_pack",
		"title": "打开一个卡包",
		"hint": "下一步：进入卡包页，打开一个已拥有的卡包。",
		"reward_type": "coins",
		"reward_amount": 50,
	},
	{
		"id": "collect_10_unique_cards",
		"title": "收集 10 张不同卡牌",
		"hint": "下一步：继续开包或逛市场，把图鉴推进到 10 张不同卡牌。",
		"reward_type": "pack",
		"reward_amount": 1,
	},
	{
		"id": "list_card",
		"title": "上架一张重复卡",
		"hint": "下一步：在库存或我的摊位页，把一张卡上架出售。",
		"reward_type": "coins",
		"reward_amount": 50,
	},
	{
		"id": "simulate_visitors",
		"title": "模拟访客",
		"hint": "下一步：进入我的摊位页，点击模拟访客。",
		"reward_type": "coins",
		"reward_amount": 50,
	},
	{
		"id": "earn_sale_gold",
		"title": "通过出售卡牌获得金币",
		"hint": "下一步：用合理价格上架卡牌，再模拟访客完成一笔销售。",
		"reward_type": "pack",
		"reward_amount": 1,
	},
	{
		"id": "buy_market_card",
		"title": "从市场购买一张卡牌",
		"hint": "下一步：进入市场，用金币购买一张模拟摊位卡牌。",
		"reward_type": "coins",
		"reward_amount": 50,
	},
]
const MAIN_THEME: Theme = preload("res://theme/main_theme.tres")

var _buttons: Dictionary = {}
var _panels: Dictionary = {}
var _idle_reward_refresh_timer: Timer
var _debug_rng := RandomNumberGenerator.new()
var _tutorial_step_index: int = 0

@onready var _dashboard_stats_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DashboardPanel/Margin/Content/DashboardStats
@onready var _idle_time_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DashboardPanel/Margin/Content/IdleTime
@onready var _idle_rewards_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DashboardPanel/Margin/Content/IdleRewards
@onready var _claim_idle_button: Button = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DashboardPanel/Margin/Content/ClaimIdleButton
@onready var _claim_idle_status_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DashboardPanel/Margin/Content/ClaimIdleStatus
@onready var _achievement_hint_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DashboardPanel/Margin/Content/AchievementNextHint
@onready var _achievement_list: VBoxContainer = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DashboardPanel/Margin/Content/AchievementScroll/AchievementList
@onready var _pack_wallet_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/PacksPanel/Margin/Content/PackWallet
@onready var _pack_list: VBoxContainer = $RootMargin/Layout/PagePanel/PageMargin/PageStack/PacksPanel/Margin/Content/PackList
@onready var _pack_status_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/PacksPanel/Margin/Content/PackStatus
@onready var _pack_results_list: VBoxContainer = $RootMargin/Layout/PagePanel/PageMargin/PageStack/PacksPanel/Margin/Content/OpenResults
@onready var _collection_summary_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/CollectionPanel/Margin/Content/CollectionSummary
@onready var _collection_filter_option: OptionButton = $RootMargin/Layout/PagePanel/PageMargin/PageStack/CollectionPanel/Margin/Content/CollectionFilters/CollectionFilter
@onready var _collection_list: VBoxContainer = $RootMargin/Layout/PagePanel/PageMargin/PageStack/CollectionPanel/Margin/Content/CollectionScroll/CollectionList
@onready var _inventory_summary_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/InventoryPanel/Margin/Content/InventorySummary
@onready var _inventory_sort_option: OptionButton = $RootMargin/Layout/PagePanel/PageMargin/PageStack/InventoryPanel/Margin/Content/InventoryControls/InventorySort
@onready var _inventory_list: VBoxContainer = $RootMargin/Layout/PagePanel/PageMargin/PageStack/InventoryPanel/Margin/Content/InventoryScroll/InventoryList
@onready var _inventory_status_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/InventoryPanel/Margin/Content/InventoryStatus
@onready var _stall_summary_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/StallPanel/Margin/Content/StallSummary
@onready var _simulate_visitors_button: Button = $RootMargin/Layout/PagePanel/PageMargin/PageStack/StallPanel/Margin/Content/SimulateVisitorsButton
@onready var _stall_listing_list: VBoxContainer = $RootMargin/Layout/PagePanel/PageMargin/PageStack/StallPanel/Margin/Content/StallListings
@onready var _stall_inventory_list: VBoxContainer = $RootMargin/Layout/PagePanel/PageMargin/PageStack/StallPanel/Margin/Content/StallInventoryScroll/StallInventoryList
@onready var _stall_transaction_list: VBoxContainer = $RootMargin/Layout/PagePanel/PageMargin/PageStack/StallPanel/Margin/Content/StallTransactions
@onready var _stall_status_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/StallPanel/Margin/Content/StallStatus
@onready var _market_summary_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/MarketPanel/Margin/Content/MarketSummary
@onready var _market_search_input: LineEdit = $RootMargin/Layout/PagePanel/PageMargin/PageStack/MarketPanel/Margin/Content/MarketFiltersTop/SearchInput
@onready var _market_uncollected_only: CheckBox = $RootMargin/Layout/PagePanel/PageMargin/PageStack/MarketPanel/Margin/Content/MarketFiltersTop/UncollectedOnly
@onready var _market_refresh_button: Button = $RootMargin/Layout/PagePanel/PageMargin/PageStack/MarketPanel/Margin/Content/MarketFiltersTop/RefreshMarketButton
@onready var _market_series_filter: OptionButton = $RootMargin/Layout/PagePanel/PageMargin/PageStack/MarketPanel/Margin/Content/MarketFiltersBottom/SeriesFilter
@onready var _market_rarity_filter: OptionButton = $RootMargin/Layout/PagePanel/PageMargin/PageStack/MarketPanel/Margin/Content/MarketFiltersBottom/RarityFilter
@onready var _market_max_price_spin: SpinBox = $RootMargin/Layout/PagePanel/PageMargin/PageStack/MarketPanel/Margin/Content/MarketFiltersBottom/MaxPriceSpin
@onready var _market_sort_option: OptionButton = $RootMargin/Layout/PagePanel/PageMargin/PageStack/MarketPanel/Margin/Content/MarketFiltersBottom/SortOption
@onready var _market_status_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/MarketPanel/Margin/Content/MarketStatus
@onready var _market_listing_list: VBoxContainer = $RootMargin/Layout/PagePanel/PageMargin/PageStack/MarketPanel/Margin/Content/MarketScroll/MarketListings
@onready var _debug_stats_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel/Margin/Content/DebugStats
@onready var _debug_state_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel/Margin/Content/DebugState
@onready var _debug_status_label: Label = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel/Margin/Content/DebugStatus
@onready var _debug_add_100_coins_button: Button = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel/Margin/Content/ResourceActions/Add100CoinsButton
@onready var _debug_add_1000_coins_button: Button = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel/Margin/Content/ResourceActions/Add1000CoinsButton
@onready var _debug_add_1_pack_button: Button = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel/Margin/Content/ResourceActions/Add1PackButton
@onready var _debug_add_5_packs_button: Button = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel/Margin/Content/ResourceActions/Add5PacksButton
@onready var _debug_fast_forward_1_hour_button: Button = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel/Margin/Content/TimeActions/FastForward1HourButton
@onready var _debug_fast_forward_8_hours_button: Button = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel/Margin/Content/TimeActions/FastForward8HoursButton
@onready var _debug_random_duplicate_card_button: Button = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel/Margin/Content/TimeActions/RandomDuplicateCardButton
@onready var _debug_save_button: Button = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel/Margin/Content/Actions/SaveButton
@onready var _debug_load_button: Button = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel/Margin/Content/Actions/LoadButton
@onready var _debug_reset_button: Button = $RootMargin/Layout/PagePanel/PageMargin/PageStack/DebugPanel/Margin/Content/Actions/ResetButton
@onready var _footer_label: Label = $FooterLabel
@onready var _tutorial_overlay: ColorRect = $TutorialOverlay
@onready var _tutorial_panel: PanelContainer = $TutorialOverlay/Center/TutorialPanel
@onready var _tutorial_step_label: Label = $TutorialOverlay/Center/TutorialPanel/Margin/Content/TutorialStepLabel
@onready var _tutorial_progress_label: Label = $TutorialOverlay/Center/TutorialPanel/Margin/Content/TutorialProgressLabel
@onready var _tutorial_next_button: Button = $TutorialOverlay/Center/TutorialPanel/Margin/Content/TutorialNextButton
@onready var _loading_overlay: ColorRect = $LoadingOverlay
@onready var _loading_panel: PanelContainer = $LoadingOverlay/Center/LoadingPanel


func _ready() -> void:
	_debug_rng.randomize()
	theme = MAIN_THEME
	_cache_navigation_nodes()
	_apply_dark_theme()
	_connect_navigation()
	_connect_debug_actions()
	_connect_dashboard_actions()
	_connect_tutorial_actions()
	_populate_collection_filter_options()
	_connect_collection_actions()
	_populate_inventory_sort_options()
	_connect_inventory_actions()
	_connect_stall_actions()
	_populate_market_filter_options()
	_connect_market_actions()
	_start_idle_reward_refresh_timer()
	GameState.state_changed.connect(_refresh_state_panels)
	_refresh_state_panels()
	show_page("dashboard")
	call_deferred("_complete_startup_screen")


func _complete_startup_screen() -> void:
	await get_tree().process_frame
	_loading_overlay.visible = false
	_maybe_show_tutorial()


func show_page(page_id: String) -> void:
	if not _panels.has(page_id):
		push_warning("Unknown page requested: %s" % page_id)
		return

	for key in _panels.keys():
		var panel := _panels[key] as Control
		panel.visible = key == page_id

	for key in _buttons.keys():
		var button := _buttons[key] as Button
		button.set_pressed_no_signal(key == page_id)

	if page_id == "debug":
		_refresh_debug_panel()
	elif page_id == "packs":
		_refresh_pack_panel()
	elif page_id == "collection":
		_refresh_collection_panel()
	elif page_id == "inventory":
		_refresh_inventory_panel()
	elif page_id == "stall":
		_refresh_stall_panel()
	elif page_id == "market":
		_refresh_market_panel()


func _cache_navigation_nodes() -> void:
	for config_data in PAGE_CONFIG:
		var config := config_data as Dictionary
		var page_id := String(config["id"])
		_buttons[page_id] = get_node(String(config["button_path"])) as Button
		_panels[page_id] = get_node(String(config["panel_path"])) as Control


func _connect_navigation() -> void:
	for page_id in _buttons.keys():
		var button := _buttons[page_id] as Button
		button.pressed.connect(_on_navigation_button_pressed.bind(page_id))


func _on_navigation_button_pressed(page_id: String) -> void:
	show_page(page_id)


func _connect_debug_actions() -> void:
	_debug_add_100_coins_button.pressed.connect(_on_debug_add_coins_pressed.bind(100))
	_debug_add_1000_coins_button.pressed.connect(_on_debug_add_coins_pressed.bind(1000))
	_debug_add_1_pack_button.pressed.connect(_on_debug_add_basic_pack_pressed.bind(1))
	_debug_add_5_packs_button.pressed.connect(_on_debug_add_basic_pack_pressed.bind(5))
	_debug_fast_forward_1_hour_button.pressed.connect(_on_debug_fast_forward_pressed.bind(3600))
	_debug_fast_forward_8_hours_button.pressed.connect(_on_debug_fast_forward_pressed.bind(8 * 3600))
	_debug_random_duplicate_card_button.pressed.connect(_on_debug_random_duplicate_card_pressed)
	_debug_save_button.pressed.connect(_on_save_button_pressed)
	_debug_load_button.pressed.connect(_on_load_button_pressed)
	_debug_reset_button.pressed.connect(_on_reset_button_pressed)


func _connect_dashboard_actions() -> void:
	_claim_idle_button.pressed.connect(_on_claim_idle_button_pressed)


func _connect_tutorial_actions() -> void:
	_tutorial_next_button.pressed.connect(_on_tutorial_next_pressed)


func _connect_collection_actions() -> void:
	_collection_filter_option.item_selected.connect(_on_collection_filter_selected)


func _connect_inventory_actions() -> void:
	_inventory_sort_option.item_selected.connect(_on_inventory_sort_selected)


func _connect_stall_actions() -> void:
	_simulate_visitors_button.pressed.connect(_on_simulate_visitors_pressed)


func _connect_market_actions() -> void:
	_market_search_input.text_changed.connect(_on_market_filter_changed)
	_market_uncollected_only.toggled.connect(_on_market_toggle_changed)
	_market_refresh_button.pressed.connect(_on_refresh_market_pressed)
	_market_series_filter.item_selected.connect(_on_market_option_changed)
	_market_rarity_filter.item_selected.connect(_on_market_option_changed)
	_market_max_price_spin.value_changed.connect(_on_market_price_changed)
	_market_sort_option.item_selected.connect(_on_market_option_changed)


func _populate_market_filter_options() -> void:
	_market_series_filter.clear()
	_market_series_filter.add_item("全部系列")
	var series_options: Array[String] = []
	for card_data in CardDatabase.get_all_cards():
		var card: Dictionary = card_data as Dictionary
		var series: String = String(card.get("series", ""))
		if not series.is_empty() and not series_options.has(series):
			series_options.append(series)
	series_options.sort()
	for series in series_options:
		_market_series_filter.add_item(series)

	_market_rarity_filter.clear()
	_market_rarity_filter.add_item("全部稀有度")
	for rarity in ["N", "R", "SR", "SSR", "UR"]:
		_market_rarity_filter.add_item(rarity)

	_market_sort_option.clear()
	_market_sort_option.add_item("最低价格")
	_market_sort_option.add_item("稀有度")
	_market_sort_option.add_item("未收集优先")


func _populate_collection_filter_options() -> void:
	_collection_filter_option.clear()
	for filter_label in ["全部", "基础系列", "森林系列", "机械系列", "N", "R", "SR", "SSR", "UR"]:
		_collection_filter_option.add_item(filter_label)


func _populate_inventory_sort_options() -> void:
	_inventory_sort_option.clear()
	for sort_label in ["稀有度", "拥有数量", "基础价格", "名称"]:
		_inventory_sort_option.add_item(sort_label)


func _start_idle_reward_refresh_timer() -> void:
	_idle_reward_refresh_timer = Timer.new()
	_idle_reward_refresh_timer.wait_time = 5.0
	_idle_reward_refresh_timer.autostart = true
	_idle_reward_refresh_timer.timeout.connect(_refresh_dashboard_panel)
	add_child(_idle_reward_refresh_timer)


func _on_claim_idle_button_pressed() -> void:
	var rewards: Dictionary = EconomyService.claim_idle_rewards()
	var claimable_intervals: int = int(rewards.get("claimable_intervals", 0))
	if claimable_intervals <= 0:
		_claim_idle_status_label.text = "暂无可领取奖励。"
	else:
		var packs: Dictionary = rewards.get("packs", {}) as Dictionary
		_claim_idle_status_label.text = "领取成功：%s，金币 +%d。" % [
			_format_pack_rewards(packs),
			int(rewards.get("coins", 0)),
		]

	_refresh_state_panels()


func _on_save_button_pressed() -> void:
	var success: bool = SaveService.save_game()
	_debug_status_label.text = "保存成功。" if success else "保存失败，请查看输出面板。"
	_refresh_debug_panel()


func _on_load_button_pressed() -> void:
	var success: bool = SaveService.load_game()
	_debug_status_label.text = "读取成功。" if success else "没有可用存档，已创建新玩家状态。"
	_refresh_debug_panel()


func _on_reset_button_pressed() -> void:
	SaveService.reset_save()
	_debug_status_label.text = "存档已重置。"
	_refresh_debug_panel()


func _on_debug_add_coins_pressed(amount: int) -> void:
	GameState.add_coins(amount)
	_debug_status_label.text = "已增加 %d 金币。" % amount
	_refresh_state_panels()


func _on_debug_add_basic_pack_pressed(count: int) -> void:
	GameState.add_pack("basic_pack", count)
	_debug_status_label.text = "已增加 %d 个 basic_pack。" % count
	_refresh_state_panels()


func _on_debug_fast_forward_pressed(seconds: int) -> void:
	GameState.set_last_claim_time_unix(maxi(0, GameState.last_claim_time_unix - seconds))
	_debug_status_label.text = "已快进 %s，可回到仪表盘领取挂机奖励。" % _format_duration(seconds)
	_refresh_state_panels()


func _on_debug_random_duplicate_card_pressed() -> void:
	var cards: Array = CardDatabase.get_all_cards()
	if cards.is_empty():
		_debug_status_label.text = "没有可生成的卡牌数据。"
		return

	var card: Dictionary = cards[_debug_rng.randi_range(0, cards.size() - 1)] as Dictionary
	var card_id: String = String(card.get("id", ""))
	GameState.add_card(card_id, 2)
	_debug_status_label.text = "已生成随机重复卡：%s x2。" % String(card.get("name", card_id))
	_refresh_state_panels()


func _on_simulate_visitors_pressed() -> void:
	var result: Dictionary = MarketService.simulate_buyer_tick()
	var visitor_count: int = int(result.get("visitor_count", 0))
	var total_sales: int = int(result.get("total_sales", 0))
	if total_sales <= 0:
		_stall_status_label.text = "来了 %d 位 NPC 访客，没有成交。" % visitor_count
	else:
		_stall_status_label.text = "来了 %d 位 NPC 访客，成交 %d 张，净收入 %d 金币。" % [
			visitor_count,
			total_sales,
			int(result.get("total_net", 0)),
		]

	_refresh_state_panels()


func _on_refresh_market_pressed() -> void:
	MarketService.generate_mock_market_listings()
	_market_status_label.text = "已刷新模拟市场。"
	_refresh_market_panel()


func _on_market_filter_changed(_value: String) -> void:
	_refresh_market_panel()


func _on_market_toggle_changed(_value: bool) -> void:
	_refresh_market_panel()


func _on_market_option_changed(_index: int) -> void:
	_refresh_market_panel()


func _on_market_price_changed(_value: float) -> void:
	_refresh_market_panel()


func _on_collection_filter_selected(_index: int) -> void:
	_refresh_collection_panel()


func _on_inventory_sort_selected(_index: int) -> void:
	_refresh_inventory_panel()


func _refresh_state_panels() -> void:
	_refresh_dashboard_panel()
	_refresh_pack_panel()
	_refresh_collection_panel()
	_refresh_inventory_panel()
	_refresh_stall_panel()
	_refresh_market_panel()
	_refresh_debug_panel()


func _refresh_dashboard_panel() -> void:
	var rewards: Dictionary = EconomyService.get_pending_idle_rewards()
	var packs: Dictionary = rewards.get("packs", {}) as Dictionary
	var claimable_intervals: int = int(rewards.get("claimable_intervals", 0))
	_dashboard_stats_label.text = "当前金币：%d\n图鉴完成度：%.1f%%" % [
		GameState.coins,
		GameState.get_collection_completion() * 100.0,
	]
	_idle_time_label.text = "可领取挂机时间：%s" % _format_duration(int(rewards.get("elapsed_seconds", 0)))
	_idle_rewards_label.text = "可领取奖励：%s，金币 +%d" % [
		_format_pack_rewards(packs),
		int(rewards.get("coins", 0)),
	]
	_claim_idle_button.disabled = claimable_intervals <= 0
	_refresh_achievement_panel()


func _maybe_show_tutorial() -> void:
	if GameState.tutorial_seen:
		_tutorial_overlay.visible = false
		return

	_tutorial_step_index = 0
	_show_tutorial_step()
	_tutorial_overlay.visible = true


func _show_tutorial_step() -> void:
	var message_index: int = clampi(_tutorial_step_index, 0, TUTORIAL_MESSAGES.size() - 1)
	_tutorial_step_label.text = TUTORIAL_MESSAGES[message_index]
	_tutorial_progress_label.text = "%d / %d" % [message_index + 1, TUTORIAL_MESSAGES.size()]
	_tutorial_next_button.text = "开始摆摊" if message_index >= TUTORIAL_MESSAGES.size() - 1 else "下一步"


func _on_tutorial_next_pressed() -> void:
	if _tutorial_step_index >= TUTORIAL_MESSAGES.size() - 1:
		GameState.set_tutorial_seen(true)
		SaveService.save_game()
		_tutorial_overlay.visible = false
		return

	_tutorial_step_index += 1
	_show_tutorial_step()


func _refresh_achievement_panel() -> void:
	_achievement_hint_label.text = _get_next_achievement_hint()
	_clear_children(_achievement_list)

	for achievement_data in ACHIEVEMENTS:
		var achievement: Dictionary = achievement_data as Dictionary
		_render_achievement_row(achievement)


func _render_achievement_row(achievement: Dictionary) -> void:
	var achievement_id: String = String(achievement.get("id", ""))
	var completed: bool = _is_achievement_completed(achievement_id)
	var claimed: bool = GameState.is_achievement_reward_claimed(achievement_id)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var info_label := Label.new()
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.text = "%s %s\n奖励：%s  状态：%s" % [
		"[完成]" if completed else "[待办]",
		String(achievement.get("title", achievement_id)),
		_format_achievement_reward(achievement),
		"已领取" if claimed else ("可领取" if completed else "未完成"),
	]

	var claim_button := Button.new()
	claim_button.text = "已领取" if claimed else ("领取奖励" if completed else "未完成")
	claim_button.disabled = claimed or not completed
	claim_button.pressed.connect(_on_claim_achievement_pressed.bind(achievement_id))
	_style_command_button(claim_button)

	row.add_child(info_label)
	row.add_child(claim_button)
	_achievement_list.add_child(row)
	_style_labels(row)


func _on_claim_achievement_pressed(achievement_id: String) -> void:
	var achievement: Dictionary = _get_achievement_config(achievement_id)
	if achievement.is_empty() or not _is_achievement_completed(achievement_id):
		return

	if not GameState.mark_achievement_reward_claimed(achievement_id):
		return

	var reward_type: String = String(achievement.get("reward_type", "coins"))
	var reward_amount: int = int(achievement.get("reward_amount", 0))
	if reward_type == "pack":
		GameState.add_pack("basic_pack", reward_amount)
	else:
		GameState.add_coins(reward_amount)

	SaveService.save_game()
	_claim_idle_status_label.text = "目标奖励已领取：%s。" % _format_achievement_reward(achievement)
	_refresh_state_panels()


func _get_achievement_config(achievement_id: String) -> Dictionary:
	for achievement_data in ACHIEVEMENTS:
		var achievement: Dictionary = achievement_data as Dictionary
		if String(achievement.get("id", "")) == achievement_id:
			return achievement

	return {}


func _is_achievement_completed(achievement_id: String) -> bool:
	if achievement_id == "collect_10_unique_cards":
		return GameState.get_seen_card_count() >= 10

	if achievement_id == "open_pack" and _sum_counts(GameState.owned_cards) > 0:
		return true

	if achievement_id == "list_card" and not GameState.stall_listings.is_empty():
		return true

	if achievement_id == "earn_sale_gold":
		return _has_transaction_type("npc_sale") or GameState.is_achievement_progress_marked(achievement_id)

	if achievement_id == "buy_market_card":
		return _has_transaction_type("mock_market_purchase") or GameState.is_achievement_progress_marked(achievement_id)

	if achievement_id == "simulate_visitors":
		return GameState.is_achievement_progress_marked(achievement_id) or _has_transaction_type("npc_sale")

	return GameState.is_achievement_progress_marked(achievement_id)


func _has_transaction_type(transaction_type: String) -> bool:
	for entry_data in GameState.transaction_log:
		var entry: Dictionary = entry_data as Dictionary
		if String(entry.get("type", "")) == transaction_type:
			return true

	return false


func _get_next_achievement_hint() -> String:
	for achievement_data in ACHIEVEMENTS:
		var achievement: Dictionary = achievement_data as Dictionary
		var achievement_id: String = String(achievement.get("id", ""))
		var completed: bool = _is_achievement_completed(achievement_id)
		var claimed: bool = GameState.is_achievement_reward_claimed(achievement_id)
		if completed and not claimed:
			return "下一步：领取目标奖励「%s」。" % String(achievement.get("title", achievement_id))
		if not completed:
			return String(achievement.get("hint", "下一步：继续推进卡牌摊位循环。"))

	return "新手目标已完成。可以继续补图鉴、调整摊位价格、刷新市场。"


func _format_achievement_reward(achievement: Dictionary) -> String:
	var reward_type: String = String(achievement.get("reward_type", "coins"))
	var reward_amount: int = int(achievement.get("reward_amount", 0))
	if reward_type == "pack":
		return "basic_pack x%d" % reward_amount

	return "%d 金币" % reward_amount


func _refresh_pack_panel() -> void:
	_pack_wallet_label.text = "当前金币：%d" % GameState.coins
	_clear_children(_pack_list)

	for pack_data in CardDatabase.get_all_packs():
		var pack: Dictionary = pack_data as Dictionary
		var pack_id: String = String(pack.get("id", ""))
		var pack_name: String = String(pack.get("name", pack_id))
		var price: int = int(pack.get("price", 0))
		var cards_per_pack: int = int(pack.get("cards_per_pack", 0))
		var owned_count: int = int(GameState.owned_packs.get(pack_id, 0))

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)

		var info_label := Label.new()
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_label.text = "%s\n拥有：%d  价格：%d 金币  每包：%d 张" % [
			pack_name,
			owned_count,
			price,
			cards_per_pack,
		]

		var open_button := Button.new()
		open_button.text = "打开 1 包"
		open_button.disabled = owned_count <= 0
		open_button.pressed.connect(_on_open_pack_pressed.bind(pack_id))
		_style_command_button(open_button)

		var buy_button := Button.new()
		buy_button.text = "购买 1 包"
		buy_button.disabled = GameState.coins < price
		buy_button.pressed.connect(_on_buy_pack_pressed.bind(pack_id))
		_style_command_button(buy_button)

		row.add_child(info_label)
		row.add_child(open_button)
		row.add_child(buy_button)
		_pack_list.add_child(row)
		_style_labels(row)


func _on_open_pack_pressed(pack_id: String) -> void:
	var opened_pack: Dictionary = EconomyService.open_pack(pack_id)
	if not bool(opened_pack.get("success", false)):
		_pack_status_label.text = String(opened_pack.get("reason", "开包失败。"))
		_refresh_state_panels()
		return

	var pack: Dictionary = CardDatabase.get_pack(pack_id)
	_pack_status_label.text = "已打开：%s。" % String(pack.get("name", pack_id))
	_render_open_results(opened_pack.get("results", []) as Array)
	_refresh_state_panels()


func _on_buy_pack_pressed(pack_id: String) -> void:
	var purchase: Dictionary = EconomyService.buy_pack(pack_id)
	if bool(purchase.get("success", false)):
		var pack: Dictionary = CardDatabase.get_pack(pack_id)
		_pack_status_label.text = "购买成功：%s，花费 %d 金币。" % [
			String(pack.get("name", pack_id)),
			int(purchase.get("price", 0)),
		]
	else:
		_pack_status_label.text = String(purchase.get("reason", "购买失败。"))

	_refresh_state_panels()


func _render_open_results(results: Array) -> void:
	_clear_children(_pack_results_list)
	if results.is_empty():
		var empty_label := Label.new()
		empty_label.text = "暂无开包结果。"
		_pack_results_list.add_child(empty_label)
		_style_labels(empty_label)
		return

	for result_data in results:
		var result: Dictionary = result_data as Dictionary
		var rarity: String = String(result.get("rarity", "N"))
		var new_text: String = "  NEW" if bool(result.get("was_new", false)) else ""
		var result_label := Label.new()
		result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result_label.text = "[%s] %s | 系列：%s | 基础价：%d | 当前拥有：%d%s" % [
			rarity,
			String(result.get("name", "未知卡牌")),
			String(result.get("series", "未知系列")),
			int(result.get("base_price", 0)),
			int(result.get("owned_count", 0)),
			new_text,
		]
		_pack_results_list.add_child(result_label)
		_style_labels(result_label)


func _refresh_collection_panel() -> void:
	var all_card_count: int = CardDatabase.get_total_cards()
	var filtered_cards: Array = _get_filtered_collection_cards()
	var filter_text: String = _get_selected_option_text(_collection_filter_option)
	if filter_text.is_empty():
		filter_text = "全部"

	_collection_summary_label.text = "图鉴完成度：%.1f%%  已收集：%d/%d  当前筛选：%s（%d 张）" % [
		GameState.get_collection_completion() * 100.0,
		GameState.get_seen_card_count(),
		all_card_count,
		filter_text,
		filtered_cards.size(),
	]

	_clear_children(_collection_list)
	if filtered_cards.is_empty():
		var empty_label := Label.new()
		empty_label.text = "没有符合筛选条件的卡牌。"
		_collection_list.add_child(empty_label)
		_style_labels(empty_label)
		return

	for card_data in filtered_cards:
		var card: Dictionary = card_data as Dictionary
		_render_collection_card(card)


func _get_filtered_collection_cards() -> Array:
	var selected_filter: String = _get_selected_option_text(_collection_filter_option)
	var rarity_filters: Array[String] = ["N", "R", "SR", "SSR", "UR"]
	var cards: Array = []

	for card_data in CardDatabase.get_all_cards():
		var card: Dictionary = card_data as Dictionary
		if selected_filter != "全部" and not selected_filter.is_empty():
			if rarity_filters.has(selected_filter):
				if String(card.get("rarity", "")) != selected_filter:
					continue
			elif String(card.get("series", "")) != selected_filter:
				continue

		cards.append(card)

	cards.sort_custom(_sort_collection_cards)
	return cards


func _sort_collection_cards(a: Dictionary, b: Dictionary) -> bool:
	var series_a: int = _series_rank(String(a.get("series", "")))
	var series_b: int = _series_rank(String(b.get("series", "")))
	if series_a == series_b:
		var number_a: String = String(a.get("collector_number", ""))
		var number_b: String = String(b.get("collector_number", ""))
		if number_a == number_b:
			return String(a.get("id", "")) < String(b.get("id", ""))
		return number_a < number_b

	return series_a < series_b


func _render_collection_card(card: Dictionary) -> void:
	var card_id: String = String(card.get("id", ""))
	var is_collected: bool = bool(GameState.collection_seen.get(card_id, false))
	var row := Label.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if is_collected:
		row.text = "[%s] %s | 系列：%s | 元素：%s | 拥有：%d | 编号：%s" % [
			String(card.get("rarity", "N")),
			String(card.get("name", card_id)),
			String(card.get("series", "未知系列")),
			String(card.get("element", "未知")),
			GameState.get_card_count(card_id),
			String(card.get("collector_number", "")),
		]
	else:
		row.text = "[%s] ？？？ | 系列：%s | 编号：%s" % [
			String(card.get("rarity", "N")),
			String(card.get("series", "未知系列")),
			String(card.get("collector_number", "")),
		]

	_collection_list.add_child(row)
	_style_labels(row)


func _refresh_inventory_panel() -> void:
	var sort_mode: String = _get_selected_option_text(_inventory_sort_option)
	if sort_mode.is_empty():
		sort_mode = "稀有度"

	_inventory_summary_label.text = "拥有卡牌种类：%d  总张数：%d  重复卡：%d  图鉴完成度：%.1f%%  空余摊位格：%d/%d" % [
		GameState.owned_cards.size(),
		_sum_counts(GameState.owned_cards),
		_sum_duplicate_card_counts(),
		GameState.get_collection_completion() * 100.0,
		MarketService.get_free_stall_slots(),
		MarketService.get_stall_slot_limit(),
	]
	_clear_children(_inventory_list)
	_render_inventory_listing_controls(
		_inventory_list,
		_inventory_status_label,
		sort_mode,
		"暂无已拥有卡牌。先去打开卡包或逛市场。"
	)


func _refresh_stall_panel() -> void:
	_stall_summary_label.text = "上架格子：%d/%d  空余：%d  当前上架总价值：%d 金币" % [
		MarketService.get_used_stall_slots(),
		MarketService.get_stall_slot_limit(),
		MarketService.get_free_stall_slots(),
		MarketService.get_total_listing_value(),
	]
	_clear_children(_stall_listing_list)
	_clear_children(_stall_inventory_list)
	_clear_children(_stall_transaction_list)
	_render_stall_listings()
	_render_inventory_listing_controls(_stall_inventory_list, _stall_status_label)
	_render_transaction_log()


func _render_inventory_listing_controls(
	parent: VBoxContainer,
	status_label: Label,
	sort_mode: String = "名称",
	empty_text: String = "暂无可上架卡牌。"
) -> void:
	var card_ids: Array = _get_owned_card_ids(sort_mode)
	if card_ids.is_empty():
		var empty_label := Label.new()
		empty_label.text = empty_text
		parent.add_child(empty_label)
		_style_labels(empty_label)
		return

	for card_id_value in card_ids:
		var card_id: String = String(card_id_value)
		var owned_count: int = GameState.get_card_count(card_id)
		if owned_count <= 0:
			continue

		var card: Dictionary = CardDatabase.get_card(card_id)
		if card.is_empty():
			continue

		var row := VBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 6)

		var info_label := Label.new()
		info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_label.text = "[%s] %s | 系列：%s | 拥有：%d | 基础价：%d | 重复：%d | 建议上架价：%d" % [
			String(card.get("rarity", "N")),
			String(card.get("name", card_id)),
			String(card.get("series", "未知系列")),
			owned_count,
			int(card.get("base_price", 0)),
			maxi(owned_count - 1, 0),
			MarketService.get_suggested_price(card_id),
		]

		var controls := HBoxContainer.new()
		controls.add_theme_constant_override("separation", 8)

		var quantity_label := Label.new()
		quantity_label.text = "数量"

		var quantity_spin := SpinBox.new()
		quantity_spin.min_value = 1.0
		quantity_spin.max_value = float(owned_count)
		quantity_spin.step = 1.0
		quantity_spin.value = 1.0
		quantity_spin.custom_minimum_size = Vector2(80, 34)

		var price_label := Label.new()
		price_label.text = "单价"

		var price_spin := SpinBox.new()
		price_spin.min_value = 1.0
		price_spin.max_value = 9999.0
		price_spin.step = 1.0
		price_spin.value = float(MarketService.get_suggested_price(card_id))
		price_spin.custom_minimum_size = Vector2(96, 34)

		var discount_button := Button.new()
		discount_button.text = "-10%"
		discount_button.pressed.connect(_on_adjust_price_pressed.bind(price_spin, 0.9))
		_style_command_button(discount_button)

		var premium_button := Button.new()
		premium_button.text = "+10%"
		premium_button.pressed.connect(_on_adjust_price_pressed.bind(price_spin, 1.1))
		_style_command_button(premium_button)

		var list_button := Button.new()
		list_button.text = "上架"
		list_button.disabled = MarketService.get_free_stall_slots() <= 0
		list_button.pressed.connect(_on_create_listing_pressed.bind(card_id, quantity_spin, price_spin, status_label))
		_style_command_button(list_button)

		controls.add_child(quantity_label)
		controls.add_child(quantity_spin)
		controls.add_child(price_label)
		controls.add_child(price_spin)
		controls.add_child(discount_button)
		controls.add_child(premium_button)
		controls.add_child(list_button)

		row.add_child(info_label)
		row.add_child(controls)
		parent.add_child(row)
		_style_labels(row)


func _get_owned_card_ids(sort_mode: String) -> Array:
	var card_ids: Array = []
	for card_id_value in GameState.owned_cards.keys():
		var card_id: String = String(card_id_value)
		if GameState.get_card_count(card_id) > 0:
			card_ids.append(card_id)

	if sort_mode == "稀有度":
		card_ids.sort_custom(_sort_inventory_by_rarity)
	elif sort_mode == "拥有数量":
		card_ids.sort_custom(_sort_inventory_by_count)
	elif sort_mode == "基础价格":
		card_ids.sort_custom(_sort_inventory_by_base_price)
	else:
		card_ids.sort_custom(_sort_inventory_by_name)

	return card_ids


func _sort_inventory_by_rarity(a: Variant, b: Variant) -> bool:
	var card_a: Dictionary = CardDatabase.get_card(String(a))
	var card_b: Dictionary = CardDatabase.get_card(String(b))
	var rarity_a: int = _rarity_rank(String(card_a.get("rarity", "")))
	var rarity_b: int = _rarity_rank(String(card_b.get("rarity", "")))
	if rarity_a == rarity_b:
		return _card_name_for_sort(String(a)) < _card_name_for_sort(String(b))

	return rarity_a > rarity_b


func _sort_inventory_by_count(a: Variant, b: Variant) -> bool:
	var count_a: int = GameState.get_card_count(String(a))
	var count_b: int = GameState.get_card_count(String(b))
	if count_a == count_b:
		return _card_name_for_sort(String(a)) < _card_name_for_sort(String(b))

	return count_a > count_b


func _sort_inventory_by_base_price(a: Variant, b: Variant) -> bool:
	var card_a: Dictionary = CardDatabase.get_card(String(a))
	var card_b: Dictionary = CardDatabase.get_card(String(b))
	var price_a: int = int(card_a.get("base_price", 0))
	var price_b: int = int(card_b.get("base_price", 0))
	if price_a == price_b:
		return _card_name_for_sort(String(a)) < _card_name_for_sort(String(b))

	return price_a > price_b


func _sort_inventory_by_name(a: Variant, b: Variant) -> bool:
	return _card_name_for_sort(String(a)) < _card_name_for_sort(String(b))


func _card_name_for_sort(card_id: String) -> String:
	var card: Dictionary = CardDatabase.get_card(card_id)
	return String(card.get("name", card_id))


func _render_stall_listings() -> void:
	if GameState.stall_listings.is_empty():
		var empty_label := Label.new()
		empty_label.text = "当前没有上架卡牌。"
		_stall_listing_list.add_child(empty_label)
		_style_labels(empty_label)
		return

	for listing_data in GameState.stall_listings:
		var listing: Dictionary = listing_data as Dictionary
		var card_id: String = String(listing.get("card_id", ""))
		var card: Dictionary = CardDatabase.get_card(card_id)
		var quantity: int = int(listing.get("quantity", 0))
		var price_each: int = int(listing.get("price_each", 0))

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)

		var info_label := Label.new()
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_label.text = "[%s] %s | 数量：%d | 单价：%d | 小计：%d" % [
			String(card.get("rarity", "N")),
			String(card.get("name", card_id)),
			quantity,
			price_each,
			quantity * price_each,
		]

		var cancel_button := Button.new()
		cancel_button.text = "取消上架"
		cancel_button.pressed.connect(_on_cancel_listing_pressed.bind(String(listing.get("listing_id", ""))))
		_style_command_button(cancel_button)

		row.add_child(info_label)
		row.add_child(cancel_button)
		_stall_listing_list.add_child(row)
		_style_labels(row)


func _render_transaction_log() -> void:
	if GameState.transaction_log.is_empty():
		var empty_label := Label.new()
		empty_label.text = "暂无交易记录。"
		_stall_transaction_list.add_child(empty_label)
		_style_labels(empty_label)
		return

	var shown_count: int = mini(5, GameState.transaction_log.size())
	for index in range(shown_count):
		var entry: Dictionary = GameState.transaction_log[index] as Dictionary
		var entry_label := Label.new()
		entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entry_label.text = _format_transaction_entry(entry)
		_stall_transaction_list.add_child(entry_label)
		_style_labels(entry_label)


func _refresh_market_panel() -> void:
	var listings: Array[Dictionary] = _get_filtered_market_listings()
	_sort_market_listings(listings)
	_market_summary_label.text = "当前金币：%d  模拟上架：%d  筛选结果：%d" % [
		GameState.coins,
		MarketService.get_mock_market_listings().size(),
		listings.size(),
	]
	_clear_children(_market_listing_list)

	if listings.is_empty():
		var empty_label := Label.new()
		empty_label.text = "没有符合条件的模拟上架。"
		_market_listing_list.add_child(empty_label)
		_style_labels(empty_label)
		return

	for listing in listings:
		_render_market_listing(listing)


func _get_filtered_market_listings() -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	var search_text: String = _market_search_input.text.strip_edges().to_lower()
	var selected_series: String = _get_selected_option_text(_market_series_filter)
	var selected_rarity: String = _get_selected_option_text(_market_rarity_filter)
	var max_price: int = int(_market_max_price_spin.value)

	for listing_data in MarketService.get_mock_market_listings():
		var listing: Dictionary = listing_data as Dictionary
		var card: Dictionary = CardDatabase.get_card(String(listing.get("card_id", "")))
		if card.is_empty():
			continue

		var card_name: String = String(card.get("name", ""))
		if not search_text.is_empty() and card_name.to_lower().find(search_text) < 0:
			continue

		if _market_uncollected_only.button_pressed and bool(GameState.collection_seen.get(String(card.get("id", "")), false)):
			continue

		if selected_series != "全部系列" and String(card.get("series", "")) != selected_series:
			continue

		if selected_rarity != "全部稀有度" and String(card.get("rarity", "")) != selected_rarity:
			continue

		if max_price > 0 and int(listing.get("price_each", 0)) > max_price:
			continue

		filtered.append(listing)

	return filtered


func _sort_market_listings(listings: Array[Dictionary]) -> void:
	var sort_mode: String = _get_selected_option_text(_market_sort_option)
	if sort_mode == "稀有度":
		listings.sort_custom(_sort_market_by_rarity)
	elif sort_mode == "未收集优先":
		listings.sort_custom(_sort_market_by_uncollected)
	else:
		listings.sort_custom(_sort_market_by_price)


func _sort_market_by_price(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("price_each", 0)) < int(b.get("price_each", 0))


func _sort_market_by_rarity(a: Dictionary, b: Dictionary) -> bool:
	var card_a: Dictionary = CardDatabase.get_card(String(a.get("card_id", "")))
	var card_b: Dictionary = CardDatabase.get_card(String(b.get("card_id", "")))
	var rarity_a: int = _rarity_rank(String(card_a.get("rarity", "")))
	var rarity_b: int = _rarity_rank(String(card_b.get("rarity", "")))
	if rarity_a == rarity_b:
		return int(a.get("price_each", 0)) < int(b.get("price_each", 0))
	return rarity_a > rarity_b


func _sort_market_by_uncollected(a: Dictionary, b: Dictionary) -> bool:
	var card_a: Dictionary = CardDatabase.get_card(String(a.get("card_id", "")))
	var card_b: Dictionary = CardDatabase.get_card(String(b.get("card_id", "")))
	var a_seen: bool = bool(GameState.collection_seen.get(String(card_a.get("id", "")), false))
	var b_seen: bool = bool(GameState.collection_seen.get(String(card_b.get("id", "")), false))
	if a_seen == b_seen:
		return int(a.get("price_each", 0)) < int(b.get("price_each", 0))
	return not a_seen and b_seen


func _render_market_listing(listing: Dictionary) -> void:
	var card_id: String = String(listing.get("card_id", ""))
	var card: Dictionary = CardDatabase.get_card(card_id)
	if card.is_empty():
		return

	var is_new: bool = not bool(GameState.collection_seen.get(card_id, false))
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var info_label := Label.new()
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.text = "%s[%s] %s | 系列：%s | 卖家：%s | 数量：%d | 价格：%d | 基础价：%d | 倍率：%.2f" % [
		"NEW " if is_new else "",
		String(card.get("rarity", "")),
		String(card.get("name", card_id)),
		String(card.get("series", "")),
		String(listing.get("seller_name", "模拟摊主")),
		int(listing.get("quantity", 0)),
		int(listing.get("price_each", 0)),
		int(card.get("base_price", 0)),
		float(listing.get("price_multiplier", 1.0)),
	]

	var buy_button := Button.new()
	buy_button.text = "购买"
	buy_button.disabled = GameState.coins < int(listing.get("price_each", 0))
	buy_button.pressed.connect(_on_buy_mock_listing_pressed.bind(String(listing.get("mock_listing_id", ""))))
	_style_command_button(buy_button)

	row.add_child(info_label)
	row.add_child(buy_button)
	_market_listing_list.add_child(row)
	_style_labels(row)


func _on_buy_mock_listing_pressed(mock_listing_id: String) -> void:
	var result: Dictionary = MarketService.purchase_mock_listing(mock_listing_id)
	if bool(result.get("success", false)):
		var card: Dictionary = result.get("card", {}) as Dictionary
		_market_status_label.text = "购买成功：%s，花费 %d 金币%s。" % [
			String(card.get("name", "未知卡牌")),
			int(result.get("price_each", 0)),
			" NEW" if bool(result.get("was_new", false)) else "",
		]
	else:
		_market_status_label.text = String(result.get("reason", "购买失败。"))

	_refresh_state_panels()


func _on_adjust_price_pressed(price_spin: SpinBox, multiplier: float) -> void:
	var adjusted: int = maxi(1, roundi(float(price_spin.value) * multiplier))
	price_spin.value = float(adjusted)


func _on_create_listing_pressed(card_id: String, quantity_spin: SpinBox, price_spin: SpinBox, status_label: Label) -> void:
	var result: Dictionary = MarketService.create_listing(card_id, int(quantity_spin.value), int(price_spin.value))
	if bool(result.get("success", false)):
		var card: Dictionary = CardDatabase.get_card(card_id)
		status_label.text = "上架成功：%s。" % String(card.get("name", card_id))
	else:
		status_label.text = String(result.get("reason", "上架失败。"))

	_refresh_state_panels()


func _on_cancel_listing_pressed(listing_id: String) -> void:
	var result: Dictionary = MarketService.cancel_listing(listing_id)
	if bool(result.get("success", false)):
		_stall_status_label.text = "已取消上架，卡牌已返回库存。"
	else:
		_stall_status_label.text = String(result.get("reason", "取消失败。"))

	_refresh_state_panels()


func _format_transaction_entry(entry: Dictionary) -> String:
	if String(entry.get("type", "")) == "npc_sale":
		return "%s 购买 %s：成交价 %d，税费 %d，净收入 %d" % [
			String(entry.get("buyer_type", "NPC 买家")),
			String(entry.get("card_name", "未知卡牌")),
			int(entry.get("price_each", 0)),
			int(entry.get("tax", 0)),
			int(entry.get("net_income", 0)),
		]

	if String(entry.get("type", "")) == "mock_market_purchase":
		return "从 %s 购买 %s：价格 %d%s" % [
			String(entry.get("seller_name", "模拟摊主")),
			String(entry.get("card_name", "未知卡牌")),
			int(entry.get("price_each", 0)),
			" NEW" if bool(entry.get("was_new", false)) else "",
		]

	return JSON.stringify(entry)


func _get_selected_option_text(option_button: OptionButton) -> String:
	var selected_index: int = option_button.selected
	if selected_index < 0:
		return ""
	return option_button.get_item_text(selected_index)


func _rarity_rank(rarity: String) -> int:
	var order: Array[String] = ["N", "R", "SR", "SSR", "UR"]
	return order.find(rarity)


func _series_rank(series: String) -> int:
	var order: Array[String] = ["基础系列", "森林系列", "机械系列"]
	var index: int = order.find(series)
	return index if index >= 0 else order.size()


func _refresh_debug_panel() -> void:
	var card_count: int = CardDatabase.get_total_cards()
	var pack_count: int = CardDatabase.get_total_packs()
	var owned_card_total: int = _sum_counts(GameState.owned_cards)
	var owned_pack_total: int = _sum_counts(GameState.owned_packs)
	var seen_unique_count: int = _count_seen_cards()
	var recent_transactions: String = _format_recent_transactions(5)
	_debug_stats_label.text = "数据库卡牌：%d\n数据库卡包：%d" % [card_count, pack_count]
	_debug_state_label.text = (
		"当前金币：%d\n拥有卡牌总数：%d\n已收集唯一卡牌数：%d\n图鉴完成度：%.1f%%\n拥有卡包数量：%d\n摊位上架数量：%d\n摊位总价值：%d\n最近交易记录：\n%s"
		% [
			GameState.coins,
			owned_card_total,
			seen_unique_count,
			GameState.get_collection_completion() * 100.0,
			owned_pack_total,
			GameState.stall_listings.size(),
			MarketService.get_total_listing_value(),
			recent_transactions,
		]
	)


func _sum_counts(counts: Dictionary) -> int:
	var total: int = 0
	for key in counts.keys():
		total += int(counts.get(key, 0))

	return total


func _sum_duplicate_card_counts() -> int:
	var total: int = 0
	for card_id in GameState.owned_cards.keys():
		total += maxi(GameState.get_card_count(String(card_id)) - 1, 0)

	return total


func _count_seen_cards() -> int:
	var seen_count: int = 0
	for card_id in GameState.collection_seen.keys():
		if bool(GameState.collection_seen.get(card_id, false)):
			seen_count += 1

	return seen_count


func _format_recent_transactions(limit: int) -> String:
	if GameState.transaction_log.is_empty():
		return "暂无交易记录"

	var lines: Array[String] = []
	var shown_count: int = mini(limit, GameState.transaction_log.size())
	for index in range(shown_count):
		var entry: Dictionary = GameState.transaction_log[index] as Dictionary
		lines.append("- %s" % _format_transaction_entry(entry))

	return "\n".join(lines)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _format_duration(total_seconds: int) -> String:
	var safe_seconds: int = maxi(0, total_seconds)
	var hours: int = floori(float(safe_seconds) / 3600.0)
	var minutes: int = floori(float(safe_seconds % 3600) / 60.0)
	var seconds: int = safe_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]


func _format_pack_rewards(packs: Dictionary) -> String:
	if packs.is_empty():
		return "卡包 0"

	var parts: Array[String] = []
	for pack_id in packs.keys():
		parts.append("%s x%d" % [String(pack_id), int(packs.get(pack_id, 0))])

	return "，".join(parts)


func _apply_dark_theme() -> void:
	var navigation_panel := $RootMargin/Layout/NavigationPanel as PanelContainer
	var page_panel := $RootMargin/Layout/PagePanel as PanelContainer
	_set_panel_style(navigation_panel, Color(0.09, 0.11, 0.14), Color(0.21, 0.25, 0.32))
	_set_panel_style(page_panel, Color(0.08, 0.095, 0.12), Color(0.21, 0.25, 0.32))
	_set_panel_style(_tutorial_panel, Color(0.10, 0.12, 0.16), Color(0.35, 0.43, 0.55))
	_set_panel_style(_loading_panel, Color(0.10, 0.12, 0.16), Color(0.35, 0.43, 0.55))
	_footer_label.add_theme_color_override("font_color", Color(0.68, 0.74, 0.82))

	for panel_data in _panels.values():
		var panel := panel_data as Control
		_set_panel_style(panel as PanelContainer, Color(0.11, 0.13, 0.17), Color(0.23, 0.28, 0.36))

	for button_data in _buttons.values():
		var button := button_data as Button
		_style_navigation_button(button)

	_style_command_button(_claim_idle_button)
	_style_command_button(_collection_filter_option)
	_style_command_button(_inventory_sort_option)
	_style_command_button(_simulate_visitors_button)
	_style_command_button(_market_refresh_button)
	_style_command_button(_debug_add_100_coins_button)
	_style_command_button(_debug_add_1000_coins_button)
	_style_command_button(_debug_add_1_pack_button)
	_style_command_button(_debug_add_5_packs_button)
	_style_command_button(_debug_fast_forward_1_hour_button)
	_style_command_button(_debug_fast_forward_8_hours_button)
	_style_command_button(_debug_random_duplicate_card_button)
	_style_command_button(_debug_save_button)
	_style_command_button(_debug_load_button)
	_style_command_button(_debug_reset_button)
	_style_command_button(_tutorial_next_button)
	_style_labels(self)


func _set_panel_style(panel: PanelContainer, background: Color, border: Color) -> void:
	panel.add_theme_stylebox_override("panel", _make_panel_style(background, border))


func _style_navigation_button(button: Button) -> void:
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(0, 38)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.13, 0.16, 0.21), Color(0.20, 0.24, 0.31)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.17, 0.20, 0.26), Color(0.30, 0.36, 0.45)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.24, 0.35, 0.52), Color(0.45, 0.62, 0.86)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))


func _style_command_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size = Vector2(96, 36)
	button.add_theme_stylebox_override("normal", _make_button_style(Color(0.15, 0.18, 0.22), Color(0.26, 0.31, 0.38)))
	button.add_theme_stylebox_override("hover", _make_button_style(Color(0.20, 0.24, 0.29), Color(0.36, 0.43, 0.52)))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.24, 0.35, 0.52), Color(0.45, 0.62, 0.86)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))


func _make_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _make_button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := _make_panel_style(background, border)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _style_labels(node: Node) -> void:
	if node is Label:
		var label := node as Label
		label.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0))

	for child in node.get_children():
		_style_labels(child)
