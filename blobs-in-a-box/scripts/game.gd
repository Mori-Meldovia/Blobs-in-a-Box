extends Node

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

# variables specifically for the players
var starting_blue_pos = Vector2(1, 1)
var starting_red_pos = Vector2(16, 1) 
var blue_player_moves : Array[Vector2i] = [starting_blue_pos]
var red_player_moves : Array[Vector2i] = [starting_red_pos]

# blue player
var blue_player = {
	"pos": starting_blue_pos,
	"color": COLOR.BLUE
}

# red player
var red_player = {
	"pos": starting_red_pos,
	"color": COLOR.RED
}
#var map_size = Vector2(16, 16)
var grid_size = 64
@export var speed = 15
#var grid = []

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


# variables for 
var old_blue_pos = coord2pos(blue_player.pos)
var old_red_pos = coord2pos(red_player.pos)
var moves = 0
var t = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#for y in range(grid_size.y):
		#var row = []
		#for x in range(grid_size.x):
			#row.push_back(null)
		#grid.push_back(row)
	$blue_child.scale = Vector2.ONE * 0.5
	$blue_child.position = coord2pos(blue_player.pos)
	
	$red_child.scale = Vector2.ONE * 0.5
	$red_child.position = coord2pos(blue_player.pos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if t >= 1:
		
		# blue player movement
		if Input.is_action_just_pressed("Up"):
			if check_collision(Vector2i(blue_player.pos.x, blue_player.pos.y - 1), blue_player.color) == COLLIDE.NONE:
				t = 0
				blue_player.pos.y -= 1
			
			if check_collision(Vector2i(red_player.pos.x, red_player.pos.y - 1), red_player.color) == COLLIDE.NONE:
				t = 0
				red_player.pos.y -= 1
			
			moves += 1
			moved()
	
		elif Input.is_action_just_pressed("Down"):
			if check_collision(Vector2i(blue_player.pos.x, blue_player.pos.y + 1), blue_player.color) == COLLIDE.NONE:
				t = 0
				blue_player.pos.y += 1
			
			if check_collision(Vector2i(red_player.pos.x, red_player.pos.y + 1), red_player.color) == COLLIDE.NONE:
				t = 0
				red_player.pos.y += 1
			
			moves += 1
			moved()
	
		elif Input.is_action_just_pressed("Left"):
			if check_collision(Vector2i(blue_player.pos.x - 1, blue_player.pos.y), blue_player.color) == COLLIDE.NONE:
				t = 0
				blue_player.pos.x -= 1
			
			if check_collision(Vector2i(red_player.pos.x - 1, red_player.pos.y), red_player.color) == COLLIDE.NONE:
				t = 0
				red_player.pos.x -= 1
			
			moves += 1
			moved()
	
		elif Input.is_action_just_pressed("Right"):
			if check_collision(Vector2i(blue_player.pos.x + 1, blue_player.pos.y), blue_player.color) == COLLIDE.NONE:
				t = 0
				blue_player.pos.x += 1
			
			if check_collision(Vector2i(red_player.pos.x + 1, red_player.pos.y), red_player.color) == COLLIDE.NONE:
				t = 0
				red_player.pos.x += 1
			
			moves += 1
			moved()
		
	
		# Undo button for moves
		elif Input.is_action_just_pressed("Undo"):
			if (moves != 0):
				# get last position of players
				blue_player_moves.pop_back()
				red_player_moves.pop_back()
				var last_blue_pos = blue_player_moves.back()
				var last_red_pos = red_player_moves.back()
				
				# allign values
				blue_player.pos.x = last_blue_pos.x
				blue_player.pos.y = last_blue_pos.y
				red_player.pos.x = last_red_pos.x
				red_player.pos.y = last_red_pos.y
				
				moves -= 1
				returnPos()
		
	if t >= 1:
		t = 1
		old_blue_pos = coord2pos(blue_player.pos)
		old_red_pos = coord2pos(red_player.pos)
		
	else:
		t = min(t + delta * speed, 1)
	
	$blue_child.position = old_blue_pos.lerp(coord2pos(blue_player.pos), t * t * (3 - 2 * t))
	$red_child.position = old_red_pos.lerp(coord2pos(red_player.pos), t * t * (3 - 2 * t))

func moved() -> void:
		blue_player_moves.append(Vector2i(blue_player.pos))
		red_player_moves.append(Vector2i(red_player.pos))
		returnPos()

func returnPos() -> void:
	print("Blue: " + str(blue_player.pos) + ", Red: " + str(red_player.pos))
	print("Blue: " + str(blue_player_moves))
	print("Red: " + str(red_player_moves))
	print()