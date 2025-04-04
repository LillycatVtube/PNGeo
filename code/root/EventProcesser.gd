extends Node

export (Dictionary) var LockedCode:Dictionary = {}
export (Dictionary) var CurrentCode:Dictionary = {}


var parent:Array = []
var current


func lock_command(unlock:bool ,eventName:String, input:String) -> void:
	if !unlock:
		LockedCode.erase(eventName)
	if unlock:
		LockedCode[eventName] = input


func process_command(eventName:String,input: String) -> void:
	var words = input.split(" ", false)
	if words.size() == 0:
		CurrentCode.erase(eventName)
		return 
	CurrentCode[eventName] = words


func _process(_delta):
	update_commands()


func update_commands() -> void:
	var eee:String = ""
	
	var input = LockedCode.values()
	for i in input:
		eee = i
	var words = eee.split(" ", false)
	if words.size() == 0:
		return 
	var combo:Dictionary = {}
	var names:Array = []
	if !LockedCode.empty():
		for n in LockedCode.keys():
			names.append(n)
			combo[n] = words
#			print(combo)
#			for word in words:
#				if word.has("parent"):
#					combo[n] = word[word.find("parent")]
#				if word.has("decor"):
#					combo[n] = word[word.find("decor")]
#				if word.has("root"):
#					combo[n] = word[word.find("root")]
#				if word.has("spin"):
#					combo[n] = word[word.find("spin")]
#				if word.has("gravity"):
#					combo[n] = word[word.find("gravity")]
#				if word.has("reset"):
#					combo[n] = word[word.find("reset")]
#				if word.has("wrap"):
#					combo[n] = word[word.find("wrap")]
			new_combo(LockedCode[n])
#	combo_maker(names,combo)


func new_combo(expr:String) -> void:
	if LockedCode.empty():
		pass
	if !LockedCode.empty():
		evaluate(expr)


func evaluate(command, variable_names = [], variable_values = []) -> void:
	var expression = Expression.new()
	var error = expression.parse(command, variable_names)
	if error != OK:
		current.add_button(0, load("res://assets/sprites/ui/icons/ui_warning0.png"), -1, true, expression.get_error_text())
#		push_error(expression.get_error_text())
		return
	
	if !code_validated(command):
		print_debug("False")
		return
	var result = expression.execute(variable_values, self)
	
#	if expression.has_execute_failed():
#		return
#		current.add_button(0, load("res://assets/sprites/ui/icons/ui_warning0.png"), -1, true, expression.get_error_text())
	
	if not expression.has_execute_failed():
		for b in current.get_button_count(0):
			current.erase_button(0,b)
		print(str(result))


func code_validated(command) -> bool:
	print(command)
	if (command.find("queue_free") != -1 || command.find("free") != -1 || command.find("OS") != -1 || command.find("IO_Manager") != -1 ||
	command.find("UI") != -1 || command.find("Camera2D") != -1 || command.find("PNGTuber") != -1 || command.find("Audio") != -1||
	command.find("DecorMaker") != -1 || command.find("UI_Advanced") != -1 || command.find("init_layerlist") != -1 ||
	command.find("init_audio_device") != -1 || command.find("Save_settings") != -1):
		return false
	return true



func combo_maker(names:Array,combo:Dictionary) -> void:
	if combo.empty():
		return
	if !combo.empty():
		print(parent)
		for par in parent:
			if combo[names.pop_front()].has("root"):
				var root = get_parent().Spr
				if combo[par.name].has("spin"):
					spin(root)
				if combo[par.name].has("gravity"):
					if root.offset.y <= OS.get_window_size().y:
						root.offset.y += 5
				if combo[par.name].has("wrap"):
					if root.offset.y >= OS.get_window_size().y:
						root.offset.y = -OS.get_window_size().y
				if combo[par.name].has("reset"):
					root.offset = Vector2(0,0)
					root.rotation_degrees = 0
			
			if combo[par.name].has("parent"):
					if combo[par.name].has("spin"):
						spin(par)
					if combo[par.name].has("gravity"):
						if par.offset.y <= OS.get_window_size().y:
							par.offset.y += 5
					if combo[par.name].has("wrap"):
						if par.offset.y >= OS.get_window_size().y:
							par.offset.y = -OS.get_window_size().y
					if combo[par.name].has("reset"):
						par.offset = Vector2(0,0)
						par.rotation_degrees = 0
				
				
			if combo[par.name].has("decor"):
				var decor = get_parent().Decor
				if combo[par.name].has("spin"):
					spin(decor)
				if combo[par.name].has("gravity"):
					if decor.offset.y <= OS.get_window_size().y:
						decor.offset.y += 5
				if combo[par.name].has("wrap"):
					if decor.offset.y >= OS.get_window_size().y:
						decor.offset.y = -OS.get_window_size().y
				if combo[par.name].has("reset"):
					decor.offset = Vector2(0,0)
					decor.rotation_degrees = 0


func spin(type):
	type.rotation_degrees += 10
