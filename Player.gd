extends 'res://Cell.gd'

const Energy = preload('res://Energy.tscn')
const FEAST_COLDOWN = 2

var feastCD = 0
var targets = []

onready var fixedNode = get_node('Fixed')
onready var powerLabel = fixedNode.get_node('PowerLabel')
onready var camera = get_node('Camera2D')
onready var actionLabel = camera.get_node('ActionLabel')
onready var floatingLabel = get_node('FloatingLabel')
onready var animator2 = get_node('AnimationPlayer2')



func _ready():
		# Move to checkpoint
	if Global.playerSpawnPosition: set_global_position(Global.playerSpawnPosition)

	# Restore hp
	if Global.playerHp:
		hpMax = Global.playerHp
		hp = Global.playerHp

	actionLabel.set_text('')

	_update_power_display()
	_update_power_label()

	set_fixed_process(true)


func _fixed_process(delta):
	# Dead
	if !alive: return

	# Controls
	if Input.is_action_pressed("ui_left"):
		direction.x = -1
	elif Input.is_action_pressed("ui_right"):
		direction.x = 1
	else:
		direction.x = 0

	if Input.is_action_just_pressed("ui_up"):
		direction.y = -1

	if Input.is_action_just_pressed("ui_select"):
		_action()
	elif Input.is_action_just_pressed("ui_accept"):
		_kill_zombies()
	elif Input.is_action_just_pressed("ui_cancel"):
		get_tree().reload_current_scene()

	# Zombie feast
	feastCD += delta
	if feastCD >= FEAST_COLDOWN && get_tree().get_nodes_in_group(GROUP_NAME_ZOMBIE).size():
		feastCD = 0
		_feed_zombies()

	# Fixed camera node
	#printt()
	#fixedCameraNode.set_global_position(camera.get_camera_pos())


func _action():
	if target:
		if target.alive:
			_attack()
		else:
			# Reset feastCD if this is first zombie
			if !get_tree().get_nodes_in_group(GROUP_NAME_ZOMBIE).size(): feastCD = 0

			target._resurrect()
			_remove_from_targets(target)


func _zombies_do(action = ''):
	var zombies = get_tree().get_nodes_in_group(GROUP_NAME_ZOMBIE)

	# One shot
	if action == 'feed':
		Global.sfx('bubbleout')

	# Loop
	for zi in range(zombies.size()):
		if action == 'attack':
			zombies[zi].target = target

		elif action == 'die':
			zombies[zi]._die()

		elif action == 'feed':
			var energy = Energy.instance()

			zombies[zi].charger.add_child(energy)
			energy._send(charger.get_global_position() - zombies[zi].charger.get_global_position())

			_damage(1, null, true)


func _attack(): _zombies_do('attack')
func _kill_zombies(): _zombies_do('die')
func _feed_zombies(): _zombies_do('feed')


func _heal(amm = hpMax):
	hp = min(hp + amm, hpMax)
	animator2.play('heal')
	floatingLabel.set_text(str('+', amm, ' A-h'))

	_update_power_display()
	_update_power_label()


func _gain_power(power):
	hpMax += power
	_heal(power)


func _update_action_actionLabel():
	actionLabel.set_text('')

	if target:
		if target.alive:
			if get_tree().get_nodes_in_group(GROUP_NAME_ZOMBIE).size(): actionLabel.set_text('ATTACK')
		else:
			actionLabel.set_text('RESURRECT')


func _update_power_label():
	powerLabel.set_text(str(hp, '/', hpMax, ' Ah'))


func _remove_from_targets(t):
	var idx = targets.find(t)

	if idx > -1:
		targets.remove(idx)

	# Assign new target
	if targets.size():
		target = targets[0]
	else:
		target = null

	_update_action_actionLabel()


func _on_Area2D_body_entered(body):
	# Only not zombie cells
	if alive and body != self and body.is_in_group(GROUP_NAME_CELL) and !body.is_in_group(GROUP_NAME_ZOMBIE):
		targets.push_back(body)
		target = targets[0]

		_update_action_actionLabel()


func _on_Area2D_body_exited(body):
	if alive and body != self and body.is_in_group(GROUP_NAME_CELL) and !body.is_in_group(GROUP_NAME_ZOMBIE):
		_remove_from_targets(body)


func _on_dead():
	actionLabel.set_text('you ran out of power ;(')

	# Restart game after 1 sec
	var t = Timer.new()
	t.set_wait_time(1)
	t.set_one_shot(true)
	add_child(t)
	t.start()

	yield(t, 'timeout')
	get_tree().reload_current_scene()


func _on_hit(power):
	_gain_power(power)
	_update_action_actionLabel()


func _on_damage():
	_update_power_label()


func _on_checkpoint(): _heal()