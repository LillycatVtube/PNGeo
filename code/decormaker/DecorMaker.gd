extends Node2D



export (bool) var MovingDecor:bool = false


func _process(_delta):
	if MovingDecor:
		$Control/Label.visible = true
	if !MovingDecor:
		$Control/Label.visible = false
	if $Control/PanelContainer/MarginContainer/VBoxContainer/GridContainer/MoveDecorButton.pressed:
		MovingDecor = true
	if !$Control/PanelContainer/MarginContainer/VBoxContainer/GridContainer/MoveDecorButton.pressed:
		MovingDecor = false

func _on_FileDialog_file_selected(path):
	IO_Manager.Saves["decor"]["spr"] = path
	var image = Image.new()
	image.load(path)
	
	var image_tex = ImageTexture.new()
	image_tex.create_from_image(image)
	get_tree().get_nodes_in_group("root")[0].Decor.texture = image_tex




func _on_Clear_pressed():
	get_tree().get_nodes_in_group("root")[0].Decor.texture = null


func _on_LoadDecor_pressed():
	$Control/FileDialog.popup()


func _on_Reset_pressed():
	get_tree().get_nodes_in_group("root")[0].Decor.position = Vector2(100,100)


func _on_CloseWindow_pressed():
	MovingDecor = false
	$Control/PanelContainer/MarginContainer/VBoxContainer/GridContainer/MoveDecorButton.pressed = false
	self.visible = false
