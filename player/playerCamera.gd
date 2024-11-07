extends Camera2D

onready var tween = $Tween
onready var zoomBase = Vector2(.65,.65)
# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.zoom = zoomBase

func _chargeZoom():
	var currentZoom = self.zoom
	tween.interpolate_property(self,"zoom", currentZoom, Vector2(.25,.25), .8)
	tween.start()

func _restZoom():
	var currentZoom = self.zoom
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(self, "zoom", currentZoom, Vector2(.3,.3),1.5,Tween.TRANS_EXPO)
	tween.start()

func _clearZoom():
	tween.stop_all()
	tween.remove_all()
	var currentZoom = self.zoom
	tween.interpolate_property(self,"zoom", currentZoom, zoomBase, .3)
	tween.start()

func _tallJumpZoom():
	var currentZoom = self.zoom
	tween.interpolate_property(self,"zoom", currentZoom, Vector2(.7,.7), .5,Tween.TRANS_ELASTIC,Tween.EASE_OUT)
	tween.interpolate_property(self,"offset_v", 0,1.2, .5,Tween.TRANS_LINEAR,Tween.EASE_OUT)
	tween.interpolate_property(self,"zoom", Vector2(.7,.7), zoomBase, 3,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,.5)
	tween.interpolate_property(self,"offset_v", 1.2, 0, 3, Tween.TRANS_LINEAR,Tween.EASE_OUT,.5)
	tween.start()
	
	
