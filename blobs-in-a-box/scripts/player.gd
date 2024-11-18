extends AnimatedSprite2D

func _process(_delta):
	if Input.is_action_pressed("Right"):
		play("right")
	elif Input.is_action_pressed("Left"):
		play("left")
	elif Input.is_action_pressed("Up"):
		play("up")
	elif Input.is_action_pressed("Down"):
		play("down")
	else:
		play("default")
