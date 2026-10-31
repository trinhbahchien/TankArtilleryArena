class_name CameraShake
extends Camera2D

## Điều khiển rung chấn màn hình (Camera Shake) và Thu phóng bản đồ linh hoạt (Dynamic Map Zoom)
## Cho phép người chơi quan sát bản đồ rộng thoáng hoặc phóng to/thu nhỏ theo ý muốn.

@export var default_zoom_level: float = 0.65 # Tầm nhìn chiến trường rộng rãi mặc định
@export var min_zoom_level: float = 0.48     # Zoom out cực đại để bao quát toàn cảnh bản đồ
@export var max_zoom_level: float = 0.90     # Zoom in cận cảnh
@export var zoom_step: float = 0.05

var target_zoom: Vector2 = Vector2(0.65, 0.65)
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	original_offset = offset
	target_zoom = Vector2(default_zoom_level, default_zoom_level)
	zoom = target_zoom
	GlobalEvents.camera_shake_requested.connect(start_shake)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		# Lăn con lăn chuột xuống -> Thu nhỏ (Zoom out), mở rộng bản đồ
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var next_z := clampf(target_zoom.x - zoom_step, min_zoom_level, max_zoom_level)
			target_zoom = Vector2(next_z, next_z)
			get_viewport().set_input_as_handled()
		# Lăn con lăn chuột lên -> Phóng to (Zoom in)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var next_z := clampf(target_zoom.x + zoom_step, min_zoom_level, max_zoom_level)
			target_zoom = Vector2(next_z, next_z)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		# Phím tắt phụ: Phím [-] hoặc [[] để mở rộng bản đồ; phím [+] hoặc []] để thu gần
		if event.keycode == KEY_MINUS or event.keycode == KEY_BRACKETLEFT:
			var next_z := clampf(target_zoom.x - zoom_step, min_zoom_level, max_zoom_level)
			target_zoom = Vector2(next_z, next_z)
		elif event.keycode == KEY_EQUAL or event.keycode == KEY_BRACKETRIGHT:
			var next_z := clampf(target_zoom.x + zoom_step, min_zoom_level, max_zoom_level)
			target_zoom = Vector2(next_z, next_z)

func start_shake(intensity: float, duration: float) -> void:
	shake_intensity = maxf(shake_intensity, intensity)
	shake_duration = maxf(shake_duration, duration)

func _process(delta: float) -> void:
	# Nội suy mượt mà tỷ lệ thu phóng camera
	if zoom.distance_to(target_zoom) > 0.001:
		zoom = zoom.lerp(target_zoom, 8.0 * delta)

	# Xử lý rung chấn
	if shake_duration > 0.0:
		shake_duration -= delta
		offset = original_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = lerpf(shake_intensity, 0.0, 8.0 * delta)
	else:
		offset = original_offset
		shake_intensity = 0.0
