# 素材生成記錄

Mode: built-in `image_gen` tool. All final PNGs are copied into this project; generated alpha is preserved without raster editing.

## Current west courtyard cast: four NEW characters

Built-in image_gen, with `swordsman.png` as STYLE / PROPORTION reference only. Four separately generated new identities, not reused master/disciple/guard assets. All PNGs are copied into the project and alpha is untouched. Native AtlasTexture quadrant regions select down/up/left/right. Read-only alpha measurements at 128 determine Sprite2D foot alignment, ignoring faint transparent fringe without changing pixels; bounds are serialized on each scene instance.

- [Shen He](characters/shen_he-directions.png) · [Exact prompt](characters/shen_he-prompt.txt): ochre work tunic, toolbelt, short hair.
- [Bai Zhi](characters/bai_zhi-directions.png) · [Exact prompt](characters/bai_zhi-prompt.txt): lilac robe, white apron, braided bun, medicine bag.
- [Gu Heng](characters/gu_heng-directions.png) · [Exact prompt](characters/gu_heng-prompt.txt): neat indigo robe, silver trim, tied hair.
- [Uncle Zhou](characters/uncle_zhou-directions.png) · [Exact prompt](characters/uncle_zhou-prompt.txt): gray-brown jacket, cloth cap, gray moustache, brass keys, ledger.

## Map 2 background and courtyard directional NPCs

Built-in image_gen, using the existing courtyard as map style reference and each v2 NPC as its own identity reference. Untouched generated PNG alpha is retained. Godot AtlasTexture regions provide down/up/left/right views; each cell is aligned to the NPC's feet by Sprite2D offsets.

- [Residence map](environment/residence.png) · [Exact prompt](environment/residence-prompt.txt)
- [Master sheet](characters/master-directions.png) · [Exact prompt](characters/master-directions-prompt.txt)
- [Disciple sheet](characters/disciple-directions.png) · [Exact prompt](characters/disciple-directions-prompt.txt)
- [Guard sheet](characters/guard-directions.png) · [Exact prompt](characters/guard-directions-prompt.txt)

The v2 front-only files remain as editor-preview / earlier assets; runtime NPCs now select their own four-direction sheet, never the hero's sheet.

The courtyard scene retains `master-v2.png`, `disciple-v2.png`, and `guard-v2.png` for static editor previews only. Generated using the hero sheet as the style reference and each original NPC as an identity reference. Original NPC files are retained as unused earlier versions; alpha pixels were not edited.

- [Master image](characters/master-v2.png) · [Exact prompt](characters/master-v2-prompt.txt)
- [Disciple image](characters/disciple-v2.png) · [Exact prompt](characters/disciple-v2-prompt.txt)
- [Guard image](characters/guard-v2.png) · [Exact prompt](characters/guard-v2-prompt.txt)

## Independent NPCs

Generated separately using the built-in tool, not recolours or copies of the hero. All files are local project assets; generation services are not used at game runtime.

- `characters/master.png`: final prompt in [master-prompt.txt](characters/master-prompt.txt).
- `characters/disciple.png`: final prompt in [disciple-prompt.txt](characters/disciple-prompt.txt).
- `characters/guard.png`: final prompt in [guard-prompt.txt](characters/guard-prompt.txt).

## `environment/courtyard.png`

```text
Use case: stylized-concept
Asset type: 2D Godot game background
Primary request: a complete top-down pixel-art wuxia courtyard scene for a playable movement test
Scene/backdrop: ancient Chinese martial arts sect courtyard with pale stone paths, mossy grass, bamboo clusters, a small red-roof pavilion at the upper edge, low stone walls, lanterns, and a shallow pond; an open walkable central area
Style/medium: crisp handcrafted 16-bit pixel art, orthographic top-down RPG map, visible square pixel clusters, cohesive tileset-like detailing
Composition/framing: landscape 16:9, environment only, open center and readable boundaries, no perspective tilt
Lighting/mood: warm late-afternoon light, calm heroic jianghu atmosphere
Color palette: jade green, weathered gray stone, muted vermilion, warm gold accents
Constraints: no characters, no text, no UI, no logos, no watermark; avoid photorealism and smooth painterly gradients; must read clearly when displayed at 960x540
```

## `characters/swordsman.png`

```text
Use case: stylized-concept
Asset type: transparent 2D Godot character sprite sheet
Primary request: one young wuxia swordsman shown in four orthographic top-down RPG directions, as an exactly aligned 2-by-2 sprite sheet
Subject: the SAME small chibi martial artist in a teal robe, dark boots, long black hair tied in a topknot, cream sash, sheathed sword on the back
Style/medium: crisp 16-bit pixel art, hard-edged square pixel clusters, readable at small game scale, no antialiasing
Composition/framing: square canvas divided into FOUR equal invisible cells; top-left FRONT facing viewer/down, top-right BACK facing away/up, bottom-left LEFT profile, bottom-right RIGHT profile. Each figure is centered in its cell at precisely the same vertical position, identical scale and height, occupies roughly the central 50 percent of its cell width and 65 percent of its height. Neutral standing pose, feet together, consistent silhouette. No cell borders.
Scene/backdrop: genuinely TRANSPARENT alpha background, no backdrop and no ground
Constraints: exactly four isolated complete character sprites, no extra characters, no floor shadows, no text, no labels, no grid lines, no watermark. All four sprites fully contained inside their equal quadrant cells. Do not make an illustration or scenery.
```
# 新增地圖背景

以原庭院背景作畫風參考，使用內建 imagegen 製作，完整成品已複製至本地，不需執行時連線。圖片未以程式修改；障礙、門口和查看點由 Godot 原生節點處理。

- 議事廳：`environment/hall.png`；精確提示 `environment/hall-prompt.txt`。
- 山腳城鎮：`environment/town.png`；精確提示 `environment/town-prompt.txt`。
- 弟子宿舍：`environment/dormitory.png`；精確提示 `environment/dormitory-prompt.txt`。
