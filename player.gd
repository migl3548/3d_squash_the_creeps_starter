extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75

# Vertical impulse applied to the character upon jumping in meters per second.
@export var jump_impulse = 20

# Vertical impulse applied to the character upon bouncing over a mob in
# meters per second.
@export var bounce_impulse = 16

#dash
@export var dash_duration := 0.5  # seconds; quick burst
var dash_unlocked := false
var dash_time_left := 0.0

#double jump
@export var double_jump_multiplier := 3.0   # ~3x the normal jump height
var double_jump_unlocked := false
var has_double_jumped := false

func unlock_double_jump():
	double_jump_unlocked = true

# Emitted when the player was hit by a mob.
# Put this at the top of the script.
signal hit

var target_velocity = Vector3.ZERO


#the dash parts of this are from chatgpt
func _physics_process(delta):
	var direction = Vector3.ZERO

	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		$AnimationPlayer.speed_scale = 4
		$Pivot.basis = Basis.looking_at(direction)
	else:
		$AnimationPlayer.speed_scale = 1

	# --- DASH UNLOCK TIMER TICK ---
	if dash_time_left > 0.0:
		dash_time_left -= delta

	# --- START DASH if unlocked & pressed & has a direction & not already dashing ---
	if dash_unlocked and Input.is_action_just_pressed("dash") and direction != Vector3.ZERO and dash_time_left <= 0.0:
		dash_time_left = dash_duration
		# Reuse jump_impulse magnitude horizontally
		target_velocity.x = direction.x * jump_impulse * 1.75
		target_velocity.z = direction.z * jump_impulse * 1.75
		# Keep current vertical velocity as-is (don’t touch Y here)

	# --- Ground (non-dash) horizontal velocity ---
	if dash_time_left <= 0.0:
		target_velocity.x = direction.x * speed
		target_velocity.z = direction.z * speed

	# --- Vertical Velocity / Gravity ---
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# --- Jump ---
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse
	
	# Double jump: press jump in air once, if unlocked
	if not is_on_floor() and double_jump_unlocked and not has_double_jumped and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse * double_jump_multiplier
		has_double_jumped = true

	# right after your normal Jump block is fine:
	if is_on_floor():
		has_double_jumped = false

	# --- Bounce-on-mob (unchanged) ---
	for index in range(get_slide_collision_count()):
		var collision = get_slide_collision(index)
		if collision.get_collider() == null:
			continue
		if collision.get_collider().is_in_group("mob"):
			var mob = collision.get_collider()
			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				mob.squash()
				target_velocity.y = bounce_impulse
				break

	# --- Move ---
	velocity = target_velocity
	move_and_slide()

	$Pivot.rotation.x = PI / 6 * velocity.y / jump_impulse


	
	
func die():
	hit.emit()
	queue_free()


func _on_mob_detector_body_entered(body):
	die()
	

#dash
func _ready():
	# ScoreLabel is a sibling under Main/UserInterface
	var score_label = get_node("../UserInterface/ScoreLabel")
	if score_label and score_label.has_signal("dash_unlocked"):
		score_label.dash_unlocked.connect(_on_dash_unlocked)
		
func _on_dash_unlocked():
	dash_unlocked = true
