extends Node2D


onready var PrevSpr = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer2/Control/PreviewSpr
onready var Silent_Norm = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/B0
onready var Silent_Happy = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/B1
onready var Silent_Excited = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/B2
onready var Silent_Angry = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/B3

onready var Talking_Norm = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/B4
onready var Talking_Happy = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/B5
onready var Talking_Excited = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/B6
onready var Talking_Angry = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/B7

onready var FrameCounter = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/GridContainer/FrameCounter
onready var Save = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/Button9
onready var Close = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/Button12
onready var Load = $Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/Button
export (int) var SelectedButtons:int = -1
var PausedAnim:bool = false


func _ready():
	self.visible = false
	PrevSpr.frames = SpriteFrames.new()
	PrevSpr.frames.add_animation("normal_silent")
	PrevSpr.frames.add_animation("normal_speak")
	PrevSpr.frames.add_animation("happy_silent")
	PrevSpr.frames.add_animation("happy_speak")
	PrevSpr.frames.add_animation("excited_silent")
	PrevSpr.frames.add_animation("excited_speak")
	PrevSpr.frames.add_animation("angry_silent")
	PrevSpr.frames.add_animation("angry_speak")

func _process(_delta):
	if SelectedButtons == -1:
		Load.disabled = true
		Save.disabled = true
	var ButtonG = Silent_Norm.group.get_pressed_button()
	if ButtonG == null:
		SelectedButtons = -1
	if ButtonG != null:
		var temp = ButtonG.name.split("B")
		SelectedButtons = str2var(temp[1])
		Load.disabled = false
		Save.disabled = false
		
		if SelectedButtons == 0:
			PrevSpr.play("normal_silent")
			FrameCounter.max_value = PrevSpr.frames.get_frame_count("normal_silent")
		if SelectedButtons == 1:
			PrevSpr.play("happy_silent")
			FrameCounter.max_value = PrevSpr.frames.get_frame_count("happy_silent")
		if SelectedButtons == 2:
			PrevSpr.play("excited_silent")
			FrameCounter.max_value = PrevSpr.frames.get_frame_count("excited_silent")
		if SelectedButtons == 3:
			PrevSpr.play("angry_silent")
			FrameCounter.max_value = PrevSpr.frames.get_frame_count("angry_silent")
		if SelectedButtons == 4:
			PrevSpr.play("normal_speak")
			FrameCounter.max_value = PrevSpr.frames.get_frame_count("normal_speak")
		if SelectedButtons == 5:
			PrevSpr.play("happy_speak")
			FrameCounter.max_value = PrevSpr.frames.get_frame_count("happy_speak")
		if SelectedButtons == 6:
			PrevSpr.play("excited_speak")
			FrameCounter.max_value = PrevSpr.frames.get_frame_count("excited_speak")
		if SelectedButtons == 7:
			PrevSpr.play("angry_speak")
			FrameCounter.max_value = PrevSpr.frames.get_frame_count("angry_speak")
		if !PausedAnim:
			FrameCounter.value = PrevSpr.frame
		if PausedAnim:
			PrevSpr.frame = FrameCounter.value



func _on_OpenSprPath_file_selected(path):
	var image = Image.new()
	image.load(path)
	
	var image_tex = ImageTexture.new()
	image_tex.create_from_image(image)
	
	if SelectedButtons == 0:
		PrevSpr.frames.add_frame("normal_silent", image_tex)
	if SelectedButtons == 1:
		PrevSpr.frames.add_frame("happy_silent", image_tex)
	if SelectedButtons == 2:
		PrevSpr.frames.add_frame("excited_silent", image_tex)
	if SelectedButtons == 3:
		PrevSpr.frames.add_frame("angry_silent", image_tex)
	if SelectedButtons == 4:
		PrevSpr.frames.add_frame("normal_speak", image_tex)
	if SelectedButtons == 5:
		PrevSpr.frames.add_frame("happy_speak", image_tex)
	if SelectedButtons == 6:
		PrevSpr.frames.add_frame("excited_speak", image_tex)
	if SelectedButtons == 7:
		PrevSpr.frames.add_frame("angry_speak", image_tex)


func _on_SaveSprPath_file_selected(path):
	ResourceSaver.save(path, PrevSpr.frames)


func _on_Button12_pressed():
	for i in PrevSpr.frames.get_frame_count("normal_silent"):
		PrevSpr.frames.remove_frame("normal_silent", 0)
	for i in PrevSpr.frames.get_frame_count("normal_speak"):
		PrevSpr.frames.remove_frame("normal_speak", 0)
	for i in PrevSpr.frames.get_frame_count("happy_silent"):
		PrevSpr.frames.remove_frame("happy_silent", 0)
	for i in PrevSpr.frames.get_frame_count("happy_speak"):
		PrevSpr.frames.remove_frame("happy_speak", 0)
	for i in PrevSpr.frames.get_frame_count("excited_silent"):
		PrevSpr.frames.remove_frame("excited_silent", 0)
	for i in PrevSpr.frames.get_frame_count("excited_speak"):
		PrevSpr.frames.remove_frame("excited_speak", 0)
	for i in PrevSpr.frames.get_frame_count("angry_silent"):
		PrevSpr.frames.remove_frame("angry_silent", 0)
	for i in PrevSpr.frames.get_frame_count("angry_speak"):
		PrevSpr.frames.remove_frame("angry_speak", 0)
	self.visible = false


func _on_Button9_pressed():
	$SaveSprPath.popup()


func _on_Button_pressed():
	$OpenSprPath.popup()


func _on_DeleteFrame_pressed():
	if SelectedButtons == 0:
		PrevSpr.frames.remove_frame("normal_silent", PrevSpr.frame)
	if SelectedButtons == 1:
		PrevSpr.frames.remove_frame("happy_silent", PrevSpr.frame)
	if SelectedButtons == 2:
		PrevSpr.frames.remove_frame("excited_silent", PrevSpr.frame)
	if SelectedButtons == 3:
		PrevSpr.frames.remove_frame("angry_silent", PrevSpr.frame)
	if SelectedButtons == 4:
		PrevSpr.frames.remove_frame("normal_speak", PrevSpr.frame)
	if SelectedButtons == 5:
		PrevSpr.frames.remove_frame("happy_speak", PrevSpr.frame)
	if SelectedButtons == 6:
		PrevSpr.frames.remove_frame("excited_speak", PrevSpr.frame)
	if SelectedButtons == 7:
		PrevSpr.frames.remove_frame("angry_speak", PrevSpr.frame)


func _on_FPSCounter_value_changed(value):
	if SelectedButtons == 0:
		PrevSpr.frames.set_animation_speed("normal_silent", value)
	if SelectedButtons == 1:
		PrevSpr.frames.set_animation_speed("happy_silent", value)
	if SelectedButtons == 2:
		PrevSpr.frames.set_animation_speed("excited_silent", value)
	if SelectedButtons == 3:
		PrevSpr.frames.set_animation_speed("angry_silent", value)
	if SelectedButtons == 4:
		PrevSpr.frames.set_animation_speed("normal_speak", value)
	if SelectedButtons == 5:
		PrevSpr.frames.set_animation_speed("happy_speak", value)
	if SelectedButtons == 6:
		PrevSpr.frames.set_animation_speed("excited_speak", value)
	if SelectedButtons == 7:
		PrevSpr.frames.set_animation_speed("angry_speak", value)


func _on_PausePlay_toggled(button_pressed):
	if button_pressed == true:
		$Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/GridContainer2/PausePlay.text = "play"
		PrevSpr.playing = false
		PausedAnim = true
	if button_pressed == false:
		$Control/PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/GridContainer2/PausePlay.text = "pause"
		PrevSpr.playing = true
		PausedAnim = false
