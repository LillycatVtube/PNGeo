extends Node2D



onready var UI = $UI
onready var Spr = $CharacterRoot/RootSprite
onready var Audio = $AudioStreamPlayer
export (float, 0, -50) var VolumeThreshold:float = -25 
export (SpriteFrames) var SpriteOverride
export (float) var MIN_DB:float = 60
export (float) var MAX_DB:float = 11050.0
export (int, "normal, happy, excited, angry") var SprExpressionState:int = 0
export (bool) var Talking:bool = false
var SoundVolume
var avatar_path:String
var selected_mic:int
onready var spectrum = AudioServer.get_bus_effect_instance(0,0)


func _ready():
	init_audio_device()
	yield(get_tree(), "idle_frame")
	reload()


func _physics_process(_delta):
	$Pointer.global_position = get_local_mouse_position()


func _process(_delta):
	update_audio()
	update_visuals()
	update_window()
	update()


func update_window():
	if UI.WinTransparent.pressed:
		get_tree().get_root().set_transparent_background(true)
		$Node2D/ColorRect.visible = false
	if !UI.WinTransparent.pressed:
		get_tree().get_root().set_transparent_background(false)
		$Node2D/ColorRect.visible = true
		$Node2D/ColorRect.color = UI.WinColor.color


func update_visuals():
	var expression:String = "normal_" 
	if !UI.EnableKey.pressed:
		SprExpressionState = UI.ExprButton.selected
	
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
	IO_Manager.save()


func reload():
	UI.WinTransparent.pressed = IO_Manager.Saves["trans"]
	UI.WinColor.color = IO_Manager.Saves["window_Color"]
	UI.VoiceLevel.value = IO_Manager.Saves["volume"]
	UI.ExprButton.selected = IO_Manager.Saves["default_Look"]
	UI.EnableKey.pressed = IO_Manager.Saves["enabled_Keys"]
	var f = File.new()
	if IO_Manager.Saves["avatar"] == ""|| !f.file_exists(IO_Manager.Saves["avatar"]):
		return
	else:
		avatar_path = IO_Manager.Saves["avatar"]
		Spr.frames = load(avatar_path)
	UI.MicButton.selected = IO_Manager.Saves["mic"]
	selected_mic = IO_Manager.Saves["mic"]
	AudioServer.capture_device = UI.MicButton.get_item_text(IO_Manager.Saves["mic"])


func _on_SaveSettings_pressed():
	Save_settings()


func _on_MicButton_item_selected(index):
	selected_mic = index
	AudioServer.capture_device = UI.MicButton.get_item_text(index)


var t
func tween_UI_forward():
	if t:
		t.kill()
	t = self.create_tween()
	t.tween_property(UI, "global_position:x", 0, 0.1).from_current().set_trans(Tween.TRANS_LINEAR)


func tween_UI_backward():
	if t:
		t.kill()
	t = self.create_tween()
	t.tween_property(UI, "global_position:x", -206, 0.1).from_current().set_trans(Tween.TRANS_LINEAR)


func _on_StaticBody2D_body_entered(body):
	if body.is_in_group("point"):
		tween_UI_forward()


func _on_StaticBody2D_body_exited(body):
	if body.is_in_group("point"):
		tween_UI_backward()
