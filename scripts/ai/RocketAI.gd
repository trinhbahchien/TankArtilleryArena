class_name RocketAI
extends CharacterBody2D

## Kẻ địch Chiến xa Phóng Tên Lửa (Rocket Tank):
## - Tác chiến ở cự ly tầm trung & xa (350 - 600 px).
## - Bắn loạt 2 rocket đạn đạo rơi xuống vị trí người chơi với điểm cảnh báo mặt đất.

@export var move_speed: float = 175.0
@export var attack_range: float = 620.0
@export var salvo_cooldown: float = 4.8
@export var rocket_damage: int = 35

@export var rocket_scene: PackedScene = preload("res://scenes/weapons/HomingRocket.tscn")
@export var explosion_vfx: PackedScene = preload("res://scenes/vfx/ExplosionVFX.tscn")

var player_target: CharacterBody2D = null
var cooldown_timer: float = 2.5

@onready var turret: Node2D = $Turret
@onready var muzzle_left: Marker2D = $Turret/MuzzleLeft
@onready var muzzle_right: Marker2D = $Turret/MuzzleRight
@onready var health_comp: HealthComponent = $HealthComponent

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("enemies")
	var hp_bar = get_node_or_null("FloatingHealthBar")
	if hp_bar and health_comp:
		hp_bar.setup(health_comp, Color(1.0, 0.55, 0.2))
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
			tw.tween_property(chassis, "modulate", Color(0.9, 0.6, 0.2), 0.08)

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
	
	if turret:
		turret.look_at(player_target.global_position)

	var player_in_smoke: bool = false
	if player_target.has_method("is_concealed"):
		player_in_smoke = player_target.is_concealed()
	elif "is_in_smoke" in player_target:
		player_in_smoke = player_target.is_in_smoke

	# Di chuyển giữ cự ly 400 - 550 px
	if dist < 360.0:
		velocity = -dir_to_player * move_speed
		rotation = lerp_angle(rotation, (-dir_to_player).angle(), 3.5 * delta)
	elif dist > 550.0 and not player_in_smoke:
		velocity = dir_to_player * move_speed
		rotation = lerp_angle(rotation, dir_to_player.angle(), 3.5 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 3.0 * delta)

	move_and_slide()

	if dist <= attack_range and not player_in_smoke and cooldown_timer <= 0.0:
		_fire_rocket_salvo()

func _fire_rocket_salvo() -> void:
	cooldown_timer = salvo_cooldown
	if not rocket_scene:
		return
		
	# Bắn rocket 1 từ muzzle_left
	var r1 = rocket_scene.instantiate()
	get_parent().add_child(r1)
	var base_dir := Vector2.RIGHT.rotated(turret.global_rotation)
	if r1.has_method("initialize"):
		var m_pos := muzzle_left.global_position if muzzle_left else global_position
		r1.initialize(m_pos, base_dir.rotated(-0.15), player_target)
		r1.damage = rocket_damage
	
	AudioManager.play_cannon()
	
	# Bắn rocket 2 lệch 0.15s từ muzzle_right
	get_tree().create_timer(0.18).timeout.connect(func():
		if is_instance_valid(self) and is_instance_valid(turret) and is_instance_valid(player_target):
			var r2 = rocket_scene.instantiate()
			get_parent().add_child(r2)
			var cur_dir := Vector2.RIGHT.rotated(turret.global_rotation)
			var m2_pos := muzzle_right.global_position if muzzle_right else global_position
			if r2.has_method("initialize"):
				r2.initialize(m2_pos, cur_dir.rotated(0.15), player_target)
				r2.damage = rocket_damage
			AudioManager.play_cannon()
	)

func _on_destroyed() -> void:
	if explosion_vfx:
		var vfx := explosion_vfx.instantiate() as Node2D
		vfx.global_position = global_position
		get_parent().add_child(vfx)
	AudioManager.play_explosion()
	queue_free()
