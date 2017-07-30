extends KinematicBody2D

signal dead
signal hit
signal damage

const ACCELERATION = 16.0
const SPEED = 200.0
const GRAVITY = 20.0
const DAMP = .8
const JUMP_VELOCITY = -420.0
const STATE_MOVE = 'move'
const STATE_IDLE = 'idle'
const FOLLOW_DISTANCE = 100.0
const ATTACK_DISTANCE = 40.0
const GROUP_NAME_ZOMBIE = 'zombie'
const GROUP_NAME_CELL = 'cell'
const GROUP_NAME_PLAYER = 'player'
const SOLID_CELL_COLLISION_MASK_ID = 1

export var hpMax = 10.0
export var alive = true
export var energyPerHit = 1.0

var velocity = Vector2()
var direction = Vector2()
var following
var target
var state = 'idle'
var hp = hpMax

onready var animator = get_node('AnimationPlayer')
onready var display = get_node('Body/Display')
onready var charger = get_node('Body/Charger')
onready var steps = get_node('Steps')


func _ready():
	set_fixed_process(true)

	connect('dead', self, '_on_dead')
	connect('damage', self, '_on_damage')
	connect('hit', self, '_on_hit', [energyPerHit])

	# Turn to zombie
	if alive:
		_live()
	else:
		_die(true)


func _fixed_process(delta):
	steps.set_emitting(false)
	var onGround = test_move(get_global_transform(), Vector2(0, 1))

	# Gravity
	if !onGround:
		velocity.y += GRAVITY

	else:
		velocity.y = 0

		# Jump
		if direction.y < 0:
			velocity.y = JUMP_VELOCITY
			Global.sfx('jump')

		direction.y = 0

	# Movement
	if direction.x:
		velocity.x += direction.normalized().x * ACCELERATION
		velocity.x = clamp(velocity.x, -SPEED, SPEED)
		state = STATE_MOVE

		steps.set_emitting(true)
	else:
		velocity.x *= DAMP
		state = STATE_IDLE

		if abs(velocity.x) < ACCELERATION: velocity.x = 0

	#if is_colliding():
		#move(get_collision_normal().slide(velocity) * delta)
	#else:
	#move(velocity * delta)
	move_and_slide(velocity)

	# Animation
	if [STATE_IDLE, STATE_MOVE].find(animator.get_current_animation()) > -1 and state != animator.get_current_animation(): animator.play(state)

	# Is zombie
	if !alive and is_in_group(GROUP_NAME_ZOMBIE):

		# Have target, approach
		if target:

			# Target only living
			if target.alive:
				var distanceToTarget = target.get_global_position() - get_global_position()

				# Target = player
				if target.is_in_group(GROUP_NAME_PLAYER):
					# Get closer
					if abs(distanceToTarget.x) > FOLLOW_DISTANCE + FOLLOW_DISTANCE * _get_follow_queue_index():
						direction.x = (distanceToTarget).normalized().x
					else: # Stop
						direction.x = 0

				# Target = cell, attack!
				else:
					# Get closer
					if abs(distanceToTarget.x) > ATTACK_DISTANCE:
						direction.x = (distanceToTarget).normalized().x
					else: # Stop
						target._damage(1, (distanceToTarget).normalized().x)

						target = get_parent().get_node('Player')
						target.emit_signal('hit')
						direction.x = 0
			else:
				target = get_parent().get_node('Player')
		else:
			target = get_parent().get_node('Player')

	# Falls of
	if get_global_position().y > Global.DEAD_HEIGHT:
		set_fixed_process(false)

		if is_in_group(GROUP_NAME_PLAYER):
			_die()
			hide()
		else:
			queue_free()


func _live():
	animator.play('live')
	remove_from_group(GROUP_NAME_ZOMBIE)
	direction *= 0
	hp = hpMax
	_update_collision_layer()
	_update_power_display()
	alive = true


func _damage(dmg = 1, impulseX = 0, silent = false):
	if alive:
		hp -= dmg
		_update_power_display()
		emit_signal('damage')

		if hp <= 0:
			_die()
		else:
			if !silent: Global.sfx('damage')

		if impulseX:
			translate(Vector2(0, -1))
			velocity += Vector2(impulseX, -.6) * 200

	return self


func _die(silence = false):
	animator.play('die')
	direction *= 0
	alive = false
	hp = 0
	remove_from_group(GROUP_NAME_ZOMBIE)

	_update_power_display()
	_update_collision_layer()

	emit_signal('dead')

	if !silence: Global.sfx('dead')


func _ressurect():
	add_to_group(GROUP_NAME_ZOMBIE)

	if alive: _die(true)

	_update_collision_layer()
	animator.play('ressurect')
	Global.sfx('ressurect')


func _get_follow_queue_index():
	var zombies = get_tree().get_nodes_in_group(GROUP_NAME_ZOMBIE)

	zombies.sort_custom(self, '_follow_queue_sort')

	return zombies.find(self)


func _follow_queue_sort(curr, next):
	var v = true
	var cpos = curr.get_global_position()
	var npos = next.get_global_position()
	var ppos = get_parent().get_node('Player').get_global_position()

	if cpos.distance_to(ppos) > npos.distance_to(ppos) : v = false

	return v


func _update_power_display():
	display.set_scale(Vector2(1, hp / hpMax))


func _update_collision_layer():
	var v = false

	if alive or is_in_group(GROUP_NAME_ZOMBIE): v = true

	set_collision_layer_bit(SOLID_CELL_COLLISION_MASK_ID, v)
	set_collision_mask_bit(SOLID_CELL_COLLISION_MASK_ID, v)