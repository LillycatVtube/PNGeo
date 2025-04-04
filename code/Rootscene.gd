extends Node2D



onready var EventP = $EventProcesser
onready var CharRoot = $CharacterRoot
onready var UI = $UI
onready var Spr = $CharacterRoot/RootSprite
onready var Audio = $AudioStreamPlayer
onready var PNGtuber = $PNGtuberMaker
onready var Detect = $StaticBody2D
onready var BG = $BG
onready var Decor = $CharacterRoot/DecorSprite
onready var DecorMaker = $DecorMaker
onready var UIAdv =  $UI_Advanced
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
var ExternalPaths:PoolStringArray
var ExternalSprites:Array
var ExternalMetaSelected:int 

var ScriptKeyColors = ['parent', 'anim', 'event', 'decor', 'root', 'selected']
var TranslatorKeyColors = [ 'load_file', 'on_load', "on", "to"]
var CommandKeyColors = ['spin', 'scale', 'move', 'sin', 'cos', 'reset', 'gravity', 'wrap', 'save', 'save_advanced', 'quit', 'change']
export (float) var MicBounce:float = 0.0
onready var RNG = RandomNumberGenerator.new()
export (float) var BlinkSpeed:float = 0.1
export (bool) var CanBlink:bool
var Blink:bool
var OnTop:bool


func _input(event):
	if PanZooming:
		if event is InputEventMouseMotion && Input.is_mouse_button_pressed(BUTTON_RIGHT):
			Spr.position += event.relative * DragSensitivity
			Decor.position = Spr.position
			
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
			Spr.scale.snapped(Vector2(1,1))
	
	if UI.MoveDecor.pressed:
		if event is InputEventMouseMotion && Input.is_mouse_button_pressed(BUTTON_RIGHT):
			Decor.position += event.relative * DragSensitivity / Vector2(1,1)
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_MIDDLE:
				Decor.position = Vector2(100,100)


func _ready():
	init_audio_device()
	yield(get_tree(), "idle_frame")
	init_layerlist()
	make_filebrowser(0)
	make_filebrowser(1)
	reload()

func init_layerlist():
	var root = UIAdv.LayerList.create_item()
	root.set_text(0, "Root_Anim")
	UIAdv.LayerList.set_hide_root(true)
	var rootspr = UIAdv.LayerList.create_item(root)
	rootspr.set_metadata(ExternalMetaSelected, BaseAnimAdv.new())
	rootspr.set_text(0,"RootSprite")
	var rootdecor = UIAdv.LayerList.create_item(root)
	rootdecor.set_metadata(ExternalMetaSelected, BaseAnimAdv.new())
	rootdecor.set_text(0,"DecorSprite")
	if IO_Manager.AdvSaves.empty() || (!IO_Manager.AdvSaves.has("sprites") && !IO_Manager.AdvSaves.has("events") && !IO_Manager.AdvSaves.has("anims")):
		return

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
	Decor.scale = Spr.scale
	if CanBlink:
		Spr.playing = false
		BlinkBlonk()

var Blonk:int = 0
var BlinkRate:float = 0.1
func BlinkBlonk():
	if !Blink:
		if Spr.frame > 0:
			if BlinkRate >0:
				BlinkRate -= 0.05
			if BlinkRate <= 0:
				Spr.frame -= 1
				BlinkRate = BlinkSpeed
		if Spr.frame == 0:
			Blonk = RNG.randi_range(0, 100)
	if Blink:
		if Spr.frame != 1:
			if BlinkRate >0:
				BlinkRate -= 0.05
			if BlinkRate <= 0:
				Spr.frame += 1
				BlinkRate = BlinkSpeed
		if Spr.frame == 1:
			Blink = false
	
	
	
	if Blonk == 0:
		Blink = true
		Blonk = -1




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
	IO_Manager.Saves["decor"]["index"] = Decor.z_index
	IO_Manager.Saves["blink"] = $UI_Advanced/Control/PanelContainer/MarginContainer/VBoxContainer/GridContainer/BlinkCheckbox.pressed
	IO_Manager.Saves["windowsize"] = OS.window_size
	IO_Manager.Saves["widndowposition"] = OS.window_position
	IO_Manager.Saves["ontop"] = OnTop
	IO_Manager.save()
	for i in CharRoot.get_children():
		if i.name != "RootSprite" && i.name != "DecorSprite":
			IO_Manager.AdvSaves["sprites"][i.name]["pos"] = i.position
			IO_Manager.AdvSaves["sprites"][i.name]["index"] = i.z_index


func reload():
	if IO_Manager.Saves.has("windowposition"):
		OS.window_position = IO_Manager.Saves["windowposition"]
	if IO_Manager.Saves.has("windowsize"):
		OS.window_size = IO_Manager.Saves["windowsize"]
	if IO_Manager.Saves.has("ontop"):
		$UI_Advanced/Control/PanelContainer/MarginContainer/VBoxContainer/GridContainer/AlwaysOnTopButton.pressed = IO_Manager.Saves["ontop"]
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
	Decor.z_index = IO_Manager.Saves["decor"]["index"]
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
	if IO_Manager.Saves.has("blink"):
		$UI_Advanced/Control/PanelContainer/MarginContainer/VBoxContainer/GridContainer/BlinkCheckbox.pressed = IO_Manager.Saves["blink"]
	
	


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


func _on_AddSpr_pressed():
	var sprite = UIAdv.LayerList.create_item(UIAdv.LayerList.get_root())
	sprite.set_metadata(ExternalMetaSelected, BaseSpriteAdv.new())
	make_sprite(sprite.get_metadata(0).Details)
	sprite.set_text(ExternalMetaSelected, sprite.get_metadata(0).Details["data"]["spr"].name)


func _on_LayerList_cell_selected():
	var selected = UIAdv.LayerList.get_selected()
	var data = selected.get_metadata(ExternalMetaSelected)
	for s in CharRoot.get_children():
		if s.name == selected.get_text(0):
			data.Details["data"]["spr"] = s
	fill_out_eventlist(data.Details)
	if data.Details["type"] != 2:
		$UI_Advanced/Control/PanelContainer/MarginContainer/VBoxContainer/PanelContainer/VBoxContainer/GridContainer/AddEvent.disabled = false
	if data.Details["type"] == 2:
		$UI_Advanced/Control/PanelContainer/MarginContainer/VBoxContainer/PanelContainer/VBoxContainer/GridContainer/AddEvent.disabled = true


func make_sprite(data:Dictionary):
	var spr = Sprite.new()
	spr.name = "Sprite"
	CharRoot.add_child(spr,true)
	spr.position = Vector2(100,100)
	spr.z_index = 1
	data["data"]["sprite_path"].append(spr)
	data["data"]["spr"] = spr
	ExternalSprites.append(spr)
	

func free_sprite(data:Dictionary):
	data["data"]["spr"].queue_free()
	


func fill_out_eventlist(res:Dictionary):
	for c in UIAdv.EventList.get_children(): ##Clear out all children
		c.queue_free()
	
	
	var res_copy = res
	
	
	var grid0 = GridContainer.new()
	UIAdv.EventList.add_child(grid0)
	grid0.columns = 2
	var label0 = LineEdit.new()
	var tex = TextureRect.new()
	var hsep0 = HSeparator.new()
	grid0.add_child(label0)
	grid0.add_child(tex)
	label0.name = "NameText"
	label0.set_h_size_flags(3)
	label0.connect("text_changed", self, "_name_changed")
	tex.name = "TypeTexture"
	UIAdv.EventList.add_child(hsep0)
	
	if res_copy["type"] == 0: ## If Sprite
		tex.texture = load("res://assets/sprites/ui/icons/ui_icon_spritenode_1.png")
		##Fill out Generic Data
		label0.text = res_copy["data"]["spr"].name
		#Fill out Positions
		var grid1 = GridContainer.new()
		UIAdv.EventList.add_child(grid1)
		grid1.columns = 2
		grid1.rect_clip_content = true
		var posxlabel = Label.new()
		var posylabel = Label.new()
		var xpos = SpinBox.new()
		var ypos = SpinBox.new()
		grid1.add_child(posxlabel)
		posxlabel.text = "X Position"
		grid1.add_child(xpos)
		xpos.max_value = 10000
		xpos.value = res_copy["data"]["spr"].position.x
		grid1.add_child(posylabel)
		posylabel.text = "Y Position"
		grid1.add_child(ypos)
		ypos.name = "YPos"
		xpos.name = "XPos"
		ypos.max_value = 10000
		ypos.value = res_copy["data"]["spr"].position.y
		xpos.connect("value_changed", self, "_on_XPos_value_changed")
		ypos.connect("value_changed", self, "_on_YPos_value_changed")
		
		
		#Fill out Z Index
		var indexlabel = Label.new()
		var index = SpinBox.new()
		grid1.add_child(indexlabel)
		indexlabel.text = "Z Index"
		grid1.add_child(index)
		index.name = "ZIndex"
		index.connect("value_changed", self, "_on_ZIndex_value_changed")
		index.max_value = 100
		index.min_value = -100
		index.value = res_copy["data"]["spr"].z_index
		
		#Fill out Sprite handeling
		var loadbutton = Button.new()
		var removebutton = Button.new()
		grid1.add_child(loadbutton)
		grid1.add_child(removebutton)
		loadbutton.name = "LoadSprButton"
		removebutton.name = "RemoveSpriteButton"
		loadbutton.connect("pressed", self, "_on_LoadSprButton_pressed")
		removebutton.connect("pressed", self, "clear_sprite_pressed")
		loadbutton.text = "Load Sprite"
		removebutton.text = "Remove Sprite"
	
	if res_copy["type"] == 1: ## If Anim
		tex.texture = load("res://assets/sprites/ui/icons/ui_icon_animnode_1.png")
		##Fill out Generic Data
		label0.text = res_copy["data"]["spr"].name
		if label0.text == "RootSprite" || label0.text == "DecorSprite":
			label0.editable = false
		#Fill out Positions
		var grid1 = GridContainer.new()
		UIAdv.EventList.add_child(grid1)
		grid1.columns = 2
		var posxlabel = Label.new()
		var posylabel = Label.new()
		var xpos = SpinBox.new()
		var ypos = SpinBox.new()
		grid1.add_child(posxlabel)
		posxlabel.text = "X Position"
		grid1.add_child(xpos)
		xpos.max_value = 10000
		xpos.value = res_copy["data"]["spr"].position.x
		grid1.add_child(posylabel)
		posylabel.text = "Y Position"
		grid1.add_child(ypos)
		ypos.name = "YPos"
		xpos.name = "XPos"
		ypos.max_value = 10000
		ypos.value = res_copy["data"]["spr"].position.y
		xpos.connect("value_changed", self, "_on_XPos_value_changed")
		ypos.connect("value_changed", self, "_on_YPos_value_changed")
		
		
		#Fill out Z Index
		var indexlabel = Label.new()
		var index = SpinBox.new()
		grid1.add_child(indexlabel)
		indexlabel.text = "Z Index"
		grid1.add_child(index)
		index.name = "ZIndex"
		index.connect("value_changed", self, "_on_ZIndex_value_changed")
		index.max_value = 100
		index.min_value = -100
		index.value = res_copy["data"]["spr"].z_index
		
		
		#Fill out Animation stuff
		var hsep = HSeparator.new()
		UIAdv.EventList.add_child(hsep)
		var grid2 = GridContainer.new()
		grid2.columns = 2
		UIAdv.EventList.add_child(grid2)
		
		var animLabel = Label.new()
		var animList = OptionButton.new()
		grid2.add_child(animLabel)
		animLabel.text = "Anims"
		animList.name = "AnimList"
		grid2.add_child(animList)
		
		for a in res_copy["data"]["spr"].frames.get_animation_names():
			animList.add_item(a)
		animList.selected = res_copy["data"]["anim_index"]
		animList.connect("item_selected", self, "change_anim")
		
		
		var frameLabel = Label.new()
		var frameCounter = SpinBox.new()
		grid2.add_child(frameLabel)
		frameLabel.text = "Current Frame"
		frameCounter.name = "FrameCounter"
		grid2.add_child(frameCounter)
		frameCounter.value = res_copy["data"]["spr"].frame
		
		
		
		#Fill out another seperator
		var hsep2 = HSeparator.new()
		UIAdv.EventList.add_child(hsep2)
		var grid3 = GridContainer.new()
		grid3.columns = 2
		UIAdv.EventList.add_child(grid3)
		
		#Fill out Sprite handeling
		var loadbutton = Button.new()
		var removebutton = Button.new()
		grid3.add_child(loadbutton)
		grid3.add_child(removebutton)
		if label0.text == "RootSprite" || label0.text == "DecorSprite":
			removebutton.disabled = true
			loadbutton.disabled = true
		loadbutton.name = "LoadAnimButton"
		removebutton.name = "RemoveSpriteButton"
		loadbutton.connect("pressed", self, "_on_LoadSprButton_pressed")
		removebutton.connect("pressed", self, "clear_sprite_pressed")
		loadbutton.text = "Load Anim"
		removebutton.text = "Remove Anim"
	
	
	if res_copy["type"] == 2: ## If Event
		tex.texture = load("res://assets/sprites/ui/icons/ui_icon_eventnode_1.png")
		##Fill out Generic Data
		var selected = UIAdv.LayerList.get_selected()
		label0.text = selected.get_text(0)
		var grid1 = GridContainer.new()
		UIAdv.EventList.add_child(grid1)
		grid1.columns = 3
		grid1.rect_clip_content = true
		
		# Fill out Presets
		var prelabel = Label.new()
		var preset = OptionButton.new()
		var help = Button.new()
		grid1.add_child(prelabel)
		prelabel.text = "Preset"
		grid1.add_child(preset)
		preset.add_item("Empty")
		preset.add_item("Spin")
		preset.add_item("Sin")
		preset.add_item("Cos")
		preset.add_item("Gravity")
		preset.add_item("Wrap")
		if EventP.LockedCode.has(selected.get_text(0)):
			preset.selected = res_copy["preset"]
		preset.name = "PresetButton"
		preset.connect("item_selected", self, "preset_selected")
		grid1.add_child(help)
		help.text = "Help"
		help.connect("pressed", self, "_on_help_pressed")
		
		#Fill out another seperator
		var hsep2 = HSeparator.new()
		UIAdv.EventList.add_child(hsep2)
		
		#Fill out Text Editor
		var textedit = TextEdit.new()
		UIAdv.EventList.add_child(textedit)
		textedit.set_v_size_flags(3)
		textedit.name = "Script"
		
		textedit.syntax_highlighting = true
		textedit.show_line_numbers = true
		
#		for scr in ScriptKeyColors:
#			textedit.add_keyword_color(scr, Color(0.29,0.6, 0.89, 1.0))
#		for com in CommandKeyColors:
#			textedit.add_keyword_color(com, Color(0.3,0.62,0.4, 1.0))
#		for tra in TranslatorKeyColors:
#			textedit.add_keyword_color(tra, Color(0.78,0.36,0.27, 1.0))
		res_copy["editor"] = textedit
		var spr
		for i in CharRoot.get_children():
			if i.name == selected.get_parent().get_text(0):
				spr = i
		textedit.connect("text_changed", self, "_on_Event_text_changed")
		if EventP.LockedCode.has(spr.name):
			textedit.text = EventP.LockedCode[spr.name]
			EventP.process_command(spr.name, textedit.text)
		if !EventP.LockedCode.has(spr.name):
			textedit.text = " "
			EventP.process_command(spr.name, textedit.text)
		#Fill out another grid
		var grid3 = GridContainer.new()
		UIAdv.EventList.add_child(grid3)
		grid3.columns = 3
		
		#Fill out Buttons
		var loadbutton = Button.new()
		var removebutton = Button.new()
		var lockbutton = CheckBox.new()
		grid3.add_child(loadbutton)
		grid3.add_child(removebutton)
		grid3.add_child(lockbutton)
		loadbutton.name = "LoadEventButton"
		removebutton.name = "RemoveEventButton"
		lockbutton.name = "LockEventButton"
		loadbutton.connect("pressed", self, "_on_LoadSprButton_pressed")
		removebutton.connect("pressed", self, "clear_sprite_pressed")
		lockbutton.connect("toggled", self, "_on_LockEvent_toggled")
		if EventP.LockedCode.has(spr.name):
			lockbutton.pressed = true
		if !EventP.LockedCode.has(spr.name):
			lockbutton.pressed = false
		loadbutton.text = "Load Event"
		removebutton.text = "Remove Event"
		lockbutton.text = "Save & Run Event"


func make_filebrowser(type:int):
	if type == 0:
		var file = FileDialog.new()
		UIAdv.add_child(file)
		file.name = "LoadSprFile"
		file.show_hidden_files = false
		file.mode = FileDialog.MODE_OPEN_FILE
		file.set_filters( ["*.png, *.jpg, *.jpeg; Supported Image Type"])
		file.access =FileDialog.ACCESS_FILESYSTEM
		file.resizable = true
		file.dialog_hide_on_ok = true
		file.connect("file_selected", self, "_on_LoadSprFile_file_selected")
	if type == 1:
		var file = FileDialog.new()
		UIAdv.add_child(file)
		file.name = "LoadAnimFile"
		file.show_hidden_files = false
		file.mode = FileDialog.MODE_OPEN_FILE
		file.set_filters( ["*.tres ; Animation file"])
		file.access =FileDialog.ACCESS_FILESYSTEM
		file.resizable = true
		file.dialog_hide_on_ok = true
		file.connect("files_selected", self, "_on_LoadAnimFiles_file_selected")
	if type == 2:
		var file = FileDialog.new()
		UIAdv.add_child(file)
		file.name = "LoadEventFile"
		file.show_hidden_files = false
		file.mode = FileDialog.MODE_OPEN_FILE
		file.set_filters( ["*.gd ; Event file"])
		file.access =FileDialog.ACCESS_FILESYSTEM
		file.resizable = true
		file.dialog_hide_on_ok = true
		file.connect("file_selected", self, "_on_LoadEventFile_file_selected")


func _on_LoadAnimFiles_file_selected(path):
	var selected = UIAdv.LayerList.get_selected()
	var data = selected.get_metadata(ExternalMetaSelected)
	IO_Manager.AdvSaves["sprites"][data.Details["data"]["spr"].name]["pth"] = path
	data.Details["data"]["spr"].set_sprite_frames(load(path))
	change_anim(0)
	data.Details["data"]["spr"].play(data.Details["data"]["selected_anim"])
	fill_out_eventlist(data.Details)
#		if pth.get_extension() == "png" || pth.get_extension() == "jpg" || pth.get_extension() == "jpeg":
#			var image = Image.new()
#			image.load(pth)
#			image.resize(image.get_width(), image.get_height(),Image.INTERPOLATE_NEAREST)
#			image.fix_alpha_edges()
#			var image_tex = ImageTexture.new()
#			image_tex.storage = ImageTexture.STORAGE_COMPRESS_LOSSLESS
#			image_tex.create_from_image(image, 2)
#
#			var selected = UIAdv.LayerList.get_selected()
#			var data = selected.get_metadata(ExternalMetaSelected)
#			data.Details["data"]["spr"].frames.add_frame(data.Details["data"]["selected_anim"], image_tex)
#			change_anim(0)
#			data.Details["data"]["spr"].play(data.Details["data"]["selected_anim"])
#			fill_out_eventlist(data.Details)


func _on_LoadEventFile_file_selected(path):
	var file = File.new()
	file.open(path, 1)
	var selected = UIAdv.LayerList.get_selected()
	EventP.process_command(selected.get_text(0),file.get_as_text())
	selected.get_metadata(0).Details["editor"].text = file.get_as_text()


func _on_LoadSprFile_file_selected(path):
	var image = Image.new()
	image.load(path)
	image.resize(image.get_width(), image.get_height(),Image.INTERPOLATE_NEAREST)
	image.fix_alpha_edges()
	var image_tex = ImageTexture.new()
	image_tex.storage = ImageTexture.STORAGE_COMPRESS_LOSSLESS
	image_tex.create_from_image(image, 2)
	
	var selected = UIAdv.LayerList.get_selected()
	var data = selected.get_metadata(ExternalMetaSelected)
	data.Details["data"]["spr"].texture = image_tex
	IO_Manager.AdvSaves["sprites"][data.Details["data"]["spr"].name]["pth"] = path
#	IO_Manager.AdvSaves["sprites"]["%" % UIAdv.LayerList.get_selected().get_metadata(0).Details["name"]] = path


func _on_LoadSprButton_pressed():
	var selected = UIAdv.LayerList.get_selected()
	var data = selected.get_metadata(0)
	for i in UIAdv.get_children():
		if i.name == "LoadSprFile" && data.Details["type"] == 0:
			i.popup()
		if i.name == "LoadAnimFiles" && data.Details["type"] == 1:
			i.popup()
		if i.name == "LoadEventFile" && data.Details["type"] == 2:
			i.popup()


func _on_ZIndex_value_changed(value):
	var selected = UIAdv.LayerList.get_selected()
	var spr
	for i in CharRoot.get_children():
		if i.name == selected.get_text(0):
			spr = i
	
	spr.z_index = value


func move_spr(is_y:bool, val:int):
	var selected = UIAdv.LayerList.get_selected()
	var data = selected.get_metadata(ExternalMetaSelected)
	var e = data.Details.duplicate(true)
	var spr
	for i in CharRoot.get_children():
		if i.name == selected.get_text(0):
			spr = i
	if !is_y:
		spr.position.x = val
		e["data"]["pos"].x = val
	if is_y:
		spr.position.y = val
		e["data"]["pos"].y = val
	
	_update_Metadata(e)


func _update_Metadata(data:Dictionary):
	var temp_data = data.duplicate(true)
	for child in UIAdv.EventList.get_children():
		if child.name == "NameText":
			temp_data["name"] = child.text
		if child.name == "XPos":
			temp_data["data"]["pos"].x = child.value
		if child.name == "YPos":
			temp_data["data"]["pos"].y = child.value
		if child.name == "ZIndex":
			temp_data["data"]["z_index"] = child.value
		
	if temp_data["type"] == 0:
		var tempres = BaseSpriteAdv.new()
		tempres.Details.merge(temp_data, true)
		
		UIAdv.LayerList.get_selected().set_metadata(0,tempres)
	if temp_data["type"] == 1:
		var tempres = BaseAnimAdv.new()
		tempres.Details.merge(temp_data, true)
		
		UIAdv.LayerList.get_selected().set_metadata(0,tempres)
	if temp_data["type"] == 2:
		var tempres = BaseEventAdv.new()
		tempres.Details.merge(temp_data, true)
		
		UIAdv.LayerList.get_selected().set_metadata(0,tempres)


func _on_XPos_value_changed(value):
	move_spr(false, value)


func _on_YPos_value_changed(value):
	move_spr(true, value)


func _name_changed(new_text):
	var selected = UIAdv.LayerList.get_selected()
	var data = selected.get_metadata(ExternalMetaSelected)
	var e = data.Details
	if e["type"] == 0 || e["type"] == 1:
		var spr
		for i in CharRoot.get_children():
			if i == e["data"]["spr"]:
				spr = i
		
		spr.name = new_text
	selected.set_text(0, new_text)
	e["name"] = new_text
#	_update_Metadata(e)


func _on_LayerList_column_title_pressed(column):
	ExternalMetaSelected = column
	print("EEEEE")


func clear_sprite_pressed():
	var selected = UIAdv.LayerList.get_selected()
	var data = selected.get_metadata(ExternalMetaSelected)
	
	if data.Details["type"] == 0 || data.Details["type"] == 1:
		free_sprite(data.Details)
	if data.Details["type"] == 2:
		pass
	
	for c in UIAdv.EventList.get_children(): ##Clear out all children
		c.queue_free()
	selected.free()
	


func _on_AddAnim_pressed():
	var sprite = UIAdv.LayerList.create_item(UIAdv.LayerList.get_root())
	sprite.set_metadata(ExternalMetaSelected, BaseAnimAdv.new())
	make_anim(sprite.get_metadata(0).Details)
	sprite.set_text(ExternalMetaSelected, sprite.get_metadata(0).Details["data"]["spr"].name)


func make_anim(data:Dictionary):
	var spr = AnimatedSprite.new()
	var spr_frames = SpriteFrames.new()
	spr.name = "Anim"
	CharRoot.add_child(spr,true)
	spr.position = Vector2(100,100)
	spr.z_index = 1
	spr.set_sprite_frames(spr_frames)
	data["data"]["spr_frames"] = spr_frames
	data["data"]["spr"] = spr
	data["data"]["anims"].append(spr_frames.get_animation_names())
	data["data"]["selected_anim"] = "default"
	ExternalSprites.append(spr)


func change_anim(index):
	var selected = UIAdv.LayerList.get_selected()
	var data = selected.get_metadata(ExternalMetaSelected)
	var b = data.Details["data"]["spr"].frames.get_animation_names()
	data.Details["data"]["anim_index"] = index
	data.Details["data"]["selected_anim"] = b[index]
	data.Details["data"]["spr"].play(b[index])


func _on_AddEvent_pressed():
	var selected = UIAdv.LayerList.get_selected()
	var event = UIAdv.LayerList.create_item(selected)
	event.set_metadata(ExternalMetaSelected, BaseEventAdv.new())
	event.set_text(ExternalMetaSelected, "Event")


func preset_selected(index):
	var selected = UIAdv.LayerList.get_selected()
	var data = selected.get_metadata(ExternalMetaSelected)
	data.Details["preset"] = index
	var spr
	for i in CharRoot.get_children():
		if i.name == selected.get_parent().get_text(0):
			spr = i
	if index == 0:
		data.Details["editor"].text = " "
		EventP.process_command(spr.name, data.Details["editor"].text)
	if index == 1:
		data.Details["editor"].text = "root is spin"
		EventP.process_command(spr.name, data.Details["editor"].text)


func _on_Event_text_changed():
	var selected = UIAdv.LayerList.get_selected()
	var data = selected.get_metadata(ExternalMetaSelected)
	var spr
	for i in CharRoot.get_children():
		if i.name == selected.get_parent().get_text(0):
			spr = i
	EventP.current = selected
	EventP.process_command(spr.name, data.Details["editor"].text)
	


func _on_LockEvent_toggled(button_pressed):
	var selected = UIAdv.LayerList.get_selected()
	var data = selected.get_metadata(ExternalMetaSelected)
	var spr
	for i in CharRoot.get_children():
		if i.name == selected.get_parent().get_text(0):
			spr = i
	
	
		
	EventP.lock_command(button_pressed, spr.name, data.Details["editor"].text)
	data.Details["locked"] = button_pressed
	if button_pressed:
		if EventP.parent.has(spr):
			return
		EventP.parent.append(spr)

	if !button_pressed:
		if EventP.parent.has(spr):
			EventP.parent.remove(EventP.parent.find(spr))
	


func _on_AdvancedModeButton_toggled(button_pressed):
	UIAdv.visible = button_pressed
	

func _on_help_pressed():
	$helpwindow.popup()


func _on_HelpText_meta_clicked(meta):
	OS.shell_open(str(meta))


func _on_HelpClose_pressed():
	$helpwindow.hide()


func _on_BlinkCheckbox_toggled(button_pressed):
	CanBlink = button_pressed


func _on_AlwaysOnTopButton_toggled(button_pressed):
	OnTop = button_pressed
	if button_pressed:
		OS.set_window_always_on_top(true)
	if !button_pressed:
		OS.set_window_always_on_top(false)
