class_name Enemy
extends Actor

signal health_updated(health)
signal killed()

enum State {
	WALKING,
	RUNNING,
	DEAD
}

var _state = State.WALKING
var player_in_range
onready var player = get_tree().get_root().get_node("Game").get_node("Level").get_node("Player")

onready var platform_detector = $PlatformDetector
onready var floor_detector_left = $FloorDetectorLeft
onready var floor_detector_right = $FloorDetectorRight
onready var sprite = $Sprite
onready var animation_player = $AnimationPlayer

export (float) var max_health=100
onready var health = max_health setget _set_health

# This function is called when the scene enters the scene tree.
# We can initialize variables here.
func _ready():
	_velocity.x = speed.x

# Physics process is a built-in loop in Godot.
# If you define _physics_process on a node, Godot will call it every frame.

# At a glance, you can see that the physics process loop:
# 1. Calculates the move velocity.
# 2. Moves the character.
# 3. Updates the sprite direction.
# 4. Updates the animation.

# Splitting the physics process logic into functions not only makes it
# easier to read, it help to change or improve the code later on:
# - If you need to change a calculation, you can use Go To -> Function
#   (Ctrl Alt F) to quickly jump to the corresponding function.
# - If you split the character into a state machine or more advanced pattern,
#   you can easily move individual functions.
func _physics_process(_delta):
	if _state == State.WALKING:
		# If the enemy encounters a wall or an edge, the horizontal velocity is flipped.
		if not floor_detector_left.is_colliding():
			_velocity.x = speed.x
		elif not floor_detector_right.is_colliding():
			_velocity.x = -speed.x
	
		if is_on_wall():
			_velocity.x *= -1
	
		# We only update the y value of _velocity as we want to handle the horizontal movement ourselves.
		_velocity.y = move_and_slide(_velocity, FLOOR_NORMAL).y
	
		# We flip the Sprite depending on which way the enemy is moving.
		sprite.scale.x = 1 if _velocity.x > 0 else -1
	if _state == State.RUNNING:
		_velocity = (player.get_global_position() - self.get_global_position()).normalized()
		_velocity *= -1
		_velocity.y = 1
		move_and_slide(_velocity*speed)
		# We flip the Sprite depending on which way the enemy is moving.
		sprite.scale.x = 1 if _velocity.x > 0 else -1
	
	if _state == State.DEAD:
		var animation = get_new_animation()
		if animation != animation_player.current_animation:
			animation_player.play(animation)


func destroy(damage):
		damage(damage)



func get_new_animation():
	var animation_new = ""
	if _state == State.WALKING:
		animation_new = "walk" if abs(_velocity.x) > 0 else "idle"
	else:
		animation_new = "destroy"
	return animation_new
	
	
func kill():
	pass

func damage(amount):
	_set_health(health - amount)
	
func _set_health(value):
	var prev_health = health
	health = clamp(value, 0, max_health)
	if health != prev_health:
		emit_signal("health_updated", health)
		if health == 0:
			_state = State.DEAD
			_velocity = Vector2.ZERO
		elif health < 51:
			_state = State.RUNNING
			print("in running state")



func _on_Range_body_entered(body):
	if body == player:
		player_in_range = true;
		print("Player in range: ", player_in_range)


func _on_Range_body_exited(body):
	if body == player:
		player_in_range = false
		print("Player in range: ", player_in_range)
