extends TextureRect


var rotator_speed = 80
var conveyor_speed = 1
var conveyor_frame = 0



func _SpriteBank_updated():
	if not is_instance_valid(contentClass):
		texture = null
		$Rotator.texture = null
		$Top.texture = null
		$Rotator.hide()
		$Top.hide()
		return

	var mod_class: ModClass = contentClass.modClass
	if not is_instance_valid(mod_class):
		texture = null
		$Rotator.texture = null
		$Top.texture = null
		$Rotator.hide()
		$Top.hide()
		if material:
			material.set_shader_parameter("water_effect", false)
		return

	if contentClass.ClassType == "mod":
		texture = mod_class.get_mod_icon()
	else:
		texture = mod_class.get_sprite(get_only_filename(contentClass.Path))
		$Rotator.texture = mod_class.get_sprite(get_only_filename(contentClass.Path) + "-rotator")
		$Top.texture = mod_class.get_sprite(get_only_filename(contentClass.Path) + "-top")

	if material:
		material.set_shader_parameter("water_effect", false)
	$Rotator.hide()
	$Top.hide()

	if contentClass.ClassType == "Drill":
		$Rotator.show()
		$Top.show()
		var drill_time: Variant = contentClass.get_effective_value("drillTime")
		if (typeof(drill_time) == TYPE_INT or typeof(drill_time) == TYPE_FLOAT) \
		and drill_time != 0:
			rotator_speed = 360 / (drill_time / 100)
	if contentClass.ContentType in ["Conveyor", "ArmoredConveyor"]:
		var speed: Variant = contentClass.get_effective_value("speed")
		if typeof(speed) == TYPE_INT or typeof(speed) == TYPE_FLOAT:
			conveyor_speed = speed
	if contentClass.ClassType == "Floor":
		var is_liquid: Variant = contentClass.get_effective_value("isLiquid", false)
		if material:
			material.set_shader_parameter("water_effect", is_liquid)





var contentClass: ContentClass:
	set = _set_contentClass

func _set_contentClass(value):
	if is_instance_valid(contentClass):
		var previous_mod: ModClass = contentClass.modClass
		if is_instance_valid(previous_mod) \
		and previous_mod.SpriteBank_updated.is_connected(_SpriteBank_updated):
			previous_mod.SpriteBank_updated.disconnect(_SpriteBank_updated)
	contentClass = value
	if is_instance_valid(contentClass):
		var current_mod: ModClass = contentClass.modClass
		if is_instance_valid(current_mod) \
		and not current_mod.SpriteBank_updated.is_connected(_SpriteBank_updated):
			current_mod.SpriteBank_updated.connect(_SpriteBank_updated)
	
	_SpriteBank_updated()
	

func _exit_tree() -> void:
	if is_instance_valid(contentClass):
		var mod_class: ModClass = contentClass.modClass
		if is_instance_valid(mod_class) \
		and mod_class.SpriteBank_updated.is_connected(_SpriteBank_updated):
			mod_class.SpriteBank_updated.disconnect(_SpriteBank_updated)


func get_only_filename(path):
	return path.get_file().substr(0, -1+path.get_file().length()-path.get_file().get_extension().length())






func update_conveyor():
	if is_instance_valid(contentClass) and is_instance_valid(contentClass.modClass):
		if contentClass.ClassType in ["Conveyor", "ArmoredConveyor"]:
			if conveyor_frame > 2:
				conveyor_frame = 0
			else:
				conveyor_frame += 1
			
			texture = contentClass.modClass.get_sprite(
				get_only_filename(contentClass.Path) + "-0-" + str(conveyor_frame)
			)
			
			await get_tree().create_timer((1/((140*conveyor_speed)/3))/8).timeout.connect(update_conveyor)
		

# Called when the node enters the scene tree for the first time.
func _ready():
	await update_conveyor()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_instance_valid(contentClass):
		if contentClass.ClassType == "Drill":
			$Rotator.set_rotation_degrees($Rotator.get_rotation_degrees()-(60*delta))
			$Rotator.pivot_offset = $Rotator.size/2
			
