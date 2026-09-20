# 女性主角素材

## 立繪比例修訂（目前使用）

Built-in image_gen edit. Female portrait is the edit target; male sheet is the mandatory body-proportion reference. Output replaces hero-female-portrait.png; generated alpha is preserved. Opening previews use tight visible alpha bounds and equal 210px height.

```text
Edit female portrait (image 1). Image 2 male sheet is the mandatory BODY PROPORTION reference, specifically its top-left front view. Keep female identity, face, ponytail ribbons, teal/cream practical robe, trousers, boots and sword. Redraw ONE front standing full-body female in EXACT same squat chibi head-to-body proportions as male: large head, very short torso, short compact legs and boots; NOT elongated legs or taller fashion-doll proportions. Hair top to chin about 45 percent of total figure height, chin to soles about 55 percent, same as male. Match male's chunky crisp pixel-art style. Neutral pose. Transparent alpha background without glow, shadow, scenery, text. Square canvas, centered full figure, complete boots, padding. Only one figure, no sheet. Female recognizable while silhouette height/width and shoulder/waist/knee/foot landmark heights match male front sprite.
```

Mode: built-in `image_gen`; final generated PNGs copied into project without raster edits. Existing male sprite sheet is the style reference; female portrait is the identity reference for the four-direction sheet.

## 立繪 — hero-female-portrait.png

```text
Use case: stylized-concept
Asset type: transparent full-body female protagonist standing portrait for a Chinese wuxia pixel RPG.
Input image: existing male hero is STYLE and palette reference ONLY, create a distinct young adult female martial artist.
Subject: confident gentle female swordswoman, long black hair in a high ponytail with cream and teal ribbons, feminine face, teal practical cross-collar robe with cream trim and sash, dark fitted trousers, black boots, sheathed sword on her back. Same sect and visual world as reference. Modest functional clothing.
Style: match reference crisp chibi pixel art, square pixel clusters, warm restrained shading, clean readable silhouette.
Composition: ONE front-facing complete standing figure centered, head to boots visible with padding, neutral pose, portrait canvas. No other views.
Background: genuinely transparent alpha, no ground or shadows, no text, watermark, border or UI.
```

## 四方向 — hero-female-directions.png

```text
Use case: stylized-concept
Asset type: transparent 2D Godot four-direction character sprite sheet.
Input image 1: female portrait is the EXACT IDENTITY reference. Input image 2: male sprite sheet is STYLE, PROPORTIONS and layout reference only.
Primary request: the SAME female swordswoman from image 1 in four orthographic chibi RPG directions, exactly 2 by 2 equal invisible quadrant cells on a square canvas. Match image 2's small chibi body proportions and crisp pixel clusters. Teal practical cross-collar robe, cream trim and sash, dark trousers and boots, long black high ponytail with cream/teal ribbons, sword sheathed on back. Consistent clothing, face and hair across views.
Layout: top-left FRONT facing viewer/down, top-right BACK facing away/up, bottom-left LEFT profile looking left, bottom-right RIGHT profile looking right. EXACTLY four complete sprites. Each centered at the same height within its own cell, same scale, occupies central 50 percent width and 65 percent height. Neutral standing pose.
Background: genuinely transparent alpha everywhere outside characters, NO black background, NO glow, NO vignette, NO cast shadow, NO ground. No text, labels, border, grid, watermark, extra views or scenery.
```
