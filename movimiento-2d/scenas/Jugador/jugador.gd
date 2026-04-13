extends CharacterBody2D

var speed_walk: float = 200.0
var speed_run: float = 400.0
var jump_velocity: float = -400.0

var wall_jump_velocity: float = -350.0
var wall_pushback: float = 500.0
var wall_slide_gravity: float = 50.0
var max_wall_slide_speed: float = 150.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		if is_on_floor() and velocity.y > 0:
			velocity.y += wall_slide_gravity * delta
			velocity.y = min(velocity.y, max_wall_slide_speed)
		else:
			velocity.y += gravity * delta
	
	var direction = Input.get_axis("ui_left","ui_right")
	var current_speed = speed_walk
	
	if Input.is_action_pressed("run"):
		current_speed = speed_run
	
	if direction:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
	
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = jump_velocity
		elif is_on_wall() and not is_on_floor():
			velocity.y = wall_jump_velocity
			
			var wall_normal = get_wall_normal()
			velocity.x = wall_normal.x * wall_pushback
	
	move_and_slide()
	
	
