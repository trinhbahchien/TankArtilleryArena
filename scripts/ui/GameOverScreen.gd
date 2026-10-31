class_name GameOverScreen
extends CanvasLayer

## Màn hình THẤT BẠI khi người chơi bị bắn hạ

@onready var retry_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/RetryButton
@onready var quit_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/QuitButton

var is_action_taken: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_propagate_process_mode(self)
	# Đảm bảo hiển thị chuột thường chuẩn giao diện UI
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if retry_btn:
		retry_btn.pressed.connect(_on_retry_pressed)
		retry_btn.button_down.connect(_on_retry_pressed)
		retry_btn.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				_on_retry_pressed()
		)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit_pressed)
		quit_btn.button_down.connect(_on_quit_pressed)
		quit_btn.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				_on_quit_pressed()
		)

func _input(event: InputEvent) -> void:
	if is_action_taken:
		return
		
	# 1. Phím tắt tiện lợi: R, Space, Enter để chơi lại; Esc để thoát
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_R or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_retry_pressed()
			return
		elif event.keycode == KEY_ESCAPE:
			_on_quit_pressed()
			return
			
	# 2. Xử lý click chuột đa tầng (hỗ trợ mọi kích thước cửa sổ, phóng to / DPI Scaling)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var mb := event as InputEventMouseButton
		var vp_pos := get_viewport().get_mouse_position()
		
		if retry_btn and retry_btn.is_visible_in_tree():
			var local_pos := retry_btn.get_local_mouse_position()
			var retry_rect := Rect2(Vector2.ZERO, retry_btn.size).grow(20.0)
			var retry_global := retry_btn.get_global_rect().grow(20.0)
			if retry_rect.has_point(local_pos) or retry_global.has_point(vp_pos) or retry_global.has_point(mb.position):
				_on_retry_pressed()
				return
				
		if quit_btn and quit_btn.is_visible_in_tree():
			var local_pos := quit_btn.get_local_mouse_position()
			var quit_rect := Rect2(Vector2.ZERO, quit_btn.size).grow(20.0)
			var quit_global := quit_btn.get_global_rect().grow(20.0)
			if quit_rect.has_point(local_pos) or quit_global.has_point(vp_pos) or quit_global.has_point(mb.position):
				_on_quit_pressed()
				return

func _propagate_process_mode(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_propagate_process_mode(child)

func _on_retry_pressed() -> void:
	if is_action_taken:
		return
	is_action_taken = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	if is_action_taken:
		return
	is_action_taken = true
	get_tree().paused = false
	if ResourceLoader.exists("res://scenes/ui/MainMenu.tscn"):
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	else:
		get_tree().quit()

