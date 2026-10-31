class_name TurretAim
extends Node2D

## Điều khiển tháp pháo và Phạm vi bắn pháo (Range Zone) 2D:
## 1. Vị trí pháo rơi theo 2 chiều (X, Y) do người dùng sử dụng con trỏ chuột quyết định tự do.
## 2. Phạm vi bắn CỐ ĐỊNH trong TẦM GẦN và TẦM TRUNG (120 px - 480 px), loại bỏ hoàn toàn cơ chế đổi phạm vi bằng con lăn.
## 3. Con trỏ chuột di chuyển tự do trong phạm vi [MIN_RANGE, MAX_RANGE].
## 4. Tách biệt hoàn toàn con trỏ trong giao diện (UI) và trong game:
##    - Trong chiến trường: Hiển thị tâm ngắm chuyên dụng đỏ (32x32).
##    - Trong giao diện (HUD, Thắng/Thua): Hiển thị chuột thường của hệ điều hành.

const MIN_RANGE: float = 280.0 # Tầm Trung bắt đầu
const MAX_RANGE: float = 720.0 # Tầm Xa tối đa
const MAX_MG_RANGE: float = 480.0 # Súng máy tối đa (Tầm Gần & Trung)
const RANGE_NAME: String = "TẦM TRUNG & XA (280 - 720 px)"
const RANGE_COLOR: Color = Color(1.0, 0.55, 0.25) # Cam vàng hỏa lực pháo

# Tọa độ điểm rơi pháo theo không gian 2 chiều (do chuột tự do điều khiển trong [280, 720])
var current_target_pos: Vector2 = Vector2.ZERO
var is_over_ui: bool = false

@onready var artillery_muzzle: Marker2D = $ArtilleryMuzzle
@onready var mg_muzzle: Marker2D = $MGMuzzle
@onready var reticle: Node2D = $Reticle
@onready var weapon_controller: Node = get_node_or_null("../WeaponController")

func _ready() -> void:
	GlobalEvents.ui_hover_changed.connect(_on_ui_hover_changed)
	
	if reticle:
		reticle.top_level = true
		
	# Khởi tạo điểm ngắm mặc định ở cự ly 400 px phía trước
	current_target_pos = global_position + Vector2.RIGHT * 400.0
	
	# Luôn hiển thị dạ quang rõ ràng vòng cự ly pháo xuyên qua vùng tối
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat


func _on_ui_hover_changed(over_ui: bool) -> void:
	is_over_ui = over_ui
	if reticle:
		reticle.visible = not is_over_ui
	queue_redraw()

func _process(_delta: float) -> void:
	if is_over_ui or get_tree().paused:
		return
	update_2d_targeting()

## Vị trí pháo rơi theo 2 chiều do con trỏ chuột tự do quyết định:
## - Pháo cối giới hạn trong TẦM TRUNG & TẦM XA: [280 px - 720 px]
## - Súng máy luôn nhắm theo hướng con trỏ chuột, tầm bắn hiệu quả tới 480 px
func update_2d_targeting() -> void:
	var mouse_pos := get_global_mouse_position()
	var to_mouse := mouse_pos - global_position
	var mouse_dist := to_mouse.length()
	var mouse_dir := to_mouse.normalized() if mouse_dist > 0.001 else Vector2.RIGHT
	
	# Điểm ngắm pháo 2 chiều bị giới hạn trong phạm vi Tầm Trung & Xa [280, 720]
	var clamped_dist := clampf(mouse_dist, MIN_RANGE, MAX_RANGE)
	current_target_pos = global_position + mouse_dir * clamped_dist
	
	# Tháp pháo quay theo hướng chuột thực tế (giúp súng máy ngắm chính xác cả ở cự ly gần)
	look_at(global_position + mouse_dir * 100.0)
	
	# Đặt tâm ngắm pháo (to bằng xe tăng) ngay tại vị trí 2 chiều đã chọn trong [280, 720]
	if reticle:
		reticle.global_position = current_target_pos
		
	queue_redraw()

func _draw() -> void:
	if is_over_ui or get_tree().paused:
		return
		
	var col := RANGE_COLOR
	
	# 1. PHẠM VI PHÁO CỐI (Tầm Trung 280 px đến Tầm Xa 720 px):
	# Cung giới hạn trong của pháo (MIN_RANGE = 280 px)
	draw_arc(Vector2.ZERO, MIN_RANGE, -PI * 0.45, PI * 0.45, 64, Color(col.r, col.g, col.b, 0.45), 2.2, true)
	# Cung giới hạn ngoài của pháo (MAX_RANGE = 720 px)
	draw_arc(Vector2.ZERO, MAX_RANGE, -PI * 0.45, PI * 0.45, 72, Color(col.r, col.g, col.b, 0.75), 2.5, true)
	
	# 2. RANH GIỚI TỐI ĐA CỦA SÚNG MÁY (MAX_MG_RANGE = 480 px):
	# Vẽ cung nét màu vàng chanh báo hiệu tầm với tối đa của súng máy
	draw_arc(Vector2.ZERO, MAX_MG_RANGE, -PI * 0.4, PI * 0.4, 56, Color(1.0, 0.9, 0.2, 0.35), 1.8, true)
	
	# 3. Tia đứt hướng đạn nối thẳng từ nòng súng đến vị trí tâm ngắm 2 chiều
	var local_target := to_local(current_target_pos)
	draw_dashed_line(Vector2(58, 0), local_target, Color(col.r, col.g, col.b, 0.85), 2.5, 7.0, true, true)
	
	# 4. Vạch chia giới hạn cắt ngang tia hướng đạn
	draw_line(Vector2(MIN_RANGE, -12), Vector2(MIN_RANGE, 12), Color(col.r, col.g, col.b, 0.8), 2.5, true)
	draw_line(Vector2(MAX_MG_RANGE, -8), Vector2(MAX_MG_RANGE, 8), Color(1.0, 0.9, 0.2, 0.7), 2.0, true)
	draw_line(Vector2(MAX_RANGE, -14), Vector2(MAX_RANGE, 14), Color(col.r, col.g, col.b, 0.95), 2.8, true)

	# Nếu đang dùng Rocket Pod: Vẽ HUD Khóa Mục Tiêu chuyên dụng
	if weapon_controller and weapon_controller.weapon_mode == WeaponController.WeaponMode.ROCKET_POD:
		_draw_rocket_lockon_ui()
		return

	# 5. PHẠM VI TÁC ĐỘNG CỦA ĐẠN PHÁO (AoE Impact & Blast Radius = 120 px / 140 px)
	var aoe_radius := 120.0
	if "weapon_preset" in GlobalEvents and GlobalEvents.weapon_preset == 1:
		aoe_radius = 140.0
	var time_ms := Time.get_ticks_msec()
	var pulse := 0.85 + 0.15 * sin(time_ms * 0.008)
	
	# Vùng ảnh hưởng sát thương bán kính 120px (Tô mờ nền cam hỏa lực)
	draw_circle(local_target, aoe_radius, Color(1.0, 0.35, 0.12, 0.14 * pulse))
	# Vòng biên giới hạn nổ ngoài cùng khử răng cưa
	draw_arc(local_target, aoe_radius, 0.0, TAU, 64, Color(1.0, 0.55, 0.22, 0.88), 2.2, true)
	# Vòng cảnh báo tâm chấn bên trong (50% bán kính)
	draw_arc(local_target, aoe_radius * 0.5, 0.0, TAU, 48, Color(1.0, 0.8, 0.3, 0.55 * pulse), 1.5, true)
	
	# 4 Vạch tiêu ngắm định vị chữ thập quanh chu vi vòng nổ
	var tick_len := 14.0
	draw_line(local_target + Vector2(0, -aoe_radius - tick_len), local_target + Vector2(0, -aoe_radius + 4), Color(1.0, 0.7, 0.25, 0.9), 2.2, true)
	draw_line(local_target + Vector2(0, aoe_radius - 4), local_target + Vector2(0, aoe_radius + tick_len), Color(1.0, 0.7, 0.25, 0.9), 2.2, true)
	draw_line(local_target + Vector2(-aoe_radius - tick_len, 0), local_target + Vector2(-aoe_radius + 4, 0), Color(1.0, 0.7, 0.25, 0.9), 2.2, true)
	draw_line(local_target + Vector2(aoe_radius - 4, 0), local_target + Vector2(aoe_radius + tick_len, 0), Color(1.0, 0.7, 0.25, 0.9), 2.2, true)
	
	# Nhãn văn bản thông báo bán kính sát thương ngay trên tâm ngắm (Không dùng Icon)
	draw_string(
		ThemeDB.fallback_font,
		local_target + Vector2(-60, -aoe_radius - 18),
		"[VÙNG NỔ AOE: %d PX]" % int(aoe_radius),
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		11,
		Color(1.0, 0.85, 0.45, 0.95)
	)

func _draw_rocket_lockon_ui() -> void:
	var local_target := to_local(current_target_pos)
	if not weapon_controller:
		return
		
	if is_instance_valid(weapon_controller.rocket_locked_target):
		var target_pos := to_local(weapon_controller.rocket_locked_target.global_position)
		var bracket_size := 32.0
		var bracket_color: Color = Color(0.2, 1.0, 0.45) if weapon_controller.is_rocket_locked else Color(1.0, 0.85, 0.2)
		
		# Vẽ 4 góc ngoặc [ ] quanh mục tiêu
		draw_line(target_pos + Vector2(-bracket_size, -bracket_size), target_pos + Vector2(-bracket_size + 12, -bracket_size), bracket_color, 2.5)
		draw_line(target_pos + Vector2(-bracket_size, -bracket_size), target_pos + Vector2(-bracket_size, -bracket_size + 12), bracket_color, 2.5)
		draw_line(target_pos + Vector2(bracket_size, -bracket_size), target_pos + Vector2(bracket_size - 12, -bracket_size), bracket_color, 2.5)
		draw_line(target_pos + Vector2(bracket_size, -bracket_size), target_pos + Vector2(bracket_size, -bracket_size + 12), bracket_color, 2.5)
		draw_line(target_pos + Vector2(-bracket_size, bracket_size), target_pos + Vector2(-bracket_size + 12, bracket_size), bracket_color, 2.5)
		draw_line(target_pos + Vector2(-bracket_size, bracket_size), target_pos + Vector2(-bracket_size, bracket_size - 12), bracket_color, 2.5)
		draw_line(target_pos + Vector2(bracket_size, bracket_size), target_pos + Vector2(bracket_size - 12, bracket_size), bracket_color, 2.5)
		draw_line(target_pos + Vector2(bracket_size, bracket_size), target_pos + Vector2(bracket_size, bracket_size - 12), bracket_color, 2.5)
		
		if weapon_controller.is_rocket_locked:
			draw_string(ThemeDB.fallback_font, target_pos + Vector2(-95, -bracket_size - 8), "[MỤC TIÊU ĐÃ KHÓA - SẴN SÀNG BẮN]", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, bracket_color)
		else:
			var pct := int((weapon_controller.rocket_lock_timer / weapon_controller.rocket_lock_duration) * 100.0)
			draw_string(ThemeDB.fallback_font, target_pos + Vector2(-60, -bracket_size - 8), "[ĐANG KHÓA: %d%%]" % pct, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, bracket_color)
	else:
		draw_string(ThemeDB.fallback_font, local_target + Vector2(-135, -25), "[YÊU CẦU KHÓA MỤC TIÊU 1.5S HOẶC BẬT RADAR]", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.9, 0.75, 0.35, 0.9))

## Súng máy luôn khả dụng trong phạm vi Tầm Gần & Trung (tối đa 480 px)
func can_fire_machinegun() -> bool:
	return true

## Trả về vị trí pháo rơi 2 chiều chính xác do chuột chỉ định
func get_target_position() -> Vector2:
	return current_target_pos

func get_artillery_muzzle_pos() -> Vector2:
	if artillery_muzzle:
		return artillery_muzzle.global_position
	return global_position

func get_mg_muzzle_pos() -> Vector2:
	if mg_muzzle:
		return mg_muzzle.global_position
	return global_position
