extends Node

#var map_size = Vector2(16, 16)
var grid_size = 64
@export var speed = 15
#var grid = []
var player = {
	"pos": Vector2i(1, 1),
	"color": COLOR.BLUE
}
enum COLLIDE {
	COLLIDE,
	NONE,
	KILL
}
enum COLOR {
	RED,
	BLUE
}
# fake enum lmao
const CELL = {
	"WALL_RED": Vector2i(0, 0),
	"WALL_BLUE": Vector2i(1, 0),
	"WALL": Vector2i(0, 1),
	"FLOOR": Vector2i(1, 1)
}

func check_collision(coord: Vector2i, color: COLOR) -> int:
	if ($Background.get_cell_atlas_coords(coord) == CELL.WALL):
		return COLLIDE.COLLIDE
	if ($Background.get_cell_atlas_coords(coord) == CELL.WALL_BLUE && color == COLOR.BLUE):
		return COLLIDE.COLLIDE
	if ($Background.get_cell_atlas_coords(coord) == CELL.WALL_RED && color == COLOR.RED):
		return COLLIDE.COLLIDE
	return COLLIDE.NONE

# Converts grid coordinate to position vector
func coord2pos(coord: Vector2i) -> Vector2:
	return grid_size * (Vector2(coord) + Vector2.ONE / 2)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#for y in range(grid_size.y):
		#var row = []
		#for x in range(grid_size.x):
			#row.push_back(null)
		#grid.push_back(row)
	$Sienna.scale = Vector2.ONE * 0.5
	$Sienna.position = coord2pos(player.pos)

var old_pos = coord2pos(player.pos)
var t = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if t >= 1:
		if Input.is_action_just_pressed("Up"):
			if check_collision(Vector2i(player.pos.x, player.pos.y - 1), player.color) == COLLIDE.NONE:
				t = 0
				player.pos.y -= 1
		if Input.is_action_just_pressed("Down"):
			if check_collision(Vector2i(player.pos.x, player.pos.y + 1), player.color) == COLLIDE.NONE:
				t = 0
				player.pos.y += 1
		if Input.is_action_just_pressed("Left"):
			if check_collision(Vector2i(player.pos.x - 1, player.pos.y), player.color) == COLLIDE.NONE:
				t = 0
				player.pos.x -= 1
		if Input.is_action_just_pressed("Right"):
			if check_collision(Vector2i(player.pos.x + 1, player.pos.y), player.color) == COLLIDE.NONE:
				t = 0
				player.pos.x += 1
	
	if t >= 1:
		t = 1
		old_pos = coord2pos(player.pos)
	else:
		t = min(t + delta * speed, 1)
	
	$Sienna.position = old_pos.lerp(coord2pos(player.pos), t * t * (3 - 2 * t))
	
