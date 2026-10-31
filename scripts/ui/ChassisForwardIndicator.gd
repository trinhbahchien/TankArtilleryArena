class_name ChassisForwardIndicator
extends Node2D

## Chỉ báo Mũi tên Hướng Trước (Chassis Forward Direction Indicator)
## - Gắn trực tiếp vào thân xe (xoay cùng góc quay thân xe).
## - Hiển thị hệ thống mũi tên quân sự (Tactical Chevrons) chỉ rõ hướng MŨI XE (Front).
## - Giúp người chơi phân biệt tuyệt đối hướng tiến (W) và hướng lùi (S),
##   ngay cả khi tháp pháo đang quay sang các góc đối diện.
## - Tích hợp đèn pha kép (Dual Headlights) và bóng đổ thân xe tạo chiều sâu 2.5D ấn tượng.

@export var primary_color: Color = Color(0.18, 0.95, 1.0, 0.92)      # Cyan Neon quân sự
@export var moving_color: Color = Color(0.28, 1.0, 0.58, 1.0)        # Xanh lục hỏa lực khi tiến
@export var reverse_color: Color = Color(1.0, 0.72, 0.22, 0.95)       # Cam vàng cảnh báo khi lùi
@export var outline_color: Color = Color(0.02, 0.08, 0.16, 0.95)     # Viền đen tương phản
@export var show_headlights: bool = true

var parent_chassis: CharacterBody2D

func _ready() -> void:
	z_index = 8
	z_as_relative = true
	parent_chassis = get_parent() as CharacterBody2D
	
	# Đảm bảo hiển thị rực rỡ không bị ảnh hưởng bởi sương mù bóng tối
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var throttle := 0.0
	if Input.is_action_pressed("move_up"):
		throttle += 1.0
	if Input.is_action_pressed("move_down"):
		throttle -= 1.0

	var time_val := Time.get_ticks_msec() * 0.001

	# =========================================================================
	# 2. ĐÈN PHA KÉP CHIẾU SÁNG PHÍA TRƯỚC (Dual Front Headlights)
	# =========================================================================
	if show_headlights:
		var left_hl := Vector2(38.0, -22.0)
		var right_hl := Vector2(38.0, 22.0)
		
		# Vệt sáng đèn pha (2 nón ánh sáng mềm phóng về phía trước)
		var beam_length := 160.0
		var beam_spread := 28.0
		
		# Nón sáng trái
		var pts_left := PackedVector2Array([
			left_hl,
			left_hl + Vector2(beam_length, -beam_spread),
			left_hl + Vector2(beam_length + 20.0, 0.0),
			left_hl + Vector2(beam_length, beam_spread * 0.5)
		])
		var colors_left := PackedColorArray([
			Color(1.0, 0.98, 0.85, 0.28),
			Color(1.0, 0.95, 0.75, 0.0),
			Color(1.0, 0.95, 0.75, 0.0),
			Color(1.0, 0.95, 0.75, 0.0)
		])
		draw_polygon(pts_left, colors_left)
		
		# Nón sáng phải
		var pts_right := PackedVector2Array([
			right_hl,
			right_hl + Vector2(beam_length, -beam_spread * 0.5),
			right_hl + Vector2(beam_length + 20.0, 0.0),
			right_hl + Vector2(beam_length, beam_spread)
		])
		var colors_right := PackedColorArray([
			Color(1.0, 0.98, 0.85, 0.28),
			Color(1.0, 0.95, 0.75, 0.0),
			Color(1.0, 0.95, 0.75, 0.0),
			Color(1.0, 0.95, 0.75, 0.0)
		])
		draw_polygon(pts_right, colors_right)

		# Bóng đèn LED pha (2 chấm sáng rực rỡ ở đầu xích)
		draw_circle(left_hl, 4.0, Color(1.0, 1.0, 0.95, 0.95))
		draw_circle(left_hl, 7.0, Color(1.0, 0.9, 0.5, 0.35))
		draw_circle(right_hl, 4.0, Color(1.0, 1.0, 0.95, 0.95))
		draw_circle(right_hl, 7.0, Color(1.0, 0.9, 0.5, 0.35))

	# =========================================================================
	# 3. MŨI TÊN CHỈ HƯỚNG PHÍA TRƯỚC (Tactical Chevrons)
	# =========================================================================
	var active_color := primary_color
	var anim_speed := 4.0
	
	if throttle > 0.0:
		active_color = moving_color
		anim_speed = 9.0
	elif throttle < 0.0:
		active_color = reverse_color
		anim_speed = 6.0

	# Tia dẫn đường phía trước (Dashed Guide Line)
	var line_alpha := 0.45 + 0.25 * sin(time_val * anim_speed)
	draw_dashed_line(
		Vector2(44.0, 0.0),
		Vector2(96.0, 0.0),
		Color(active_color.r, active_color.g, active_color.b, line_alpha),
		2.2,
		6.0,
		true,
		true
	)

	# Vẽ 3 mũi tên Chevrons quân sự hướng về phía trước (+X)
	var chevron_xs := [54.0, 70.0, 88.0]
	var chevron_sizes := [10.0, 13.0, 16.0]
	
	for i in range(3):
		var base_x: float = chevron_xs[i]
		var sz: float = chevron_sizes[i]
		
		# Hiệu ứng sóng năng lượng chạy dồn từ sau ra trước (Wave cascade)
		var phase: float = (time_val * anim_speed - float(i) * 0.7)
		var pulse: float = 0.5 + 0.5 * sin(phase)
		var chev_col := Color(
			active_color.r,
			active_color.g,
			active_color.b,
			clampf(0.4 + pulse * 0.6, 0.35, 1.0)
		)

		var arrow_pts := PackedVector2Array([
			Vector2(base_x + sz * 0.6, 0.0),        # Đỉnh nhọn phía trước
			Vector2(base_x - sz * 0.4, -sz * 0.85),  # Cánh trái
			Vector2(base_x - sz * 0.1, 0.0),         # Lõm tâm
			Vector2(base_x - sz * 0.4, sz * 0.85)   # Cánh phải
		])

		# Viền nét đậm tương phản
		draw_polyline(arrow_pts, outline_color, 3.8, true)
		# Lớp phủ màu neon
		draw_colored_polygon(arrow_pts, chev_col)
		# Đường gân sáng bên trong
		draw_line(
			Vector2(base_x - sz * 0.3, -sz * 0.7),
			Vector2(base_x + sz * 0.45, 0.0),
			Color(1.0, 1.0, 1.0, 0.75 * pulse),
			1.8,
			true
		)
		draw_line(
			Vector2(base_x - sz * 0.3, sz * 0.7),
			Vector2(base_x + sz * 0.45, 0.0),
			Color(1.0, 1.0, 1.0, 0.75 * pulse),
			1.8,
			true
		)

	# =========================================================================
	# 4. Ổ BI ĐẾ THÁP PHÁO (Turret Mechanical Ring)
	# =========================================================================
	# Vành cơ khí kim loại neo tháp pháo vững chãi trên thân xe
	draw_circle(Vector2.ZERO, 20.0, Color(0.12, 0.14, 0.18, 0.75))
	draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 48, Color(0.28, 0.32, 0.40, 0.85), 2.0, true)
	draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 36, Color(0.08, 0.10, 0.12, 0.95), 1.5, true)
