class_name MainMenu
extends Control

## Menu Chính của trò chơi (Main Menu Scene)
## - Giao diện mở đầu tiêu chuẩn đồ án tốt nghiệp với phong cách quân sự hiện đại.
## - Cho phép lựa chọn các chế độ: Chiến Dịch, Chọn Màn Chơi (1-10), Tùy Chỉnh Hỏa Lực, Phòng Tập Bắn, Hướng Dẫn.
## - Xử lý chuyển cảnh và âm lượng toàn cục.

@onready var campaign_btn: Button = $CenterContainer/VBoxContainer/ButtonGroup/CampaignButton
@onready var level_select_btn: Button = get_node_or_null("CenterContainer/VBoxContainer/ButtonGroup/LevelSelectButton") as Button
@onready var customization_btn: Button = get_node_or_null("CenterContainer/VBoxContainer/ButtonGroup/CustomizationButton") as Button
@onready var sandbox_btn: Button = $CenterContainer/VBoxContainer/ButtonGroup/SandboxButton
@onready var instructions_btn: Button = $CenterContainer/VBoxContainer/ButtonGroup/InstructionsButton
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/ButtonGroup/QuitButton

# Modal Hướng dẫn
@onready var instructions_modal: PanelContainer = $InstructionsModal
@onready var close_instructions_btn: Button = $InstructionsModal/VBoxContainer/CloseButton

# Modal Tùy chỉnh Vũ khí & Hỏa lực
@onready var customization_modal: PanelContainer = get_node_or_null("CustomizationModal") as PanelContainer
@onready var weapon_option: OptionButton = get_node_or_null("CustomizationModal/VBoxContainer/SelectorsRow/WeaponSection/WeaponOption") as OptionButton
@onready var secondary_weapon_option: OptionButton = get_node_or_null("CustomizationModal/VBoxContainer/SelectorsRow/SecondaryWeaponSection/SecondaryWeaponOption") as OptionButton
@onready var primary_details: RichTextLabel = get_node_or_null("CustomizationModal/VBoxContainer/CardsRow/PrimaryCard/PrimaryDetails") as RichTextLabel
@onready var secondary_details: RichTextLabel = get_node_or_null("CustomizationModal/VBoxContainer/CardsRow/SecondaryCard/SecondaryDetails") as RichTextLabel
@onready var save_customization_btn: Button = get_node_or_null("CustomizationModal/VBoxContainer/ActionRow/SaveButton") as Button
@onready var close_customization_btn: Button = get_node_or_null("CustomizationModal/VBoxContainer/ActionRow/CloseCustomizationButton") as Button

@onready var volume_slider: HSlider = $BottomBar/HBoxContainer/VolumeSlider
@onready var volume_label: Label = $BottomBar/HBoxContainer/VolumeLabel
@onready var fullscreen_btn: Button = $BottomBar/HBoxContainer/FullscreenButton

func _ready() -> void:
	# Luôn bảo đảm con trỏ chuột Windows hiển thị tự do trong Menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if instructions_modal:
		instructions_modal.visible = false
	if customization_modal:
		customization_modal.visible = false
		
	if campaign_btn:
		campaign_btn.pressed.connect(_on_campaign_pressed)
	if level_select_btn:
		level_select_btn.pressed.connect(_on_level_select_pressed)
	if customization_btn:
		customization_btn.pressed.connect(_on_customization_pressed)
	if sandbox_btn:
		sandbox_btn.pressed.connect(_on_sandbox_pressed)
	if instructions_btn:
		instructions_btn.pressed.connect(_on_instructions_pressed)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
	if close_instructions_btn:
		close_instructions_btn.pressed.connect(_on_close_instructions_pressed)

	_setup_customization_ui()
		
	if volume_slider:
		var master_vol_db := AudioServer.get_bus_volume_db(0)
		var master_linear := db_to_linear(master_vol_db)
		volume_slider.value = master_linear * 100.0
		if volume_label:
			volume_label.text = "%d%%" % int(volume_slider.value)
		volume_slider.value_changed.connect(_on_volume_changed)
		
	if fullscreen_btn:
		fullscreen_btn.pressed.connect(_on_toggle_fullscreen)

func _setup_customization_ui() -> void:
	if not customization_modal:
		return
		
	if weapon_option:
		weapon_option.clear()
		weapon_option.add_item("Pháo cối Parabola 2.5D (Nổ lan AoE, cầu vồng vượt tường)", 0)
		weapon_option.add_item("Song pháo Trực xạ AP (Bắn loạt 2 viên xuyên giáp sơ tốc cao)", 1)
		weapon_option.add_item("Rocket chùm Dẫn đường (Tự tìm diệt mục tiêu khi khóa ngắm)", 2)
		weapon_option.selected = clampi(GlobalEvents.default_weapon_mode, 0, 2)
		weapon_option.item_selected.connect(func(_idx: int): _update_customization_details())

	if secondary_weapon_option:
		secondary_weapon_option.clear()
		secondary_weapon_option.add_item("Súng Xuyên Giáp AP [Mặc định] (75 HP, Xuyên thấu đa mục tiêu)", 0)
		secondary_weapon_option.add_item("Súng Máy Liên Thanh (Tốc bắn tăng dần xé gió, cơ chế Quá nhiệt)", 1)
		secondary_weapon_option.add_item("Súng Shotgun Tán Xạ (Bắn chùm 6 mảnh đạn 12 HP x 6 = 72 HP cận chiến)", 2)
		secondary_weapon_option.selected = clampi(GlobalEvents.secondary_weapon_mode, 0, 2)
		secondary_weapon_option.item_selected.connect(func(_idx: int): _update_customization_details())
		
	if save_customization_btn:
		save_customization_btn.pressed.connect(_on_save_customization_pressed)
	if close_customization_btn:
		close_customization_btn.pressed.connect(_on_close_customization_pressed)
		
	_update_customization_details()

func _update_customization_details() -> void:
	var w_idx := weapon_option.selected if weapon_option else 0
	var sec_idx := secondary_weapon_option.selected if secondary_weapon_option else 0
	
	if primary_details:
		var p_text := ""
		match w_idx:
			1:
				p_text = "[color=#38bdf8][b]SONG PHÁO TRỰC XẠ AP[/b][/color]\n\n" + \
					"• [b]Sát thương:[/b] [color=#ffff55]25 HP x 2 = 50 HP[/color]\n" + \
					"• [b]Thời gian nạp:[/b] 1.4s (Nhanh)\n" + \
					"• [b]Sơ tốc đạn:[/b] 850 px/s (Trực xạ bắn thẳng)\n" + \
					"• [b]Ưu thế chiến thuật:[/b] Bắn loạt kép dồn sát thương cực tốt ở cự ly trung bình."
			2:
				p_text = "[color=#38bdf8][b]ROCKET CHÙM DẪN ĐƯỜNG[/b][/color]\n\n" + \
					"• [b]Sát thương:[/b] [color=#ffff55]35 HP x 3 = 105 HP[/color]\n" + \
					"• [b]Thời gian nạp:[/b] 3.0s | [b]Tầm bắn:[/b] 720 px\n" + \
					"• [b]Cơ chế:[/b] Cần rê chuột khóa mục tiêu 1.5s (hoặc khóa ngay khi bật Radar [F]).\n" + \
					"• [b]Ưu thế:[/b] Đạn tự uốn lượn tìm diệt mục tiêu từ khoảng cách an toàn."
			_:
				p_text = "[color=#38bdf8][b]PHÁO CỐI PARABOLA 2.5D (CHUẨN)[/b][/color]\n\n" + \
					"• [b]Sát thương:[/b] [color=#ffff55]50 HP (Nổ lan AoE 120 px)[/color]\n" + \
					"• [b]Thời gian nạp:[/b] 2.2s\n" + \
					"• [b]Quỹ đạo:[/b] Cầu vồng Parabola ném xiên 2.5D\n" + \
					"• [b]Ưu thế chiến thuật:[/b] Bắn cầu vồng vượt qua tường kiên cố, tiêu diệt cụm địch."
		primary_details.text = p_text
		
	if secondary_details:
		var s_text := ""
		match sec_idx:
			1:
				s_text = "[color=#4ade80][b]SÚNG MÁY LIÊN THANH[/b][/color]\n\n" + \
					"• [b]Sát thương:[/b] 8 HP/viên (Liên thanh)\n" + \
					"• [b]Tốc bắn:[/b] [color=#ffff55][b]TĂNG DẦN TỪ 0.16s -> 0.045s![/b][/color]\n" + \
					"• [b]Cơ chế Quá nhiệt:[/b] Giữ chuột càng lâu nòng súng quay càng nhanh. Đạt 100% nhiệt sẽ ngưng 2.8s để hạ nhiệt.\n" + \
					"• [b]Ưu thế:[/b] Sấy xé gió dập tắt xe địch cơ động."
			2:
				s_text = "[color=#4ade80][b]SÚNG SHOTGUN TÁN XẠ[/b][/color]\n\n" + \
					"• [b]Sát thương:[/b] 12 HP x 6 = [color=#ffff55][b]72 HP[/b][/color] (Cận chiến)\n" + \
					"• [b]Thời gian nạp:[/b] 0.82s\n" + \
					"• [b]Góc tán xạ:[/b] Chùm 6 mảnh đạn hình nón 18°\n" + \
					"• [b]Ưu thế:[/b] Hỏa lực hủy diệt áp đảo khi đối đầu ở cự ly gần."
			_:
				s_text = "[color=#4ade80][b]SÚNG XUYÊN GIÁP AP (MẶC ĐỊNH)[/b][/color]\n\n" + \
					"• [b]Sát thương:[/b] [color=#ffff55][b]75 HP[/b][/color] (Cực lớn!)\n" + \
					"• [b]Thời gian nạp:[/b] 0.70s | [b]Sơ tốc:[/b] 1350 px/s\n" + \
					"• [b]Tính năng độc quyền:[/b] [color=#ffaa33]Đục xuyên tối đa 3 mục tiêu & hòm gỗ![/color]\n" + \
					"• [b]Ưu thế:[/b] Xuyên thủng phòng tuyến và tiêu diệt địch nấp sau công sự."
		secondary_details.text = s_text

func _on_customization_pressed() -> void:
	if customization_modal:
		if instructions_modal and instructions_modal.visible:
			instructions_modal.visible = false
		customization_modal.visible = true
		customization_modal.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(customization_modal, "modulate:a", 1.0, 0.2)

func _on_close_customization_pressed() -> void:
	if customization_modal:
		var tween := create_tween()
		tween.tween_property(customization_modal, "modulate:a", 0.0, 0.15)
		tween.finished.connect(func(): customization_modal.visible = false)

func _on_save_customization_pressed() -> void:
	var w_idx := weapon_option.selected if weapon_option else 0
	var sec_idx := secondary_weapon_option.selected if secondary_weapon_option else 0
	GlobalEvents.save_weapon_customization(w_idx, sec_idx, 0)
	if save_customization_btn:
		var orig_text := save_customization_btn.text
		save_customization_btn.text = "ĐÃ LƯU THÀNH CÔNG!"
		get_tree().create_timer(1.2).timeout.connect(func():
			if is_instance_valid(save_customization_btn):
				save_customization_btn.text = orig_text
		)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			if customization_modal and customization_modal.visible:
				_on_close_customization_pressed()
			elif instructions_modal and instructions_modal.visible:
				_on_close_instructions_pressed()
			else:
				_on_quit_pressed()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			if customization_modal and customization_modal.visible:
				_on_close_customization_pressed()
			elif instructions_modal and instructions_modal.visible:
				_on_close_instructions_pressed()
			else:
				_on_campaign_pressed()

func _on_campaign_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/Level1.tscn")

func _on_level_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/LevelSelectMenu.tscn")

func _on_sandbox_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/Sandbox.tscn")

func _on_instructions_pressed() -> void:
	if instructions_modal:
		if customization_modal and customization_modal.visible:
			customization_modal.visible = false
		instructions_modal.visible = true
		instructions_modal.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(instructions_modal, "modulate:a", 1.0, 0.2)

func _on_close_instructions_pressed() -> void:
	if instructions_modal:
		var tween := create_tween()
		tween.tween_property(instructions_modal, "modulate:a", 0.0, 0.15)
		tween.finished.connect(func(): instructions_modal.visible = false)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_volume_changed(val: float) -> void:
	var linear_vol := val / 100.0
	if volume_label:
		volume_label.text = "%d%%" % int(val)
	if linear_vol <= 0.01:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, linear_to_db(linear_vol))

func _on_toggle_fullscreen() -> void:
	var current_mode := DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if fullscreen_btn:
			fullscreen_btn.text = "Toàn màn hình"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		if fullscreen_btn:
			fullscreen_btn.text = "Cửa sổ"
