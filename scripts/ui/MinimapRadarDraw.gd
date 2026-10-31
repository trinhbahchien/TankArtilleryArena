class_name MinimapRadarDraw
extends Control

## Vẽ Minimap Radar Quân sự xoay quét 360 độ (Delta Force Tactical Radar)
## Tích hợp khử răng cưa (Antialiased) mượt mà sắc nét ở mọi độ phân giải.

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
		
	var center := size * 0.5
	var r := hud.radar_radius
	var player_pos := hud.player_tank.global_position
	
	# 1. Nền kính Radar tối
	draw_circle(center, r, Color(0.02, 0.07, 0.04, 0.82))
	
	# 2. Vành viền Bezel kim loại xanh rêu quân sự (Khử răng cưa mịn màng)
	draw_arc(center, r, 0, TAU, 64, Color(0.18, 0.65, 0.35, 0.98), 2.5, true)
	draw_arc(center, r + 2.5, 0, TAU, 64, Color(0.06, 0.22, 0.12, 0.85), 1.8, true)
	
	# 3. Các vòng cự ly đồng tâm (Range Rings: 50m, 100m, 150m)
	var rings: Array[float] = [0.33, 0.66, 1.0]
	for ring_factor: float in rings:
		var ring_r: float = r * ring_factor
		draw_arc(center, ring_r, 0, TAU, 48, Color(0.2, 0.65, 0.38, 0.38), 1.2, true)
		
	# 4. Trục chữ thập & 4 hướng la bàn (N, S, E, W)
	draw_line(center - Vector2(r, 0), center + Vector2(r, 0), Color(0.2, 0.65, 0.38, 0.32), 1.2, true)
	draw_line(center - Vector2(0, r), center + Vector2(0, r), Color(0.2, 0.65, 0.38, 0.32), 1.2, true)
	
	draw_string(ThemeDB.fallback_font, center + Vector2(-5, -r + 14), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.4, 1.0, 0.6, 0.95))
	draw_string(ThemeDB.fallback_font, center + Vector2(-5, r - 5), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.4, 0.9, 0.6, 0.75))
	draw_string(ThemeDB.fallback_font, center + Vector2(r - 14, 4), "E", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.4, 0.9, 0.6, 0.75))
	draw_string(ThemeDB.fallback_font, center + Vector2(-r + 4, 4), "W", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.4, 0.9, 0.6, 0.75))

	# 5. Tia quét Radar 360 độ (Sweep Beam) mượt mà
	var sweep_angle := hud.radar_sweep_angle
	var sweep_end := center + Vector2(cos(sweep_angle), sin(sweep_angle)) * r
	draw_line(center, sweep_end, Color(0.4, 1.0, 0.6, 0.9), 2.0, true)
	
	# Đuôi quét mờ mềm mại (Sweep trail fan)
	for t in range(1, 9):
		var trail_angle := sweep_angle - float(t) * 0.08
		var trail_end := center + Vector2(cos(trail_angle), sin(trail_angle)) * r
		var alpha := 0.45 * (1.0 - float(t) / 9.0)
		draw_line(center, trail_end, Color(0.2, 0.85, 0.4, alpha), 1.5, true)

	# 6. Sóng siêu âm nổ ra khi bấm quét Radar (Sonar Ping Pulse Wave)
	if hud.radar_active_timer > 0.0:
		var ping_r := r * hud.radar_ping_anim
		var ping_alpha := (1.0 - hud.radar_ping_anim) * 0.85
		draw_arc(center, ping_r, 0, TAU, 56, Color(0.3, 1.0, 0.55, ping_alpha), 2.5, true)

	# 7. Vật thể chướng ngại vật / Tường trên bản đồ
	var walls := get_tree().get_nodes_in_group("obstacles")
	for w in walls:
		if not is_instance_valid(w):
			continue
		var w_node := w as Node2D
		if not w_node:
			continue
		var diff := w_node.global_position - player_pos
		var radar_pos := center + (diff / hud.radar_scan_range) * r
		if center.distance_to(radar_pos) < r - 4.0:
			draw_circle(radar_pos, 2.2, Color(0.2, 0.55, 0.32, 0.45))

	# 8. Xe tăng địch (Enemies)
	var enemies := get_tree().get_nodes_in_group("enemy")
	var is_radar_active := (hud.radar_active_timer > 0.0)
	var time_ms := Time.get_ticks_msec()
	
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var e_node := e as Node2D
		if not e_node:
			continue
		var diff := e_node.global_position - player_pos
		var radar_pos := center + (diff / hud.radar_scan_range) * r
		
		# Kẹp vị trí trong phạm vi radar
		var dist_to_center := center.distance_to(radar_pos)
		if dist_to_center > r - 6.0:
			radar_pos = center + (radar_pos - center).normalized() * (r - 6.0)

		if is_radar_active:
			# KHI ĐANG QUÉT RADAR: Hiện rõ chấm đỏ viền kim cương nhấp nháy phát sóng
			var pulse := 0.6 + 0.4 * sin(time_ms * 0.015)
			draw_circle(radar_pos, 4.5 * pulse, Color(1.0, 0.15, 0.15, 0.98))
			draw_arc(radar_pos, 7.5 * pulse, 0, TAU, 16, Color(1.0, 0.35, 0.35, 0.85 * pulse), 1.6, true)
		else:
			# Bình thường: Chấm đỏ nhỏ viền mờ
			draw_circle(radar_pos, 3.2, Color(1.0, 0.25, 0.25, 0.8))

	# 9. Người chơi ở chính tâm (Green Chevron hướng theo thân xe + vạch tháp pháo)
	var chassis_rot := hud.player_tank.rotation
	var p_size := 8.5
	var fwd := Vector2(cos(chassis_rot), sin(chassis_rot))
	var right := Vector2(-sin(chassis_rot), cos(chassis_rot))
	
	var player_chevron := PackedVector2Array([
		center + fwd * p_size,
		center - fwd * p_size * 0.6 + right * p_size * 0.7,
		center - fwd * p_size * 0.2,
		center - fwd * p_size * 0.6 - right * p_size * 0.7
	])
	draw_colored_polygon(player_chevron, Color(0.2, 1.0, 0.45, 0.98))
	draw_polyline(player_chevron, Color(0.0, 0.2, 0.05, 1.0), 1.8, true)
	
	# Vạch hướng nòng pháo
	if hud.turret_node:
		var turret_rot := hud.turret_node.global_rotation
		var barrel_dir := Vector2(cos(turret_rot), sin(turret_rot))
		draw_line(center, center + barrel_dir * 15.0, Color(1.0, 0.9, 0.2, 0.9), 2.2, true)
