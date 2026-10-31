class_name FloatingHealthBar
extends Control

## Thanh máu đồ họa trôi nổi trên nóc xe tăng, cập nhật mượt mà khi nhận sát thương

@onready var progress_bar: ProgressBar = $ProgressBar

func setup(health_comp: HealthComponent, bar_color: Color = Color(0.9, 0.2, 0.2)) -> void:
	if not health_comp:
		return
	
	health_comp.health_changed.connect(_on_health_changed)
	if progress_bar:
		progress_bar.max_value = health_comp.max_health
		progress_bar.value = health_comp.current_health
		
		# Tùy chỉnh màu sắc (Đỏ cho địch, Xanh lá cho người chơi)
		var fill_style := StyleBoxFlat.new()
		fill_style.bg_color = bar_color
		fill_style.corner_radius_top_left = 3
		fill_style.corner_radius_top_right = 3
		fill_style.corner_radius_bottom_left = 3
		fill_style.corner_radius_bottom_right = 3
		progress_bar.add_theme_stylebox_override("fill", fill_style)

func _on_health_changed(current_hp: int, _max_hp: int) -> void:
	if progress_bar:
		var tween := create_tween()
		tween.tween_property(progress_bar, "value", float(current_hp), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
