# Papua Quest System - Documentation

## Overview
Sistem quest telah berhasil diimplementasikan untuk scene Papua, di mana setiap NPC memiliki quest unik untuk meminta artifact tertentu yang tersebar di map.

## Quest Assignments

### 1. Cultural Guide
- **Artifact Required:** `noken`
- **Quest Title:** "Sacred Noken Collection"
- **Quest Description:** "I need to collect the Sacred Noken for our cultural preservation project. Can you help me find it?"

### 2. Archaeologist 
- **Artifact Required:** `kapak_dani`
- **Quest Title:** "Ancient Tool Research"
- **Quest Description:** "I'm conducting research on ancient Dani tools. The Kapak Dani would be perfect for my study. Have you seen one?"

### 3. Tribal Elder
- **Artifact Required:** `koteka`
- **Quest Title:** "Traditional Attire Preservation"  
- **Quest Description:** "Our village needs the sacred Koteka for the upcoming ceremony. Can you help us find this important traditional item?"

### 4. Artisan
- **Artifact Required:** `cenderawasih_pegunungan`
- **Quest Title:** "Bird of Paradise Art"
- **Quest Description:** "I'm creating a masterpiece inspired by Papua's nature. The Cenderawasih Pegunungan would be the perfect model for my art. Could you find one for me?"

## System Features

### Quest Management
- Each NPC has unique `quest_artifact_required` property
- Quest completion status tracked with `quest_completed` boolean
- Quest title and description stored for each NPC

### Dialog Integration
- Dynamic dialog generation based on quest status
- Different responses for:
  - Initial quest offer
  - Quest information display
  - When player has required artifact
  - After quest completion
- "Give Artifact" option appears when player has required item

### Inventory Integration  
- `has_required_artifact()` function checks player inventory
- `give_artifact_to_npc()` function removes artifact and completes quest
- Automatic quest completion when artifact is given
- Error handling for missing inventory system

### Scene Configuration
Scene file `PapuaScene_Manual.tscn` updated with quest properties for all NPCs:
- quest_artifact_required
- quest_title  
- quest_description
- quest_completed (initially false)

## Quest Flow

1. **Quest Discovery**: Player talks to NPC → Quest is offered
2. **Artifact Collection**: Player explores and finds required artifact
3. **Artifact Check**: When talking to NPC, system checks if player has artifact
4. **Artifact Delivery**: If available, "Give Artifact" option appears
5. **Quest Completion**: Player gives artifact → Quest marked complete → NPC shows appreciation

## Technical Implementation

### Core Functions
```gdscript
# Check if player has required artifact
func has_required_artifact() -> bool

# Give artifact to NPC and complete quest  
func give_artifact_to_npc() -> bool

# Setup quest artifact based on NPC name
func setup_quest_artifact()

# Add quest-specific dialogues
func add_quest_dialogues()

# Handle quest-related dialog consequences
func _handle_check_artifact()
func _handle_complete_quest()
```

### Dialog System
- Quest dialogs dynamically generated
- Multiple dialog branches based on quest status
- Consequence system for quest actions
- Support for both hardcoded and dynamic quest dialogs

## Testing
- Run `QuestSystemTest.gd` to verify system functionality
- All quest assignments and dialog integration tested
- Inventory system integration verified

## Status: ✅ COMPLETE
Sistema quest telah selesai diimplementasikan dan siap untuk digunakan. Setiap NPC di Papua memiliki quest unik untuk mengumpulkan artifact tertentu, dengan sistem dialog yang terintegrasi dan inventory system yang berfungsi.