class_name WeaponController
extends Node

## Quản lý Toàn diện Hệ thống Hỏa Lực Xe Tăng:
## - VŨ KHÍ CHÍNH (Chuột trái): Pháo cối Parabola, Song pháo AP, Rocket chùm (Được cấu hình cố định tại Menu).
## - VŨ KHÍ PHỤ (Chuột phải): 3 loại súng chuyên biệt được cấu hình từ Menu:
##   1. Súng xuyên giáp AP (Mặc định): Sơ tốc cao, sát thương lớn, tốc bắn và hồi lâu hơn súng máy.
##   2. Súng máy liên thanh: Tốc bắn cực nhanh, có cơ chế quá nhiệt (Burn Out).
##   3. Súng shotgun tán xạ: Bắn chùm 6 mảnh đạn rẻ quạt uy lực hủy diệt ở cự ly cận chiến.
## - Nguyên tắc: Chỉ có thể tùy chỉnh vũ khí ở Menu, không đổi tự do trong màn chơi để đảm bảo tính chiến thuật.

signal artillery_fired(cooldown_time: float)
signal mg_fired()
signal secondary_fired(cooldown_time: float)
signal secondary_blocked_long_range()
signal weapon_mode_changed(new_mode: int)

enum WeaponMode {
	ARTILLERY = 0,    # Pháo cối Parabola Tầm xa (AoE 120px / 140px)
	TWIN_CANNON = 1,  # Song pháo nòng kép AP (Bắn 2 phát đạn thẳng tốc độ cao)
	ROCKET_POD = 2    # Bệ phóng Rocket chùm tự hành tìm mục tiêu
}

enum SecondaryWeaponMode {
	AP_GUN = 0,       # Súng xuyên giáp AP (Mặc định - Tốc bắn chậm, hồi lâu, sát thương cao)
	MACHINE_GUN = 1,  # Súng máy liên thanh (Tốc bắn siêu tốc, cơ chế quá nhiệt)
	SHOTGUN = 2       # Súng shotgun (Bắn chùm rẻ quạt cận chiến cực mạnh)
}

@export var weapon_mode: WeaponMode = WeaponMode.ARTILLERY
@export var secondary_weapon_mode: SecondaryWeaponMode = SecondaryWeaponMode.AP_GUN

@export var artillery_shell_scene: PackedScene = preload("res://scenes/weapons/ArtilleryShell.tscn")
@export var mg_bullet_scene: PackedScene = preload("res://scenes/weapons/MachineGunBullet.tscn")
@export var twin_bullet_scene: PackedScene = preload("res://scenes/weapons/TwinCannonBullet.tscn")
@export var homing_rocket_scene: PackedScene = preload("res://scenes/weapons/HomingRocket.tscn")
@export var heavy_ap_scene: PackedScene = preload("res://scenes/weapons/HeavyAPBullet.tscn")
@export var shotgun_scene: PackedScene = preload("res://scenes/weapons/ShotgunPellet.tscn")

# Hồi chiêu Vũ khí Chính (Chuột trái)
@export var artillery_cooldown: float = 2.2
@export var twin_cannon_cooldown: float = 1.4
@export var rocket_pod_cooldown: float = 3.0

# Hồi chiêu Vũ khí Phụ (Chuột phải)
@export var ap_cooldown: float = 0.70      # Súng xuyên giáp AP: Sát thương cực lớn 75 HP, xuyên thấu
@export var mg_initial_cooldown: float = 0.16 # Súng máy: Tốc bắn ban đầu khi mới bóp cò
@export var mg_max_cooldown: float = 0.045    # Súng máy: Tốc bắn cực đại khi sấy liên tục (bắn nhanh dần)
@export var mg_cooldown: float = 0.10      # Trung bình
@export var shotgun_cooldown: float = 0.82 # Súng shotgun: Hồi chiêu nạp chùm đạn

# Cơ chế Quá nhiệt / Burn Out của Súng máy
@export var mg_heat_capacity: float = 100.0
@export var mg_heat_per_shot: float = 5.2
@export var mg_cooling_rate: float = 35.0
@export var mg_overheat_penalty: float = 2.8

# Cơ chế Khóa mục tiêu Đạn đuổi (Rocket Pod Lock-on: 1.5s hoặc có Radar)
@export var rocket_lock_duration: float = 1.5
@export var rocket_max_range: float = 720.0
var rocket_lock_timer: float = 0.0
var is_rocket_locked: bool = false
var rocket_locked_target: Node2D = null

var primary_timer: float = 0.0
var artillery_timer: float = 0.0 # Tương thích HUD
var secondary_timer: float = 0.0
var mg_timer: float = 0.0        # Tương thích HUD súng máy
var mg_heat: float = 0.0
var is_mg_overheated: bool = false
var mg_overheat_timer: float = 0.0
var is_firing_mg: bool = false
var mg_spool_progress: float = 0.0 # Tiến độ tăng tốc độ súng máy (0.0 -> 1.0)
var is_over_ui: bool = false

@onready var turret_aim: TurretAim = $"../Turret"

func _ready() -> void:
	GlobalEvents.ui_hover_changed.connect(func(over: bool): is_over_ui = over)
	if "default_weapon_mode" in GlobalEvents:
		weapon_mode = clampi(GlobalEvents.default_weapon_mode, 0, 2) as WeaponMode
	if "secondary_weapon_mode" in GlobalEvents:
		secondary_weapon_mode = clampi(GlobalEvents.secondary_weapon_mode, 0, 2) as SecondaryWeaponMode
	if "weapon_preset" in GlobalEvents:
		apply_weapon_preset(GlobalEvents.weapon_preset)

func apply_weapon_preset(preset: int) -> void:
	match preset:
		1: # PHÁO BINH HẠNG NẶNG
			artillery_cooldown = 1.35
			twin_cannon_cooldown = 1.2
		2: # ĐỘT KÍCH HỎA LỰC
			mg_heat_capacity = 130.0
			mg_cooling_rate = 55.0
			ap_cooldown = 0.52
			shotgun_cooldown = 0.65
		3: # TÁC CHIẾN TÊN LỬA
			rocket_lock_duration = 0.75
			rocket_max_range = 800.0
		_: # CÂN BẰNG TIÊU CHUẨN
			artillery_cooldown = 1.6
			twin_cannon_cooldown = 1.4
			mg_heat_capacity = 100.0
			mg_cooling_rate = 35.0
			ap_cooldown = 0.68
			shotgun_cooldown = 0.82
			rocket_lock_duration = 1.5
			rocket_max_range = 720.0

func _unhandled_input(_event: InputEvent) -> void:
	# Lưu ý thiết kế: Vũ khí chỉ được thiết lập tại Menu trước khi xuất kích.
	# Khóa việc bấm phím 1, 2, 3 chuyển đổi trong trận để nâng cao tính kỷ luật chiến thuật.
	pass

func _process(delta: float) -> void:
	if primary_timer > 0.0:
		primary_timer = maxf(primary_timer - delta, 0.0)
	artillery_timer = primary_timer
	
	if secondary_timer > 0.0:
		secondary_timer = maxf(secondary_timer - delta, 0.0)
	mg_timer = secondary_timer
	
	# Quản lý tản nhiệt súng máy (kể cả khi không chọn, nếu còn nhiệt dư vẫn hạ nhiệt an toàn)
	if is_mg_overheated:
		mg_overheat_timer = maxf(mg_overheat_timer - delta, 0.0)
		mg_heat = (mg_overheat_timer / mg_overheat_penalty) * mg_heat_capacity
		mg_spool_progress = 0.0 # Quá nhiệt làm mất đà quay nòng súng
		if mg_overheat_timer <= 0.0:
			is_mg_overheated = false
			mg_heat = 0.0
	else:
		if is_firing_mg:
			# Đang giữ cò sấy súng máy -> Tăng tốc vòng quay nòng súng (bắn nhanh dần)
			mg_spool_progress = minf(1.0, mg_spool_progress + delta * 2.2)
		else:
			# Nhả chuột -> Vòng quay nòng súng chậm dần về 0
			mg_spool_progress = maxf(0.0, mg_spool_progress - delta * 3.5)
			if mg_heat > 0.0:
				mg_heat = maxf(mg_heat - mg_cooling_rate * delta, 0.0)
			
	# Cập nhật cơ chế khóa mục tiêu tên lửa
	_update_rocket_targeting(delta)
	
	is_firing_mg = false
	handle_firing()

func _update_rocket_targeting(delta: float) -> void:
	if weapon_mode != WeaponMode.ROCKET_POD:
		rocket_lock_timer = 0.0
		is_rocket_locked = false
		rocket_locked_target = null
		return
		
	var my_pos: Vector2 = Vector2.ZERO
	if owner and owner is Node2D:
		my_pos = (owner as Node2D).global_position
	elif get_parent() is Node2D:
		my_pos = (get_parent() as Node2D).global_position
		
	var aim_pos: Vector2 = my_pos
	if turret_aim:
		aim_pos = turret_aim.get_target_position()
	elif owner and owner is Node2D:
		aim_pos = (owner as Node2D).get_global_mouse_position()
	elif get_parent() is Node2D:
		aim_pos = (get_parent() as Node2D).get_global_mouse_position()
		
	var enemies := get_tree().get_nodes_in_group("enemy")
	var candidate: Node2D = null
	var candidate_dist: float = 160.0
	
	for e in enemies:
		if is_instance_valid(e) and e is Node2D:
			var e_node := e as Node2D
			# Bỏ qua kẻ địch đang ẩn nấp trong khói mù
			if _is_node_concealed(e_node):
				continue
			var dist_to_player: float = my_pos.distance_to(e_node.global_position)
			if dist_to_player <= rocket_max_range:
				var dist_to_aim: float = aim_pos.distance_to(e_node.global_position)
				if dist_to_aim < candidate_dist:
					candidate_dist = dist_to_aim
					candidate = e_node
					
	# Kiểm tra trạng thái Radar hoạt động
	var has_active_radar: bool = false
	if "is_radar_active" in GlobalEvents:
		has_active_radar = GlobalEvents.is_radar_active
		
	if has_active_radar:
		# Có Radar: Tự động khóa mục tiêu trong tầm bắn tức thì
		if not candidate:
			var nearest_d: float = rocket_max_range
			for e in enemies:
				if is_instance_valid(e) and e is Node2D:
					var e_node := e as Node2D
					if _is_node_concealed(e_node):
						continue
					var d: float = my_pos.distance_to(e_node.global_position)
					if d <= nearest_d:
						nearest_d = d
						candidate = e_node
						
		if candidate:
			rocket_locked_target = candidate
			rocket_lock_timer = rocket_lock_duration
			is_rocket_locked = true
		else:
			rocket_locked_target = null
			rocket_lock_timer = 0.0
			is_rocket_locked = false
	else:
		# Không có Radar: Phải rê chuột theo dõi mục tiêu liên tục 1.5s
		if candidate:
			if rocket_locked_target == candidate:
				rocket_lock_timer = minf(rocket_lock_timer + delta, rocket_lock_duration)
			else:
				rocket_locked_target = candidate
				rocket_lock_timer = 0.0
			is_rocket_locked = (rocket_lock_timer >= rocket_lock_duration)
		else:
			rocket_lock_timer = maxf(rocket_lock_timer - delta * 2.5, 0.0)
			if rocket_lock_timer <= 0.0:
				is_rocket_locked = false
				rocket_locked_target = null

func _is_node_concealed(node: Node2D) -> bool:
	if not is_instance_valid(node):
		return true
	if node.has_method("is_concealed") and node.is_concealed():
		return true
	if "is_in_smoke" in node and node.is_in_smoke:
		return true
	return false

func handle_firing() -> void:
	# Khóa hỏa lực khi đang rê chuột trên UI hoặc khi trận đấu tạm dừng
	if is_over_ui or get_tree().paused:
		return

	# 1. BẮN VŨ KHÍ CHÍNH (CHUỘT TRÁI)
	if Input.is_action_just_pressed("fire_artillery"):
		if primary_timer <= 0.0:
			match weapon_mode:
				WeaponMode.ARTILLERY:
					fire_artillery()
				WeaponMode.TWIN_CANNON:
					fire_twin_cannon()
				WeaponMode.ROCKET_POD:
					fire_rocket_pod()
			
	# 2. BẮN VŨ KHÍ PHỤ (CHUỘT PHẢI) - Gồm 3 loại được cấu hình từ Menu
	if Input.is_action_pressed("fire_machinegun"):
		match secondary_weapon_mode:
			SecondaryWeaponMode.AP_GUN:
				if secondary_timer <= 0.0:
					fire_ap_gun()
			SecondaryWeaponMode.MACHINE_GUN:
				is_firing_mg = true
				if not is_mg_overheated and secondary_timer <= 0.0:
					fire_machinegun()
			SecondaryWeaponMode.SHOTGUN:
				if secondary_timer <= 0.0:
					fire_shotgun()

# =========================================================================
# VŨ KHÍ CHÍNH (CHUỘT TRÁI)
# =========================================================================

func fire_artillery() -> void:
	if not turret_aim or not artillery_shell_scene:
		return
		
	if owner and owner.has_method("notify_gunfire"):
		owner.notify_gunfire()
		
	primary_timer = artillery_cooldown
	artillery_timer = primary_timer
	var start_pos := turret_aim.get_artillery_muzzle_pos()
	var target_pos := turret_aim.get_target_position()
	
	var shell := artillery_shell_scene.instantiate() as ArtilleryShell
	get_tree().current_scene.add_child(shell)
	shell.initialize(start_pos, target_pos)
	
	AudioManager.play_cannon()
	trigger_muzzle_flash_light(start_pos, Color(1.0, 0.8, 0.4), 2.5)
	artillery_fired.emit(artillery_cooldown)

func fire_twin_cannon() -> void:
	if not turret_aim or not twin_bullet_scene:
		return
		
	if owner and owner.has_method("notify_gunfire"):
		owner.notify_gunfire()
		
	primary_timer = twin_cannon_cooldown
	artillery_timer = primary_timer
	var center_pos := turret_aim.get_artillery_muzzle_pos()
	var shoot_dir := Vector2.RIGHT.rotated(turret_aim.global_rotation)
	var right_vec := Vector2(-shoot_dir.y, shoot_dir.x)
	
	# Bắn phát 1 (nòng trái)
	var b1 := twin_bullet_scene.instantiate() as TwinCannonBullet
	get_tree().current_scene.add_child(b1)
	b1.initialize(center_pos - right_vec * 10.0, shoot_dir)
	
	# Bắn phát 2 (nòng phải lệch 0.08s)
	get_tree().create_timer(0.08).timeout.connect(func():
		if is_instance_valid(turret_aim):
			var b2 := twin_bullet_scene.instantiate() as TwinCannonBullet
			get_tree().current_scene.add_child(b2)
			var cur_dir := Vector2.RIGHT.rotated(turret_aim.global_rotation)
			var r_vec := Vector2(-cur_dir.y, cur_dir.x)
			b2.initialize(turret_aim.get_artillery_muzzle_pos() + r_vec * 10.0, cur_dir)
			AudioManager.play_cannon()
	)
	
	AudioManager.play_cannon()
	trigger_muzzle_flash_light(center_pos, Color(1.0, 0.6, 0.2), 2.0)
	GlobalEvents.camera_shake_requested.emit(5.0, 0.2)

func fire_rocket_pod() -> void:
	if not turret_aim or not homing_rocket_scene:
		return
		
	# BẮT BUỘC: Phải khóa mục tiêu 1.5s HOẶC có Radar đang quét + trong tầm bắn
	if not is_rocket_locked or not is_instance_valid(rocket_locked_target):
		AudioManager.play_empty_click()
		return
		
	if owner and owner.has_method("notify_gunfire"):
		owner.notify_gunfire()
		
	primary_timer = rocket_pod_cooldown
	artillery_timer = primary_timer
	
	var locked_enemy: Node2D = rocket_locked_target
	
	# Bắn loạt 3 rocket chùm bám đuổi chuẩn xác mục tiêu đã khóa
	var angles: Array[float] = [-0.28, 0.0, 0.28]
	for i in range(angles.size()):
		var angle_offset: float = angles[i]
		get_tree().create_timer(float(i) * 0.1).timeout.connect(func():
			if is_instance_valid(turret_aim):
				var r := homing_rocket_scene.instantiate() as HomingRocket
				get_tree().current_scene.add_child(r)
				var cur_base := Vector2.RIGHT.rotated(turret_aim.global_rotation)
				var launch_dir := cur_base.rotated(angle_offset)
				r.initialize(turret_aim.get_artillery_muzzle_pos(), launch_dir, locked_enemy)
				AudioManager.play_cannon()
				trigger_muzzle_flash_light(turret_aim.get_artillery_muzzle_pos(), Color(1.0, 0.5, 0.2), 1.6)
		)
		
	rocket_lock_timer = 0.0
	is_rocket_locked = false
	rocket_locked_target = null

# =========================================================================
# VŨ KHÍ PHỤ (CHUỘT PHẢI) - 3 LOẠI SÚNG
# =========================================================================

## 1. Súng Xuyên Giáp Hạng Nặng (AP Gun - MẶC ĐỊNH)
## Tốc bắn và hồi lâu hơn súng máy (0.68s), sát thương cao (38 HP), xuyên giáp
func fire_ap_gun() -> void:
	if not turret_aim or not heavy_ap_scene:
		return
		
	if owner and owner.has_method("notify_gunfire"):
		owner.notify_gunfire()
		
	secondary_timer = ap_cooldown
	mg_timer = secondary_timer
	
	var start_pos := turret_aim.get_mg_muzzle_pos()
	var shoot_dir := Vector2.RIGHT.rotated(turret_aim.global_rotation)
	
	var bullet = heavy_ap_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.initialize(start_pos, shoot_dir)
	
	AudioManager.play_cannon()
	trigger_muzzle_flash_light(start_pos, Color(0.3, 0.9, 1.0), 2.2)
	GlobalEvents.camera_shake_requested.emit(3.5, 0.15)
	mg_fired.emit()
	secondary_fired.emit(ap_cooldown)

## 2. Súng Máy Liên Thanh (Machine Gun)
## Tốc bắn tăng dần theo thời gian sấy (0.16s -> 0.045s), sát thương liên thanh, cơ chế Quá nhiệt
func fire_machinegun() -> void:
	if not turret_aim or not mg_bullet_scene or is_mg_overheated:
		return
		
	if owner and owner.has_method("notify_gunfire"):
		owner.notify_gunfire()
		
	# Tốc bắn tăng dần: Giữ chuột càng lâu nòng súng quay càng nhanh, hồi chiêu giảm từ 0.16s xuống 0.045s
	var current_mg_cd: float = lerpf(mg_initial_cooldown, mg_max_cooldown, mg_spool_progress)
	secondary_timer = current_mg_cd
	mg_timer = secondary_timer
	
	# Sấy càng nhanh thì tích nhiệt càng tăng tương ứng
	var heat_added: float = mg_heat_per_shot * lerpf(0.8, 1.25, mg_spool_progress)
	mg_heat += heat_added
	
	# Kiểm tra chạm ngưỡng quá nhiệt (Burn Out)
	if mg_heat >= mg_heat_capacity:
		mg_heat = mg_heat_capacity
		is_mg_overheated = true
		mg_overheat_timer = mg_overheat_penalty
		mg_spool_progress = 0.0
		GlobalEvents.camera_shake_requested.emit(3.5, 0.18)
		trigger_overheat_steam(turret_aim.get_mg_muzzle_pos())
	
	var start_pos := turret_aim.get_mg_muzzle_pos()
	var shoot_dir := Vector2.RIGHT.rotated(turret_aim.global_rotation)
	
	var bullet := mg_bullet_scene.instantiate() as MachineGunBullet
	get_tree().current_scene.add_child(bullet)
	bullet.initialize(start_pos, shoot_dir)
	
	AudioManager.play_machinegun()
	trigger_muzzle_flash_light(start_pos, Color(1.0, 0.9, 0.5), 1.2)
	mg_fired.emit()
	secondary_fired.emit(current_mg_cd)

## 3. Súng Shotgun Tán Xạ (Shotgun)
## Bắn chùm 6 mảnh đạn hình nón rẻ quạt, sát thương cực mạnh ở cự ly cận chiến
func fire_shotgun() -> void:
	if not turret_aim or not shotgun_scene:
		return
		
	if owner and owner.has_method("notify_gunfire"):
		owner.notify_gunfire()
		
	secondary_timer = shotgun_cooldown
	mg_timer = secondary_timer
	
	var start_pos := turret_aim.get_mg_muzzle_pos()
	var base_dir := Vector2.RIGHT.rotated(turret_aim.global_rotation)
	
	# 6 Mảnh đạn tán xạ theo các góc đối xứng
	var spread_angles: Array[float] = [-0.30, -0.18, -0.06, 0.06, 0.18, 0.30]
	for ang in spread_angles:
		var pellet = shotgun_scene.instantiate()
		get_tree().current_scene.add_child(pellet)
		var pellet_dir := base_dir.rotated(ang + randf_range(-0.04, 0.04))
		pellet.initialize(start_pos, pellet_dir)
		
	AudioManager.play_cannon()
	trigger_muzzle_flash_light(start_pos, Color(1.0, 0.5, 0.2), 2.2)
	GlobalEvents.camera_shake_requested.emit(4.2, 0.18)
	mg_fired.emit()
	secondary_fired.emit(shotgun_cooldown)

func trigger_overheat_steam(pos: Vector2) -> void:
	var smoke := CPUParticles2D.new()
	smoke.global_position = pos
	smoke.emitting = true
	smoke.one_shot = true
	smoke.explosiveness = 0.8
	smoke.amount = 16
	smoke.lifetime = 0.8
	smoke.gravity = Vector2(0, -35)
	smoke.initial_velocity_min = 20.0
	smoke.initial_velocity_max = 50.0
	smoke.scale_amount_min = 5.0
	smoke.scale_amount_max = 12.0
	smoke.color = Color(0.9, 0.9, 0.9, 0.65)
	get_tree().current_scene.add_child(smoke)
	get_tree().create_timer(1.0).timeout.connect(smoke.queue_free)

func trigger_muzzle_flash_light(pos: Vector2, color: Color = Color(1.0, 0.8, 0.4), energy: float = 2.0) -> void:
	var flash := PointLight2D.new()
	flash.global_position = pos
	flash.color = color
	flash.energy = energy
	if ResourceLoader.exists("res://assets/sprites/effects/shadow_circle.png"):
		flash.texture = load("res://assets/sprites/effects/shadow_circle.png")
	flash.texture_scale = 1.3
	get_tree().current_scene.add_child(flash)
	
	var tween := create_tween()
	tween.tween_property(flash, "energy", 0.0, 0.12)
	tween.finished.connect(flash.queue_free)
