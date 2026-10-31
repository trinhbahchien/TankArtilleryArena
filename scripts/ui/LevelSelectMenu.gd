class_name LevelSelectMenu
extends Control

## Màn hình Chọn Màn Chơi Tự Do (10 Màn Chơi Chiến Dịch)
## - Cho phép người chơi tự do xuất kích vào bất kỳ màn nào trong 10 màn.
## - Hiển thị Thời gian mục tiêu để đạt S-Rank, Kỷ lục điểm và Xếp hạng cao nhất đã đạt được.

@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var back_btn: Button = $MarginContainer/VBoxContainer/TopBar/BackButton
@onready var total_stars_lbl: Label = get_node_or_null("MarginContainer/VBoxContainer/TopBar/TotalStarsLabel") as Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
		
	_populate_levels()

func _populate_levels() -> void:
	if not grid_container:
		return
		
	# Xóa các node mẫu nếu có
	for child in grid_container.get_children():
		child.queue_free()

	var total_stars: int = ScoreManager.get_total_stars()
	if total_stars_lbl:
		if total_stars >= 50:
			total_stars_lbl.text = "TỔNG SAO: 50 / 50 [MAX CẤP TOÀN DIỆN!]"
			total_stars_lbl.modulate = Color(1.0, 0.9, 0.2)
		else:
			total_stars_lbl.text = "TỔNG SAO: %d / 50" % total_stars

	for lvl_num in range(1, 11):
		var info: Dictionary = ScoreManager.get_level_info(lvl_num)
		var card := _create_level_card(lvl_num, info)
		grid_container.add_child(card)

func _create_level_card(lvl_num: int, info: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(270, 222)
	
	var best_stars: int = int(info.get("best_stars", 0))
	var is_max: bool = (best_stars >= 5)
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.18, 0.94) if not is_max else Color(0.14, 0.12, 0.05, 0.95)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(1.0, 0.85, 0.25, 0.95) if is_max else Color(0.2, 0.55, 0.8, 0.85)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	sb.content_margin_left = 14
	sb.content_margin_top = 10
	sb.content_margin_right = 14
	sb.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# 1. Tiêu đề màn
	var title_lbl := Label.new()
	title_lbl.text = "MÀN %d: %s" % [lvl_num, info.get("title", "Chiến dịch")]
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35) if is_max else Color(0.35, 0.85, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title_lbl)

	# 2. Xếp hạng Sao (1-5 Sao)
	var stars_lbl := Label.new()
	if is_max:
		stars_lbl.text = "[5/5 SAO - MAX CẤP]"
		stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	elif best_stars > 0:
		stars_lbl.text = "[%d/5 SAO]" % best_stars
		stars_lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6))
	else:
		stars_lbl.text = "[0/5 SAO - Chưa đạt]"
		stars_lbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
	stars_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(stars_lbl)

	# 3. Kỷ lục & Hạng đã lưu
	var best_score: int = info.get("best_score", 0)
	var best_rank: String = info.get("best_rank", "--")
	var record_lbl := Label.new()
	if best_score > 0:
		record_lbl.text = "Kỷ lục: %d pt | Hạng [%s]" % [best_score, best_rank]
		record_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35) if is_max else Color(0.35, 1.0, 0.55))
	else:
		record_lbl.text = "Kỷ lục: Chưa lập"
		record_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	record_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(record_lbl)

	# 4. Mô tả ngắn
	var desc_lbl := Label.new()
	desc_lbl.text = info.get("desc", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(0, 44)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(desc_lbl)

	# 5. Nút Xuất Kích
	var play_btn := Button.new()
	play_btn.text = "XUẤT KÍCH NGAY"
	play_btn.custom_minimum_size = Vector2(0, 32)
	play_btn.add_theme_font_size_override("font_size", 12)
	
	var btn_sb := StyleBoxFlat.new()
	btn_sb.bg_color = Color(0.12, 0.38, 0.22, 0.9)
	btn_sb.border_width_left = 1
	btn_sb.border_width_top = 1
	btn_sb.border_width_right = 1
	btn_sb.border_width_bottom = 1
	btn_sb.border_color = Color(0.3, 0.9, 0.5, 0.95)
	btn_sb.corner_radius_top_left = 4
	btn_sb.corner_radius_top_right = 4
	btn_sb.corner_radius_bottom_right = 4
	btn_sb.corner_radius_bottom_left = 4
	play_btn.add_theme_stylebox_override("normal", btn_sb)
	
	var scene_path: String = info.get("scene", "res://scenes/levels/Level1.tscn")
	play_btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file(scene_path)
	)
	vbox.add_child(play_btn)

	return panel

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
