class_name MainLevel
extends Node2D

## Quản lý màn chơi, Camera, Vòng lặp thắng/thua (Game Loop), phân tách con trỏ UI/Game và cập nhật HUD

@export var victory_screen_scene: PackedScene = preload("res://scenes/ui/VictoryScreen.tscn")
@export var game_over_screen_scene: PackedScene = preload("res://scenes/ui/GameOverScreen.tscn")
@export var pause_menu_scene: PackedScene = preload("res://scenes/ui/PauseMenu.tscn")
@export var delta_force_hud_scene: PackedScene = preload("res://scenes/ui/DeltaForceHUD.tscn")
var delta_force_hud: DeltaForceHUD

@export_group("Level Configuration")
@export var level_number: int = 1
@export var level_title: String = "MÀN 1: NHẬP MÔN PHÁO BINH"
@export var next_level_scene: PackedScene = null
@export var is_final_level: bool = false
@export var is_sandbox: bool = false

@onready var player_tank: CharacterBody2D = $PlayerTank
@onready var turret_node: TurretAim = $PlayerTank/Turret
@onready var weapon_controller: WeaponController = $PlayerTank/WeaponController

@onready var hud_container: Control = get_node_or_null("HUD/MarginContainer") as Control
@onready var title_label: Label = get_node_or_null("HUD/MarginContainer/VBoxContainer/Title") as Label
@onready var enemy_count_label: Label = get_node_or_null("HUD/MarginContainer/VBoxContainer/EnemyCountLabel") as Label
@onready var elevation_label: Label = get_node_or_null("HUD/MarginContainer/VBoxContainer/ElevationLabel") as Label
@onready var reload_label: Label = get_node_or_null("HUD/MarginContainer/VBoxContainer/ReloadLabel") as Label
@onready var mg_status_label: Label = get_node_or_null("HUD/MarginContainer/VBoxContainer/MGStatusLabel") as Label
@onready var skill_status_label: Label = get_node_or_null("HUD/MarginContainer/VBoxContainer/SkillStatusLabel") as Label

@export var crosshair_texture: Texture2D = preload("res://assets/sprites/UI/crossair_red.png")


var match_timer: float = 0.0
var total_enemies: int = 0
var enemies_killed: int = 0
var game_finished: bool = false
var is_in_ui: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Khởi đầu trận đấu: Chế độ con trỏ trong game (Tâm ngắm chuyên dụng)
	set_cursor_mode(false)
	
	# Thay thế nền phẳng đen đơn điệu bằng Hệ thống Địa hình Chiến thuật Quân sự Chi tiết (Surviv.io Style)
	var ground_color := get_node_or_null("GroundColor")
	if ground_color:
		ground_color.visible = false
	var tactical_terrain := TacticalTerrain.new()
	tactical_terrain.level_number = level_number
	tactical_terrain.level_title = level_title
	add_child(tactical_terrain)
	move_child(tactical_terrain, 0)
	
	# Điều chỉnh độ sáng màn chơi ở mức dịu mắt, tương phản cao, không gây chói mắt (74% ambient daylight)
	var canvas_mod := get_node_or_null("WorldCanvasModulate") as CanvasModulate
	if canvas_mod:
		canvas_mod.color = Color(0.74, 0.76, 0.78, 1.0)
	
	if player_tank and player_tank.has_node("Camera2D"):
		var cam: Camera2D = player_tank.get_node("Camera2D")
		cam.limit_left = -40
		cam.limit_top = -40
		cam.limit_right = 2240
		cam.limit_bottom = 1440
	
	if weapon_controller:
		weapon_controller.secondary_blocked_long_range.connect(_on_secondary_blocked)
		
	GlobalEvents.game_state_changed.connect(_on_game_state_changed)
	
	# Khởi tạo Pause Menu
	if pause_menu_scene:
		var pause_menu := pause_menu_scene.instantiate()
		add_child(pause_menu)
		
	# Khởi tạo Delta Force Tactical Military HUD
	if has_node("HUD"):
		$HUD.visible = false
	if delta_force_hud_scene:
		delta_force_hud = delta_force_hud_scene.instantiate() as DeltaForceHUD
		add_child(delta_force_hud)
		
	if title_label:
		title_label.text = level_title
		
	# Đếm tổng số xe tăng địch ban đầu
	total_enemies = get_tree().get_nodes_in_group("enemy").size()
	if is_sandbox:
		if enemy_count_label:
			enemy_count_label.text = "BIA TAP BAN MO PHONG (Tu hoi sinh)"
			enemy_count_label.modulate = Color(0.4, 0.9, 1.0)
	else:
		update_enemy_count()



func set_cursor_mode(in_ui: bool) -> void:
	is_in_ui = in_ui
	GlobalEvents.ui_hover_changed.emit(is_in_ui)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if is_in_ui:
		# CON TRỎ GIAO DIỆN (UI): Con trỏ thường (mũi tên tiêu chuẩn của hệ điều hành)
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	else:
		# CON TRỎ TRONG GAME: Tâm ngắm chuyên dụng đỏ (crosshair 32x32 với tâm chính giữa)
		if crosshair_texture:
			Input.set_custom_mouse_cursor(crosshair_texture, Input.CURSOR_ARROW, Vector2(16, 16))

func _process(delta: float) -> void:
	if not game_finished:
		match_timer += delta
		check_enemy_count()
	
	update_cursor_separation()
	update_hud()

func update_cursor_separation() -> void:
	var mouse_screen_pos := get_viewport().get_mouse_position()
	var over_hud := false
	if delta_force_hud and delta_force_hud.is_inside_tree():
		over_hud = delta_force_hud.is_mouse_over_hud(mouse_screen_pos)
	elif hud_container and hud_container.is_visible_in_tree():
		over_hud = hud_container.get_global_rect().has_point(mouse_screen_pos) or Rect2(Vector2.ZERO, hud_container.size).has_point(hud_container.get_local_mouse_position())
	
	var should_ui := game_finished or get_tree().paused or over_hud
	if should_ui != is_in_ui:
		set_cursor_mode(should_ui)

func check_enemy_count() -> void:
	if is_sandbox:
		return
		
	var current_enemies := get_tree().get_nodes_in_group("enemy").size()
	enemies_killed = total_enemies - current_enemies
	update_enemy_count()
	
	# Nếu đã tiêu diệt hết toàn bộ kẻ địch -> CHIẾN THẮNG!
	if current_enemies == 0 and total_enemies > 0 and not game_finished:
		trigger_victory()

func update_enemy_count() -> void:
	if enemy_count_label:
		var current_enemies := get_tree().get_nodes_in_group("enemy").size()
		enemy_count_label.text = "Xe tang con lai: %d / %d xe" % [current_enemies, total_enemies]
		if current_enemies > 0:
			enemy_count_label.modulate = Color(1.0, 0.4, 0.4)
		else:
			enemy_count_label.text = "DA QUET SACH TOAN BO KE DICH!"
			enemy_count_label.modulate = Color(0.3, 1.0, 0.4)

func update_hud() -> void:
	if turret_node and elevation_label:
		var current_dist := int(turret_node.global_position.distance_to(turret_node.current_target_pos))
		elevation_label.text = "Phao coi (Chuot trai): Cu ly %d px (Tam Trung & Xa: 280-720 px)" % current_dist
		elevation_label.modulate = TurretAim.RANGE_COLOR
	
	if weapon_controller and reload_label:
		if weapon_controller.artillery_timer <= 0.0:
			reload_label.text = "Phao chinh: SAN SANG"
			reload_label.modulate = Color(0.4, 1.0, 0.4)
		else:
			reload_label.text = "Phao chinh: Dang nap... (%.1fs)" % weapon_controller.artillery_timer
			reload_label.modulate = Color(1.0, 0.8, 0.2)
	
	if mg_status_label:
		mg_status_label.text = "Sung may (Chuot phai): KHA DUNG (Tam Gan & Trung: 0-480 px)"
		mg_status_label.modulate = Color(1.0, 0.9, 0.2)
		
	if player_tank and skill_status_label:
		var rep_text := "[Q] Sua chua: "
		var rep_color := Color(0.35, 1.0, 0.5)
		if player_tank.repair_timer > 0.0:
			rep_text += "Hoi... (%.1fs)" % player_tank.repair_timer
			rep_color = Color(0.85, 0.85, 0.4)
		elif player_tank.health_comp and player_tank.health_comp.current_health >= player_tank.health_comp.max_health:
			rep_text += "DAY MAU (100%)"
			rep_color = Color(0.5, 0.9, 0.6)
		else:
			rep_text += "SAN SANG (+35 HP)"
			
		var smoke_text := " | [E] Khoi mu: "
		if player_tank.is_in_smoke:
			smoke_text += "AN TRONG KHOI "
			if player_tank.smoke_timer > 0.0:
				smoke_text += "(Hoi %.1fs)" % player_tank.smoke_timer
		elif player_tank.smoke_timer > 0.0:
			smoke_text += "Hoi... (%.1fs)" % player_tank.smoke_timer
		else:
			smoke_text += "SAN SANG (Tha khoi)"
			
		skill_status_label.text = rep_text + smoke_text
		skill_status_label.modulate = rep_color

func _on_secondary_blocked() -> void:
	if mg_status_label:
		mg_status_label.modulate = Color(2.5, 0.4, 0.2)
		var tween := create_tween()
		tween.tween_property(mg_status_label, "modulate", Color(0.85, 0.35, 0.3), 0.3)

func _on_game_state_changed(new_state: String) -> void:
	if new_state == "DEFEAT" and not game_finished:
		trigger_defeat()

func trigger_victory() -> void:
	game_finished = true
	set_cursor_mode(true)
	GlobalEvents.game_state_changed.emit("VICTORY")
	
	var hp_ratio := 1.0
	if player_tank and player_tank.health_comp:
		hp_ratio = float(player_tank.health_comp.current_health) / float(player_tank.health_comp.max_health)
		
	var score_result: Dictionary = {}
	if ScoreManager:
		score_result = ScoreManager.calculate_score(level_number, match_timer, enemies_killed, hp_ratio)
		
	if victory_screen_scene:
		var win_ui := victory_screen_scene.instantiate() as VictoryScreen
		add_child(win_ui)
		win_ui.setup(match_timer, enemies_killed, next_level_scene, is_final_level, score_result)
	get_tree().paused = true

func trigger_defeat() -> void:
	game_finished = true
	set_cursor_mode(true)
	if game_over_screen_scene:
		var defeat_ui := game_over_screen_scene.instantiate() as GameOverScreen
		add_child(defeat_ui)
	get_tree().paused = true
