class_name TankChassis
extends CharacterBody2D

## Điều khiển chuyển động thân xe tăng 2D và Kỹ năng tác chiến:
## - Di chuyển: WASD / Mũi tên (tiến, lùi, xoay thân xe).
## - Kỹ năng [Q]: Tự sửa chữa khẩn cấp (+35 HP, Cooldown 12s).
## - Kỹ năng [E]: Thả khói mù ngụy trang (Kéo dài 6s, Cooldown 14s, AI mất dấu, giảm 50% dmg).

signal repair_used(cooldown: float, heal_amount: int)
signal smoke_used(cooldown: float, duration: float)
signal smoke_state_changed(is_active: bool)

@export var move_speed: float = 280.0
@export var reverse_speed: float = 190.0
@export var rotation_speed: float = 4.2
@export var acceleration: float = 16.0
@export var friction: float = 18.0

# Thông số Kỹ năng Tự sửa chữa [Q]
@export var repair_heal_amount: int = 35
@export var repair_cooldown: float = 12.0
var repair_timer: float = 0.0

# Thông số Kỹ năng Thả khói [E] (Màn khói mù cố định)
@export var smoke_cooldown: float = 14.0
@export var smoke_duration: float = 6.0
@export var smoke_screen_scene: PackedScene = preload("res://scenes/vfx/SmokeScreenCloud.tscn")
var smoke_timer: float = 0.0
var is_in_smoke: bool = false
var is_in_bush: bool = false
var bush_reveal_timer: float = 0.0

var current_speed: float = 0.0

@onready var chassis_sprite: Sprite2D = $ChassisSprite
@onready var health_comp: HealthComponent = $HealthComponent
@onready var health_bar: FloatingHealthBar = $FloatingHealthBar
@onready var damage_smoke: CPUParticles2D = get_node_or_null("DamageSmokeParticles")
@onready var repair_particles: CPUParticles2D = get_node_or_null("RepairParticles")

func _ready() -> void:
	add_to_group("player")
	if health_comp and health_bar:
		health_bar.setup(health_comp, Color(0.2, 0.85, 0.3))
		health_comp.died.connect(_on_died)
		health_comp.health_changed.connect(_on_health_changed)

func _on_health_changed(current_hp: int, max_hp: int) -> void:
	# Báo động sắp hỏng xe: Khi máu <= 35%, xả khói đen mịt mù từ đuôi xe
	if damage_smoke:
		damage_smoke.emitting = (float(current_hp) / float(max_hp) <= 0.35)

func _process(delta: float) -> void:
	# Cập nhật thời gian hồi chiêu
	if repair_timer > 0.0:
		repair_timer = maxf(repair_timer - delta, 0.0)
	if smoke_timer > 0.0:
		smoke_timer = maxf(smoke_timer - delta, 0.0)
	if bush_reveal_timer > 0.0:
		bush_reveal_timer = maxf(bush_reveal_timer - delta, 0.0)

func notify_gunfire() -> void:
	if is_in_bush:
		bush_reveal_timer = 2.5

func is_concealed() -> bool:
	if is_in_smoke:
		return true
	if is_in_bush and bush_reveal_timer <= 0.0:
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or (health_comp and health_comp.current_health <= 0):
		return
		
	# Phím Q: Tự sửa chữa khẩn cấp | Phím E: Thả khói mù ngụy trang
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_Q:
			trigger_self_repair()
		elif event.keycode == KEY_E:
			trigger_smoke_screen()

## Kích hoạt Tự sửa chữa [Q] (+35 HP)
func trigger_self_repair() -> void:
	if repair_timer > 0.0 or not health_comp:
		return
		
	# Không cần sửa nếu đã đầy máu
	if health_comp.current_health >= health_comp.max_health:
		return
		
	repair_timer = repair_cooldown
	health_comp.heal(repair_heal_amount)
	repair_used.emit(repair_cooldown, repair_heal_amount)
	
	if repair_particles:
		repair_particles.restart()
		repair_particles.emitting = true
		
	AudioManager.play_heal()

## Kích hoạt Thả khói mù ngụy trang [E] (Màn khói cố định tại vị trí kích hoạt)
func trigger_smoke_screen() -> void:
	if smoke_timer > 0.0:
		return
		
	smoke_timer = smoke_cooldown
	smoke_used.emit(smoke_cooldown, smoke_duration)
	
	if smoke_screen_scene:
		var cloud := smoke_screen_scene.instantiate() as Node2D
		cloud.global_position = global_position
		get_parent().add_child(cloud)


func _physics_process(delta: float) -> void:
	handle_movement(delta)

func handle_movement(delta: float) -> void:
	# 1. Xoay thân xe (A/D hoặc phím mũi tên)
	var steer_input := Input.get_axis("turn_left", "turn_right")
	if steer_input != 0.0:
		rotation += steer_input * rotation_speed * delta

	# 2. Tiến / lùi (W/S)
	var throttle_input := Input.get_axis("move_down", "move_up")
	var target_speed := 0.0
	
	if throttle_input > 0.0:
		target_speed = throttle_input * move_speed
	elif throttle_input < 0.0:
		target_speed = throttle_input * reverse_speed
	
	# Gia tốc mượt mà
	if target_speed != 0.0:
		current_speed = lerpf(current_speed, target_speed, acceleration * delta)
	else:
		current_speed = lerpf(current_speed, 0.0, friction * delta)
	
	# 3. Di chuyển theo hướng mũi xe
	var forward_dir := Vector2.RIGHT.rotated(rotation)
	velocity = forward_dir * current_speed
	
	move_and_slide()
	
	# Bật bụi xích đôi khi di chuyển hoặc quay xe tại chỗ
	var is_moving := absf(current_speed) > 15.0 or (steer_input != 0.0 and absf(current_speed) > 5.0)
	var left_tread: CPUParticles2D = get_node_or_null("LeftTreadParticles")
	var right_tread: CPUParticles2D = get_node_or_null("RightTreadParticles")
	var tread_particles: CPUParticles2D = get_node_or_null("TreadParticles")
	if left_tread:
		left_tread.emitting = is_moving
	if right_tread:
		right_tread.emitting = is_moving
	if tread_particles:
		tread_particles.emitting = is_moving

func take_damage(amount: int, is_aoe: bool = false) -> void:
	# Nếu đang ở trong màn khói -> Giảm 50% sát thương
	var final_dmg := amount
	if is_in_smoke:
		final_dmg = maxi(int(amount * 0.5), 1)
		
	if health_comp:
		health_comp.take_damage(final_dmg, is_aoe)
	else:
		if chassis_sprite:
			chassis_sprite.modulate = Color(2.0, 0.4, 0.4)
			var tween := create_tween()
			tween.tween_property(chassis_sprite, "modulate", Color.WHITE, 0.2)

func _on_died() -> void:
	# Xe người chơi bị phá hủy
	GlobalEvents.camera_shake_requested.emit(16.0, 0.6)
	GlobalEvents.game_state_changed.emit("DEFEAT")
