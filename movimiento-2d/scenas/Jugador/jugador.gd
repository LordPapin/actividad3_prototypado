extends CharacterBody2D

# --- VARIABLES DEL INSPECTOR ---
@export var speed_walk: float = 200.0
@export var speed_run: float = 400.0
@export var jump_velocity: float = -400.0

@export var wall_jump_velocity: float = -350.0
@export var wall_pushback: float = 500.0
@export var wall_slide_gravity: float = 50.0
@export var max_wall_slide_speed: float = 150.0

#  DEFINIR LOS ESTADOS POSIBLES
enum State { IDLE, WALK, RUN, IN_AIR, WALL_SLIDE }

#  VARIABLE PARA SABER EN QUÉ ESTADO ESTAMOS (Empezamos quietos)
var current_state = State.IDLE

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# Obtenemos el input del jugador
	var direction = Input.get_axis("ui_left", "ui_right")
	var is_running = Input.is_action_pressed("run")

	# Aplicamos gravedad base si no estamos en el suelo y NO estamos deslizando por la pared
	if not is_on_floor() and current_state != State.WALL_SLIDE:
		velocity.y += gravity * delta

	#  LA MÁQUINA DE ESTADOS (Evalúamos el estado actual y decidimos qué hacer)
	match current_state:
		
		State.IDLE:
			# Comportamiento: Quieto
			velocity.x = move_toward(velocity.x, 0, speed_walk)
			
			# Transiciones (Cambios a otros estados)
			if direction != 0:
				current_state = State.WALK if not is_running else State.RUN
			if not is_on_floor():
				current_state = State.IN_AIR
			if Input.is_action_just_pressed("ui_accept"):
				jump()

		State.WALK:
			# Comportamiento: Caminar
			velocity.x = direction * speed_walk
			
			# Transiciones
			if direction == 0:
				current_state = State.IDLE
			elif is_running:
				current_state = State.RUN
			if not is_on_floor():
				current_state = State.IN_AIR
			if Input.is_action_just_pressed("ui_accept"):
				jump()

		State.RUN:
			# Comportamiento: Correr
			velocity.x = direction * speed_run
			
			# Transiciones
			if direction == 0:
				current_state = State.IDLE
			elif not is_running:
				current_state = State.WALK
			if not is_on_floor():
				current_state = State.IN_AIR
			if Input.is_action_just_pressed("ui_accept"):
				jump()

		State.IN_AIR:
			# Comportamiento: Control en el aire
			var current_air_speed = speed_run if is_running else speed_walk
			if direction:
				velocity.x = direction * current_air_speed
			else:
				velocity.x = move_toward(velocity.x, 0, current_air_speed)

			# Transiciones
			if is_on_floor():
				current_state = State.IDLE
			elif is_on_wall() and velocity.y > 0 and direction != 0:
				# Solo entramos a WALL_SLIDE si empujamos contra la pared cayendo
				current_state = State.WALL_SLIDE

		State.WALL_SLIDE:
			# Comportamiento: Deslizar por la pared
			velocity.y += wall_slide_gravity * delta
			velocity.y = min(velocity.y, max_wall_slide_speed)

			# Transiciones
			if Input.is_action_just_pressed("ui_accept"):
				wall_jump()
			elif not is_on_wall() or is_on_floor() or direction == 0:
				# Si soltamos la tecla de ir hacia la pared o tocamos suelo, salimos del estado
				current_state = State.IN_AIR if not is_on_floor() else State.IDLE

	#  APLICAR FÍSICAS (Al final del frame)
	move_and_slide()


# --- FUNCIONES AUXILIARES ---
func jump():
	velocity.y = jump_velocity
	current_state = State.IN_AIR # Cambiamos de estado al saltar

func wall_jump():
	velocity.y = wall_jump_velocity
	var wall_normal = get_wall_normal()
	velocity.x = wall_normal.x * wall_pushback
	current_state = State.IN_AIR # Tras el salto en la pared, pasamos a estado aéreo
