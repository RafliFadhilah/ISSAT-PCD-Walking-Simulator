extends Node3D

@onready var pot_inventory = {}
signal inventory_updated(inventory)


func add(food: Node3D) -> void:
    if food.has_meta("added_to_pot") and food.get_meta("added_to_pot"):
        print("Bahan ini sudah ditambahkan ke pot!")
        return
    
    # Tambahkan bahan ke pot
    if pot_inventory.has(food.name):
        pot_inventory[food.name] += 1
    else:
        pot_inventory[food.name] = 1
    print("Bahan ditambahkan ke pot:", food.name, "Jumlah sekarang:", pot_inventory[food.name])
    
    # Emit signal untuk update UI
    emit_signal("inventory_updated", pot_inventory)


func cook() -> void:
    if not pot_inventory:
        print("Pot kosong, tidak ada bahan untuk dimasak.")
        return
    
    # Proses memasak bahan-bahan di pot
    print("Memasak bahan-bahan:", pot_inventory)
    
    # Reset inventory setelah memasak
    pot_inventory.clear()
    
    # Emit signal untuk update UI
    emit_signal("inventory_updated", pot_inventory)
    
    # Simulasi hasil masakan
    print("Masakan selesai!")

func display_inventory() -> void:
    if pot_inventory.empty():
        print("Pot kosong.")
    else:
        print("Isi pot saat ini:")
        for food_name in pot_inventory.keys():
            print("- %s: %d" % [food_name, pot_inventory[food_name]])
