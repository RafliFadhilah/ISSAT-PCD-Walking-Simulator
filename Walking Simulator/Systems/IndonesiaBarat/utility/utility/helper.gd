# res://scripts/utils.gd
class_name Helper  # optional, agar bisa dipanggil langsung sebagai class

static func normalize_dict(dict: Dictionary) -> Dictionary:
    var result = {}
    for k in dict.keys():
        result[str(k)] = int(dict[k])
    return result