class_name ExplosionVFX
extends Node2D

## Hiệu ứng nổ hạt và khói khi pháo chạm đất

@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var smoke_particles: CPUParticles2D = $SmokeParticles

func _ready() -> void:
	if particles:
		particles.emitting = true
	if smoke_particles:
		smoke_particles.emitting = true
	
	# Tự động hủy sau khi hạt tan hết (0.75 giây)
	var timer := get_tree().create_timer(0.75)
	timer.timeout.connect(queue_free)
