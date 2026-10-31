class_name InWorldTrackingDraw
extends Control

## Vẽ các thẻ theo dõi mục tiêu quân sự (Hostile Diamond Tags) khi bật Quét Radar

var hud: DeltaForceHUD

func _ready() -> void:
	_find_hud()

func _find_hud() -> void:
	var n: Node = get_parent()
	while n and not (n is DeltaForceHUD):
		n = n.get_parent()
	hud = n as DeltaForceHUD

func _process(_delta: float) -> void:
	if not hud:
		_find_hud()
	if hud and hud.radar_active_timer > 0.0:
		queue_redraw()
	elif is_visible_in_tree():
		queue_redraw()

func _draw() -> void:
	if not hud:
		_find_hud()
	if not hud or hud.radar_active_timer <= 0.0 or not is_instance_valid(hud.player_tank):
		return
		
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return
		
	var enemies := get_tree().get_nodes_in_group("enemy")
	var pulse := 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.012)
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		var enemy_node := enemy as Node2D
		if not enemy_node:
			continue
			
		# Chuyển đổi tọa độ thế giới sang tọa độ màn hình HUD
		var screen_pos := enemy_node.get_global_transform_with_canvas().origin
		var dist := int(hud.player_tank.global_position.distance_to(enemy_node.global_position))
		
		# 1. Vẽ kim cương đỏ nhấp nháy trên đầu xe tăng địch
		var d_size := 11.0 * pulse
		var diamond_pts := PackedVector2Array([
			screen_pos + Vector2(0, -50 - d_size),
			screen_pos + Vector2(d_size, -50),
			screen_pos + Vector2(0, -50 + d_size),
			screen_pos + Vector2(-d_size, -50)
		])
		draw_polyline(diamond_pts, Color(1.0, 0.1, 0.1, 0.9), 2.2, true)
		draw_colored_polygon(diamond_pts, Color(1.0, 0.15, 0.15, 0.35 * pulse))
		
		# 2. Vòng radar sonar lan tỏa quanh mục tiêu
		draw_arc(screen_pos, 28.0 * pulse, 0, TAU, 32, Color(1.0, 0.2, 0.2, 0.45 * pulse), 1.6, true)
		
		# 3. Thẻ thông tin cự ly quân sự
		var tag_text := "HOSTILE [%d M]" % dist
		draw_string(
			ThemeDB.fallback_font,
			screen_pos + Vector2(-50, -68),
			tag_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			13,
			Color(1.0, 0.35, 0.35, 0.98)
		)
