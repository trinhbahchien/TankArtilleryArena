class_name MammothBossAI
extends CharacterBody2D

## Trùm Cuối: Siêu Pháo Hạm Mặt Đất "Mammoth Tank" (Boss Phase 5)
## - Xe tăng khổng lồ 350 HP, giáp dày, di chuyển uy lực và chậm rãi.
## - Vũ khí kép: Pháo đại bác nòng đôi (bắn 2 quả pháo cối cùng lúc) + Súng máy liên thanh 3 tia rẻ quạt.
## - Tích hợp đầy đủ Fog of War, cơ chế mù khi vào khói và xả khói đen cảnh báo khi sắp bị tiêu diệt.

@export var move_speed: float = 135.0
@export var rotation_speed: float = 2.2
@export var turret_speed: float = 2.0
@export var min_artillery_range: float = 200.0
@export var max_artillery_range: float = 780.0
@export var artillery_cooldown: float = 3.8
@export var mg_cooldown: float = 0.2

@export var artillery_shell_scene: PackedScene = preload("res://scenes/weapons/ArtilleryShell.tscn")
@export var enemy_mg_bullet_scene: PackedScene = preload("res://scenes/weapons/EnemyMachineGunBullet.tscn")
@export var explosion_vfx_scene: PackedScene = preload("res://scenes/vfx/ExplosionVFX.tscn")

var artillery_timer: float = 1.5
var mg_timer: float = 0.0
var current_target: Node2D = null

# Cơ chế Fog of War & Khói mù
var is_in_smoke: bool = false
var is_visible_to_player: bool = true
var gunfire_reveal_timer: float = 0.0
@export var proximity_reveal_dist: float = 180.0

@onready var turret: Node2D = $Turret
@onready var muzzle_left: Marker2D = $Turret/MuzzleLeft
@onready var muzzle_right: Marker2D = $Turret/MuzzleRight
@onready var mg_muzzle: Marker2D = $Turret/MGMuzzle
@onready var health_comp: HealthComponent = $HealthComponent
@onready var health_bar: FloatingHealthBar = $FloatingHealthBar
@onready var state_label: Label = $StateLabel
@onready var damage_smoke: CPUParticles2D = get_node_or_null("DamageSmokeParticles")

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	
	if health_comp and health_bar:
		health_bar.setup(health_comp, Color(1.0, 0.2, 0.2))
		health_comp.died.connect(_on_died)
		health_comp.health_changed.connect(_on_health_changed)
		
	find_target()

func _on_health_changed(current_hp: int, max_hp: int) -> void:
	# Xe sắp phát nổ: Khói đen cuồn cuộn khi HP <= 35% (<= 120 HP)
	if damage_smoke:
		damage_smoke.emitting = (float(current_hp) / float(max_hp) <= 0.35)

func find_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		current_target = players[0] as Node2D

func _process(delta: float) -> void:
	if artillery_timer > 0.0:
		artillery_timer = maxf(artillery_timer - delta, 0.0)
	if mg_timer > 0.0:
		mg_timer = maxf(mg_timer - delta, 0.0)
	if gunfire_reveal_timer > 0.0:
		gunfire_reveal_timer = maxf(gunfire_reveal_timer - delta, 0.0)
		
	update_fog_of_war_visibility(delta)

func update_fog_of_war_visibility(delta: float) -> void:
	if not is_instance_valid(current_target):
		find_target()
		if not is_instance_valid(current_target):
			return
			
	if is_in_smoke:
		is_visible_to_player = false
	else:
		var dist := global_position.distance_to(current_target.global_position)
		if dist <= proximity_reveal_dist or gunfire_reveal_timer > 0.0:
			is_visible_to_player = true
		else:
			var space_state := get_world_2d().direct_space_state
			var query := PhysicsRayQueryParameters2D.create(global_position, current_target.global_position)
			query.collision_mask = 1
			query.exclude = [get_rid(), current_target.get_rid()]
			var hit := space_state.intersect_ray(query)
			is_visible_to_player = hit.is_empty()
			
	var target_alpha := 1.0 if is_visible_to_player else 0.0
	modulate.a = lerpf(modulate.a, target_alpha, 10.0 * delta)
	
	if health_bar:
		health_bar.visible = (is_visible_to_player and modulate.a > 0.3)
	if state_label:
		state_label.visible = (is_visible_to_player and modulate.a > 0.3)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(current_target):
		find_target()
		if not is_instance_valid(current_target):
			return
			
	var dist := global_position.distance_to(current_target.global_position)
	
	# 1. Quay tháp pháo về mục tiêu nếu không bị khói mù che khuất
	if not is_in_smoke and not _is_target_in_smoke():
		var to_target := (current_target.global_position - turret.global_position).angle()
		turret.global_rotation = rotate_toward(turret.global_rotation, to_target, turret_speed * delta)
		
		# 2. Đánh giá và khai hỏa song pháo & súng máy
		evaluate_boss_combat(dist)
		
	# 3. Di chuyển dũng mãnh tiến về phía người chơi
	handle_movement(dist, delta)

func _is_target_in_smoke() -> bool:
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

func evaluate_boss_combat(dist: float) -> void:
	if dist > max_artillery_range + 60.0:
		return
		
	var angle_to_target := (current_target.global_position - turret.global_position).angle()
	var angle_err := absf(angle_difference(turret.global_rotation, angle_to_target))
	if angle_err > 0.4:
		return
		
	# Bắn pháo cối song song 2 nòng
	if artillery_timer <= 0.0 and dist >= min_artillery_range and dist <= max_artillery_range:
		fire_twin_artillery(dist)
		
	# Bắn súng máy rẻ quạt 3 tia
	if mg_timer <= 0.0 and dist <= 500.0:
		fire_spread_machinegun()

## Khai hỏa Đại bác nòng đôi (Twin Cannon Fire)
func fire_twin_artillery(dist: float) -> void:
	artillery_timer = artillery_cooldown
	gunfire_reveal_timer = 2.2
	
	var target_pos := current_target.global_position
	if current_target is CharacterBody2D:
		target_pos += (current_target as CharacterBody2D).velocity * 0.5
		
	# Quả 1: Nòng trái
	if muzzle_left and artillery_shell_scene:
		var shell1 := artillery_shell_scene.instantiate() as ArtilleryShell
		get_tree().current_scene.add_child(shell1)
		shell1.initialize(muzzle_left.global_position, target_pos + Vector2(-25, -15))
		
	# Quả 2: Nòng phải (bắn kèm)
	if muzzle_right and artillery_shell_scene:
		var shell2 := artillery_shell_scene.instantiate() as ArtilleryShell
		get_tree().current_scene.add_child(shell2)
		shell2.initialize(muzzle_right.global_position, target_pos + Vector2(25, 15))
		
	AudioManager.play_cannon()
	trigger_muzzle_flash_light(muzzle_left.global_position, Color(1.0, 0.7, 0.3), 3.0)
	trigger_muzzle_flash_light(muzzle_right.global_position, Color(1.0, 0.7, 0.3), 3.0)
	GlobalEvents.camera_shake_requested.emit(8.0, 0.3)

@export var enemy_shotgun_scene: PackedScene = preload("res://scenes/weapons/ShotgunPellet.tscn")

## Khai hỏa Súng máy rẻ quạt 3 tia (Triple Spread MG) hoặc Shotgun áp sát
func fire_spread_machinegun() -> void:
	mg_timer = mg_cooldown
	gunfire_reveal_timer = 1.5
	if not mg_muzzle:
		return
		
	var start_pos := mg_muzzle.global_position
	var base_angle := turret.global_rotation

	# Nếu người chơi áp sát trong cự ly 280 px: Trùm xả chùm Shotgun 5 mảnh đạn uy lực cực lớn
	var dist_to_tgt := global_position.distance_to(current_target.global_position) if is_instance_valid(current_target) else 999.0
	if dist_to_tgt <= 280.0 and enemy_shotgun_scene:
		mg_timer = 0.95
		var spread := [-0.25, -0.12, 0.0, 0.12, 0.25]
		for offset_angle in spread:
			var pellet = enemy_shotgun_scene.instantiate()
			get_tree().current_scene.add_child(pellet)
			pellet.initialize(start_pos, Vector2.RIGHT.rotated(base_angle + offset_angle), true)
		AudioManager.play_cannon()
		trigger_muzzle_flash_light(start_pos, Color(1.0, 0.5, 0.2), 2.2)
		return
		
	if not enemy_mg_bullet_scene:
		return
		
	var spread_angles := [-0.14, 0.0, 0.14]
	for offset_angle in spread_angles:
		var bullet := enemy_mg_bullet_scene.instantiate() as EnemyMachineGunBullet
		get_tree().current_scene.add_child(bullet)
		bullet.initialize(start_pos, Vector2.RIGHT.rotated(base_angle + offset_angle))
		
	AudioManager.play_machinegun()
	trigger_muzzle_flash_light(start_pos, Color(1.0, 0.9, 0.4), 1.6)

func trigger_muzzle_flash_light(pos: Vector2, color: Color = Color(1.0, 0.8, 0.4), energy: float = 2.0) -> void:
	var flash := PointLight2D.new()
	flash.global_position = pos
	flash.color = color
	flash.energy = energy
	if ResourceLoader.exists("res://assets/sprites/effects/shadow_circle.png"):
		flash.texture = load("res://assets/sprites/effects/shadow_circle.png")
	flash.texture_scale = 1.4
	get_tree().current_scene.add_child(flash)
	
	var tween := create_tween()
	tween.tween_property(flash, "energy", 0.0, 0.13)
	tween.finished.connect(flash.queue_free)


func handle_movement(dist: float, delta: float) -> void:
	var target_heading := (current_target.global_position - global_position).angle()
	rotation = rotate_toward(rotation, target_heading, rotation_speed * delta)
	
	var desired_speed := 0.0
	if dist > 340.0:
		desired_speed = move_speed
	elif dist < 220.0:
		desired_speed = -move_speed * 0.6 # Lùi lại giữ khoảng cách pháo
		
	velocity = Vector2.RIGHT.rotated(rotation) * desired_speed
	move_and_slide()

func take_damage(amount: int, is_aoe: bool = false) -> void:
	if not health_comp:
		return
	gunfire_reveal_timer = 2.2
	var final_dmg := amount
	if is_in_smoke:
		final_dmg = maxi(int(amount * 0.5), 1)
	health_comp.take_damage(final_dmg, is_aoe)

func _on_died() -> void:
	# Nổ liên hoàn quy mô lớn khi trùm bị tiêu diệt
	for i in range(3):
		if explosion_vfx_scene:
			var vfx := explosion_vfx_scene.instantiate() as Node2D
			vfx.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
			get_parent().add_child(vfx)
			
	GlobalEvents.camera_shake_requested.emit(24.0, 0.8)
	AudioManager.play_explosion()
	queue_free()
