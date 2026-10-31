class_name DeltaForceHUD
extends CanvasLayer

## Giao diện Quân sự Chiến thuật chuẩn Delta Force (Tactical Military Tank HUD)
## Căn chỉnh bố cục chính xác theo bản thiết kế thực chiến:
## - Top-Left: Map + Radar tròn xoay quét 360°, bán kính cự ly 50m-150m + nút Quét Radar dò tìm.
## - Bottom-Center: Health Panel (Thanh máu quân sự lớn) + La bàn góc quay thân xe & tháp pháo chỉ rõ hướng ĐẦU XE.
## - Center: Cự ly khoảng cách [154 M DISTANCE], tốc độ di chuyển [XX KPH] và góc nâng pháo.
## - Bottom-Right (Trái): Cụm Kỹ năng tác chiến [Q] Sửa xe, [E] Khói mù, [F] Dò Radar.
## - Bottom-Right (Phải): Bảng Trạng thái vũ khí (Pháo cối / Súng máy).
## - Right-Center: Bảng chỉ dẫn điều khiển di chuyển, nút bắn, phím tắt.
## - In-World: Đánh dấu mục tiêu quân sự (Hostile Diamond Tags) xuyên tường khi Quét Radar.

@export var radar_radius: float = 58.0 # Thu nhỏ gọn gàng, giải phóng tầm nhìn
@export var radar_scan_range: float = 1400.0 # Bán kính thực tế quét trong thế giới game
@export var radar_cooldown: float = 14.0
@export var radar_duration: float = 7.5

var player_tank: CharacterBody2D
var turret_node: TurretAim
var weapon_controller: WeaponController
var main_level: Node2D

var radar_cooldown_timer: float = 0.0
var radar_active_timer: float = 0.0
var radar_sweep_angle: float = 0.0
var radar_ping_anim: float = 0.0
var is_hud_hidden: bool = false # Phím [H] để ẩn/hiện toàn bộ UI

@onready var radar_control: Control = $MinimapRadar
@onready var compass_control: Control = $BottomCenter/ChassisCompass
@onready var health_panel: Control = $BottomCenter/HealthPanel
@onready var center_hud: Control = $CenterAimData
@onready var top_bar: Control = $TopMissionBar
@onready var skills_panel: Control = $BottomRightSkills
@onready var weapons_panel: Control = $BottomRightWeapons
@onready var guide_panel: Control = get_node_or_null("RightControlsGuide") as Control

@onready var radar_btn: Button = $MinimapRadar/RadarScanButton
@onready var radar_status_lbl: Label = $MinimapRadar/RadarStatusLabel

@onready var distance_label: Label = $CenterAimData/VBoxContainer/DistanceLabel
@onready var speed_label: Label = $CenterAimData/VBoxContainer/HBoxContainer/SpeedLabel
@onready var angle_label: Label = $CenterAimData/VBoxContainer/HBoxContainer/AngleLabel

@onready var mission_title: Label = $TopMissionBar/HBoxContainer/MissionTitle
@onready var enemy_count_lbl: Label = $TopMissionBar/HBoxContainer/EnemyCountLabel
@onready var match_time_lbl: Label = $TopMissionBar/HBoxContainer/MatchTimeLabel

@onready var hp_bar: ProgressBar = $BottomCenter/HealthPanel/HPBar
@onready var hp_label: Label = $BottomCenter/HealthPanel/HPLabel
@onready var heading_label: Label = $BottomCenter/ChassisCompass/HeadingLabel

@onready var artillery_status: Label = $BottomRightWeapons/VBoxContainer/ArtilleryCard/Status
@onready var mg_status: Label = $BottomRightWeapons/VBoxContainer/MGCard/Status

@onready var skill_q_lbl: Label = $BottomRightSkills/VBoxContainer/SkillsHBox/SkillQ/Label
@onready var skill_e_lbl: Label = $BottomRightSkills/VBoxContainer/SkillsHBox/SkillE/Label
@onready var skill_f_lbl: Label = $BottomRightSkills/VBoxContainer/SkillsHBox/SkillF/Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	main_level = get_parent() as Node2D
	if main_level:
		player_tank = main_level.get_node_or_null("PlayerTank") as CharacterBody2D
		if player_tank:
			turret_node = player_tank.get_node_or_null("Turret") as TurretAim
			weapon_controller = player_tank.get_node_or_null("WeaponController") as WeaponController
	
	if radar_btn:
		radar_btn.pressed.connect(trigger_radar_scan)
		
	# Bắt sự kiện click vào kỹ năng trên HUD
	var q_btn := get_node_or_null("BottomRightSkills/VBoxContainer/SkillsHBox/SkillQ/Button") as Button
	var e_btn := get_node_or_null("BottomRightSkills/VBoxContainer/SkillsHBox/SkillE/Button") as Button
	var f_btn := get_node_or_null("BottomRightSkills/VBoxContainer/SkillsHBox/SkillF/Button") as Button
	if q_btn:
		q_btn.pressed.connect(func():
			if is_instance_valid(player_tank) and player_tank.has_method("trigger_self_repair"):
				player_tank.trigger_self_repair()
		)
	if e_btn:
		e_btn.pressed.connect(func():
			if is_instance_valid(player_tank) and player_tank.has_method("trigger_smoke_screen"):
				player_tank.trigger_smoke_screen()
		)
	if f_btn:
		f_btn.pressed.connect(trigger_radar_scan)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_F or event.keycode == KEY_R:
			trigger_radar_scan()
		elif event.keycode == KEY_H:
			is_hud_hidden = not is_hud_hidden
			_toggle_hud_visibility(not is_hud_hidden)

func _toggle_hud_visibility(show_hud: bool) -> void:
	if radar_control: radar_control.visible = show_hud
	if top_bar: top_bar.visible = show_hud
	if compass_control: compass_control.visible = show_hud
	if health_panel: health_panel.visible = show_hud
	if skills_panel: skills_panel.visible = show_hud
	if weapons_panel: weapons_panel.visible = show_hud

func trigger_radar_scan() -> void:
	if radar_cooldown_timer > 0.0 or get_tree().paused:
		return
		
	radar_cooldown_timer = radar_cooldown
	radar_active_timer = radar_duration
	radar_ping_anim = 0.0
	
	# Phát âm thanh Sonar Ping chuẩn quân sự
	AudioManager.play_radar_ping()
	GlobalEvents.radar_scan_triggered.emit(radar_duration)

func _process(delta: float) -> void:
	if not is_instance_valid(player_tank):
		if main_level:
			player_tank = main_level.get_node_or_null("PlayerTank") as CharacterBody2D
			if player_tank:
				turret_node = player_tank.get_node_or_null("Turret") as TurretAim
				weapon_controller = player_tank.get_node_or_null("WeaponController") as WeaponController
		return

	# 1. Cập nhật góc quay quét Radar 360 độ
	radar_sweep_angle += delta * 3.2
	if radar_sweep_angle >= TAU:
		radar_sweep_angle -= TAU

	# 2. Cập nhật thời gian hồi chiêu Radar
	if radar_cooldown_timer > 0.0:
		radar_cooldown_timer = maxf(radar_cooldown_timer - delta, 0.0)
	if radar_active_timer > 0.0:
		radar_active_timer = maxf(radar_active_timer - delta, 0.0)
		radar_ping_anim = minf(radar_ping_anim + delta * 1.5, 1.0)
		if radar_status_lbl:
			radar_status_lbl.text = "RADAR: ĐANG QUÉT (%.1fs)" % radar_active_timer
			radar_status_lbl.modulate = Color(0.3, 1.0, 0.5)
	else:
		if radar_status_lbl:
			if radar_cooldown_timer > 0.0:
				radar_status_lbl.text = "TỤ NẠP RADAR: %.1fs" % radar_cooldown_timer
				radar_status_lbl.modulate = Color(1.0, 0.8, 0.2)
			else:
				radar_status_lbl.text = "[F] RADAR SẴN SÀNG"
				radar_status_lbl.modulate = Color(0.4, 0.95, 1.0)

	# 3. Yêu cầu vẽ lại Minimap và La bàn thân xe
	if radar_control:
		radar_control.queue_redraw()
	if compass_control:
		compass_control.queue_redraw()

	# 4. Cập nhật các bảng số liệu Delta Force
	update_center_hud()
	update_top_mission_bar()
	update_bottom_right_weapons()
	update_chassis_compass_data()

func update_center_hud() -> void:
	if not player_tank or not distance_label:
		return
		
	var dist := 0.0
	var current_elev := 45.0
	if turret_node:
		dist = turret_node.global_position.distance_to(turret_node.current_target_pos)
		current_elev = lerpf(30.0, 68.0, (dist - 280.0) / (720.0 - 280.0))
		current_elev = clampf(current_elev, 25.0, 75.0)
		
	distance_label.text = "%d M" % int(dist)
	if angle_label:
		angle_label.text = "%d° Angle" % int(current_elev)
		
	if speed_label:
		var kph := int(absf(player_tank.velocity.length()) * 0.12)
		speed_label.text = "%d KPH" % kph

func update_top_mission_bar() -> void:
	if not main_level:
		return
		
	if mission_title and "level_title" in main_level:
		mission_title.text = "SEC. OBJ: " + str(main_level.level_title).to_upper()
		
	if enemy_count_lbl:
		var current_enemies := get_tree().get_nodes_in_group("enemy").size()
		if "is_sandbox" in main_level and main_level.is_sandbox:
			enemy_count_lbl.text = "MỤC TIÊU MÔ PHỎNG (Tự hồi sinh)"
			enemy_count_lbl.modulate = Color(0.3, 0.9, 1.0)
		else:
			enemy_count_lbl.text = "QUÂN ĐỊCH: %d XE" % current_enemies
			enemy_count_lbl.modulate = Color(1.0, 0.4, 0.4) if current_enemies > 0 else Color(0.3, 1.0, 0.4)
			
	if match_time_lbl and "match_timer" in main_level:
		var mins := int(main_level.match_timer) / 60
		var secs := int(main_level.match_timer) % 60
		match_time_lbl.text = "THỜI GIAN: %02d:%02d" % [mins, secs]

func update_chassis_compass_data() -> void:
	if not player_tank:
		return
		
	# Cập nhật máu người chơi vào Health Panel kèm thông số cự ly và tốc độ
	if player_tank.health_comp and hp_bar and hp_label:
		hp_bar.max_value = player_tank.health_comp.max_health
		hp_bar.value = player_tank.health_comp.current_health
		var dist := 0.0
		if turret_node:
			dist = turret_node.global_position.distance_to(turret_node.current_target_pos)
		var kph := int(absf(player_tank.velocity.length()) * 0.12)
		hp_label.text = "MÁU: %d/%d HP | CỰ LY: %d M | TỐC ĐỘ: %d KPH" % [player_tank.health_comp.current_health, player_tank.health_comp.max_health, int(dist), kph]
		
	# Cập nhật số đo góc phương vị của thân xe
	if heading_label:
		var deg := int(rad_to_deg(player_tank.rotation)) % 360
		if deg < 0: deg += 360
		heading_label.text = "%03d° HEADING" % deg

@onready var artillery_icon: Label = get_node_or_null("BottomRightWeapons/VBoxContainer/ArtilleryCard/Icon") as Label
@onready var mg_icon: Label = get_node_or_null("BottomRightWeapons/VBoxContainer/MGCard/Icon") as Label
@onready var mg_heat_bar: ProgressBar = get_node_or_null("BottomRightWeapons/VBoxContainer/MGCard/HeatBar") as ProgressBar

func update_bottom_right_weapons() -> void:
	if weapon_controller:
		# 1. Cập nhật tên và trạng thái vũ khí chính (Chuột trái)
		if artillery_icon:
			match weapon_controller.weapon_mode:
				WeaponController.WeaponMode.ARTILLERY:
					artillery_icon.text = "PHÁO CỐI (Chuột Trái)"
					artillery_icon.modulate = Color(1.0, 0.65, 0.3)
				WeaponController.WeaponMode.TWIN_CANNON:
					artillery_icon.text = "SONG PHÁO AP (Chuột Trái)"
					artillery_icon.modulate = Color(0.4, 0.9, 1.0)
				WeaponController.WeaponMode.ROCKET_POD:
					artillery_icon.text = "ROCKET CHÙM (Chuột Trái)"
					artillery_icon.modulate = Color(1.0, 0.45, 0.2)

		if artillery_status:
			if weapon_controller.weapon_mode == WeaponController.WeaponMode.ROCKET_POD:
				if weapon_controller.primary_timer > 0.0:
					artillery_status.text = "NẠP ĐẠN: %.1fs" % weapon_controller.primary_timer
					artillery_status.modulate = Color(1.0, 0.8, 0.2)
				elif weapon_controller.is_rocket_locked:
					artillery_status.text = "ĐÃ KHÓA MỤC TIÊU - SẴN SÀNG BẮN"
					artillery_status.modulate = Color(0.35, 1.0, 0.5)
				elif weapon_controller.rocket_lock_timer > 0.0:
					var pct := int((weapon_controller.rocket_lock_timer / weapon_controller.rocket_lock_duration) * 100.0)
					artillery_status.text = "ĐANG KHÓA: %d%% (1.5s HOẶC [F] RADAR)" % pct
					artillery_status.modulate = Color(1.0, 0.8, 0.2)
				else:
					artillery_status.text = "RÊ CHUỘT VÀO ĐỊCH HOẶC BẬT [F] RADAR"
					artillery_status.modulate = Color(0.7, 0.7, 0.7)
			else:
				if weapon_controller.primary_timer <= 0.0:
					artillery_status.text = "SẴN SÀNG KHAI HỎA"
					artillery_status.modulate = Color(0.35, 1.0, 0.5)
				else:
					artillery_status.text = "NẠP ĐẠN: %.1fs" % weapon_controller.primary_timer
					artillery_status.modulate = Color(1.0, 0.8, 0.2)

		# 2. Cập nhật vũ khí phụ (Chuột phải - 3 loại súng)
		var sec_mode: int = weapon_controller.secondary_weapon_mode
		match sec_mode:
			WeaponController.SecondaryWeaponMode.AP_GUN:
				if mg_icon:
					mg_icon.text = "SÚNG XUYÊN GIÁP (Chuột Phải)"
					mg_icon.modulate = Color(0.4, 0.95, 1.0)
				if mg_status:
					if weapon_controller.secondary_timer <= 0.0:
						mg_status.text = "SẴN SÀNG (75 DMG - XUYÊN GIÁP)"
						mg_status.modulate = Color(0.35, 1.0, 0.5)
					else:
						mg_status.text = "NẠP ĐẠN AP: %.1fs" % weapon_controller.secondary_timer
						mg_status.modulate = Color(1.0, 0.8, 0.2)
				if mg_heat_bar:
					mg_heat_bar.visible = false

			WeaponController.SecondaryWeaponMode.MACHINE_GUN:
				if mg_icon:
					mg_icon.text = "SÚNG MÁY LIÊN THANH (Chuột Phải)"
					mg_icon.modulate = Color(1.0, 0.9, 0.2)
				if mg_heat_bar:
					mg_heat_bar.visible = true
					mg_heat_bar.max_value = weapon_controller.mg_heat_capacity
					mg_heat_bar.value = weapon_controller.mg_heat
					if weapon_controller.is_mg_overheated:
						mg_heat_bar.modulate = Color(1.0, 0.2, 0.2)
					else:
						var t := weapon_controller.mg_heat / weapon_controller.mg_heat_capacity
						mg_heat_bar.modulate = Color(lerpf(0.2, 1.0, t), lerpf(0.9, 0.3, t), 0.3)
				if mg_status:
					if weapon_controller.is_mg_overheated:
						mg_status.text = "QUÁ NHIỆT (Hạ: %.1fs)" % weapon_controller.mg_overheat_timer
						mg_status.modulate = Color(1.0, 0.25, 0.25)
					elif weapon_controller.mg_spool_progress > 0.4:
						var heat_pct := int(weapon_controller.mg_heat)
						mg_status.text = "SẤY TỐC ĐỘ CAO (%d%% NHIỆT)" % heat_pct
						mg_status.modulate = Color(1.0, 0.45, 0.2)
					elif weapon_controller.mg_heat > 10.0:
						var heat_pct := int(weapon_controller.mg_heat)
						mg_status.text = "ĐANG BẮN (%d%% NHIỆT)" % heat_pct
						var t := weapon_controller.mg_heat / weapon_controller.mg_heat_capacity
						mg_status.modulate = Color(1.0, lerpf(0.9, 0.3, t), 0.2)
					else:
						mg_status.text = "SẴN SÀNG (Bắn nhanh dần)"
						mg_status.modulate = Color(1.0, 0.9, 0.2)

			WeaponController.SecondaryWeaponMode.SHOTGUN:
				if mg_icon:
					mg_icon.text = "SÚNG SHOTGUN (Chuột Phải)"
					mg_icon.modulate = Color(1.0, 0.55, 0.2)
				if mg_status:
					if weapon_controller.secondary_timer <= 0.0:
						mg_status.text = "SẴN SÀNG BẮN CHÙM (72 DMG)"
						mg_status.modulate = Color(0.35, 1.0, 0.5)
					else:
						mg_status.text = "NẠP ĐẠN SHOTGUN: %.1fs" % weapon_controller.secondary_timer
						mg_status.modulate = Color(1.0, 0.8, 0.2)
				if mg_heat_bar:
					mg_heat_bar.visible = false
			
	if player_tank:
		if skill_q_lbl:
			if player_tank.repair_timer > 0.0:
				skill_q_lbl.text = "[Q] %.1fs" % player_tank.repair_timer
				skill_q_lbl.modulate = Color(1.0, 0.8, 0.2)
			elif player_tank.health_comp and player_tank.health_comp.current_health >= player_tank.health_comp.max_health:
				skill_q_lbl.text = "[Q] ĐẦY"
				skill_q_lbl.modulate = Color(0.5, 0.8, 0.6)
			else:
				skill_q_lbl.text = "[Q] SỬA (+35)"
				skill_q_lbl.modulate = Color(0.3, 1.0, 0.5)
				
		if skill_e_lbl:
			if player_tank.is_in_smoke:
				skill_e_lbl.text = "[E] TRONG KHÓI"
				skill_e_lbl.modulate = Color(0.4, 0.9, 1.0)
			elif player_tank.is_in_bush:
				if player_tank.bush_reveal_timer > 0.0:
					skill_e_lbl.text = "[BỤI] BỊ LỘ (%.1fs)" % player_tank.bush_reveal_timer
					skill_e_lbl.modulate = Color(1.0, 0.4, 0.4)
				else:
					skill_e_lbl.text = "[BỤI CÂY] ẨN THÂN"
					skill_e_lbl.modulate = Color(0.3, 1.0, 0.5)
			elif player_tank.smoke_timer > 0.0:
				skill_e_lbl.text = "[E] %.1fs" % player_tank.smoke_timer
				skill_e_lbl.modulate = Color(1.0, 0.8, 0.2)
			else:
				skill_e_lbl.text = "[E] KHÓI MÙ"
				skill_e_lbl.modulate = Color(0.3, 1.0, 0.5)
				
		if skill_f_lbl:
			if radar_active_timer > 0.0:
				skill_f_lbl.text = "[F] ĐANG DÒ"
				skill_f_lbl.modulate = Color(0.3, 1.0, 0.5)
			elif radar_cooldown_timer > 0.0:
				skill_f_lbl.text = "[F] %.1fs" % radar_cooldown_timer
				skill_f_lbl.modulate = Color(1.0, 0.8, 0.2)
			else:
				skill_f_lbl.text = "[F] DÒ RADAR"
				skill_f_lbl.modulate = Color(0.4, 0.9, 1.0)

func is_mouse_over_hud(mouse_pos: Vector2) -> bool:
	if radar_control and radar_control.is_visible_in_tree() and radar_control.get_global_rect().grow(12.0).has_point(mouse_pos):
		return true
	if top_bar and top_bar.is_visible_in_tree() and top_bar.get_global_rect().grow(10.0).has_point(mouse_pos):
		return true
	if skills_panel and skills_panel.is_visible_in_tree() and skills_panel.get_global_rect().grow(12.0).has_point(mouse_pos):
		return true
	if weapons_panel and weapons_panel.is_visible_in_tree() and weapons_panel.get_global_rect().grow(12.0).has_point(mouse_pos):
		return true
	if guide_panel and guide_panel.is_visible_in_tree() and guide_panel.get_global_rect().grow(12.0).has_point(mouse_pos):
		return true
	if compass_control and compass_control.is_visible_in_tree() and compass_control.get_global_rect().grow(12.0).has_point(mouse_pos):
		return true
	if health_panel and health_panel.is_visible_in_tree() and health_panel.get_global_rect().grow(12.0).has_point(mouse_pos):
		return true
	return false
