# PSX Asset Organization - Phase 2

**Date:** 2025-08-28  
**Phase:** 2 - PSX Asset Organization  
**Status:** In Progress

## Asset Organization Structure

### Directory Layout
```
Assets/Terrain/Shared/psx_models/
├── trees/
│   ├── jungle/          # Papua region trees
│   └── pine/           # Tambora region trees
├── vegetation/
│   ├── grass/          # Grass variants
│   └── ferns/          # Fern variants
├── stones/
│   └── rocks/          # Stone and rock variants
├── debris/
│   ├── logs/           # Tree logs
│   └── stumps/         # Tree stumps
├── mushrooms/
│   └── variants/       # Mushroom variants
└── textures/
    └── atlases/        # Texture atlases for performance
```

### Asset Categories

#### Trees
- **Jungle Trees:** `tree_1.fbx` to `tree_9.fbx` (Papua region)
- **Pine Trees:** `pine_tree_n_1.fbx` to `pine_tree_n_3.fbx` (Tambora region)

#### Vegetation
- **Grass:** `grass_1.fbx` to `grass_4.fbx`
- **Ferns:** `fern_1.fbx` to `fern_3.fbx`
- **Wheat:** `wheat_1.fbx`, `wheat_1_1.fbx`

#### Stones
- **Rocks:** `stone_1.fbx` to `stone_5.fbx`

#### Debris
- **Logs:** `tree_log_1.fbx`
- **Stumps:** `tree_stump_1.fbx`

#### Mushrooms
- **Variants:** `mushroom_n_1.fbx` to `mushroom_n_4.fbx` (with sub-variants)

## Implementation Notes

### Phase 2 Goals
1. **Organize assets** without affecting existing scenes
2. **Create texture atlases** for performance
3. **Update asset packs** with organized references
4. **Maintain backward compatibility**

### Safety Measures
- ✅ Keep original assets untouched
- ✅ Use copy operations, not moves
- ✅ Test existing scenes after changes
- ✅ Maintain asset pack compatibility
