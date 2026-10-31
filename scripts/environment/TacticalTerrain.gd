class_name TacticalTerrain
extends Node2D

## Bộ kết xuất Địa hình Chiến thuật Sinh Động Phong Cách SURVIV.IO (Surviv.io Style Battlefield Terrain)
## - Mô phỏng thẩm mỹ bản đồ 2D Top-down kinh điển của Surviv.io:
##   + Thổ nhưỡng sống động theo từng Biome (Đồng cỏ xanh mát, Rừng thu lá đỏ/vàng, Sa mạc kho xăng, Đấu trường đảo Killpit).
##   + Bờ cát biển lượn sóng bao bọc 4 mép biên bản đồ.
##   + Dòng sông uốn lượn tự nhiên có cầu gỗ/cầu bê tông bắc qua cho xe tăng cơ động.
##   + Tán cây tròn lồng nhau nhiều tầng màu (Signature Surviv.io Layered Round Trees) với bóng đổ mềm.
##   + Tảng đá cuội tự nhiên bo tròn (Rounded Boulders) tạo điểm nhấn địa hình.
##   + Đường mòn đất sỏi nối liền các cụm công sự và cứ điểm tác chiến.
##   + Sàn bê tông quân sự modular slabs lót dưới các khu nhà và chân tường.

@export var map_bounds: Rect2 = Rect2(-100, -100, 2400, 1600)
@export var play_area: Rect2 = Rect2(0, 0, 2200, 1400)
@export var grid_step: float = 128.0

var level_number: int = 1
var level_title: String = ""

# Danh sách dữ liệu tạo ngẫu nhiên nhưng cố định (Deterministic procedural seed)
var _trees: Array[Dictionary] = []
var _boulders: Array[Dictionary] = []
var _roads: Array[Array] = []
var _river_points: Array[Vector2] = []
var _bridges: Array[Rect2] = []
var _grass_patches: Array[Dictionary] = []

enum BiomeType {
	SUMMER_GRASS, # Cỏ xanh rực rỡ surviv.io (Màn 1, 2, 8, Sandbox)
	AUTUMN_FOREST,# Rừng thu lá vàng đỏ (Màn 4, 7 - Phong cách Fowl Forest)
	DESERT_ARID,  # Sa mạc cát vàng kho xăng (Màn 3, 5)
	RIVER_DELTA,  # Đồng bằng sông ngòi uốn lượn (Màn 6)
	KILLPIT_ARENA # Đấu trường đảo trung tâm The Killpit (Màn 9, 10 - Siêu Trùm Mammoth)
}

var current_biome: BiomeType = BiomeType.SUMMER_GRASS

func _ready() -> void:
	z_index = -5
	_determine_biome()
	_generate_procedural_features()
	get_tree().create_timer(0.05).timeout.connect(queue_redraw)

func _determine_biome() -> void:
	match level_number:
		4, 7:
			current_biome = BiomeType.AUTUMN_FOREST
		3, 5:
			current_biome = BiomeType.DESERT_ARID
		6:
			current_biome = BiomeType.RIVER_DELTA
		9, 10:
			current_biome = BiomeType.KILLPIT_ARENA
		_:
			current_biome = BiomeType.SUMMER_GRASS

func _generate_procedural_features() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026 + level_number * 173
	
	# 1. Tạo các mảng cỏ / đất đan xen (Grass color patches)
	_grass_patches.clear()
	for i in range(40):
		var pos := Vector2(rng.randf_range(80, 2120), rng.randf_range(80, 1320))
		var r := rng.randf_range(50, 140)
		_grass_patches.append({ "pos": pos, "radius": r, "variant": rng.randi() % 3 })
		
	# 2. Tạo dòng sông và cầu vượt sông
	_river_points.clear()
	_bridges.clear()
	
	if current_biome == BiomeType.RIVER_DELTA or current_biome == BiomeType.SUMMER_GRASS:
		# Sông uốn lượn từ Bắc xuống Nam (hơi lệch đông)
		var river_x := 1150.0
		var num_pts := 16
		for i in range(num_pts + 1):
			var t := float(i) / float(num_pts)
			var y := lerpf(-80.0, 1480.0, t)
			var x_offset := sin(t * PI * 2.2 + 0.5) * 110.0 + cos(t * PI * 3.5) * 45.0
			_river_points.append(Vector2(river_x + x_offset, y))
			
		# Đặt 2 cầu gỗ bắc qua sông ở các trục di chuyển
		_bridges.append(Rect2(Vector2(1100, 380), Vector2(170, 75)))
		_bridges.append(Rect2(Vector2(1180, 960), Vector2(170, 75)))
		
	elif current_biome == BiomeType.KILLPIT_ARENA:
		# Đấu trường hồ nước hình tròn bao quanh đảo trung tâm (The Killpit Moat)
		# Sẽ được vẽ riêng trong hàm _draw_killpit_lake()
		pass
		
	# 3. Tạo đường mòn đất nối các cứ điểm
	_roads.clear()
	var road1: Array[Vector2] = [
		Vector2(100, 700),
		Vector2(450, 680),
		Vector2(850, 420),
		Vector2(1200, 420),
		Vector2(1700, 420),
		Vector2(2050, 700)
	]
	var road2: Array[Vector2] = [
		Vector2(1200, 420),
		Vector2(1220, 960),
		Vector2(1650, 1050),
		Vector2(2000, 1050)
	]
	_roads.append(road1)
	_roads.append(road2)

	# 4. Tạo các tán cây tròn phân tầng phong cách Surviv.io
	_trees.clear()
	var num_trees := 65 if current_biome == BiomeType.AUTUMN_FOREST else 45
	var attempts := 0
	while _trees.size() < num_trees and attempts < 300:
		attempts += 1
		var pos := Vector2(rng.randf_range(120, 2080), rng.randf_range(120, 1280))
		
		# Tránh đè lên vị trí xuất phát của người chơi (340, 700)
		if pos.distance_to(Vector2(340, 700)) < 160:
			continue
			
		# Tránh lòng sông
		var on_river := false
		for pt in _river_points:
			if pos.distance_to(pt) < 110:
				on_river = true
				break
		if on_river:
			continue
			
		# Tránh đè lên cầu
		var on_bridge := false
		for br in _bridges:
			if br.grow(35).has_point(pos):
				on_bridge = true
				break
		if on_bridge:
			continue
			
		var r := rng.randf_range(32.0, 58.0)
		var tree_variant := rng.randi() % 4
		_trees.append({ "pos": pos, "radius": r, "variant": tree_variant })

	# 5. Tạo các tảng đá cuội tự nhiên bo tròn
	_boulders.clear()
	for i in range(22):
		var pos := Vector2(rng.randf_range(150, 2050), rng.randf_range(150, 1250))
		if pos.distance_to(Vector2(340, 700)) < 140:
			continue
		var r := rng.randf_range(18.0, 34.0)
		_boulders.append({ "pos": pos, "radius": r, "rot": rng.randf_range(0, TAU) })

func _draw() -> void:
	# BƯỚC 1: VẼ ĐẠI DƯƠNG / BIỂN NGOÀI KHƠI (OCEAN WATER BORDER)
	var ocean_color := Color(0.14, 0.35, 0.52, 1.0)
	draw_rect(map_bounds, ocean_color, true)
	
	# BƯỚC 2: BÃI CÁT VÀNG LƯỢN SÓNG (BEACH SHORELINE)
	var beach_color := Color(0.74, 0.65, 0.44, 1.0)
	var sand_margin := 75.0
	var island_rect := Rect2(
		play_area.position - Vector2(sand_margin, sand_margin),
		play_area.size + Vector2(sand_margin * 2.0, sand_margin * 2.0)
	)
	draw_rect(island_rect, beach_color, true)
	
	# Vẽ đường viền sóng vỗ bờ biển mờ ảo
	draw_rect(island_rect.grow(12), Color(1.0, 1.0, 1.0, 0.18), false, 3.5)
	
	# BƯỚC 3: MẶT ĐẤT CHÍNH THEO BIOME (VIBRANT GROUND TERRAIN)
	_draw_base_ground()
	
	# BƯỚC 4: VẼ ĐƯỜNG MÒN ĐẤT SỎI (DIRT PATHS & ROADS)
	_draw_dirt_roads()
	
	# BƯỚC 5: VẼ DÒNG SÔNG VÀ CẦU VƯỢT SÔNG (RIVERS & WOODEN BRIDGES)
	if current_biome == BiomeType.KILLPIT_ARENA:
		_draw_killpit_lake()
	else:
		_draw_winding_river()
		
	# BƯỚC 6: SÀN BÊ TÔNG QUÂN SỰ DƯỚI CÁC CỤM TƯỜNG (CONCRETE FOUNDATIONS)
	_draw_compound_slabs()
	
	# BƯỚC 7: TẢNG ĐÁ CUỘI SURVIV.IO (ROUNDED BOULDERS)
	_draw_boulders()
	
	# BƯỚC 8: VÙNG RÊU CỎ DƯỚI BỤI RẬM CHIẾN THUẬT (BUSH UNDERGROWTH)
	_draw_bush_undergrowth()
	
	# BƯỚC 9: CÁC TÁN CÂY TRÒN LỒNG NHAU SURVIV.IO (LAYERED TREE CANOPY)
	_draw_trees()
	
	# BƯỚC 10: VẠCH SƠN QUÂN SỰ NGUY HIỂM Ở BIÊN ĐẤU TRƯỜNG (HAZARD BORDERS)
	_draw_hazard_borders()

# -----------------------------------------------------------------------------
# CÁC HÀM VẼ CHI TIẾT THÀNH PHẦN
# -----------------------------------------------------------------------------

func _draw_base_ground() -> void:
	var base_col: Color
	var patch_col1: Color
	var patch_col2: Color
	var grid_col: Color
	
	match current_biome:
		BiomeType.AUTUMN_FOREST:
			base_col = Color(0.54, 0.40, 0.18, 1.0)
			patch_col1 = Color(0.48, 0.34, 0.14, 0.55)
			patch_col2 = Color(0.58, 0.38, 0.16, 0.45)
			grid_col = Color(0.42, 0.30, 0.12, 0.22)
		BiomeType.DESERT_ARID:
			base_col = Color(0.62, 0.55, 0.38, 1.0)
			patch_col1 = Color(0.56, 0.48, 0.32, 0.55)
			patch_col2 = Color(0.66, 0.58, 0.42, 0.45)
			grid_col = Color(0.48, 0.40, 0.28, 0.22)
		_:
			# Cỏ xanh dịu mắt, độ bão hòa vừa phải chuẩn Surviv.io
			base_col = Color(0.35, 0.55, 0.24, 1.0)
			patch_col1 = Color(0.30, 0.48, 0.20, 0.60)
			patch_col2 = Color(0.38, 0.58, 0.26, 0.50)
			grid_col = Color(0.26, 0.44, 0.17, 0.25)
			
	# Nền cỏ chính
	draw_rect(play_area, base_col, true)
	
	# Các mảng cỏ đậm/nhạt tự nhiên loang lổ
	for p in _grass_patches:
		var col := patch_col1 if p["variant"] == 0 else patch_col2
		draw_circle(p["pos"], p["radius"], col)
		draw_circle(p["pos"] + Vector2(10, 8), p["radius"] * 0.65, col * 1.06)
		
	# Lưới tọa độ chiến thuật mờ kiểu Surviv.io (Tactical Grid)
	var x := play_area.position.x
	while x <= play_area.end.x:
		draw_line(Vector2(x, play_area.position.y), Vector2(x, play_area.end.y), grid_col, 1.2)
		x += grid_step
		
	var y := play_area.position.y
	while y <= play_area.end.y:
		draw_line(Vector2(play_area.position.x, y), Vector2(play_area.end.x, y), grid_col, 1.2)
		y += grid_step

func _draw_dirt_roads() -> void:
	var road_color := Color(0.56, 0.48, 0.34, 0.70)
	var tread_color := Color(0.42, 0.35, 0.24, 0.40)
	
	for road in _roads:
		if road.size() < 2:
			continue
		# Vẽ mặt đường đất chính
		for i in range(road.size() - 1):
			var p1: Vector2 = road[i]
			var p2: Vector2 = road[i + 1]
			draw_line(p1, p2, road_color, 44.0, true)
			# Vẽ 2 vệt bánh xích xe tăng in hằn trên đường mòn
			var dir := (p2 - p1).normalized()
			var normal := Vector2(-dir.y, dir.x)
			draw_line(p1 + normal * 12.0, p2 + normal * 12.0, tread_color, 2.5, true)
			draw_line(p1 - normal * 12.0, p2 - normal * 12.0, tread_color, 2.5, true)

func _draw_winding_river() -> void:
	if _river_points.size() < 2:
		return
		
	var river_width := 85.0
	var bank_width := river_width + 24.0
	var river_bank_col := Color(0.26, 0.36, 0.18, 0.9)
	var water_col := Color(0.18, 0.42, 0.58, 0.95)
	var deep_water_col := Color(0.13, 0.32, 0.46, 0.85)
	
	# Bờ sông ẩm ướt
	for i in range(_river_points.size() - 1):
		draw_line(_river_points[i], _river_points[i + 1], river_bank_col, bank_width, true)
		
	# Lòng sông nước xanh
	for i in range(_river_points.size() - 1):
		draw_line(_river_points[i], _river_points[i + 1], water_col, river_width, true)
		draw_line(_river_points[i], _river_points[i + 1], deep_water_col, river_width * 0.45, true)
		
	# Vẽ các cây cầu gỗ vượt sông
	for br in _bridges:
		_draw_wooden_bridge(br)

func _draw_wooden_bridge(br: Rect2) -> void:
	# Bóng đổ của cầu xuống mặt nước
	draw_rect(Rect2(br.position, br.size + Vector2(6, 8)), Color(0, 0, 0, 0.35), true)
	
	# Mố cầu bê tông hai bên bờ
	var abutment_col := Color(0.38, 0.40, 0.44, 1.0)
	draw_rect(Rect2(br.position.x - 8, br.position.y - 4, 14, br.size.y + 8), abutment_col, true)
	draw_rect(Rect2(br.end.x - 6, br.position.y - 4, 14, br.size.y + 8), abutment_col, true)
	
	# Mặt cầu ván gỗ xếp ngang
	var plank_col1 := Color(0.54, 0.38, 0.22, 1.0)
	var plank_col2 := Color(0.48, 0.33, 0.18, 1.0)
	var plank_w := 14.0
	var curr_x := br.position.x
	var idx := 0
	while curr_x < br.end.x:
		var p_col := plank_col1 if idx % 2 == 0 else plank_col2
		draw_rect(Rect2(curr_x, br.position.y, plank_w - 2.0, br.size.y), p_col, true)
		curr_x += plank_w
		idx += 1
		
	# Lan can cầu gỗ hai bên
	var rail_col := Color(0.32, 0.22, 0.12, 1.0)
	draw_rect(Rect2(br.position.x, br.position.y - 3, br.size.x, 5), rail_col, true)
	draw_rect(Rect2(br.position.x, br.end.y - 2, br.size.x, 5), rail_col, true)

func _draw_killpit_lake() -> void:
	# Đấu trường Đảo Trung Tâm "The Killpit" (Màn 10 - Siêu Trùm Mammoth)
	var center := Vector2(1100, 700)
	var moat_inner := 340.0
	var moat_outer := 460.0
	
	# Vành hào nước xung quanh đảo
	var water_col := Color(0.18, 0.42, 0.60, 0.95)
	var bank_col := Color(0.72, 0.64, 0.44, 1.0) # Bờ cát bao quanh hào
	
	draw_circle(center, moat_outer + 20.0, bank_col)
	draw_circle(center, moat_outer, water_col)
	draw_circle(center, moat_inner, bank_col)
	
	# Đảo trung tâm rộng lớn cho Siêu Trùm Mammoth
	var island_col := Color(0.36, 0.56, 0.25, 1.0)
	draw_circle(center, moat_inner - 16.0, island_col)
	
	# Đấu trường sàn bê tông quân sự hình bát giác ở tâm đảo
	draw_circle(center, 180.0, Color(0.20, 0.23, 0.27, 0.85))
	draw_arc(center, 180.0, 0, TAU, 32, Color(0.72, 0.58, 0.14, 0.9), 3.0, true)
	draw_circle(center, 120.0, Color(0.16, 0.18, 0.22, 0.9))
	
	# 4 Cây cầu kiên cố Bắc, Nam, Đông, Tây nối vào đảo trung tâm
	var bridge_w := 90.0
	var b_len := moat_outer - moat_inner + 40.0
	_draw_fortified_bridge(Rect2(center.x - bridge_w * 0.5, center.y - moat_outer - 15, bridge_w, b_len))
	_draw_fortified_bridge(Rect2(center.x - bridge_w * 0.5, center.y + moat_inner - 25, bridge_w, b_len))
	_draw_fortified_bridge(Rect2(center.x - moat_outer - 15, center.y - bridge_w * 0.5, b_len, bridge_w))
	_draw_fortified_bridge(Rect2(center.x + moat_inner - 25, center.y - bridge_w * 0.5, b_len, bridge_w))

func _draw_fortified_bridge(rect: Rect2) -> void:
	draw_rect(rect.grow(4), Color(0, 0, 0, 0.35), true)
	draw_rect(rect, Color(0.35, 0.38, 0.42, 1.0), true)
	draw_rect(rect, Color(0.72, 0.58, 0.14, 0.75), false, 2.5)

func _draw_compound_slabs() -> void:
	# Tìm các bức tường bê tông trong màn chơi và lót sàn gạch bê tông quân sự bên dưới
	var walls := get_tree().get_nodes_in_group("walls")
	for w in walls:
		if is_instance_valid(w):
			var pos: Vector2 = w.global_position
			var slab_r := Rect2(pos - Vector2(34, 34), Vector2(68, 68))
			draw_rect(slab_r, Color(0.18, 0.21, 0.25, 0.65), true)
			draw_rect(slab_r, Color(0.10, 0.12, 0.15, 0.45), false, 1.2)

func _draw_boulders() -> void:
	for b in _boulders:
		var pos: Vector2 = b["pos"]
		var r: float = b["radius"]
		
		# Bóng đổ
		draw_circle(pos + Vector2(5, 6), r * 1.05, Color(0, 0, 0, 0.28))
		# Vỏ ngoài viền đá đậm
		draw_circle(pos, r, Color(0.34, 0.37, 0.40, 1.0))
		# Thân đá xám tự nhiên
		draw_circle(pos, r * 0.90, Color(0.50, 0.54, 0.58, 1.0))
		# Highlight sáng góc trên trái kiểu 2.5D
		draw_circle(pos + Vector2(-r * 0.22, -r * 0.22), r * 0.55, Color(0.68, 0.73, 0.77, 0.85))
		draw_circle(pos + Vector2(-r * 0.28, -r * 0.28), r * 0.26, Color(0.85, 0.89, 0.92, 0.9))

func _draw_trees() -> void:
	for t in _trees:
		var pos: Vector2 = t["pos"]
		var r: float = t["radius"]
		var variant: int = t["variant"]
		
		var leaf_base: Color
		match current_biome:
			BiomeType.AUTUMN_FOREST:
				match variant:
					0: leaf_base = Color(0.85, 0.35, 0.12) # Đỏ phong
					1: leaf_base = Color(0.92, 0.52, 0.15) # Cam thu
					2: leaf_base = Color(0.95, 0.72, 0.22) # Vàng rực
					_: leaf_base = Color(0.48, 0.62, 0.22) # Xanh rêu
			BiomeType.DESERT_ARID:
				match variant:
					0: leaf_base = Color(0.58, 0.68, 0.32) # Cây cọ sa mạc
					1: leaf_base = Color(0.45, 0.58, 0.26)
					_: leaf_base = Color(0.65, 0.62, 0.38) # Bụi khô
			_:
				match variant:
					0: leaf_base = Color(0.28, 0.62, 0.22) # Xanh non Surviv.io
					1: leaf_base = Color(0.22, 0.52, 0.18) # Xanh lục đậm
					2: leaf_base = Color(0.35, 0.70, 0.26) # Xanh tươi
					_: leaf_base = Color(0.18, 0.44, 0.15) # Rừng sẫm
					
		# BƯỚC 1: BÓNG ĐỔ MỀM LỆCH GÓC
		draw_circle(pos + Vector2(7, 9), r * 1.06, Color(0, 0, 0, 0.25))
		
		# BƯỚC 2: VÒNG LÁ NGOÀI CÙNG (ĐẬM VIỀN ĐẶC TRƯNG SURVIV.IO)
		draw_circle(pos, r, leaf_base * 0.68)
		
		# BƯỚC 3: VÒNG LÁ CHÍNH
		draw_circle(pos, r * 0.92, leaf_base)
		
		# BƯỚC 4: VÒNG HIGHLIGHT SÁNG 2.5D PHÍA TRÊN BÊN TRÁI (DỊU MẮT)
		draw_circle(pos + Vector2(-r * 0.18, -r * 0.18), r * 0.66, leaf_base * 1.15)
		draw_circle(pos + Vector2(-r * 0.24, -r * 0.24), r * 0.35, leaf_base * 1.28)
		
		# BƯỚC 5: TÂM THÂN CÂY NHỎ Ở CHÍNH GIỮA
		draw_circle(pos, r * 0.15, Color(0.24, 0.17, 0.10, 0.95))

func _draw_bush_undergrowth() -> void:
	var bushes := get_tree().get_nodes_in_group("bush")
	var moss_col := Color(0.16, 0.32, 0.14, 0.55) if current_biome != BiomeType.AUTUMN_FOREST else Color(0.45, 0.28, 0.12, 0.55)
	for bush in bushes:
		if is_instance_valid(bush):
			var b_pos: Vector2 = bush.global_position
			draw_circle(b_pos, 52.0, moss_col)
			draw_circle(b_pos + Vector2(4, 4), 32.0, moss_col * 0.8)

func _draw_hazard_borders() -> void:
	# Dải cảnh báo sọc chéo quân sự vàng - đen bảo vệ vùng giao tranh
	var col_yellow := Color(0.85, 0.70, 0.16, 0.65)
	var col_dark := Color(0.12, 0.12, 0.14, 0.75)
	
	# Mép trên
	for x in range(0, 2200, 48):
		var p1 := Vector2(x, 15)
		var p2 := Vector2(x + 24, 15)
		draw_line(p1, p2, col_yellow, 6.0)
		draw_line(p2, p2 + Vector2(24, 0), col_dark, 6.0)
		
	# Mép dưới
	for x in range(0, 2200, 48):
		var p1 := Vector2(x, 1385)
		var p2 := Vector2(x + 24, 1385)
		draw_line(p1, p2, col_yellow, 6.0)
		draw_line(p2, p2 + Vector2(24, 0), col_dark, 6.0)
