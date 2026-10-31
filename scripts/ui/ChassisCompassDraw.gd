class_name ChassisCompassDraw
extends Control

## Vẽ La bàn Góc Hướng Thân xe & Tháp pháo (Tank Orientation Compass Widget)
## Lấy cảm hứng trực tiếp từ giao diện điều khiển xe tăng của Delta Force.
## Tích hợp khử răng cưa antialiased trên tất cả các đường nét vector.

var hud: DeltaForceHUD

func _ready() -> void:
	_find_hud()

func _find_hud() -> void:
	var n: Node = get_parent()
	while n and not (n is DeltaForceHUD):
		n = n.get_parent()
	hud = n as DeltaForceHUD

func _draw() -> void:
	if not hud:
		_find_hud()
	if not hud or not is_instance_valid(hud.player_tank):
		return
		
	var center := size * 0.5 - Vector2(0, 4)
	var radius := 24.0
	
	# 1. Vòng la bàn bán kính kính mờ nhỏ gọn (Khử răng cưa mịn)
	draw_circle(center, radius, Color(0.04, 0.08, 0.12, 0.7))
	draw_arc(center, radius, 0, TAU, 40, Color(0.2, 0.55, 0.75, 0.75), 1.5, true)
	
	# Các vạch chia độ phương vị
	for i in range(8):
		var ang := float(i) * TAU / 8.0
		var p1 := center + Vector2(cos(ang), sin(ang)) * (radius - 3.5)
		var p2 := center + Vector2(cos(ang), sin(ang)) * radius
		draw_line(p1, p2, Color(0.3, 0.75, 0.95, 0.8), 1.2, true)

	# 2. Thân xe tăng (Chassis Wireframe) xoay theo góc quay của xe
	var chassis_rot := hud.player_tank.rotation
	
	var cos_c := cos(chassis_rot)
	var sin_c := sin(chassis_rot)
	var fwd := Vector2(cos_c, sin_c)
	var right := Vector2(-sin_c, cos_c)
	
	# Kích thước hình học thân xe trên la bàn nhỏ gọn
	var l := 13.0 # Nửa chiều dài
	var w := 9.0  # Nửa chiều rộng
	
	# 4 đỉnh của khung thân xe
	var front_right := center + fwd * l + right * w
	var front_left  := center + fwd * l - right * w
	var rear_left   := center - fwd * l - right * w
	var rear_right  := center - fwd * l + right * w
	
	var body_pts := PackedVector2Array([
		front_left, front_right, rear_right, rear_left
	])
	
	# Nền thân xe (Màu sa mạc quân sự sắc nét)
	draw_colored_polygon(body_pts, Color(0.28, 0.25, 0.16, 0.78))
	draw_polyline(body_pts, Color(0.95, 0.85, 0.52, 0.98), 2.2, true)
	
	# Vết xích hai bên
	draw_line(front_left - right * 3.0, rear_left - right * 3.0, Color(0.85, 0.75, 0.45, 0.85), 2.5, true)
	draw_line(front_right + right * 3.0, rear_right + right * 3.0, Color(0.85, 0.75, 0.45, 0.85), 2.5, true)

	# 3. MŨI TÊN CHỈ RÕ HƯỚNG ĐẦU XE (Front Chevron Arrow)
	var arrow_tip := center + fwd * (l + 13.0)
	var arrow_left := center + fwd * (l + 4.0) - right * 7.5
	var arrow_right := center + fwd * (l + 4.0) + right * 7.5
	
	var arrow_pts := PackedVector2Array([
		arrow_tip, arrow_left, center + fwd * (l + 6.0), arrow_right
	])
	draw_colored_polygon(arrow_pts, Color(0.25, 1.0, 0.5, 0.98))
	draw_polyline(arrow_pts, Color(0.0, 0.2, 0.05, 1.0), 1.8, true)

	# 4. Tháp pháo và Nòng pháo (Turret & Barrel) xoay theo hướng ngắm thực tế
	if hud.turret_node:
		var turret_rot := hud.turret_node.global_rotation
		var barrel_fwd := Vector2(cos(turret_rot), sin(turret_rot))
		
		# Vòng bệ tháp pháo ở tâm
		draw_circle(center, 7.5, Color(0.18, 0.38, 0.52, 0.95))
		draw_arc(center, 7.5, 0, TAU, 24, Color(0.45, 0.95, 1.0, 0.98), 1.8, true)
		
		# Nòng pháo vươn dài ra ngoài thân xe
		var barrel_end := center + barrel_fwd * (l + 9.0)
		draw_line(center, barrel_end, Color(1.0, 0.88, 0.28, 0.98), 3.2, true)
		draw_circle(barrel_end, 2.8, Color(1.0, 0.98, 0.45, 1.0))
