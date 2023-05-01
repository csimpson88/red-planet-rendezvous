extends Node2D

# camera parameters
@export_category("Camera Parameters")
@onready var camera : Camera2D = $Camera2D
@export_range(0.1, 2.0, 0.01) var initial_zoom : float = 1.0
@export_range(0.1, 2.0, 0.01) var final_zoom : float = 0.25
@export_range(0.1, 2.0, 0.01) var zoom_speed : float = 0.5
@export_range(0.0, 1024.0, 1.0) var max_camera_offset : float = 0.0
@export_range(0.01, 2.0, 0.01) var camera_speed : float = 1.0
var camera_target_zoom : float = 1.0
var camera_target_offset : Vector2
var camera_offset : Vector2 = Vector2.ZERO

@export_category("Environment")
@export_range(0.0, 10.0, 0.01) var gravity : float = 3.71
@export_range(100.0, 10000.0, 1.0) var initial_altitude : float = 1000.0
@export_range(-1000.0, 1000.0, 1.0) var initial_x : float = 0.0
@export_range(0.0, 1000.0, 1.0) var initial_velocity : float = 500.0

@export_category("Rope Parameters")
@export_range(0.0, 512.0, 1.0) var rope_min_length : float = 64.0
@export_range(0.0, 2048.0, 1.0) var rope_max_length : float = 512.0
@export_range(0.0, 1000.0, 1.0) var rope_stiffness : float = 250.0
@export_range(0.0, 100.0, 1.0) var rope_dampening : float = 10.0

const rope_offset : float = 16.0
var rover_graphical_offset : float = 32.0
var rope_length : float
var is_rover_lowered : bool = false

@onready var sky_crane : CharacterBody2D = $SkyCrane
@onready var rover : CharacterBody2D = $Rover
@onready var rope : MeshInstance2D = $Rope
@onready var ground : StaticBody2D = $Ground
@onready var target : Sprite2D = $Target
@onready var hud_info : Control = $CanvasLayer/HUDInfo
@onready var bottom_label : Label = $CanvasLayer/BottomLabel
@onready var speed_label : Label = $CanvasLayer/HUDInfo/SpeedLabel
@onready var fuel_mass_label : Label = $CanvasLayer/HUDInfo/FuelMassLabel
@onready var altitude_bar : Container = $CanvasLayer/HUDInfo/AltitudeBar
@onready var fuel_bar : TextureProgressBar = $CanvasLayer/HUDInfo/FuelBar
@onready var info_label: Label = $CanvasLayer/InfoLabel
@onready var arrow_container: Container = $CanvasLayer/HUDInfo/ArrowContainer
@onready var canvas_layer : CanvasLayer = $CanvasLayer
@onready var space_button : Sprite2D = $CanvasLayer/SpaceButton
@onready var title_sprite : Sprite2D = $CanvasLayer/TitleSprite

@onready var win_noise : AudioStreamPlayer2D = $Camera2D/WinNoise

@onready var is_starting : bool = true

enum GameState{
	start,
	retracted,
	lowered,
	detached,
	win,
	lose
}

@onready var game_state : GameState = GameState.start
var sky_crane_initial_position : Vector2
var sky_crane_initial_rotation : float
@export var sky_crane_initial_speed : float = 100.0

var rover_initial_position : Vector2
var rover_initial_rotation : float

func _ready() -> void:
	game_state = GameState.start
	sky_crane_initial_position = sky_crane.global_position
	sky_crane_initial_rotation = sky_crane.rotation
	sky_crane.gravity = gravity
	rover.gravity = gravity
	
	rover_initial_position = sky_crane_initial_position + Vector2.DOWN.rotated(sky_crane.rotation) * rope_min_length
	rover_initial_rotation = sky_crane_initial_rotation
	
	rover_graphical_offset = 128.0
	
	fuel_bar.max_value = sky_crane.max_fuel
	fuel_bar.value = sky_crane.max_fuel
	
	camera_target_offset = sky_crane.global_position
	to_start()

func _process(delta: float) -> void:
	camera_offset.y = move_toward(camera_offset.y, camera_target_offset.y, delta * camera_speed * abs(camera_offset.y - camera_target_offset.y))
	camera.global_position = sky_crane.global_position + camera_offset
	camera.zoom = camera.zoom.move_toward(camera_target_zoom * Vector2.ONE, delta * zoom_speed * abs(camera.zoom.x - camera_target_zoom))
	
	update_rope()
	update_ground()
	update_hud()
	match game_state:
		GameState.start:
			process_start(delta)
		GameState.retracted:
			process_retracted(delta)
		GameState.lowered:
			process_lowered(delta)
		GameState.detached:
			process_detached(delta)
		GameState.win:
			process_win(delta)
		GameState.lose:
			process_lose(delta)

func update_hud() -> void:
	speed_label.text = "Velocity  x: " + str(int(sky_crane.velocity.x)) + "  y: " + str(-int(sky_crane.velocity.y))
	
	var rover_alt = rover.global_position.y - target.global_position.y
	var sky_crane_alt = sky_crane.global_position.y - target.global_position.y
	rover_alt /= (sky_crane_initial_position.y - target.global_position.y)
	sky_crane_alt /= (sky_crane_initial_position.y - target.global_position.y)
	altitude_bar.set_rover_alt(rover_alt)
	altitude_bar.set_sky_crane_alt(sky_crane_alt)
	
	fuel_bar.value = sky_crane.fuel_mass
	fuel_mass_label.text = str(int(sky_crane.fuel_mass)) + " kg"
	update_arrow()

func update_rope() -> void:
	var rope_start : Vector2 = sky_crane.global_position + rope_offset * Vector2.DOWN.rotated(sky_crane.rotation)
	var rope_end : Vector2 = rover.global_position + rover_graphical_offset * Vector2.DOWN.rotated(rover.rotation)
	rope.global_position = rope_start
	rope.rotation = rope_start.angle_to_point(rope_end) - PI/2.0
	rope.mesh.size.y = rope_start.distance_to(rope_end)
	rope.mesh.center_offset.y = rope.mesh.size.y / 2.0

func update_arrow() -> void:
	var target_vector = target.global_position - sky_crane.global_position
	arrow_container.set_direction(sky_crane.global_position.angle_to_point(target.global_position))
	var is_off_side : bool = (abs(target_vector.x) > 2000.0)
	var is_off_bottom : bool = (abs(target_vector.y) > 2000.0)
	if is_off_side or is_off_bottom:
		arrow_container.visible = true
	else:
		arrow_container.visible = false
	
	
func update_ground() -> void:
	ground.global_position.x = sky_crane.global_position.x

func to_start() -> void:
	hud_info.visible = false
	info_label.visible = true
	info_label.text = "Deliver the rover to the target below."
	space_button.visible = true
	bottom_label.text = "Press Space to Play!"
	sky_crane.disable_motion()
	sky_crane.set_velocity(Vector2.ZERO)
	sky_crane.set_global_position(sky_crane_initial_position)
	sky_crane.set_rotation(sky_crane_initial_rotation)
	sky_crane.fuel_mass = sky_crane.max_fuel
	rover.disable_motion()
	rover.set_velocity(Vector2.ZERO)
	rover.set_global_position(rover_initial_position)
	rover.set_rotation(rover_initial_rotation)
	camera_target_zoom = initial_zoom
	camera_target_offset = Vector2.ZERO
	game_state = GameState.start
	rope.visible = true
	title_sprite.visible = true

func to_retracted() -> void:
	sky_crane.set_velocity(sky_crane_initial_speed * Vector2.DOWN.rotated(sky_crane.rotation))
	sky_crane.enable_motion()
	sky_crane.external_force = rover.mass * gravity * Vector2.DOWN
	rover.enable_motion()
	sky_crane.velocity = initial_velocity * Vector2.DOWN.rotated(sky_crane.rotation)
	rover.velocity = sky_crane.velocity
	
	hud_info.visible = true
	info_label.visible = false
	title_sprite.visible = false
	bottom_label.text = "Lower Rover"
	game_state = GameState.retracted
	camera_target_zoom = final_zoom
	camera_target_offset = Vector2.DOWN * max_camera_offset

func to_lowered() -> void:
	rope_length = rope_max_length
	rover.velocity = sky_crane.velocity
	sky_crane.velocity = sky_crane.velocity + Vector2.UP.rotated(sky_crane.rotation) / sky_crane.mass * 5000.0
	rover.velocity = sky_crane.velocity + Vector2.DOWN.rotated(sky_crane.rotation) / rover.mass * 5000.0
	rover.collision_mask |= 0b111
	
	game_state = GameState.lowered
	space_button.visible = true
	bottom_label.text = "Detach Rover"

func to_detached() -> void:
	rover.external_force = Vector2.ZERO
	sky_crane.external_force = Vector2.ZERO
	rope.visible = false
	game_state = GameState.detached
	info_label.text = "Land the Sky Crane anywhere to complete the mission"
	info_label.visible = true
	bottom_label.text = ""
	space_button.visible = false
	arrow_container.visible = false

func to_lose(message : String) -> void:
	rover.disable_motion()
	rover.external_force = Vector2.ZERO
	rover.set_velocity(Vector2.ZERO)
	sky_crane.disable_motion()
	sky_crane.thrust = 0.0
	sky_crane.external_force = Vector2.ZERO
	sky_crane.set_velocity(Vector2.ZERO)
	game_state = GameState.lose
	bottom_label.text = "Try Again" 
	info_label.visible = true
	info_label.text = message + "\nMission FAILED!"
	space_button.visible = true

func to_win() -> void:
	rover.disable_motion()
	rover.external_force = Vector2.ZERO
	rover.set_velocity(Vector2.ZERO)
	sky_crane.disable_motion()
	sky_crane.thrust = 0.0
	win_noise.play()
	sky_crane.external_force = Vector2.ZERO
	sky_crane.set_velocity(Vector2.ZERO)
	var distance_from_target : int = abs(floor(rover.global_position.x / 100.0))
	bottom_label.text = "Play Again"
	space_button.visible = true
	info_label.visible = true
	info_label.text = "Mission SUCCESS!\nDistance from target = " + str(distance_from_target) + " m"
	game_state = GameState.win

func process_start(delta:float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		to_retracted()

func process_retracted(delta: float) -> void:
	rover.set_global_position(sky_crane.global_position + Vector2.DOWN * rope_min_length)
	rover.set_rotation(sky_crane.rotation)
	if Input.is_action_just_pressed("ui_accept"):
		to_lowered()

func process_lowered(delta: float) -> void:
	var rope_vector : Vector2 = rover.global_position - sky_crane.global_position
	var dist = rope_vector.length()
	if dist > rope_length:
		var rope_spring_force : Vector2 = rope_stiffness * (dist - rope_length) * rope_vector.normalized()
		var relative_velocity : Vector2 = rover.velocity - sky_crane.velocity
		var rope_dampening_force : Vector2 = relative_velocity * rope_dampening
		sky_crane.external_force = rope_spring_force + rope_dampening_force
		rover.external_force = -sky_crane.external_force # equal and opposite reaction
	else:
		sky_crane.external_force = Vector2.ZERO
		rover.external_force = Vector2.ZERO
	if Input.is_action_just_pressed("ui_accept"):
		to_detached()

func process_detached(delta: float) -> void:
	if rover.is_on_floor_only() and sky_crane.is_on_floor_only():
		to_win()


func process_win(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		to_start()


func process_lose(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		to_start()



func _on_sky_crane_damaged() -> void:
	to_lose("You broke the sky crane!")


func _on_rover_damaged() -> void:
	to_lose("You broke the rover!")


func _on_sky_crane_squish() -> void:
	to_lose("You squished the rover!")
