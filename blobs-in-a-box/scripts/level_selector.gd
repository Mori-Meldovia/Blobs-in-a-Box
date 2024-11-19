extends Control

var num_grids = 1
var num = 1

@onready var gridbox = $MarginContainer/VBoxContainer/GridContainer

func _ready():
	# Number all the level boxes and unlock them
	# Replace with your game's level/unlocks/etc.
	# You can also connect the "level_selected" signals here
	num_grids = gridbox.get_child_count()
	for box in gridbox.get_children():
		box.level_num = num
		box.locked = false
		num += 1


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
