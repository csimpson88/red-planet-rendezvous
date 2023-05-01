extends Container

@onready var sky_crane := $SkyCraneIndicator
@onready var rover := $RoverIndicator
@onready var target := $TargetIndicator
@onready var bar := $Bar

func set_sky_crane_alt(v : float):
	sky_crane.position.y = (1.0-v) * size.y
func set_rover_alt(v : float):
	rover.position.y = (1.0-v) * size.y
