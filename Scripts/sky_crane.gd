extends CharacterBody2D

@export_range(0.0, 10000.0, 100.0) var max_thrust : float = 5000.0
@export_range(0.0, 256.0, 1.0) var thrust_delta : float = 128.0
@export_range(1.0, 100.0) var angular_inertia : float = 10.0
@export_range(0.0, 5.0, 0.1) var max_angular_velocity : float = 1.0
@export_range(0.0, 10000.0, 1.0) var max_fuel : float = 500.0
@export_range(0.0, 1.0, 0.001) var fuel_kg_per_sec_per_N : float = 0.01
@export_range(1.0, 1000.0, 1.0) var empty_mass : float = 500.0
@export_range(0.0, 1000.0, 1.0) var damage_velocity_threshold : float = 500.0
var gravity : float = 3.71 : set = _set_gravity

@onready var thrust : float = 0.0
@onready var left_flame : Sprite2D = $LeftFlame
@onready var right_flame : Sprite2D = $RightFlame
@onready var is_motion_enabled : bool = false
@onready var external_force : Vector2 = Vector2.ZERO

@onready var thrust_noise : AudioStreamPlayer2D = $ThrustNoise
@onready var damage_noise : AudioStreamPlayer2D = $DamageNoise

var mass : float
var fuel_mass : float

var angular_velocity : float
@onready var previous_velocity : Vector2 = Vector2.ZERO
@onready var is_touching_rover : bool = false
@onready var is_landed = false

signal damaged

func _ready() -> void:
	fuel_mass = max_fuel
	mass = empty_mass + fuel_mass

func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	var force_sum := Vector2.ZERO
	if is_motion_enabled:
		# get rotation inputs
		var w = 0.0
		if Input.is_action_pressed("ui_right"):
			w += max_angular_velocity
		if Input.is_action_pressed("ui_left"):
			w -= max_angular_velocity
		angular_velocity = move_toward(angular_velocity, w, max_angular_velocity / (angular_inertia * mass / empty_mass))
		
		# get thrust inputs
		if Input.is_action_pressed("ui_up"):
			thrust += thrust_delta * delta * 100.0
		if Input.is_action_pressed("ui_down"):
			thrust -= thrust_delta * delta * 100.0
		thrust = clamp(thrust, 0.0, max_thrust)
		fuel_mass -= fuel_kg_per_sec_per_N * delta * thrust
		fuel_mass = clamp(fuel_mass, 0.0, max_fuel)
		if fuel_mass <= 0:
			thrust = 0.0
		force_sum += thrust * Vector2.UP.rotated(rotation)
		
		mass = empty_mass + fuel_mass
		force_sum += gravity * mass * Vector2.DOWN
		
		force_sum += external_force
	else:
		thrust = 0.0
		angular_velocity = 0.0
	
	if thrust == 0.0:
		disable_thrust_noise()
	else:
		enable_thrust_noise()
	thrust_noise.volume_db = clamp(thrust/max_thrust * 20.0 - 20.0, -20.0, 0.0)
	var acceleration = force_sum / mass
	velocity += acceleration
	rotation += angular_velocity * delta
	previous_velocity = velocity
	move_and_slide()
	is_touching_rover = true
	for i in get_slide_collision_count():
		var velocity_change = velocity - previous_velocity
		if velocity_change.length() > damage_velocity_threshold:
			take_damage()
		var collision := get_slide_collision(i)
		var collider_name = collision.get_collider().name
		if collider_name == "Ground":
			velocity.x = 0.0
	
	# make flames scale with thrust
	var seconds_elapsed : float = Time.get_ticks_msec()/1000.0
	var flame_flicker : float = 0.1 * fmod(floor(seconds_elapsed*24.0), 2.0)
	var flame_scale : float = (thrust * (1.0 + flame_flicker)) / max_thrust
	left_flame.scale.y = flame_scale
	right_flame.scale.y = flame_scale

func take_damage() -> void:
	damage_noise.play()
	damaged.emit()

func disable_motion() -> void:
	is_motion_enabled = false

func enable_motion() -> void:
	is_motion_enabled = true

func reset_position(pos : Vector2):
	position = pos

func _set_gravity(g : float) -> void:
	gravity = g

	
func enable_thrust_noise() -> void:
	if not thrust_noise.playing:
		thrust_noise.play()

func disable_thrust_noise() -> void:
	if thrust_noise.playing:
		thrust_noise.stop()
