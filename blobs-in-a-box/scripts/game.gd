extends Node

enum COLOR {
	BLUE = 1,
	RED,
	GRAY
}

enum OBJECTS {
	EMPTY = -1,
	FLAG,
	STAR,
	SKULL
}

enum MOVABLES {
	PLAYER,
	PUSH
}

const GRID_SIZE := 64
const SPEED := 15

var moves := 0

var movables : Array[Dictionary]
var flags : Array[Dictionary] = []
var stars := 0 # to be implemented
var win : bool
var defeat : bool
@onready var win_label : Label = $Win
@onready var defeat_label : Label = $Defeat


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	win_label.hide()
	defeat_label.hide()
	win = false
	defeat = false
	# Can only fetch nodes when ready
	movables = [
		{
			"node": $PlayerBlue,
			"type": MOVABLES.PLAYER,
			"color": COLOR.BLUE,
			"pos": null,
			"last_pos": null,
			"moves": [],
			"shader_node": $PlayerRed
		},
		{
			"node": $PlayerRed,
			"type": MOVABLES.PLAYER,
			"color": COLOR.RED,
			"pos": null,
			"last_pos": null,
			"moves": [],
			"shader_node": false
		}
	]
	
	# Initialise obj.pos, snap to grid, and add an initial move
	for obj in movables:
		obj.node.scale = Vector2.ONE * 0.45
		obj.pos = pos2coord(obj.node.position)
		obj.node.position = coord2pos(obj.pos)
		obj.moves.append(obj.pos)
	
	# Make a count of all flags and stars
	var search_size := DisplayServer.screen_get_usable_rect().size / (Vector2i.ONE * GRID_SIZE)
	for y in range(search_size.y):
		for x in range(search_size.x):
			var pos := Vector2i(x, y)
			var atlas: Vector2i = $Objects.get_cell_atlas_coords(pos)
			if atlas.x == 0:
				# is a flag
				if atlas.y == 0:
					# purple flag
					flags.append({
						"pos": pos,
						"color": COLOR.BLUE,
						"reached": false
					})
					flags.append({
						"pos": pos,
						"color": COLOR.RED,
						"reached": false
					})
				else:
					flags.append({
						"pos": pos,
						"color": atlas.y,
						"reached": false
					})
			if atlas.x == 1:
				# is a star
				if atlas.y == 0:
					# purple star
					stars += 2
				else:
					stars += 1
	print(win)
	print(defeat)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
var t := 1.
func _process(delta: float) -> void:
	if t >= 1:
		# Store last position for interpolation
		for obj in movables:
			obj.last_pos = coord2pos(obj.pos)
		
		# Detect movement
		var moved := false
		if (!win && !defeat):
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
			
			if (defeat):
				defeat_hide(movables)
		
		if moved:
			t = 0
			moves += 1
			for obj in movables:
				obj.moves.append(obj.pos)
			returnPos()
		
	else:
		t = minf(t + delta * SPEED, 1)
	
	for obj in movables:
		# Update positions
		obj.node.position = obj.last_pos.lerp(coord2pos(obj.pos), t * t * (3 - 2 * t))
		
		# Check for objects
		var object := check_object(obj.pos, obj.color)
		if object == OBJECTS.STAR && obj.type == MOVABLES.PLAYER:
			destroy_object(obj.pos, obj.color)
			stars -= 1
		elif object == OBJECTS.SKULL && obj.type == MOVABLES.PLAYER:
			defeat_show(obj)
		
		# Shader
		if obj.shader_node:
			obj.node.material.set("shader_param/offset", (obj.node.position - obj.shader_node.position) * 2)
	
	# Win condition
	var flags_left := false
	for flag in flags:
		flag.reached = false
		for obj in movables:
			if obj.pos == flag.pos && obj.color & flag.color:
				flag.reached = true
		if !flag.reached:
			flags_left = true
			
	if !flags_left && stars == 0:
		win_show()
	


# Converts grid coordinate to position vector
func coord2pos(coord: Vector2i) -> Vector2:
	return GRID_SIZE * (Vector2(coord) + Vector2.ONE / 2)

# Converts position vector to grid position. Used to fetch starting positions of movables
func pos2coord(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos / GRID_SIZE))

# Checks for a wall collision
func can_move(coord: Vector2i, color: COLOR) -> bool:
	if $Walls.get_cell_atlas_coords(coord).y < 4:
		# wall
		return false
	elif $Walls.get_cell_atlas_coords(coord).y < 8:
		# red wall
		if color & COLOR.RED:
			return false
	elif $Walls.get_cell_atlas_coords(coord).y < 12:
		# blue wall
		if color & COLOR.BLUE:
			return false
	return true

# Checks for an object that is the same color
func check_object(coord: Vector2i, color: COLOR) -> OBJECTS:
	var atlas : Vector2i = $Objects.get_cell_atlas_coords(coord)
	if atlas.y == 1 && !(color & COLOR.BLUE) || atlas.y == 2 && !(color & COLOR.RED):
		# non matching color
		return OBJECTS.EMPTY
	else:
		return atlas.x # should correspond to OBJECTS

# Destroys an object of that color
func destroy_object(coord: Vector2i, color: COLOR) -> void:
	var atlas : Vector2i = $Objects.get_cell_atlas_coords(coord)
	if atlas.y == 0 && color != COLOR.GRAY:
		# Purple object. Destroy corresponding component.
		if color == COLOR.RED:
			# Spawn a blue object
			$Objects.set_cell(coord, 0, Vector2i(atlas.x, 1))
		elif color == COLOR.BLUE:
			# Spawn a red object
			$Objects.set_cell(coord, 0, Vector2i(atlas.x, 2))
		else:
			# What is this
			$Objects.set_cell(coord)
			print("Error in destroy_object()")
		
	else:
		$Objects.set_cell(coord)

func win_show() -> void:
	win = true
	win_label.show()

func defeat_show(obj) -> void:
	defeat = true
	defeat_label.show()
	obj.node.hide()

func defeat_hide(movables) -> void:
	defeat = false
	defeat_label.hide()
	for obj in movables:
		obj.node.show()

# Dumps debug information
func returnPos() -> void:
	return
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
		elif obj.color == COLOR.GRAY:
			color = "GRAY"
		
		print(type + " " + color + " | " + str(obj.pos))
		print(obj.moves)
		print()
