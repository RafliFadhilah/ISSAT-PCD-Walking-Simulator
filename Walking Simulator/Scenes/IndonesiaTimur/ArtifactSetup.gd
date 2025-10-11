extends Node
# Script helper untuk setup artifact yang bisa diambil

# Cara menggunakan:
# 1. Attach script WorldCulturalItem.gd ke setiap node artifact
# 2. Set properties yang diperlukan
# 3. Tambahkan collision untuk interaksi

func setup_artifact_pickup():
	"""
	Panduan setup artifact yang bisa diambil:
	
	1. ATTACH SCRIPT ke node artifact:
	   - Select node artifact (contoh: kapak_dani, koteka, dll)
	   - Attach script: res://Systems/Items/WorldCulturalItem.gd
	
	2. SET PROPERTIES di Inspector:
	   - item_name: "kapak_dani" 
	   - cultural_region: "Indonesia Timur"
	   - interaction_prompt: "Press E to collect Kapak Dani"
	
	3. TAMBAHKAN COLLISION AREA:
	   - Tambah child node: Area3D (nama: InteractionArea)
	   - Set collision_layer = 4
	   - Tambah child ke Area3D: CollisionShape3D
	   - Set shape ke BoxShape3D atau sesuai bentuk artifact
	
	4. PASTIKAN ITEM DATA ADA:
	   - Buat file .tres di: Systems/Items/ItemData/kapak_dani.tres
	   - Atau buat otomatis via CulturalItemFactory
	"""
	pass

# Contoh setup untuk kapak_dani:
func setup_kapak_dani_example():
	# Node struktur yang diperlukan:
	# kapak_dani (MeshInstance3D dengan script WorldCulturalItem.gd)
	# ├── InteractionArea (Area3D, collision_layer = 4)
	# │   └── CollisionShape3D (BoxShape3D)
	# └── [model children...]
	
	# Properties yang harus di-set:
	# item_name = "kapak_dani"
	# cultural_region = "Indonesia Timur" 
	# interaction_prompt = "Press E to collect Traditional Dani Axe"
	pass

# Untuk semua artifact di Papua Scene:
var papua_artifacts = [
	{
		"name": "kapak_dani",
		"display_name": "Kapak Dani",
		"description": "Traditional axe used by Dani tribe",
		"cultural_significance": "Symbol of strength and craftsmanship"
	},
	{
		"name": "koteka", 
		"display_name": "Koteka",
		"description": "Traditional clothing of Papua highlands",
		"cultural_significance": "Traditional attire representing Papua culture"
	},
	{
		"name": "noken",
		"display_name": "Noken", 
		"description": "Traditional Papua bag",
		"cultural_significance": "UNESCO-recognized cultural heritage"
	},
	{
		"name": "cenderawasih_pegunungan",
		"display_name": "Cenderawasih Pegunungan",
		"description": "Bird of Paradise sculpture", 
		"cultural_significance": "Symbol of Papua's natural beauty"
	}
]