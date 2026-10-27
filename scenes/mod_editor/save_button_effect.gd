extends CPUParticles2D

func _process(delta):
	emitting = not get_parent().disabled
