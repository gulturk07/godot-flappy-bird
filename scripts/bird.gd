# script: bird

extends RigidBody2D

onready var state = FlyingState.new(self)
var prev_state

var speed = 50

const STATE_FLYING   = 0
const STATE_FLAPPING = 1
const STATE_HIT      = 2
const STATE_GROUNDED = 3

signal state_changed

func _ready():
	
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process(true)
	
	add_to_group(game.GROUP_BIRDS)
	
	connect("body_entered",self,"_on_body_enter")
	pass

func _process(delta):
	state.update(delta)
	pass
	
func _input(event):
	state.input(event)
	pass
	
func _unhandled_input(event):
	if state.has_method("unhandled_input"):
		state.unhandled_input(event)
	pass

func _on_body_enter(other_body):
	if state.has_method("on_body_enter"):
		state.on_body_enter(other_body) 
	pass

func set_state(new_state):
	state.exit()
	
	prev_state = get_state()
	
	if new_state == STATE_FLYING:
		state = FlyingState.new(self)
	elif new_state == STATE_FLAPPING:
		state = FlappingState.new(self)
	elif new_state == STATE_HIT:
		state = HitState.new(self)
	elif new_state == STATE_GROUNDED:
		state = GroundedState.new(self)
	
	emit_signal("state_changed", self)
	
	pass
	
func get_state():
	if state is FlyingState:
		return STATE_FLYING
	elif state is FlappingState:
		return STATE_FLAPPING
	elif state is HitState:
		return STATE_HIT
	elif state is GroundedState:
		return STATE_GROUNDED 	
	pass
	
# class FlyingState ---------------------------

class FlyingState:
	var bird
	var previous_gravity_scale
	
	func _init(bird):
		self.bird = bird
		bird.get_node("anim").play("flying")
		bird.linear_velocity = Vector2(bird. speed, bird.linear_velocity.y)
		previous_gravity_scale = bird.gravity_scale
		bird.gravity_scale = 0
		pass
		
	func update(delta):
		pass
	
	func input(event):
		pass
		
	func exit():
		bird.gravity_scale = previous_gravity_scale
		bird.get_node("anim").stop()
		bird.get_node("anim_sprite").position = Vector2(0,0)
		pass
		
# class FlappingState ---------------------------

class FlappingState:
	var bird
	
	func _init(bird):
		self.bird = bird
		bird.linear_velocity = Vector2(bird.speed, bird.linear_velocity.y)
		flap()
		pass
		
	func update(delta):
		if rad2deg(bird.rotation) < -30:
			bird.rotation = deg2rad(-30)
			bird.angular_velocity = 0
		
		if bird.get_linear_velocity().y > 0:
			bird.set_angular_velocity(1.5)
		pass
	
	func input(event):
		if event.is_action_pressed("flap"):
			flap()
		pass
	
	func unhandled_input(event):
		if !(event is InputEventMouseButton) or !event.is_pressed() or event.is_echo():
			return
		
		if event.button_index == BUTTON_LEFT:
			flap()
		 
		pass
	
	func on_body_enter(other_body):
		if other_body.is_in_group(game.GROUP_PIPES):
			bird.set_state(bird.STATE_HIT)
		elif other_body.is_in_group(game.GROUP_GROUNDS):
			bird.set_state(bird.STATE_GROUNDED)
		pass 
	
	func flap():
		bird.set_linear_velocity(Vector2(bird.get_linear_velocity().x, -150))
		bird.set_angular_velocity(-3)
		bird.get_node("anim").play("flap")
		
		audio_player.play_wing()
		
		pass
		
	func exit():
		pass		

# class HitState ---------------------------

class HitState:
	var bird
	
	func _init(bird):
		self.bird = bird
		
		bird.linear_velocity = Vector2(0,0)
		bird.angular_velocity = 2
		
		var other_body = bird.get_colliding_bodies()[0]
		bird.add_collision_exception_with(other_body)
		
		audio_player.play_hit()
		audio_player.play_die()
		
		pass
		
	func update(delta):
		pass
	
	func input(event):
		pass
	
	func on_body_enter(other_body):
		if other_body.is_in_group(game.GROUP_GROUNDS):
			bird.set_state(bird.STATE_GROUNDED)
		pass 
		
	func exit():
		pass		
		
# class GroundedState ---------------------------

class GroundedState:
	var bird
	
	func _init(bird):
		self.bird = bird
		bird.linear_velocity = Vector2(0,0)
		bird.angular_velocity = 0
		
		if bird.prev_state != bird.STATE_HIT:
			audio_player.play_hit()
		
		pass
		
	func update(delta):
		pass
	
	func input(event):
		pass
		
	func exit():
		pass		