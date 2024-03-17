extends Node


var SaveFileLocation:String = OS.get_user_data_dir()
var Saves:Dictionary = {}

var SavePth:String = ""


func get_pth() -> Dictionary:
	return{
		"SaveFolder": SaveFileLocation, 
		"SavePath": SaveFileLocation + "/Saves.tres"
	}


func _ready():
	initalize()


func initalize() -> void:
	var dir = Directory.new()
	var files = get_pth()
	
	
	if !dir.dir_exists(files["SaveFolder"]):
		dir.make_dir(SaveFileLocation)
		print("Made Folder at: %s" % SaveFileLocation)
	if dir.dir_exists(files["SaveFolder"]):
		dir.open(files["SaveFolder"])
		if !dir.file_exists(files["SavePath"]):
			create_empty_file(files["SavePath"])
		if dir.file_exists(files["SavePath"]):
			load_save(files["SavePath"])


func create_empty_file(path:String) -> void:
	var temp = Resource.new()
	temp.set("script", load("res://code/io/SaveMain.gd"))
	temp.SaveMain = {
		"trans": false,
		"window_Color": Color(0,1.0,0,1.0),
		"volume": 0.4,
		"default_Look": 0,
		"enabled_Keys": false,
		"keys" : {"mapping": {}},
		"avatar": "",
		"pan_zoom": {"pan": Vector2(), "zoom": Vector2(1,1)},
		"decor": {"pos": Vector2(), "spr": "", "enabled": false},
		"mic": int()
		}
	ResourceSaver.save(path, temp)


func load_save(path:String) -> void:
	if Saves.empty():
		var temp = load(path)
		if temp != null:
			if temp.SaveMain.empty():
				"ERR: No SaveMain Assets are available"
				return
			if !temp.SaveMain.empty():
				Saves = temp.SaveMain.duplicate()
				print("Load Successful")
	if !Saves.empty():
		return


func save() -> void:
	if Saves.empty():
		return
	if !Saves.empty():
		var temp = Resource.new()
		temp.set("script", load("res://code/io/SaveMain.gd"))
		temp.SaveMain = Saves.duplicate(true)
		ResourceSaver.save(get_pth()["SavePath"], temp)
