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
	SKULL,
	BUTTON_GREEN,
	BUTTON_YELLOW,
	BUTTON_AQUA,
	GATE_GREEN_H_CLOSED,
	GATE_GREEN_H_OPEN,
	GATE_GREEN_V_CLOSED,
	GATE_GREEN_V_OPEN,
	GATE_YELLOW_H_CLOSED,
	GATE_YELLOW_H_OPEN,
	GATE_YELLOW_V_CLOSED,
	GATE_YELLOW_V_OPEN,
	GATE_AQUA_H_CLOSED,
	GATE_AQUA_H_OPEN,
	GATE_AQUA_V_CLOSED,
	GATE_AQUA_V_OPEN,
	BELT_RIGHT,
	BELT_DOWN,
	BELT_LEFT,
	BELT_UP
}

enum MOVABLES {
	UNMOVABLE,
	PLAYER,
	PUSH
}

enum COLLIDE {
	COLLIDE,
	NONE,
	MOVABLE
}

const GRID_SIZE := 64
const SPEED := 15
const SOURCE = 3
var SEARCH_SIZE := DisplayServer.screen_get_usable_rect().size / (Vector2i.ONE * GRID_SIZE)

var moves := 0

var movables : Array[Dictionary] = []
var flags : Array[Dictionary] = [] # "pos" and "color" and "reached"
var objects_destoryed : Array[Dictionary] = [] # "move_occurence", "pos", "original_v2i_object", "obj_type"
var no_of_stars := 0
var win := false
var defeat := false
@onready var win_label : Label = $Win
@onready var defeat_label : Label = $Defeat


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	win_label.hide()
	defeat_label.hide()
	
	# Fetch and load nodes automatically
	for child in get_children():
		if child is not Sprite2D:
			continue
		
		var child_name := child.get_name()
		
		var type := MOVABLES.PUSH
		var color := COLOR.GRAY
		var shader_node = null
		
		if child_name.begins_with("Player"):
			type = MOVABLES.PLAYER
		elif child_name.begins_with("Crate"):
			type = MOVABLES.PUSH
		
		if child_name.ends_with("Red"):
			color = COLOR.RED
		elif child_name.ends_with("Blue"):
			color = COLOR.BLUE
			shader_node = get_node(child_name.replace("Blue", "Red"))
		elif child_name.ends_with("Gray"):
			color = COLOR.GRAY
		
		var obj := {
			"node": child,
			"type": type,
			"color": color,
			"pos": pos2coord(child.position),
			"last_pos": null,
			"moves": [pos2coord(child.position)],
			"shader_node": shader_node
		}
		movables.append(obj)
		
		if type == MOVABLES.PLAYER:
			child.scale = Vector2.ONE * 0.45
		elif type == MOVABLES.PUSH:
			child.scale = Vector2.ONE * 2
		child.position = coord2pos(obj.pos)
	
	for y in range(SEARCH_SIZE.y):
		for x in range(SEARCH_SIZE.x):
			var pos := Vector2i(x, y)
			var atlas : Vector2i = $Objects.get_cell_atlas_coords(pos)
			
			# Make a count of all flags and stars
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
					no_of_stars += 2
				else:
					no_of_stars += 1
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
var t := 1.
func _process(delta: float) -> void:
	var moved := false
	
	if t >= 1:
		# Store last position for interpolation
		for obj in movables:
			obj.last_pos = coord2pos(obj.pos)
		
		# Detect movement
		var move_intended := false
		if !win && !defeat:
			var offset := Vector2i.ZERO
			if Input.is_action_just_pressed("Up"):
				move_intended = true
				offset.y = -1
			elif Input.is_action_just_pressed("Down"):
				move_intended = true
				offset.y = 1
			elif Input.is_action_just_pressed("Left"):
				move_intended = true
				offset.x = -1
			elif Input.is_action_just_pressed("Right"):
				move_intended = true
				offset.x = 1
			
			if move_intended:
				var move := func (stack, this) -> bool:
					var obj: Dictionary = stack[-1]
					var new_pos: Vector2i = obj.pos + offset
					var collide := can_move(new_pos, obj.color)
					if collide == COLLIDE.NONE:
						for movable in stack:
							movable.pos += offset
						return true
					elif collide == COLLIDE.MOVABLE:
						for movable in movables:
							if movable.pos == new_pos && movable.color & obj.color:
								stack.append(movable)
								return this.call(stack, this)
								
						print("Error happened in collision detection")
						return false
					elif collide == COLLIDE.COLLIDE:
						return false
					
					print("Encountered unknown collide type!")
					return false
					
				for obj in movables:
					if obj.type == MOVABLES.PLAYER:
						moved = move.call([obj], move) || move
			
			if Input.is_action_just_pressed("Wait"):
				move_intended = true
		
		# Check for belts
		for obj in movables:
			if move_intended && obj.type == MOVABLES.PLAYER:
				var object := check_object(obj.moves[-1], obj.color)
				
				if object == OBJECTS.BELT_UP && can_move(Vector2i(obj.pos.x, obj.pos.y - 1), obj.color) == COLLIDE.NONE:
					obj.pos.y -= 1
					moved = true
				if object == OBJECTS.BELT_DOWN && can_move(Vector2i(obj.pos.x, obj.pos.y + 1), obj.color) == COLLIDE.NONE:
					obj.pos.y += 1
					moved = true
				if object == OBJECTS.BELT_LEFT && can_move(Vector2i(obj.pos.x - 1, obj.pos.y), obj.color) == COLLIDE.NONE:
					obj.pos.x -= 1
					moved = true
				if object == OBJECTS.BELT_RIGHT && can_move(Vector2i(obj.pos.x + 1, obj.pos.y), obj.color) == COLLIDE.NONE:
					obj.pos.x += 1
					moved = true
		
		if moved:
			t = 0
			moves += 1
			for obj in movables:
				obj.moves.append(obj.pos)
			returnPos()
		
		if !win:
			# Undo
			if Input.is_action_just_pressed("Undo") && moves > 0:
				for obj in movables:
					
					var object := check_object(obj.pos, obj.color)
					
					# Buttons
					checkButtons(object)
					
					# Players
					obj.moves.pop_back()
					obj.pos = obj.moves.back()
					
					# Destroyed objects : For stars and dups (TBI)
					var current_destroyed_index = 0
					for destroyed in objects_destoryed:
						# "move_occurence", "pos", "original_v2i_object", "obj_type"
						if destroyed.move_occurence == moves:
								objects_destoryed.remove_at(current_destroyed_index)
								current_destroyed_index -= 1
								
								# sets the object back to normal
								$Objects.set_cell(destroyed.pos, SOURCE, destroyed.original_v2i_object)
								
								# Stars (counting)
								if destroyed.obj_type == OBJECTS.STAR:
										no_of_stars += 1
						current_destroyed_index += 1
				
				t = 0
				moves -= 1
				returnPos()
				
				# defeat
				if defeat:
					defeat_hide()
				
		
	else:
		t = minf(t + delta * SPEED, 1)
		
		for obj in movables:
			# Update positions
			obj.node.position = obj.last_pos.lerp(coord2pos(obj.pos), t * t * (3 - 2 * t))
		
			# Shader
			if obj.shader_node:
				var offset : Vector2 = obj.node.position - obj.shader_node.position
				obj.node.material.set("shader_parameter/offset", offset * 2)
	
	# Check for objects
	
	for obj in movables:
		if moved && obj.moves[-1] != obj.moves[-2]:
			var object := check_object(obj.pos, obj.color)
			
			# Star
			if object == OBJECTS.STAR && obj.type == MOVABLES.PLAYER:
				destroy_object(obj.pos, obj.color, OBJECTS.STAR)
				no_of_stars -= 1
			
			# Skull
			elif object == OBJECTS.SKULL && obj.type == MOVABLES.PLAYER:
				
				
				defeat_show(obj)
			
			# Buttons
			checkButtons(object)
	
	var buttons_rehit : Array = []
	var total_num_on_button = 0
	for obj1 in movables:
		for obj2 in movables:
			var is_button_G = check_object(obj2.pos, obj1.color) == OBJECTS.BUTTON_GREEN
			var is_button_Y = check_object(obj2.pos, obj1.color) == OBJECTS.BUTTON_YELLOW
			var is_button_A = check_object(obj2.pos, obj1.color) == OBJECTS.BUTTON_AQUA
			if obj2 != obj1 && obj2.pos == obj1.pos && (is_button_G || is_button_Y || is_button_A):
				total_num_on_button += 1
		
		if total_num_on_button > 1:
			checkButtons(check_object(obj1.pos, obj1.color))
	
	# Win condition
	var flags_left := false
	for flag in flags:
		flag.reached = false
		for obj in movables:
			if obj.pos == flag.pos && obj.color & flag.color:
				flag.reached = true
		if !flag.reached:
			flags_left = true
	
	if !flags_left && no_of_stars == 0:
		win_show()



# Converts grid coordinate to position vector
func coord2pos(coord: Vector2i) -> Vector2:
	return GRID_SIZE * (Vector2(coord) + Vector2.ONE / 2)

# Converts position vector to grid position. Used to fetch starting positions of movables
func pos2coord(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos / GRID_SIZE))

# Checks for a wall collision
func can_move(coord: Vector2i, color: COLOR) -> COLLIDE:
	if $Walls.get_cell_atlas_coords(coord).y < 4:
		# wall
		return COLLIDE.COLLIDE
	elif $Walls.get_cell_atlas_coords(coord).y < 8:
		# red wall
		if color & COLOR.RED:
			return COLLIDE.COLLIDE
	elif $Walls.get_cell_atlas_coords(coord).y < 12:
		# blue wall
		if color & COLOR.BLUE:
			return COLLIDE.COLLIDE
	
	# check for gates
	var obj = check_object(coord, color)
	if obj == OBJECTS.GATE_GREEN_H_CLOSED || obj == OBJECTS.GATE_GREEN_V_CLOSED || obj == OBJECTS.GATE_YELLOW_H_CLOSED || obj == OBJECTS.GATE_YELLOW_V_CLOSED || obj == OBJECTS.GATE_AQUA_H_CLOSED || obj == OBJECTS.GATE_AQUA_V_CLOSED:
		return COLLIDE.COLLIDE
	
	# check for crates
	for movable in movables:
		if movable.pos == coord && movable.color & color:
			return COLLIDE.MOVABLE
	
	return COLLIDE.NONE

# Checks for an object that is the same color
func check_object(coord: Vector2i, color: COLOR) -> OBJECTS:
	var atlas : Vector2i = $Objects.get_cell_atlas_coords(coord)
	if atlas.y == 1 && !(color & COLOR.BLUE) || atlas.y == 2 && !(color & COLOR.RED):
		# non matching color
		return OBJECTS.EMPTY
	else:
		return atlas.x as OBJECTS # should correspond to OBJECTS

# Destroys an object of that color
func destroy_object(coord: Vector2i, color: COLOR, obj_type : OBJECTS) -> void:
	var atlas : Vector2i = $Objects.get_cell_atlas_coords(coord)
	var new_v2i_object : Vector2i
	if atlas.y == 0 && color != COLOR.GRAY:
		# Purple object. Destroy corresponding component.
		if color == COLOR.RED:
			# Spawn a blue object
			new_v2i_object = Vector2i(atlas.x, 1)
			$Objects.set_cell(coord, SOURCE, Vector2i(atlas.x, 1))
		elif color == COLOR.BLUE:
			# Spawn a red object
			new_v2i_object = Vector2i(atlas.x, 2)
			$Objects.set_cell(coord, SOURCE, Vector2i(atlas.x, 2))
		else:
			# What is this
			$Objects.set_cell(coord)
			print("Error in destroy_object()")
		
	else:
		$Objects.set_cell(coord)
	
	objects_destoryed.append({
		"move_occurence" : moves,
		"pos" : coord,
		"original_v2i_object" : atlas,
		"obj_type" : obj_type
	})

func checkButtons(object : OBJECTS) -> void:
	if object == OBJECTS.BUTTON_GREEN:
		for y in range(SEARCH_SIZE.y):
			for x in range(SEARCH_SIZE.x):
				var pos := Vector2i(x, y)
				var atlas : Vector2i = $Objects.get_cell_atlas_coords(pos)
				if atlas.x == OBJECTS.GATE_GREEN_H_CLOSED || atlas.x == OBJECTS.GATE_GREEN_V_CLOSED:
					$Objects.set_cell(pos, SOURCE, atlas + Vector2i.RIGHT)
				elif atlas.x == OBJECTS.GATE_GREEN_H_OPEN || atlas.x == OBJECTS.GATE_GREEN_V_OPEN:
							$Objects.set_cell(pos, SOURCE, atlas + Vector2i.LEFT)
	elif object == OBJECTS.BUTTON_YELLOW:
		for y in range(SEARCH_SIZE.y):
			for x in range(SEARCH_SIZE.x):
				var pos := Vector2i(x, y)
				var atlas : Vector2i = $Objects.get_cell_atlas_coords(pos)
				if atlas.x == OBJECTS.GATE_YELLOW_H_CLOSED || atlas.x == OBJECTS.GATE_YELLOW_V_CLOSED:
					$Objects.set_cell(pos, SOURCE, atlas + Vector2i.RIGHT)
				elif atlas.x == OBJECTS.GATE_YELLOW_H_OPEN || atlas.x == OBJECTS.GATE_YELLOW_V_OPEN:
					$Objects.set_cell(pos, SOURCE, atlas + Vector2i.LEFT)
	elif object == OBJECTS.BUTTON_AQUA:
		for y in range(SEARCH_SIZE.y):
			for x in range(SEARCH_SIZE.x):
				var pos := Vector2i(x, y)
				var atlas : Vector2i = $Objects.get_cell_atlas_coords(pos)
				if atlas.x == OBJECTS.GATE_AQUA_H_CLOSED || atlas.x == OBJECTS.GATE_AQUA_V_CLOSED:
					$Objects.set_cell(pos, SOURCE, atlas + Vector2i.RIGHT)
				elif atlas.x == OBJECTS.GATE_AQUA_H_OPEN || atlas.x == OBJECTS.GATE_AQUA_V_OPEN:
					$Objects.set_cell(pos, SOURCE, atlas + Vector2i.LEFT)

func win_show() -> void:
	win = true
	win_label.show()

func defeat_show(obj) -> void:
	defeat = true
	defeat_label.show()
	obj.node.hide()

func defeat_hide() -> void:
	defeat = false
	defeat_label.hide()
	for obj in movables:
		obj.node.show()

# Dumps debug information
func returnPos() -> void:
	return
	@warning_ignore("unreachable_code")
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
		
		print(type + " " + color + " | " + str(obj.moves))
	print()
