extends Button

export (int, "normal, happy, excited, angry") var buttontype:int
export (String) var action:String = "ui_up"

func _ready():
	set_process_unhandled_key_input(false)
	reload()
	display_key()

func display_key():
	text = "%s" % InputMap.get_action_list(action)[0].as_text()



func _on_toggle(button_pressed):
	set_process_unhandled_key_input(button_pressed)
	if button_pressed:
		text = "..."
	else:
		display_key()


func _unhandled_key_input(event):
	remap_key(event)
	pressed = false


func remap_key(event):
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	if buttontype == 0:
		IO_Manager.Saves["keys"]["mapping"]["norm"] = event
	if buttontype == 1:
		IO_Manager.Saves["keys"]["mapping"]["happy"] = event
	if buttontype == 2:
		IO_Manager.Saves["keys"]["mapping"]["excited"] = event
	if buttontype == 3:
		IO_Manager.Saves["keys"]["mapping"]["angry"] = event
	text = "%s" % event.as_text()


func reload():
	if IO_Manager.Saves["keys"]["mapping"].has_all(["norm", "happy", "excited", "angry"]):
		if buttontype == 0:
			remap_key(IO_Manager.Saves["keys"]["mapping"]["norm"])
		if buttontype == 1:
			remap_key(IO_Manager.Saves["keys"]["mapping"]["happy"])
		if buttontype == 2:
			remap_key(IO_Manager.Saves["keys"]["mapping"]["excited"])
		if buttontype == 3:
			remap_key(IO_Manager.Saves["keys"]["mapping"]["angry"])
		
	if !IO_Manager.Saves["keys"]["mapping"].has_all(["norm", "happy", "excited", "angry"]):
		if buttontype == 0:
			IO_Manager.Saves["keys"]["mapping"]["norm"] = InputMap.get_action_list(action)[0]
		if buttontype == 1:
			IO_Manager.Saves["keys"]["mapping"]["happy"] = InputMap.get_action_list(action)[0]
		if buttontype == 2:
			IO_Manager.Saves["keys"]["mapping"]["excited"] = InputMap.get_action_list(action)[0]
		if buttontype == 3:
			IO_Manager.Saves["keys"]["mapping"]["angry"] = InputMap.get_action_list(action)[0]
