extends CharacterBody2D

@export_range(1.0, 100.0) var angular_inertia : float = 10.0
@export_range(0.0, 5.0, 0.1) var max_angular_velocity : float = 1.0
@export_range(1.0, 1000.0, 1.0) var mass : float = 500.0
@export_range(0.0, 1000.0, 1.0) var ground_damage_velocity_threshold : float = 500.0
var gravity : float = 3.71 : set = _set_gravity

@onready var is_motion_enabled : bool = false
@onready var external_force : Vector2 = Vector2.ZERO


var angular_velocity : float
var previous_velocity : Vector2
signal damaged

@onready var damage_noise : AudioStreamPlayer2D = $DamageNoise

func _ready() -> void:
	previous_velocity = Vector2.ZERO
	pass

func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	var force_sum := Vector2.ZERO
	if is_motion_enabled:
		force_sum += gravity * mass * Vector2.DOWN
		force_sum += external_force
	
	var acceleration = force_sum / mass
	velocity += acceleration
	rotation += angular_velocity * delta
	previous_velocity = velocity
	move_and_slide()
	for i in get_slide_collision_count():
		var velocity_change = velocity - previous_velocity
		if velocity_change.length() > ground_damage_velocity_threshold:
			take_damage()
			
		var collision := get_slide_collision(i)
		var collider_name = collision.get_collider().name
		if collider_name == "Ground":
			velocity.x = 0.0
	
func disable_motion() -> void:
	is_motion_enabled = false

func enable_motion() -> void:
	is_motion_enabled = true

func reset_position(pos : Vector2):
	position = pos

func take_damage() -> void:
	damage_noise.play()
	damaged.emit()

func _set_gravity(g : float) -> void:
	gravity = g
