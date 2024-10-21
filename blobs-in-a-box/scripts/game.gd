extends Node

enum COLOR {
	BLUE,
	RED
}

enum MOVABLES {
	PLAYER,
	PUSH
}

# variables specifically for the players
var starting_blue_pos := Vector2i(1, 1)
var starting_red_pos := Vector2i(16, 1) 
var blue_player_moves : Array[Vector2i] = [starting_blue_pos]
var red_player_moves : Array[Vector2i] = [starting_red_pos]

var movables : Array[Dictionary]

const GRID_SIZE := 64
@export var speed := 15
var moves := 0
var t := 1.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Can only fetch nodes when ready
	movables = [
		{
			"node": $PlayerBlue,
			"type": MOVABLES.PLAYER,
			"color": COLOR.BLUE,
			"pos": starting_blue_pos,
			"last_pos": null,
			"moves": []
		},
		{
			"node": $PlayerRed,
			"type": MOVABLES.PLAYER,
			"color": COLOR.RED,
			"pos": starting_red_pos,
			"last_pos": null,
			"moves": []
		}
	]
	
	for obj in movables:
		obj.node.scale = Vector2.ONE * 0.45
		obj.node.position = coord2pos(obj.pos)
		obj.moves.append(obj.pos)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if t >= 1:
		# Store last position for interpolation
		for obj in movables:
			obj.last_pos = coord2pos(obj.pos)
		
		# Detect movement
		var moved := false
		if Input.is_action_just_pressed("Up"):
			for obj in movables:
				if obj.type == MOVABLES.PLAYER && can_move(Vector2i(obj.pos.x, obj.pos.y - 1), obj.color):
					obj.pos.y -= 1
					moved = true
		elif Input.is_action_just_pressed("Down"):
			for obj in movables:
				if obj.type == MOVABLES.PLAYER && can_move(Vector2i(obj.pos.x, obj.pos.y + 1), obj.color):
					obj.pos.y += 1
					moved = true
		elif Input.is_action_just_pressed("Left"):
			for obj in movables:
				if obj.type == MOVABLES.PLAYER && can_move(Vector2i(obj.pos.x - 1, obj.pos.y), obj.color):
					obj.pos.x -= 1
					moved = true
		elif Input.is_action_just_pressed("Right"):
			for obj in movables:
				if obj.type == MOVABLES.PLAYER && can_move(Vector2i(obj.pos.x + 1, obj.pos.y), obj.color):
					obj.pos.x += 1
					moved = true
		elif Input.is_action_just_pressed("Undo") && moves > 0:
			# Undo button for moves
			for obj in movables:
				obj.moves.pop_back()
				obj.pos = obj.moves.back()
			t = 0
			moves -= 1
			returnPos()
		
		if moved:
			t = 0
			moves += 1
			for obj in movables:
				obj.moves.append(obj.pos)
			returnPos()
		
	else:
		t = minf(t + delta * speed, 1)
	
	# Update positions
	for obj in movables:
		obj.node.position = obj.last_pos.lerp(coord2pos(obj.pos), t * t * (3 - 2 * t))
	


# Converts grid coordinate to position vector
func coord2pos(coord: Vector2i) -> Vector2:
	return GRID_SIZE * (Vector2(coord) + Vector2.ONE / 2)

# Checks for a wall collision
func can_move(coord: Vector2i, color: COLOR) -> bool:
	if $Walls.get_cell_atlas_coords(coord).y < 4:
		# wall
		return false
	elif $Walls.get_cell_atlas_coords(coord).y < 8:
		# red wall
		if color == COLOR.RED:
			return false
	elif $Walls.get_cell_atlas_coords(coord).y < 12:
		# blue wall
		if color == COLOR.BLUE:
			return false
	return true

# Dumps debug information
func returnPos() -> void:
	for obj in movables:
		var type = "UNKNOWN"
		if obj.type == MOVABLES.PLAYER:
			type = "PLAYER"
		elif obj.type == MOVABLES.PUSH:
			type = "PUSH"
		
		var color = "UNKNOWN"
		if obj.color == COLOR.BLUE:
			color = "BLUE"
		elif obj.color == COLOR.RED:
			color = "RED"
		
		print(type + " " + color + " | " + str(obj.pos))
		print(obj.moves)
	
	print()
	
