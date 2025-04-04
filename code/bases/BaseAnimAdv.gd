extends Resource
class_name BaseAnimAdv

export (Dictionary) var Details:Dictionary = {
	"type": 1, # Types: 0 = Sprite, 1 = Anim, 2 = Event
	"name": "Anim",
	"data": {
		"pos": Vector2(100,100),
		"z_index": 1,
		"sprite_path": [],
		"spr": "",
		"spr_frames": "",
		"anims": PoolStringArray(),
		"selected_anim": "",
		"anim_index": 0
	}
}
