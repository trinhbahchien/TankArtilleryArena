class_name PauseMenu
extends CanvasLayer

## Menu Tạm Dừng trong trận đấu (ESC Pause Menu)
## - Hoạt động độc lập kể cả khi game bị đóng băng (process_mode = PROCESS_MODE_ALWAYS).
## - Tích hợp đầy đủ phím tắt (ESC, R), thanh chỉnh âm lượng SFX/BGM và thoát về Menu.
## - Khắc phục sai lệch click chuột với hitbox tolerance .grow(20.0).

@onready var background_dim: ColorRect = $Dimmer
@onready var menu_panel: PanelContainer = $CenterContainer/PanelContainer
@onready var resume_btn: Button = $CenterContainer/PanelContainer/VBoxContainer/ResumeButton
@onready var restart_btn: Button = $CenterContainer/PanelContainer/VBoxContainer/RestartButton
@onready var level_select_btn: Button = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/LevelSelectButton") as Button
@onready var menu_btn: Button = $CenterContainer/PanelContainer/VBoxContainer/MainMenuButton
@onready var volume_slider: HSlider = $CenterContainer/PanelContainer/VBoxContainer/AudioRow/VolumeSlider
@onready var volume_label: Label = $CenterContainer/PanelContainer/VBoxContainer/AudioRow/VolumeValueLabel

var is_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if resume_btn:
		resume_btn.pressed.connect(resume_game)
	if restart_btn:
		restart_btn.pressed.connect(restart_game)
	if level_select_btn:
		level_select_btn.pressed.connect(func():
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/ui/LevelSelectMenu.tscn")
		)
	if menu_btn:
		menu_btn.pressed.connect(quit_to_main_menu)
		
	if volume_slider:
		var master_vol_db := AudioServer.get_bus_volume_db(0)
		var master_linear := db_to_linear(master_vol_db)
		volume_slider.value = master_linear * 100.0
		if volume_label:
			volume_label.text = "%d%%" % int(volume_slider.value)
		volume_slider.value_changed.connect(_on_volume_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			# Không mở pause menu nếu đã thua hoặc thắng
			if _is_game_finished():
				return
			toggle_pause()
			get_viewport().set_input_as_handled()
		elif is_paused:
			if event.keycode == KEY_R:
				restart_game()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				resume_game()
				get_viewport().set_input_as_handled()
				
	# Hỗ trợ click chuột trực tiếp
	if is_paused and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var mb := event as InputEventMouseButton
		var click_pos: Vector2 = mb.position
		if _is_point_in_control(resume_btn, click_pos):
			resume_game()
		elif _is_point_in_control(restart_btn, click_pos):
			restart_game()
		elif _is_point_in_control(level_select_btn, click_pos):
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/ui/LevelSelectMenu.tscn")
		elif _is_point_in_control(menu_btn, click_pos):
			quit_to_main_menu()


func _is_point_in_control(ctrl: Control, screen_pos: Vector2) -> bool:
	if not ctrl or not ctrl.is_visible_in_tree():
		return false
	var global_rect := ctrl.get_global_rect().grow(20.0)
	return global_rect.has_point(screen_pos)

func _is_game_finished() -> bool:
	var root := get_tree().current_scene
	if root and "game_finished" in root:
		return root.game_finished
	return false

func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if menu_panel:
		menu_panel.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(menu_panel, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD)

func resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func quit_to_main_menu() -> void:
	get_tree().paused = false
	var menu_scene_path := "res://scenes/ui/MainMenu.tscn"
	if ResourceLoader.exists(menu_scene_path):
		get_tree().change_scene_to_file(menu_scene_path)
	else:
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
