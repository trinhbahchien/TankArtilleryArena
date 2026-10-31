class_name EnemyAI
extends CharacterBody2D

## Trí tuệ nhân tạo Xe Tăng Địch LINH HOẠT với 2 CHẾ ĐỘ RÕ RÀNG:
## 1. TẤN CÔNG (Attack/Assault): Tập trung tiến đến mục tiêu (người chơi hoặc trụ/căn cứ sau này) để tiêu diệt
## 2. PHÒNG THỦ (Defense): Phòng thủ cố định tại 1 hoặc nhiều vị trí chốt điểm, bật khiên giáp -50% sát thương, không bỏ vị trí chạy lung tung!

enum CombatRole { ATTACK, DEFENSE }
enum AIState { PATROL, ADVANCING_ATTACK, COMBAT_ENGAGE, RETURNING_TO_POST, GUARDING_POST, SEARCHING, UNSTUCK }

@export var combat_role: CombatRole = CombatRole.ATTACK
@export var explicit_target: Node2D = null

# Lộ trình tuần tra định sẵn xuyên suốt bản đồ
@export var patrol_route: Array[Vector2] = []
@export var patrol_speed: float = 140.0
@export var sight_range: float = 650.0
@export var alert_radius_on_hit: float = 450.0

# Danh sách vị trí cố định để phòng thủ (có thể thiết lập trong Inspector)
@export var defense_positions: Array[Vector2] = []
@export var defense_patrol_interval: float = 12.0
@export var defense_engage_range: float = 580.0
@export var defense_leash_range: float = 660.0 # Nếu mục tiêu chạy xa hơn tầm này, AI phòng thủ lập tức quay về vị trí cố định

# Thông số chuyển động linh hoạt
@export var move_speed: float = 210.0
@export var reverse_speed: float = 140.0
@export var rotation_speed: float = 3.8
@export var turret_speed: float = 5.5

# Cự ly hỏa lực
@export var min_artillery_range: float = 140.0
@export var max_artillery_range: float = 620.0
@export var optimal_combat_dist: float = 320.0
@export var kiting_distance: float = 180.0

enum EnemyWeaponType {
	STANDARD_ARTILLERY = 0, # Pháo cối + Súng máy
	SHOTGUN_RAIDER = 1,     # Đột kích Shotgun tán xạ cận chiến
	HEAVY_AP_SNIPER = 2,    # Bắn đạn xuyên giáp AP cự ly xa
	TWIN_CANNON = 3         # Song pháo nòng kép
}

@export var weapon_type: EnemyWeaponType = EnemyWeaponType.STANDARD_ARTILLERY

# Hồi chiêu vũ khí
@export var attack_artillery_cooldown: float = 3.0
@export var defense_artillery_cooldown: float = 2.0 # Nạp pháo siêu tốc khi cố thủ phòng ngự
@export var mg_cooldown: float = 0.16

@export var artillery_shell_scene: PackedScene = preload("res://scenes/weapons/ArtilleryShell.tscn")
@export var enemy_mg_bullet_scene: PackedScene = preload("res://scenes/weapons/EnemyMachineGunBullet.tscn")
@export var enemy_heavy_ap_scene: PackedScene = preload("res://scenes/weapons/HeavyAPBullet.tscn")
@export var enemy_shotgun_scene: PackedScene = preload("res://scenes/weapons/ShotgunPellet.tscn")
@export var enemy_twin_scene: PackedScene = preload("res://scenes/weapons/TwinCannonBullet.tscn")
@export var explosion_vfx_scene: PackedScene = preload("res://scenes/vfx/ExplosionVFX.tscn")

var current_state: AIState = AIState.PATROL
var is_alerted: bool = false
var current_patrol_idx: int = 0
var patrol_scan_time: float = 0.0
var lost_sight_timer: float = 0.0
var last_known_player_pos: Vector2 = Vector2.ZERO

var is_shield_active: bool = false
var artillery_timer: float = 1.0
var mg_timer: float = 0.0
var current_target: Node2D = null

# Quản lý chốt phòng thủ
var current_defense_idx: int = 0
var defense_patrol_timer: float = 0.0
var anchor_defense_point: Vector2 = Vector2.ZERO

# Cơ chế di chuyển linh hoạt & tránh kẹt
var combat_strafe_dir: float = 1.0
var strafe_timer: float = 0.0
var stuck_detect_timer: float = 0.0
var unstuck_timer: float = 0.0
var unstuck_turn_dir: float = 1.0

@onready var chassis_sprite: Sprite2D = $ChassisSprite
@onready var turret: Node2D = $Turret
@onready var artillery_muzzle: Marker2D = $Turret/ArtilleryMuzzle
@onready var mg_muzzle: Marker2D = $Turret/MGMuzzle
@onready var line_of_sight_ray: RayCast2D = $Turret/LineOfSightRay
@onready var feeler_front: RayCast2D = $Feelers/FrontFeeler
@onready var feeler_left: RayCast2D = $Feelers/LeftFeeler
@onready var feeler_right: RayCast2D = $Feelers/RightFeeler
@onready var health_comp: HealthComponent = $HealthComponent
@onready var health_bar: FloatingHealthBar = $FloatingHealthBar
@onready var defense_shield: Node2D = $DefenseShieldVisual
@onready var state_label: Label = $StateLabel
@onready var damage_smoke: CPUParticles2D = get_node_or_null("DamageSmokeParticles")

var is_in_smoke: bool = false
var is_in_bush: bool = false

# Cơ chế Ẩn tầm nhìn địch sau tường (Fog of War / Line of Sight)
var is_visible_to_player: bool = true
var gunfire_reveal_timer: float = 0.0
@export var proximity_reveal_dist: float = 140.0 # Bán kính nghe tiếng động cơ áp sát

func _ready() -> void:
	if health_comp and health_bar:
		var bar_color := Color(0.95, 0.3, 0.3) if combat_role == CombatRole.ATTACK else Color(0.3, 0.75, 1.0)
		health_bar.setup(health_comp, bar_color)
		health_comp.died.connect(_on_died)
		health_comp.health_changed.connect(_on_health_changed)
	
	# Khởi tạo điểm chốt phòng thủ cố định
	if defense_positions.is_empty():
		defense_positions.append(global_position)
	anchor_defense_point = defense_positions[0]

	# Khởi tạo lộ trình tuần tra mặc định nếu chưa gán thủ công
	if patrol_route.is_empty():
		patrol_route.append(global_position)
		patrol_route.append(global_position + Vector2(240, 0))
		patrol_route.append(global_position + Vector2(240, 200))
		patrol_route.append(global_position + Vector2(0, 200))

	# Đa dạng hóa vũ khí và phong cách tác chiến của kẻ địch
	if weapon_type == EnemyWeaponType.STANDARD_ARTILLERY:
		var pos_seed := int(abs(global_position.x * 73.0 + global_position.y * 37.0)) % 100
		if pos_seed < 30:
			weapon_type = EnemyWeaponType.SHOTGUN_RAIDER
		elif pos_seed < 60:
			weapon_type = EnemyWeaponType.HEAVY_AP_SNIPER
		elif pos_seed < 80:
			weapon_type = EnemyWeaponType.TWIN_CANNON

	match weapon_type:
		EnemyWeaponType.SHOTGUN_RAIDER:
			if chassis_sprite:
				chassis_sprite.modulate = Color(1.3, 0.65, 0.25) # Màu cam đột kích
			move_speed = 240.0
			optimal_combat_dist = 220.0
			kiting_distance = 110.0
		EnemyWeaponType.HEAVY_AP_SNIPER:
			if chassis_sprite:
				chassis_sprite.modulate = Color(0.4, 0.9, 1.3) # Màu xanh thép xuyên giáp
			move_speed = 180.0
			optimal_combat_dist = 520.0
			kiting_distance = 280.0
		EnemyWeaponType.TWIN_CANNON:
			if chassis_sprite:
				chassis_sprite.modulate = Color(1.2, 1.0, 0.35) # Màu vàng song pháo
			move_speed = 200.0
			optimal_combat_dist = 360.0
	
	find_target()
	update_mode_visuals()

func _on_health_changed(current_hp: int, max_hp: int) -> void:
	# Báo động xe sắp hỏng: Khi máu <= 35%, xả khói đen mịt mù từ đuôi xe
	if damage_smoke:
		damage_smoke.emitting = (float(current_hp) / float(max_hp) <= 0.35)

## Tìm kiếm mục tiêu linh hoạt: Ưu tiên công trình/trụ ("objective") hoặc xe người chơi ("player")
func find_target() -> void:
	if is_instance_valid(explicit_target):
		current_target = explicit_target
		return
	
	# Mở rộng cho sau này: Tìm trụ hoặc căn cứ
	var objectives := get_tree().get_nodes_in_group("objective")
	if objectives.size() > 0 and is_instance_valid(objectives[0]):
		current_target = objectives[0] as Node2D
		return
		
	# Tìm người chơi
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		current_target = players[0] as Node2D
		return
		
	current_target = get_tree().current_scene.find_child("PlayerTank", true, false) as Node2D

func _process(delta: float) -> void:
	if artillery_timer > 0.0:
		artillery_timer = maxf(artillery_timer - delta, 0.0)
	if mg_timer > 0.0:
		mg_timer = maxf(mg_timer - delta, 0.0)
		
	# Đếm ngược thời gian bị lộ vị trí khi nổ súng hoặc trúng đạn
	if gunfire_reveal_timer > 0.0:
		gunfire_reveal_timer = maxf(gunfire_reveal_timer - delta, 0.0)
		
	# Cập nhật cơ chế ẩn tầm nhìn sau tường (Fog of War)
	update_fog_of_war_visibility(delta)
	
	# Đổi hướng luồn lách chiến đấu (strafe)
	strafe_timer += delta
	if strafe_timer > randf_range(2.0, 3.5):
		strafe_timer = 0.0
		combat_strafe_dir *= -1.0
	
	# Tuần tra chuyển vị trí chốt phòng thủ định kỳ nếu có nhiều vị trí
	if combat_role == CombatRole.DEFENSE and defense_positions.size() > 1:
		defense_patrol_timer += delta
		if defense_patrol_timer > defense_patrol_interval:
			defense_patrol_timer = 0.0
			current_defense_idx = (current_defense_idx + 1) % defense_positions.size()
			anchor_defense_point = defense_positions[current_defense_idx]
	
	# Hiệu ứng xoay khiên phòng thủ
	if defense_shield and defense_shield.visible:
		defense_shield.rotation += 2.2 * delta

## Cơ chế Ẩn tầm nhìn địch sau tường (Fog of War Occlusion):
## Kẻ địch bị tường cản tầm nhìn sẽ tàng hình khỏi góc nhìn của người chơi;
## Chỉ lộ diện khi có góc nhìn thẳng (Raycast), hoặc khi áp sát gần, hoặc khi nổ súng tạo chớp lửa.
func update_fog_of_war_visibility(delta: float) -> void:
	var player: Node2D = null
	if is_instance_valid(current_target) and current_target.is_in_group("player"):
		player = current_target
	else:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			
	if not is_instance_valid(player):
		return
		
	if is_in_smoke:
		# Ở trong màn khói mù -> Che khuất hoàn toàn
		is_visible_to_player = false
	else:
		var dist_to_player := global_position.distance_to(player.global_position)
		if dist_to_player <= proximity_reveal_dist:
			# Áp sát cận chiến -> Lộ diện do tiếng máy xe
			is_visible_to_player = true
		elif gunfire_reveal_timer > 0.0:
			# Vừa nổ súng hoặc bị bắn trúng -> Chớp lửa và sóng âm làm lộ diện
			is_visible_to_player = true
		else:
			# Bắn tia kiểm tra tường ngăn giữa xe địch và người chơi
			var space_state := get_world_2d().direct_space_state
			var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position)
			query.collision_mask = 1 # Layer 1 là tường thành
			query.exclude = [get_rid(), player.get_rid()]
			var hit := space_state.intersect_ray(query)
			
			# Nếu hit rỗng -> Tầm nhìn thông suốt -> Người chơi nhìn thấy địch
			# Nếu hit có tường -> Bị tường che khuất -> Người chơi KHÔNG thấy địch
			is_visible_to_player = hit.is_empty()
			
	var target_alpha := 1.0 if is_visible_to_player else 0.0
	modulate.a = lerpf(modulate.a, target_alpha, 12.0 * delta)
	
	if health_bar:
		health_bar.visible = (is_visible_to_player and modulate.a > 0.3)
	if state_label:
		state_label.visible = (is_visible_to_player and modulate.a > 0.3)


func can_see_target() -> bool:
	if not is_instance_valid(current_target):
		return false
		
	# Nếu mục tiêu nấp trong bụi rậm hoặc màn khói -> Bị ẩn giấu trừ khi nổ súng
	if current_target.has_method("is_concealed") and current_target.is_concealed():
		if gunfire_reveal_timer <= 0.0:
			return false
	elif "is_in_smoke" in current_target and current_target.is_in_smoke:
		if gunfire_reveal_timer <= 0.0:
			return false
	if SmokeScreenCloud.is_line_blocked_by_smoke(global_position, current_target.global_position):
		if gunfire_reveal_timer <= 0.0:
			return false
			
	var dist := global_position.distance_to(current_target.global_position)
	if dist <= proximity_reveal_dist:
		return true
	if dist > sight_range:
		return false
		
	# Bắn tia kiểm tra tường chắn tầm nhìn
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, current_target.global_position)
	query.collision_mask = 1 # Layer 1 là tường
	query.exclude = [get_rid(), current_target.get_rid()]
	var hit := space_state.intersect_ray(query)
	return hit.is_empty()

func trigger_alert(spread_to_allies: bool = true) -> void:
	if not is_alerted:
		is_alerted = true
		lost_sight_timer = 0.0
		if is_instance_valid(current_target):
			last_known_player_pos = current_target.global_position
			
	if spread_to_allies:
		alert_nearby_allies()

func alert_nearby_allies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy != self:
			if enemy.global_position.distance_to(global_position) <= alert_radius_on_hit:
				if enemy.has_method("trigger_alert"):
					enemy.trigger_alert(false)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(current_target):
		find_target()
		if not is_instance_valid(current_target):
			return
	
	var dist_to_target := global_position.distance_to(current_target.global_position)
	var has_vision := can_see_target()
	
	# Kiểm tra phát hiện người chơi hoặc nhận diện vị trí
	if not is_alerted:
		if has_vision:
			trigger_alert(true)
	else:
		if has_vision:
			last_known_player_pos = current_target.global_position
			lost_sight_timer = 0.0
		else:
			lost_sight_timer += delta
			if lost_sight_timer > 7.0:
				# Mất dấu quá lâu và không bị bắn -> quay lại lộ trình tuần tra
				is_alerted = false
				lost_sight_timer = 0.0
	
	# 1. QUẢN LÝ TRẠNG THÁI VÀ CHẾ ĐỘ
	update_ai_mode_and_state(dist_to_target, has_vision)
	
	# 2. ĐIỀU KHIỂN THÁP PHÁO BẮN ĐÓN MỤC TIÊU HOẶC QUÉT TUẦN TRA
	aim_turret_at_target(dist_to_target, delta)
	
	# 3. ĐÁNH GIÁ VÀ XẢ ĐẠN (CHỈ KHI ĐÃ BÁO ĐỘNG VÀ THẤY MỤC TIÊU)
	if is_alerted and has_vision:
		evaluate_and_fire(dist_to_target)
	
	# 4. CHUYỂN ĐỘNG LINH HOẠT VÀ TRÁNH CHƯỚNG NGẠI VẬT
	execute_flexible_movement(dist_to_target, delta)

func update_ai_mode_and_state(dist: float, has_vision: bool) -> void:
	if not is_alerted:
		current_state = AIState.PATROL
		is_shield_active = false
	elif combat_role == CombatRole.DEFENSE:
		is_shield_active = (dist <= defense_engage_range)
		var dist_to_post := global_position.distance_to(anchor_defense_point)
		
		if dist > defense_leash_range:
			current_state = AIState.RETURNING_TO_POST
		elif dist_to_post > 140.0 and dist > defense_engage_range:
			current_state = AIState.RETURNING_TO_POST
		else:
			current_state = AIState.GUARDING_POST
	else:
		# Chế độ TẤN CÔNG: Dí người chơi tới bến
		is_shield_active = false
		if not has_vision and lost_sight_timer > 0.0:
			current_state = AIState.SEARCHING
		elif dist > optimal_combat_dist + 80.0:
			current_state = AIState.ADVANCING_ATTACK
		else:
			current_state = AIState.COMBAT_ENGAGE
			
	update_mode_visuals()

func update_mode_visuals() -> void:
	if defense_shield:
		defense_shield.visible = is_shield_active
		
	if state_label:
		if is_in_smoke or (is_in_bush and gunfire_reveal_timer <= 0.0):
			state_label.text = "[MAT TAM NHIN]"
			state_label.modulate = Color(0.7, 0.75, 0.8)
		elif not is_alerted:
			state_label.text = "[TUAN TRA LO TRINH]"
			state_label.modulate = Color(0.5, 0.95, 0.5)
		elif current_state == AIState.SEARCHING:
			state_label.text = "[LUNG SUC MUC TIEU]"
			state_label.modulate = Color(1.0, 0.65, 0.2)
		elif is_target_hidden_by_smoke():
			state_label.text = "[MAT DAU MUC TIEU]"
			state_label.modulate = Color(0.85, 0.8, 0.5)
		elif combat_role == CombatRole.DEFENSE:
			if is_shield_active:
				state_label.text = "[PHONG THU - KHIEN GIAP]"
				state_label.modulate = Color(0.3, 0.85, 1.0)
			else:
				state_label.text = "[CO THU VI TRI]"
				state_label.modulate = Color(0.4, 0.7, 0.9)
		else:
			state_label.text = "[DI TAN CONG TOI BEN]"
			state_label.modulate = Color(1.0, 0.25, 0.25)

func is_target_hidden_by_smoke() -> bool:
	if not is_instance_valid(current_target):
		return false
	if current_target.has_method("is_concealed"):
		if current_target.is_concealed():
			return true
	elif "is_in_smoke" in current_target and current_target.is_in_smoke:
		return true
	if SmokeScreenCloud.is_line_blocked_by_smoke(global_position, current_target.global_position):
		return true
	return false

func aim_turret_at_target(dist: float, delta: float) -> void:
	if not is_alerted or current_state == AIState.PATROL:
		patrol_scan_time += delta * 2.2
		var scan_offset := sin(patrol_scan_time) * 0.55
		turret.global_rotation = rotate_toward(turret.global_rotation, rotation + scan_offset, turret_speed * 0.6 * delta)
		return
		
	if current_state == AIState.SEARCHING:
		var search_dir := (last_known_player_pos - global_position).normalized()
		turret.global_rotation = rotate_toward(turret.global_rotation, search_dir.angle(), turret_speed * delta)
		return

	if is_in_smoke or (is_in_bush and gunfire_reveal_timer <= 0.0) or is_target_hidden_by_smoke():
		return
		
	var target_pos := current_target.global_position
	# Bắn đón nếu mục tiêu đang di chuyển
	if current_target is CharacterBody2D:
		var char_target := current_target as CharacterBody2D
		if char_target.velocity.length() > 15.0:
			var flight_time := clampf(dist / 620.0, 0.35, 1.1)
			target_pos += char_target.velocity * flight_time * 0.72
	
	var target_dir := global_position.direction_to(target_pos)
	turret.global_rotation = rotate_toward(turret.global_rotation, target_dir.angle(), turret_speed * delta)

func evaluate_and_fire(dist: float) -> void:
	if dist > max_artillery_range + 50.0:
		return
		
	# Nếu bản thân AI hoặc mục tiêu bị che bởi màn khói mù ngụy trang -> Mất dấu, không thể nhắm bắn!
	if is_in_smoke or is_target_hidden_by_smoke():
		return
		
	# Kiểm tra góc quay tháp pháo đã chuẩn chưa
	var angle_to_target := (current_target.global_position - turret.global_position).angle()
	var angle_err := absf(angle_difference(turret.global_rotation, angle_to_target))
	if angle_err > 0.32:
		return
		
	line_of_sight_ray.target_position = line_of_sight_ray.to_local(current_target.global_position)
	line_of_sight_ray.force_raycast_update()
	var wall_blocked := line_of_sight_ray.is_colliding()
	
	var cooldown := defense_artillery_cooldown if is_shield_active else attack_artillery_cooldown
	
	match weapon_type:
		EnemyWeaponType.SHOTGUN_RAIDER:
			if not wall_blocked and dist <= 380.0 and mg_timer <= 0.0:
				fire_enemy_shotgun()
		EnemyWeaponType.HEAVY_AP_SNIPER:
			if not wall_blocked and dist <= 700.0 and artillery_timer <= 0.0:
				fire_enemy_heavy_ap()
		EnemyWeaponType.TWIN_CANNON:
			if not wall_blocked and dist <= 560.0 and artillery_timer <= 0.0:
				fire_enemy_twin_cannon()
		_: # STANDARD_ARTILLERY
			if wall_blocked:
				# Bị tường cản tầm nhìn thẳng: Bắn pháo cối vòng cầu bay bổng qua tường!
				if artillery_timer <= 0.0 and dist <= max_artillery_range:
					fire_artillery(dist, cooldown)
			else:
				# Tầm nhìn thông thoáng: Xả súng máy và pháo cối dồn sát thương
				if mg_timer <= 0.0 and dist <= 480.0:
					fire_machine_gun()
				if artillery_timer <= 0.0 and dist >= min_artillery_range and dist <= max_artillery_range:
					fire_artillery(dist, cooldown)

func fire_enemy_shotgun() -> void:
	mg_timer = 1.35
	gunfire_reveal_timer = 1.6
	if not enemy_shotgun_scene:
		return
	var start_pos := mg_muzzle.global_position
	var base_dir := Vector2.RIGHT.rotated(turret.global_rotation)
	var angles: Array[float] = [-0.25, -0.12, 0.0, 0.12, 0.25]
	for a in angles:
		var pellet = enemy_shotgun_scene.instantiate()
		get_tree().current_scene.add_child(pellet)
		pellet.initialize(start_pos, base_dir.rotated(a), true)
	AudioManager.play_cannon()
	trigger_muzzle_flash_light(start_pos, Color(1.0, 0.5, 0.2), 2.0)

func fire_enemy_heavy_ap() -> void:
	artillery_timer = 1.65
	gunfire_reveal_timer = 2.0
	if not enemy_heavy_ap_scene:
		return
	var start_pos := artillery_muzzle.global_position
	var shoot_dir := Vector2.RIGHT.rotated(turret.global_rotation)
	var bullet = enemy_heavy_ap_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.initialize(start_pos, shoot_dir, true)
	AudioManager.play_cannon()
	trigger_muzzle_flash_light(start_pos, Color(0.4, 0.8, 1.2), 2.2)

func fire_enemy_twin_cannon() -> void:
	artillery_timer = 2.0
	gunfire_reveal_timer = 2.0
	if not enemy_twin_scene:
		return
	var start_pos := artillery_muzzle.global_position
	var shoot_dir := Vector2.RIGHT.rotated(turret.global_rotation)
	var right_vec := Vector2(-shoot_dir.y, shoot_dir.x)
	var b1 := enemy_twin_scene.instantiate() as TwinCannonBullet
	get_tree().current_scene.add_child(b1)
	b1.initialize(start_pos - right_vec * 8.0, shoot_dir, true)
	get_tree().create_timer(0.08).timeout.connect(func():
		if is_instance_valid(turret):
			var b2 := enemy_twin_scene.instantiate() as TwinCannonBullet
			get_tree().current_scene.add_child(b2)
			var cur_dir := Vector2.RIGHT.rotated(turret.global_rotation)
			var r_v := Vector2(-cur_dir.y, cur_dir.x)
			b2.initialize(start_pos + r_v * 8.0, cur_dir, true)
	)
	AudioManager.play_cannon()
	trigger_muzzle_flash_light(start_pos, Color(1.0, 0.7, 0.2), 2.0)

func fire_artillery(dist: float, cooldown_to_set: float) -> void:
	artillery_timer = cooldown_to_set
	gunfire_reveal_timer = 2.0 # Bị lộ vị trí khi nổ pháo
	if not artillery_shell_scene:
		return
		
	var start_pos := artillery_muzzle.global_position
	var aim_target := current_target.global_position
	if current_target is CharacterBody2D:
		var char_target := current_target as CharacterBody2D
		if char_target.velocity.length() > 15.0:
			var flight_time := clampf(dist / 620.0, 0.35, 1.1)
			aim_target += char_target.velocity * flight_time * 0.65
	
	# Độ lệch ngẫu nhiên nhỏ
	var spread := 20.0 if combat_role == CombatRole.DEFENSE else 28.0
	var offset := Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
	
	var shell := artillery_shell_scene.instantiate() as ArtilleryShell
	get_tree().current_scene.add_child(shell)
	shell.initialize(start_pos, aim_target + offset)
	AudioManager.play_cannon()
	trigger_muzzle_flash_light(start_pos, Color(1.0, 0.75, 0.35), 2.2)

func fire_machine_gun() -> void:
	mg_timer = mg_cooldown
	gunfire_reveal_timer = 1.4 # Bị lộ vị trí khi xả súng máy
	if not enemy_mg_bullet_scene:
		return
		
	var start_pos := mg_muzzle.global_position
	var shoot_dir := Vector2.RIGHT.rotated(turret.global_rotation)
	
	var bullet := enemy_mg_bullet_scene.instantiate() as EnemyMachineGunBullet
	get_tree().current_scene.add_child(bullet)
	bullet.initialize(start_pos, shoot_dir)
	AudioManager.play_machinegun()
	trigger_muzzle_flash_light(start_pos, Color(1.0, 0.9, 0.4), 1.2)

func trigger_muzzle_flash_light(pos: Vector2, color: Color = Color(1.0, 0.8, 0.4), energy: float = 2.0) -> void:
	var flash := PointLight2D.new()
	flash.global_position = pos
	flash.color = color
	flash.energy = energy
	if ResourceLoader.exists("res://assets/sprites/effects/shadow_circle.png"):
		flash.texture = load("res://assets/sprites/effects/shadow_circle.png")
	flash.texture_scale = 1.2
	get_tree().current_scene.add_child(flash)
	
	var tween := create_tween()
	tween.tween_property(flash, "energy", 0.0, 0.12)
	tween.finished.connect(flash.queue_free)


## Xử lý chuyển động linh hoạt (Agile Movement) và né tránh vật cản mượt mà
func execute_flexible_movement(dist: float, delta: float) -> void:
	# Xử lý gỡ kẹt tự động nếu bị chèn góc tường
	if unstuck_timer > 0.0:
		unstuck_timer -= delta
		rotation = rotate_toward(rotation, rotation + unstuck_turn_dir * 2.5, rotation_speed * delta)
		velocity = -Vector2.RIGHT.rotated(rotation) * reverse_speed
		move_and_slide()
		return
		
	var target_vector := Vector2.ZERO
	var desired_speed := move_speed
	
	match current_state:
		AIState.PATROL:
			if patrol_route.size() > 0:
				var waypoint: Vector2 = patrol_route[current_patrol_idx]
				target_vector = global_position.direction_to(waypoint)
				desired_speed = patrol_speed
				if global_position.distance_to(waypoint) < 55.0:
					current_patrol_idx = (current_patrol_idx + 1) % patrol_route.size()
			else:
				target_vector = Vector2.RIGHT.rotated(rotation)
				desired_speed = 0.0

		AIState.SEARCHING:
			# Lao đến vị trí cuối cùng nhìn thấy người chơi để lùng sục
			target_vector = global_position.direction_to(last_known_player_pos)
			desired_speed = move_speed * 0.95

		AIState.RETURNING_TO_POST:
			# Quay trở về vị trí phòng thủ cố định
			target_vector = global_position.direction_to(anchor_defense_point)
			desired_speed = move_speed
			
		AIState.GUARDING_POST:
			# Đứng giữ chốt cố định, xoay nhẹ canh gác hoặc de nhẹ giữ cự ly nếu bị áp sát
			if dist < kiting_distance:
				target_vector = current_target.global_position.direction_to(global_position)
				desired_speed = reverse_speed
			else:
				# Giữ vững vị trí, hướng thân xe theo tháp pháo
				var target_heading := turret.global_rotation
				rotation = rotate_toward(rotation, target_heading, rotation_speed * delta)
				velocity = velocity.lerp(Vector2.ZERO, 10.0 * delta)
				move_and_slide()
				return
				
		AIState.ADVANCING_ATTACK:
			# Chế độ Tấn công: Dồn dập lao về phía mục tiêu
			target_vector = global_position.direction_to(current_target.global_position)
			desired_speed = move_speed
			
		AIState.COMBAT_ENGAGE:
			if dist < kiting_distance:
				target_vector = current_target.global_position.direction_to(global_position)
				desired_speed = reverse_speed
			else:
				# Luồn lách theo phương ngang (strafe) quanh mục tiêu để né đạn
				var to_target := global_position.direction_to(current_target.global_position)
				var tangent := to_target.rotated(PI * 0.45 * combat_strafe_dir)
				target_vector = (to_target * 0.4 + tangent * 0.9).normalized()
				desired_speed = move_speed * 0.9
	
	# Tính toán hướng lái mượt mà với cảm biến né tường (Whisker Steering)
	var final_heading := calculate_steer_heading(target_vector)
	rotation = rotate_toward(rotation, final_heading, rotation_speed * delta)
	
	var forward := Vector2.RIGHT.rotated(rotation)
	velocity = forward * desired_speed
	move_and_slide()
	
	var tread_particles: CPUParticles2D = get_node_or_null("TreadParticles")
	if tread_particles:
		tread_particles.emitting = velocity.length() > 20.0
	
	# Kiểm tra phát hiện kẹt xe: Nếu có lệnh chạy mà vận tốc thực gần bằng 0 quá 0.5s
	if desired_speed > 50.0 and get_real_velocity().length() < 18.0:
		stuck_detect_timer += delta
		if stuck_detect_timer > 0.5:
			stuck_detect_timer = 0.0
			unstuck_timer = 0.45
			unstuck_turn_dir = 1.0 if randf() > 0.5 else -1.0
	else:
		stuck_detect_timer = 0.0

## Cảm biến né tường thông minh (Multi-feeler repulsion):
## Kết hợp vector mục tiêu với lực đẩy tường để lướt mượt mà men theo bờ tường thay vì đâm thẳng
func calculate_steer_heading(desired_dir: Vector2) -> float:
	var repulsion := Vector2.ZERO
	
	if feeler_front and feeler_front.is_colliding():
		repulsion += feeler_front.get_collision_normal() * 2.8
	if feeler_left and feeler_left.is_colliding():
		repulsion += feeler_left.get_collision_normal() * 1.6
	if feeler_right and feeler_right.is_colliding():
		repulsion += feeler_right.get_collision_normal() * 1.6
		
	var steer_vector := desired_dir
	if repulsion != Vector2.ZERO:
		steer_vector = (desired_dir + repulsion).normalized()
		
	return steer_vector.angle()

func take_damage(amount: int, is_aoe: bool = false) -> void:
	if not health_comp:
		return
		
	gunfire_reveal_timer = 2.2 # Lộ diện khi bị trúng đạn pháo hoặc súng máy
	
	# NGAY LẬP TỨC CHUYỂN SANG CHẾ ĐỘ TẤN CÔNG KHI BỊ TRÚNG ĐẠN!
	trigger_alert(true)
	
	var actual_damage := amount
	# Khiên phòng thủ giảm 50% sát thương nhận vào
	if is_shield_active:
		actual_damage = int(amount * 0.5)
	# Màn khói mù hấp thụ bớt 50% sát thương lạc
	if is_in_smoke:
		actual_damage = maxi(int(actual_damage * 0.5), 1)
		
	if defense_shield and is_shield_active:
		defense_shield.modulate = Color(2.5, 2.5, 3.5, 1.0)
		var tween := create_tween()
		tween.tween_property(defense_shield, "modulate", Color(0.3, 0.85, 1.0, 0.65), 0.25)
			
	health_comp.take_damage(actual_damage, is_aoe)

func _on_died() -> void:
	if explosion_vfx_scene:
		var vfx := explosion_vfx_scene.instantiate() as Node2D
		vfx.global_position = global_position
		get_parent().add_child(vfx)
	
	GlobalEvents.camera_shake_requested.emit(12.0, 0.45)
	AudioManager.play_explosion()
	queue_free()
