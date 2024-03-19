extends Node2D



onready var UI = $UI
onready var Spr = $CharacterRoot/RootSprite
onready var Audio = $AudioStreamPlayer
onready var PNGtuber = $PNGtuberMaker
onready var Detect = $StaticBody2D
onready var BG = $BG
onready var Decor = $CharacterRoot/DecorSprite
onready var DecorMaker = $DecorMaker
export (float, 0, -50) var VolumeThreshold:float = -25 
export (SpriteFrames) var SpriteOverride
export (float) var MIN_DB:float = 60
export (float) var MAX_DB:float = 11050.0
export (int, "normal, happy, excited, angry") var SprExpressionState:int = 0
export (bool) var Talking:bool = false
var SoundVolume
var avatar_path:String
var decor_path:String
var selected_mic:int
onready var spectrum = AudioServer.get_bus_effect_instance(0,0)
export (bool) var PanZooming:bool
var ZoomSpeed:float =0.05
var MinZoom:float = 0.001
var MaxZoom:float = 2.0
var DragSensitivity:float = 1.0



func _input(event):
	if PanZooming:
		if event is InputEventMouseMotion && Input.is_mouse_button_pressed(BUTTON_RIGHT):
			Spr.position += event.relative * DragSensitivity
			
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_WHEEL_UP:
				Spr.scale += Vector2(ZoomSpeed,ZoomSpeed) * Spr.scale
			if event.button_index == BUTTON_WHEEL_DOWN:
				Spr.scale -= Vector2(ZoomSpeed,ZoomSpeed) * Spr.scale
			if event.button_index == BUTTON_MIDDLE:
				Spr.scale = Vector2(1,1)
				Spr.position = Vector2(100,100)
			Spr.scale.x = clamp(Spr.scale.x, MinZoom, MaxZoom)
			Spr.scale.y = clamp(Spr.scale.y, MinZoom, MaxZoom)
	
	if UI.MoveDecor.pressed:
		if event is InputEventMouseMotion && Input.is_mouse_button_pressed(BUTTON_RIGHT):
			Decor.position += event.relative * DragSensitivity / Vector2(1,1)


func _ready():
	init_audio_device()
	yield(get_tree(), "idle_frame")
	reload()


func _physics_process(_delta):
	$Pointer.global_position = get_local_mouse_position()
	BG.position = $Camera2D.position
	PNGtuber.position = $Camera2D.position
	Detect.position = $Camera2D.position
	BG.scale = $Camera2D.zoom
	PNGtuber.scale = $Camera2D.zoom
	UI.scale = $Camera2D.zoom
	Detect.scale = $Camera2D.zoom
	DecorMaker.scale = $Camera2D.zoom
	DecorMaker.position = $Camera2D.position


func _process(_delta):
	update_audio()
	update_visuals()
	update_window()
	update()
	


func update_window():
	if UI.WinTransparent.pressed:
		get_tree().get_root().set_transparent_background(true)
		$BG/ColorRect.visible = false
	if !UI.WinTransparent.pressed:
		get_tree().get_root().set_transparent_background(false)
		$BG/ColorRect.visible = true
		$BG/ColorRect.color = UI.WinColor.color
	if UI.PanZoom.pressed:
		UI.MoveDecor.pressed = false
		PanZooming = true
		$BG/Label.visible = true
	if !UI.PanZoom.pressed:
		PanZooming = false
		$BG/Label.visible = false
	if UI.MoveDecor.pressed:
		UI.PanZoom.pressed = false
		$BG/Label2.visible = true
	if !UI.MoveDecor.pressed:
		$BG/Label2.visible = false
	
	if !OS.is_window_focused():
		tween_UI_backward()


func update_visuals():
	var expression:String = "normal_" 
	if !UI.EnableKey.pressed:
		SprExpressionState = UI.ExprButton.selected
		UI.NormalKey.disabled = true
		UI.AngryKey.disabled = true
		UI.HappyKey.disabled = true
		UI.ExcitedKey.disabled = true
	
	if UI.EnableKey.pressed:
		UI.NormalKey.disabled = false
		UI.AngryKey.disabled = false
		UI.HappyKey.disabled = false
		UI.ExcitedKey.disabled = false
		if Input.is_action_just_pressed("ui_up"):
			SprExpressionState = 0
		if Input.is_action_just_pressed("ui_down"):
			SprExpressionState = 1
		if Input.is_action_just_pressed("ui_left"):
			SprExpressionState = 2
		if Input.is_action_just_pressed("ui_right"):
			SprExpressionState = 3
	
	if SprExpressionState == 0:
		expression = "normal_" 
	if SprExpressionState == 1:
		expression = "happy_" 
	if SprExpressionState == 2:
		expression = "excited_" 
	if SprExpressionState == 3:
		expression = "angry_" 
	if Talking:
		Spr.play(expression + "speak")
	if !Talking:
		Spr.play(expression + "silent")
	
	
	#--Decor--
	if UI.EnableDecor.pressed:
		Decor.visible = true
	if !UI.EnableDecor.pressed:
		Decor.visible = false


func update_audio():
	
	SoundVolume = spectrum.get_magnitude_for_frequency_range(0,MAX_DB).length()
	var energy = clamp((MIN_DB + linear2db(SoundVolume)) / MIN_DB, 0, 1)
	if energy <= UI.VoiceLevel.value:
		Talking = false
		
	if energy > UI.VoiceLevel.value:
		Talking = true
	update()


func init_audio_device():
	for i in AudioServer.get_device_list():
		UI.MicButton.add_item(i)


func _on_OpenMaker_pressed():
	$PNGtuberMaker.visible = true


func _on_LoadPNGtuber_file_selected(path):
	Spr.frames = load(path)
	avatar_path = path


func _on_LoadTuber_pressed():
	$UI/RootUI/LoadPNGtuber.popup()


func Save_settings():
	IO_Manager.Saves["trans"] = UI.WinTransparent.pressed
	IO_Manager.Saves["window_Color"] = UI.WinColor.color
	IO_Manager.Saves["volume"] = UI.VoiceLevel.value
	IO_Manager.Saves["default_Look"] = UI.ExprButton.selected
	IO_Manager.Saves["enabled_Keys"] = UI.EnableKey.pressed
	IO_Manager.Saves["avatar"] = avatar_path
	IO_Manager.Saves["mic"] = selected_mic
	IO_Manager.Saves["pan_zoom"] = {"pan": Spr.position, "zoom": Spr.scale}
	IO_Manager.Saves["decor"]["pos"] = Decor.position
	IO_Manager.Saves["decor"]["enabled"] = Decor.visible
	IO_Manager.Saves["decor"]["spr"] = decor_path
	IO_Manager.save()


func reload():
	$Camera2D.zoom = Vector2(1,1)
	$Camera2D.position = Vector2(0,0)
	UI.WinTransparent.pressed = IO_Manager.Saves["trans"]
	UI.WinColor.color = IO_Manager.Saves["window_Color"]
	UI.VoiceLevel.value = IO_Manager.Saves["volume"]
	UI.ExprButton.selected = IO_Manager.Saves["default_Look"]
	UI.EnableKey.pressed = IO_Manager.Saves["enabled_Keys"]
	UI.MicButton.selected = IO_Manager.Saves["mic"]
	selected_mic = IO_Manager.Saves["mic"]
	AudioServer.capture_device = UI.MicButton.get_item_text(IO_Manager.Saves["mic"])
	Spr.scale= IO_Manager.Saves["pan_zoom"]["zoom"]
	Spr.position = IO_Manager.Saves["pan_zoom"]["pan"]
	Decor.position = IO_Manager.Saves["decor"]["pos"]
	UI.EnableDecor.pressed = IO_Manager.Saves["decor"]["enabled"]
	var f = File.new()
	if f.file_exists(IO_Manager.Saves["decor"]["spr"]):
		var e = load(IO_Manager.Saves["decor"]["spr"])
		decor_path = IO_Manager.Saves["decor"]["spr"]
		Decor.frames = e
		Decor.play("default")
	if f.file_exists(IO_Manager.Saves["avatar"]):
		avatar_path = IO_Manager.Saves["avatar"]
		Spr.frames = load(avatar_path)
	


func _on_SaveSettings_pressed():
	Save_settings()


func _on_MicButton_item_selected(index):
	selected_mic = index
	AudioServer.capture_device = UI.MicButton.get_item_text(index)


var t
func tween_UI_forward():
	if t:
		t.kill()
	if !OS.is_window_focused():
		tween_UI_backward()
	if OS.is_window_focused():
		
		t = self.create_tween()
		t.tween_property(UI, "global_position", Vector2(0,0) + $Camera2D.position, 0.1).from_current().set_trans(Tween.TRANS_LINEAR)


func tween_UI_backward():
	if t:
		t.kill()
	t = self.create_tween()
	t.tween_property(UI, "global_position", Vector2(-1000,0) + $Camera2D.position + $Camera2D.zoom, 0.1).from_current().set_trans(Tween.TRANS_LINEAR)


func _on_StaticBody2D_body_entered(body):
	if body.is_in_group("point") && OS.is_window_focused():
		tween_UI_forward()


func _on_StaticBody2D_body_exited(body):
	if body.is_in_group("point"):
		tween_UI_backward()


func _on_OpenDecorMaker_pressed():
	UI.PanZoom.pressed = false
	
	DecorMaker.visible = true


func _on_LoadDecor_file_selected(path):
	Decor.frames = load(path)
	decor_path = path
	Decor.play("default")


func _on_LoadDecor_pressed():
	$UI/RootUI/LoadDecor.popup()


func _on_OpenSaveFolder_pressed():
	OS.shell_open(IO_Manager.SaveFileLocation)
