class_name SniperAI
extends CharacterBody2D

## Kẻ địch Chiến xa Bắn Tỉa (Sniper Tank):
## - Tác chiến ở cự ly xa (500 - 750 px).
## - Chiếu tia Laser đỏ khóa mục tiêu trong 1.3s trước khi bắn phát đạn xuyên giáp cực mạnh.
## - Cho phép người chơi nhận biết và dùng Khói mù [E] hoặc nấp sau tường để phá khóa.

@export var move_speed: float = 160.0
@export var sniper_range: float = 750.0
@export var fire_cooldown: float = 4.2
@export var charge_time: float = 1.3
@export var bullet_damage: int = 45

@export var bullet_scene: PackedScene = preload("res://scenes/weapons/EnemyMachineGunBullet.tscn")
@export var explosion_vfx: PackedScene = preload("res://scenes/vfx/ExplosionVFX.tscn")

var player_target: CharacterBody2D = null
var cooldown_timer: float = 2.0
var charge_timer: float = 0.0
var is_charging: bool = false
var laser_end_point: Vector2 = Vector2.ZERO

@onready var turret: Node2D = $Turret
@onready var muzzle: Marker2D = $Turret/Muzzle
@onready var health_comp: HealthComponent = $HealthComponent
@onready var laser_line: Line2D = $Turret/LaserSight

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("enemies")
	var hp_bar = get_node_or_null("FloatingHealthBar")
	if hp_bar and health_comp:
		hp_bar.setup(health_comp, Color(0.2, 0.6, 1.0))
	if health_comp:
		health_comp.died.connect(_on_destroyed)

func take_damage(amount: int, is_aoe: bool = false) -> void:
	trigger_alert(true)
	if health_comp:
		health_comp.take_damage(amount, is_aoe)
		var chassis = get_node_or_null("ChassisSprite")
		if chassis:
			var tw = create_tween()
			tw.tween_property(chassis, "modulate", Color(2.5, 2.5, 2.5), 0.05)
			tw.tween_property(chassis, "modulate", Color(0.4, 0.7, 1.1), 0.08)

func trigger_alert(spread_to_allies: bool = true) -> void:
	if spread_to_allies:
		var enemies := get_tree().get_nodes_in_group("enemy")
		for e in enemies:
			if is_instance_valid(e) and e != self and e.global_position.distance_to(global_position) <= 450.0:
				if e.has_method("trigger_alert"):
					e.trigger_alert(false)

func _process(delta: float) -> void:
	if not is_instance_valid(player_target):
		player_target = get_tree().get_first_node_in_group("player") as CharacterBody2D
		return

	if cooldown_timer > 0.0:
		cooldown_timer = maxf(cooldown_timer - delta, 0.0)

	var dist := global_position.distance_to(player_target.global_position)
	var dir_to_player := (player_target.global_position - global_position).normalized()
	
	# Quay tháp pháo về phía người chơi
	if turret:
		turret.look_at(player_target.global_position)

	# Kiểm tra người chơi có đang ẩn thân (khói hoặc bụi cây) không
	var player_in_smoke: bool = false
	if player_target.has_method("is_concealed"):
		player_in_smoke = player_target.is_concealed()
	elif "is_in_smoke" in player_target:
		player_in_smoke = player_target.is_in_smoke
	
	# Di chuyển giữ cự ly bắn tỉa tối ưu (500 - 650 px)
	if dist < 420.0:
		# Quá gần -> Lùi xe lại
		velocity = -dir_to_player * move_speed
		rotation = lerp_angle(rotation, (-dir_to_player).angle(), 4.0 * delta)
	elif dist > 680.0 and not player_in_smoke:
		# Quá xa -> Tiến lên từ từ
		velocity = dir_to_player * (move_speed * 0.8)
		rotation = lerp_angle(rotation, dir_to_player.angle(), 4.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 3.0 * delta)
		
	move_and_slide()

	# Quản lý ngắm bắn Laser & Khai hỏa
	if dist <= sniper_range and not player_in_smoke:
		if cooldown_timer <= 0.0 and not is_charging:
			# Bắt đầu khóa mục tiêu
			is_charging = true
			charge_timer = charge_time
			if laser_line:
				laser_line.visible = true

		if is_charging:
			charge_timer -= delta
			_update_laser_aim()
			if charge_timer <= 0.0:
				_fire_sniper_shot()
	else:
		# Mất dấu hoặc người chơi ẩn vào khói -> Hủy ngắm
		is_charging = false
		if laser_line:
			laser_line.visible = false

func _update_laser_aim() -> void:
	if not laser_line or not muzzle or not player_target:
		return
	var m_pos := muzzle.global_position
	var t_pos := player_target.global_position
	
	# Chiếu tia laser từ họng súng đến người chơi
	laser_line.global_position = Vector2.ZERO
	laser_line.rotation = 0.0
	laser_line.clear_points()
	laser_line.add_point(m_pos)
	
	# Raycast kiểm tra vật cản
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(m_pos, t_pos, 1) # Layer 1 = Obstacles
	var hit := space.intersect_ray(query)
	if hit:
		laser_line.add_point(hit.position)
	else:
		laser_line.add_point(t_pos)
		
	# Laser nhấp nháy đỏ rực rỡ khi sắp bắn
	var charge_pct := 1.0 - (charge_timer / charge_time)
	laser_line.default_color = Color(1.0, 0.1, 0.1, 0.4 + charge_pct * 0.6)
	laser_line.width = lerpf(1.5, 3.5, charge_pct)

func _fire_sniper_shot() -> void:
	is_charging = false
	cooldown_timer = fire_cooldown
	if laser_line:
		laser_line.visible = false
		
	if not muzzle or not bullet_scene:
		return
		
	var shoot_dir := Vector2.RIGHT.rotated(turret.global_rotation)
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	if bullet.has_method("initialize"):
		bullet.initialize(muzzle.global_position, shoot_dir)
		bullet.damage = bullet_damage
		bullet.speed = 880.0 # Tốc độ đạn cực nhanh
		
	AudioManager.play_cannon()
	GlobalEvents.camera_shake_requested.emit(5.0, 0.2)

func _on_destroyed() -> void:
	if explosion_vfx:
		var vfx := explosion_vfx.instantiate() as Node2D
		vfx.global_position = global_position
		get_parent().add_child(vfx)
	AudioManager.play_explosion()
	queue_free()
