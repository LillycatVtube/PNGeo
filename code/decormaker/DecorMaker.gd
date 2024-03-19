extends Node2D


onready var PrevSpr = $PrevSpr


func _on_FileDialog_file_selected(path):
	IO_Manager.Saves["decor"]["spr"] = path
	var image = Image.new()
	image.load(path)
	image.resize(image.get_width(), image.get_height(),Image.INTERPOLATE_NEAREST)
	image.fix_alpha_edges()
	var image_tex = ImageTexture.new()
	image_tex.storage = ImageTexture.STORAGE_COMPRESS_LOSSLESS
	image_tex.create_from_image(image, 2)
	
	PrevSpr.frames.add_frame("default", image_tex)




func _on_Clear_pressed():
	PrevSpr.frames.clear("default")


func _on_LoadDecor_pressed():
	$Control/FileDialog.popup()


func _on_Reset_pressed():
	PrevSpr.position = Vector2(100,100)


func _on_CloseWindow_pressed():
	self.visible = false


func _on_FileDialog_files_selected(paths):
	for p in paths:
		var image = Image.new()
		image.load(p)
		image.resize(image.get_width(), image.get_height(),Image.INTERPOLATE_NEAREST)
		image.fix_alpha_edges()
		var image_tex = ImageTexture.new()
		image_tex.storage = ImageTexture.STORAGE_COMPRESS_LOSSLESS
		image_tex.create_from_image(image, 2)
		
		PrevSpr.frames.add_frame("default",image_tex)


func _on_Save_pressed():
	$Control/SaveFile.popup()


func _on_SaveFile_file_selected(path):
	ResourceSaver.save(path, PrevSpr.frames)


func _on_Framerate_value_changed(value):
	PrevSpr.frames.set_animation_speed("default", value)
