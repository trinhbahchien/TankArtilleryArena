class_name VictoryScreen
extends CanvasLayer

## Màn hình CHIẾN THẮNG với thống kê trận đánh, chuyển màn tiếp theo hoặc chơi lại

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Title
@onready var subtitle_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Subtitle
@onready var stars_display_label: Label = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StarsDisplayLabel") as Label
@onready var stars_sub_label: Label = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StarsSubLabel") as Label
@onready var time_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TimeLabel
@onready var kills_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/KillsLabel
@onready var score_label: Label = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ScoreLabel") as Label
@onready var rank_label: Label = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RankLabel") as Label

@onready var next_level_btn: Button = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/NextLevelButton")
@onready var replay_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ReplayButton
@onready var level_select_btn: Button = get_node_or_null("CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/LevelSelectButton") as Button
@onready var quit_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/QuitButton

var next_level_scene: PackedScene = null
var is_action_taken: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_propagate_process_mode(self)
	# Đảm bảo hiển thị chuột thường chuẩn giao diện UI
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if next_level_btn:
		next_level_btn.pressed.connect(_on_next_level_pressed)
	if replay_btn:
		replay_btn.pressed.connect(_on_replay_pressed)
	if level_select_btn:
		level_select_btn.pressed.connect(_on_level_select_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)

func _input(event: InputEvent) -> void:
	if is_action_taken:
		return
		
	# 1. Phím tắt tiện lợi: Space/Enter ưu tiên qua màn tiếp theo (hoặc chơi lại); R để chơi lại; Esc về menu
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if next_level_scene != null and next_level_btn and next_level_btn.is_visible_in_tree():
				_on_next_level_pressed()
			else:
				_on_replay_pressed()
			return
		elif event.keycode == KEY_R:
			_on_replay_pressed()
			return
		elif event.keycode == KEY_ESCAPE:
			_on_quit_pressed()
			return

func _propagate_process_mode(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_propagate_process_mode(child)

func setup(time_seconds: float, enemies_killed: int, next_scene: PackedScene = null, is_campaign_complete: bool = false, score_data: Dictionary = {}) -> void:
	next_level_scene = next_scene
	
	var stars: int = int(score_data.get("stars", 1))
	if stars_display_label:
		if stars >= 5:
			stars_display_label.text = "[ 5 / 5 SAO - MAX CẤP ]"
			stars_display_label.modulate = Color(1.0, 0.9, 0.2)
		else:
			stars_display_label.text = "[ %d / 5 SAO ]" % stars
			if stars == 4:
				stars_display_label.modulate = Color(1.0, 0.75, 0.25)
			elif stars == 3:
				stars_display_label.modulate = Color(0.35, 1.0, 0.55)
			else:
				stars_display_label.modulate = Color(0.75, 0.85, 1.0)
			
	if stars_sub_label:
		if stars == 5:
			stars_sub_label.text = "ĐẠT 5/5 SAO - MAX CẤP CHIẾN THẦN!"
			stars_sub_label.modulate = Color(1.0, 0.85, 0.2)
		elif stars == 4:
			stars_sub_label.text = "ĐẠT 4/5 SAO - CHỈ HUY TINH NHUỆ!"
			stars_sub_label.modulate = Color(1.0, 0.75, 0.3)
		elif stars == 3:
			stars_sub_label.text = "ĐẠT 3/5 SAO - ĐẠI ĐỘI TRƯỞNG ƯU TÚ"
			stars_sub_label.modulate = Color(0.4, 0.9, 1.0)
		elif stars == 2:
			stars_sub_label.text = "ĐẠT 2/5 SAO - TAY SÚNG THỰC LỰC"
			stars_sub_label.modulate = Color(0.8, 0.85, 0.9)
		else:
			stars_sub_label.text = "ĐẠT 1/5 SAO - CHIẾN BINH NHẬP MÔN"
			stars_sub_label.modulate = Color(0.7, 0.75, 0.8)

	var mins := int(time_seconds) / 60
	var secs := int(time_seconds) % 60
	if time_label:
		var target_t: float = score_data.get("target_time", 60.0)
		var t_mins := int(target_t) / 60
		var t_secs := int(target_t) % 60
		var tb: int = score_data.get("time_bonus", 0)
		time_label.text = "Thời gian: %02d:%02d (Mục tiêu: %02d:%02d) | Thưởng tốc độ: +%d" % [mins, secs, t_mins, t_secs, tb]
		
	if kills_label:
		var hp_b: int = score_data.get("hp_bonus", 0)
		kills_label.text = "Diệt địch: %d xe | Bảo toàn giáp: +%d pt" % [enemies_killed, hp_b]
		
	if score_label:
		var tot_score: int = score_data.get("total_score", 0)
		var record_str := " [KỶ LỤC MỚI!]" if score_data.get("is_new_record", false) else ""
		score_label.text = "TỔNG ĐIỂM: %d PT%s" % [tot_score, record_str]
		
	if rank_label:
		var r: String = score_data.get("rank", "A")
		rank_label.text = "XẾP HẠNG CHIẾN THUẬT: [%s]" % r
		if r == "S":
			rank_label.modulate = Color(1.0, 0.85, 0.25)
		elif r == "A":
			rank_label.modulate = Color(0.35, 1.0, 0.5)
		elif r == "B":
			rank_label.modulate = Color(0.4, 0.85, 1.0)
		else:
			rank_label.modulate = Color(0.8, 0.85, 0.9)
		
	if is_campaign_complete:
		if title_label:
			title_label.text = "ĐẠI THẮNG TOÀN CHIẾN DỊCH (10 MÀN)!"
		if subtitle_label:
			subtitle_label.text = "Bạn đã tiêu diệt Siêu Pháo Hạm Mammoth và giải phóng toàn bộ 10 chiến trường!"
		if next_level_btn:
			next_level_btn.visible = false
	elif next_level_scene != null:
		if next_level_btn:
			next_level_btn.visible = true
	else:
		if next_level_btn:
			next_level_btn.visible = false

func _on_next_level_pressed() -> void:
	if is_action_taken or not next_level_scene:
		return
	is_action_taken = true
	get_tree().paused = false
	get_tree().change_scene_to_packed(next_level_scene)

func _on_replay_pressed() -> void:
	if is_action_taken:
		return
	is_action_taken = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_level_select_pressed() -> void:
	if is_action_taken:
		return
	is_action_taken = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/LevelSelectMenu.tscn")

func _on_quit_pressed() -> void:
	if is_action_taken:
		return
	is_action_taken = true
	get_tree().paused = false
	if ResourceLoader.exists("res://scenes/ui/MainMenu.tscn"):
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	else:
		get_tree().quit()
