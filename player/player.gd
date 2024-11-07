extends KinematicBody2D

onready var sprite = $sprite
onready var floorArea = $floorArea #detect ground
onready var saveStandArea = $saveStandArea #track standling areas
onready var saveStandCollision = $saveStandArea/CollisionShape2D #
onready var checkPointCollision = $checkPointArea/checkPointCollision
onready var timer = $Timer
onready var zTimer = $Timer/zTimer #handle z-index during fall
onready var coyoteTimer = $Timer/coyoteTimer 
var coyoteTime = true
onready var bufferJumpTimer = $Timer/bufferJumpTimer 
onready var tween = $Tween #jump arc
onready var jumpCancelTween = $jumpCancelTween 
onready var camera = $sprite/playerCamera 



#colllision areas for directional interactions - detecting objects in front or behind the player
onready var frontArea = $frontArea 
onready var backArea = $backArea

var playerCanMove = true
var jumping = false
var falling = false
var softCheck = false
var fallSpeed = .25 

var jumpReady = false
var activeJumping
var landing = false
var bufferJump = false
var canBuffer = false
var acting = false #restrict movement

var momentum = 0
var vSpeed = false #vertical speed status
var speed = 150
var maxSpeed = 200

var lastKnownPosition = Vector2.ZERO

var velocity = Vector2.ZERO
var direction = Vector2.ZERO
var inputVector = Vector2.ZERO


#runs whenscene is ready
func _ready() -> void:
	lastKnownPosition = global_position #stores starting postion
	
	
	
#main loop - called every frame - h  andles movement, jumping, falling
func _process(delta: float):

#control player speed (decrease/increase)
	if speed > maxSpeed:
		speed -= 400 * delta
	if speed <100:
		speed += 200 * delta

#trigger coyote time
	if floorArea.get_overlapping_bodies().size() == 0 and floorArea.get_overlapping_areas().size() ==0 and jumping == false and falling == false and softCheck == false:
		if coyoteTimer.time_left == 0 and falling == false and coyoteTime == true:
			coyoteTimer.start()
		elif coyoteTime == false:
			if frontArea.get_overlapping_bodies().size() > 0:
				self.z_index = -3
			else:
				self.z_index = 0
			
			saveStandCollision.disabled = true
			falling = true
			softCheck = true
			zTimer.start()
			timer.start()
	elif floorArea.get_overlapping_bodies().size() > 0 or floorArea.get_overlapping_areas().size() > 0 and jumping == false:
		coyoteTime = true
	elif jumping == true:
		coyoteTime = false
		
#descent speed
	if falling == true:
		checkPointCollision.disabled = true
		GlobalLevelStats.vSpeed = false
		maxSpeed = 200
		jumpReady = false
		jumping = false
		self.global_position.y += fallSpeed
		fallSpeed += 15 * delta #fall speed

	if playerCanMove == false:
		velocity = Vector2.ZERO

#player inp horiontal/vertical movement
	if playerCanMove == true:
		var accelleration = speed *4
		var friction = speed * 7
		inputVector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
		inputVector.y = (Input.get_action_strength("down") - Input.get_action_strength("up"))/2 
		inputVector = inputVector.normalized()
			
		if inputVector.x >0:
			sprite.flip_h = false
		elif inputVector.x <0:
			sprite.flip_h = true
			
#movement/velocity
		if inputVector != Vector2.ZERO:
			velocity = velocity.move_toward(inputVector * speed, accelleration * delta)
		elif inputVector == Vector2.ZERO:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
		velocity = move_and_slide(velocity)
	
#momentum/max speed adjustments
	if abs(velocity.x) > 85 or abs(velocity.y) > 65 and GlobalLevelStats.vSpeed == false:
		if jumping == false and GlobalLevelStats.overCharge == true:
			GlobalLevelStats.momentum += 12* delta
	elif GlobalLevelStats.momentum > 0:
		GlobalLevelStats.momentum -= 85 * delta
		
	if GlobalLevelStats.momentum >= 20 and GlobalLevelStats.vSpeed == false:
		GlobalLevelStats.vSpeed = true
		maxSpeed = 145
		speed = maxSpeed
		
#momentum reset
	if inputVector == Vector2.ZERO and GlobalLevelStats.vSpeed == true:
		GlobalLevelStats.momentum = 0
		GlobalLevelStats.vSpeed = false
		maxSpeed = 200
		speed = 140
		

	if bufferJump == true and jumping == false:
		bufferJump = false
		if GlobalLevelStats.wings == true:
			_normalJump()
		else:
			_winglessJump()


#jump inputs
func _input(_event: InputEvent):
	if falling == false and playerCanMove == true:
		if Input.is_action_just_pressed("jump") and jumping == true and canBuffer == true:
			acting = true
			bufferJump = true
			canBuffer = false
			bufferJumpTimer.start()
		
		elif Input.is_action_just_pressed("jump") and jumping == false and acting == false and GlobalLevelStats.wings == false:
			_winglessJump()
			
			
#cancel jump if released button
		if Input.is_action_just_released("jump") and jumping == true and activeJumping == true:
			_normalJumpCancel()


#func _winglessJumpActiveless():
#	pass

#standard jump
func _winglessJump():
	if falling == false:
		canBuffer = true
		activeJumping = true
		jumping = true

#upward arc to create jump arc
		tween.interpolate_property(sprite,"position:y", 0, -30, .25, Tween.TRANS_QUINT,Tween.EASE_OUT)
		tween.start()

		yield(tween,"tween_all_completed")
		if activeJumping == true:

#brings player back down
			tween.interpolate_property(sprite,"position:y", -30, 0, .27, Tween.TRANS_SINE,Tween.EASE_IN)
			tween.start()
			yield(tween,"tween_all_completed")
			if activeJumping == true:
				jumping = false
				acting = false

#placeholder
func _fullJump():
	pass
	
#placholder
func _normalJump():
	pass

#cancel jump midair
func _normalJumpCancel():
		activeJumping = false 
		tween.emit_signal("tween_all_completed") #cancels upward movement
		tween.remove_all() #clears tween animation
		activeJumping = false


		var spritePos = sprite.position.y

		tween.interpolate_property(sprite,"position:y", spritePos, 0, (spritePos/100 * -1),Tween.TRANS_SINE,Tween.EASE_IN)
		tween.start()
		yield(tween,"tween_all_completed") #completes downard movement
		jumping = false
		acting = false


#occurs when timer expires (resets player and state)
func _on_Timer_timeout():
	

	camera._clearZoom()
	inputVector = Vector2.ZERO
	GlobalLevelStats.momentum = 0

#resets player pos, resapwn to checkpoint
	self.global_position = GlobalLevelStats.checkPoint
	
	playerCanMove = false
	falling = false
	acting = false
	checkPointCollision.disabled = false
	self.z_index = 0
	saveStandCollision.disabled = false
	yield(get_tree().create_timer(.2),"timeout") #small delay post respawn
	playerCanMove = true
	softCheck = false #new fall checks
	fallSpeed = .25
	

func _on_zTimer_timeout() -> void:
	self.z_index = -3

func _on_bufferJumpTimer_timeout() -> void:
	bufferJump = false

func _on_coyoteTimer_timeout() -> void:
	coyoteTime = false
