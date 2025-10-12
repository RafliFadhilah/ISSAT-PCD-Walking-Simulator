# NPC Animation System

## Overview
Sistem animasi untuk CulturalNPC yang menangani berbagai state animasi NPC berdasarkan interaksi dengan player.

## File Animasi
Lokasi: `Assets/Animation/Papua/`

Animasi yang tersedia:
- `breathing_idle.res` - Animasi idle (bernapas)
- `walking.res` - Animasi berjalan
- `victory.res` - Animasi kemenangan/menerima item
- `talking.res` - Animasi berbicara (opsional)

## Implementasi

### Variabel Sistem Animasi
```gdscript
var animation_player: AnimationPlayer
var current_animation: String = ""
var animation_state: String = "idle"  # idle, walking, victory
```

### Fungsi Utama

#### `setup_animation_system()`
Mencari dan menginisialisasi AnimationPlayer dari hierarchy NPC.

#### `play_animation(anim_name: String, blend_time: float = 0.2)`
Memainkan animasi dengan blending smooth.

Parameter:
- `anim_name`: Nama state animasi ("idle", "walking", "victory", "talking")
- `blend_time`: Durasi transisi antar animasi (default 0.2 detik)

#### `set_animation_state(state: String)`
Mengatur state animasi NPC.

#### `update_animation_based_on_distance()`
Update animasi otomatis berdasarkan jarak player (dipanggil di `_process`).

## State Animasi

### 1. Idle State
- **Trigger**: Default state, atau ketika tidak ada interaksi
- **Animasi**: `breathing_idle`
- **Behavior**: NPC bernapas dengan tenang

### 2. Talking State
- **Trigger**: Saat dialogue dimulai (`_interact()`)
- **Animasi**: `talking` (fallback ke idle jika tidak tersedia)
- **Behavior**: NPC berbicara dengan player
- **Transisi**: Kembali ke idle saat dialogue berakhir

### 3. Victory State
- **Trigger**: Saat NPC menerima artifact quest (`give_artifact_to_npc()`)
- **Animasi**: `victory`
- **Behavior**: NPC merayakan dengan gesture kemenangan
- **Duration**: Otomatis kembali ke idle setelah animasi selesai

### 4. Walking State (Future Implementation)
- **Note**: Saat ini belum diimplementasikan untuk NPC statis
- **Animasi**: `walking`
- **Potential Use**: Untuk NPC yang patrol atau berjalan

## Contoh Penggunaan

### Manual Trigger Animasi
```gdscript
# Play victory animation
npc.play_animation("victory", 0.3)

# Set to idle
npc.set_animation_state("idle")

# Play talking with slower blend
npc.play_animation("talking", 0.5)
```

### Event-Based Animation
Animasi otomatis terpicu pada:
1. **Interaction Start**: Talking animation
2. **Dialogue End**: Idle animation
3. **Quest Complete**: Victory animation → Idle (setelah selesai)

## Animation Mapping
```gdscript
var animation_map = {
    "idle": "breathing_idle",
    "walking": "walking",
    "victory": "victory",
    "talking": "talking"
}
```

## Blend Times
- **Standard Transition**: 0.2 detik
- **Interaction Start**: 0.3 detik (lebih smooth)
- **Dialogue End**: 0.5 detik (lebih perlahan untuk transisi natural)

## Debug
Log animasi dapat dilihat di console:
- `"NPC [nama] - AnimationPlayer found"`
- `"NPC [nama] - Playing animation: [anim_name]"`
- `"Animation not found: [anim_name]"` (warning)

## Notes
- Sistem menggunakan AnimationPlayer yang ada di hierarchy NPC
- Animasi di-blend untuk transisi yang smooth
- Victory animation otomatis kembali ke idle setelah selesai
- System mencegah restart animasi yang sama jika sudah playing

## Future Enhancements
1. **Patrol Animation**: Implementasi walking untuk NPC patrol
2. **Emotion Animations**: Tambahkan animasi emosi (happy, sad, surprised)
3. **Gesture Animations**: Hand gestures untuk dialogue yang lebih ekspresif
4. **Look At Player**: Rotasi kepala NPC mengikuti player
5. **Animation Blending**: Blend multiple animations (misalnya walking + talking)
