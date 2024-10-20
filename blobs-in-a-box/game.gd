extends Node

#var map_size = Vector2(16, 16)
var grid_size = 64
#var grid = []
var player = {
	"pos": Vector2(3, 5)
}
enum COLLIDE {
	COLLIDE,
	NONE,
	KILL
}

func check_collision(pos: Vector2) -> int:
	return COLLIDE.NONE

# Converts grid coordinate to position vector
func coord2pos(coord: Vector2) -> Vector2:
	return grid_size * (coord + Vector2.ONE / 2)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#for y in range(grid_size.y):
		#var row = []
		#for x in range(grid_size.x):
			#row.push_back(null)
		#grid.push_back(row)
	$Sienna.scale = Vector2.ONE * 0.5
	$Sienna.position = coord2pos(player.pos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Up"):
		#if check_collision(Vector2(player.pos.x, player.pos.y - 1)) == COLLIDE.NONE:
		player.pos.y -= 1
	if Input.is_action_just_pressed("Down"):
		player.pos.y += 1
	if Input.is_action_just_pressed("Left"):
		player.pos.x -= 1
	if Input.is_action_just_pressed("Right"):
		player.pos.x += 1
	
	#couldn't get interpolation to work
	#$Sienna.position = Vector2(move_toward($Sienna.position.x, coord2pos(player.pos).x, delta), move_toward($Sienna.position.y, coord2pos(player.pos).y, delta))
	$Sienna.position = coord2pos(player.pos)
	
	
