# 武俠庭院測試

## 新增三張地圖（目前共五張）

| 入口 | 新場景 | 返回方式 |
| --- | --- | --- |
| 庭院掌門背後，繞過掌門向北走 | 議事廳 `scenes/hall.tscn` | 南門回庭院 |
| 庭院南方拱門下石階，繼續向下 | 山腳城鎮 `scenes/town.tscn` | 北方山路回庭院 |
| 西院周伯背後，向北走入屋門 | 弟子宿舍 `scenes/dormitory.tscn` | 南門回西院 |

三張都有獨立本地 PNG、原生 Sprite2D、StaticBody2D / CollisionPolygon2D、Area2D 出口與 Player 場景。家具和建物保持簡化碰撞，背景仍非 TileMap。每張兩個查看點：靠近按 E，選擇觀察或日後核對；取消不提交選擇。台詞在 `data/exploration.json`，只增加懸疑疑點，不提前揭露不平等，也不替代西院四人查訪。

任何序章進度皆可探索新地圖；完成秦川對話後下山，仍先觸發原有離山結尾。換圖保留本次執行的選擇與進度，不提供磁碟存檔。R 回目前場景抵達點。F5 或最新版 `builds/windows/Wuxia.exe` 均可離線執行。

驗證：`godot --headless --path . --script res://tests/expansion_test.gd`，涵蓋六向往返、六處選項、跨圖保留及離山劇情。

## 第二張地圖與 NPC 轉身

從庭院左側橋向左走到橋末端，即可進入西院（掌門與弟子住處）；西院右側橋可回庭院。跨地圖保留本次遊戲的序章進度與對話選擇，R 回到目前地圖的抵達點。使用原生 Area2D 出口、CollisionShape2D / CollisionPolygon2D 碰撞與 Autoload 暫存，無網路、仍未提供磁碟存檔。

NPC 交談時會依主角位置選擇自己的四方向圖；主角也會面向對方。西院是獨立原生場景，只有四位全新 NPC：沈禾（修橋學徒）、白芷（藥房學徒）、顧衡（練劍弟子）、周伯（住處管事）。庭院的掌門、阿棠、秦川不在西院重複出現。

故事方向已確認為「武俠懸疑，後期才揭露不平等」。西院先查空床主人小滿，逐一聽完四人證詞，再回找周伯核對兩半收訖單。選項改變人物反應與下站調查優先順序，取消當前對話不提交該段選擇或查訪進度；完成查訪後再交談會提供提醒，不重新要求選擇。此時不解釋門籍、待遇或制度答案。目前五張場景已實作，[七張地圖故事規劃](data/story_plan.md) 尚有東竹亭與聽風崖待製作。

西院規則獨立在 `scripts/residence_story.gd`，台詞在 `data/residence.json`；作者用的[角色與伏筆文件](data/west_courtyard_cast.md) 記錄已確定事實與不能提前揭露的內容。測試 `tests/residence_test.gd` 覆蓋 16 種選項組合、查訪順序、轉身、重複對話與取消回滾。

測試：`godot --headless --path . --script res://tests/maps_test.gd`。新版地圖、角色圖與完整提示：[素材紀錄](assets/PROMPTS.md)。

## 新增：對話選項與統一人物畫風

庭院三位 NPC 與西院四位新 NPC 各使用自己的 `assets/characters/*-directions.png`：以主角為畫風參考，統一大頭、短身比例與像素陰影，保留不同造型。圖片、縮放與位置設定在原生 Sprite2D / AtlasTexture 節點，對話選項使用 Button / VBoxContainer 與信號。

序章三個選擇點：掌門問先救人或追查；阿棠提供短笛或竹印線索；秦川讓你決定信任或追問。選擇影響後續台詞、右上江湖札記與三種序章結果（守約尋人／循證追查／孤身追影）。另有西院四個選項點及新增地圖六個查看點；背包與磁碟存檔尚未實作。

E／空白鍵／Enter 繼續對話；1／2 直接選擇，或上下／W、S 選取後確認，也可用滑鼠點按鈕。Esc 取消整段當前對話，不提交該段選擇。完成對話才保存至本次遊戲進度，重新啟動會重置。

分支測試：`godot --headless --path . --script res://tests/choices_test.gd`（全部 8 種組合與取消回滾）。目前素材與精確生成提示見 [素材紀錄](assets/PROMPTS.md)。

使用 Godot 4.7 開啟 `project.godot`，按 **F6** 執行 `scenes/courtyard.tscn`，或按 **F5** 執行專案。

也可以直接雙擊 `builds/windows/Wuxia.exe` 執行 Windows 原生版，不需要開啟 Godot、瀏覽器、啟動伺服器或連上網路。

## 本地與離線執行

遊戲場景、程式、角色、庭院與劇情全部在專案內，使用 `res://` 檔案路徑引用。執行程式沒有 HTTP、WebSocket、網頁橋接或遠端下載。`res://` 指專案目錄或原生版的內嵌資料包，不是網站。

Godot 的 UID 是本地資源的唯一識別碼，用來追蹤移動或改名的檔案，[官方 ResourceUID 說明](https://docs.godotengine.org/en/4.2/classes/class_resourceuid.html)也有解釋。`.gd.uid`、PNG 的 `.import` 與 `.godot/uid_cache.bin` 由引擎自動產生；保留它們不代表需要網路。我們撰寫的遊戲程式與 `scenes/` 場景不使用 `uid://` 載入，全部以路徑指定。不要靠反覆刪除引擎索引來達成離線，它們在本地匯入時會重新產生。

Windows 原生版將程式與資源包內嵌進 `Wuxia.exe`，劇情 `data/prologue.json` 也明確納入打包；使用本地系統字型，沒有網路字型下載。PNG 製作階段使用內建線上圖片生成工具，但成品已落地；遊戲不含圖片生成 API、登入、API key 或服務依賴。

重新匯出：在 Godot 的「專案 → 匯出」選擇 **Windows Offline**，或執行 `tools/build_windows.ps1 -GodotPath '你的本機 Godot 執行檔路徑'`。本機已備妥相符的匯出範本後，重新匯出不需要下載。

- WASD 或方向鍵：上下左右移動，雙鍵可斜向移動且不會加速。
- R：回到目前地圖的出生／抵達點。
- E / 空白鍵：靠近 NPC 時對話；對話中按同一鍵讀下一句。
- Esc：關閉對話，不推進劇情。對話時暫停移動，也不能用 R 傳送。
- 角色會隨移動方向切換四方向站姿，附輕微移動起伏；此版沒有完整逐格走路動畫或戰鬥。
- 庭院周邊、池塘、涼亭、部分竹叢與木樁有簡化碰撞；背景目前是一張圖，不是可編輯 TileMap。
- 南方拱門中央可雙向穿越，門柱與兩側牆面保持碰撞；角色進入門下時會被屋頂遮擋。

## 序章：劍譜疑雲

右上角顯示當前目標。依序完成三位 NPC 的對話：

1. 北側柳青霄掌門：得知《青霜劍譜》失竊，接受調查。
2. 東側阿棠師妹：取得帶傷信使與墨竹袖紋的線索。
3. 南側秦川守門弟子：得知山下竹林的路線與短笛警告。
4. 從南方拱門中央走下石階，觸發序章結尾。

提前拜訪其他 NPC 不會跳過劇情；已完成對話會改用提醒台詞。序章結束後仍可返回庭院走動。竹林下一章尚未製作。

R 只重設角色位置，不清除任務。劇情狀態目前不存檔，重新執行專案即重新開始。若關閉門外的結尾對話，往回走上石階後再走下即可重新觸發。

主角與七位 NPC 各使用不同的 PNG。NPC 有四方向站姿，尚無逐格走路動畫；主角的四方向移動保持不變。角色依腳下位置 Y 排序。劇情台詞位於 `data/prologue.json`、`data/residence.json`，NPC 與對話框使用獨立場景及腳本；對話透過訊號通知主場景更新劇情與移動鎖定。

角色速度可在 Player 場景的 Inspector 中調整 `Move Speed`。

## 素材與生成方式

素材以內建 image generation 工具生成，透明角色的 alpha 原樣保留；完整提示詞記錄在 [assets/PROMPTS.md](assets/PROMPTS.md)，摘要如下：

- `assets/environment/courtyard.png`：16-bit top-down pixel-art wuxia courtyard, pale stone paths, bamboo, ancient sect buildings, pond and open central walkable plaza, jade/gray/vermilion palette, no characters/text/UI.
- `assets/characters/swordsman.png`：transparent 2×2 sprite sheet of the same teal-robed chibi wuxia swordsman; down/up/left/right arranged top-left/top-right/bottom-left/bottom-right; crisp pixel art, consistent scale, no labels or shadows.
- `assets/characters/master.png`：柳青霄，白髮長鬚、白藍長袍、持木杖。
- `assets/characters/disciple.png`：阿棠，雙髻紅緞帶、紅白短裝、腰間布包。
- `assets/characters/guard.png`：秦川，短髮頭帶、綠衣皮甲、持長槍。

三位 NPC 的最終提示詞分別保存在同資料夾的 `master-prompt.txt`、`disciple-prompt.txt`、`guard-prompt.txt`。PNG alpha 原樣保留，以 Godot 原生 Sprite2D 的縮放及偏移對齊角色腳下。

場景與邏輯分開放在 `scenes/`、`scripts/`。移動採用 Godot 官方的 [CharacterBody2D + Input.get_vector + move_and_slide](https://docs.godotengine.org/en/stable/tutorials/2d/2d_movement.html) 模式。

## 驗證

已以 Godot 4.7.2 完成主場景載入、四方向移動／朝向、斜向等速、回到起點、拱門雙向及偏中心通行、門柱與邊界碰撞、NPC 距離與碰撞、對話輸入／中止／鎖定、亂序與重複拜訪、全部序章階段及門外結尾的自動測試。

實際渲染檢查畫面：`tests/preview.png`、`tests/gate_preview.png`、`tests/dialogue_preview.png`。前景屋頂與門柱使用原背景貼圖的原生 Polygon2D UV 遮罩，沒有修改點陣素材。

可使用 `godot --headless --path . --script res://tests/movement_test.gd` 重跑自動測試。

`tests/offline_audit.gd` 檢查遊戲路徑引用、網路 API、素材與台詞的本地存在及原生匯出設定。已在不含原先 UID、`.import` 或 `.godot` 的本地副本重新匯入，並從該副本匯出原生版；`tests/pack_test.gd` 直接從 `Wuxia.exe` 的內嵌資源包驗證四份不同圖片與 NPC 劇情。`Wuxia.exe` 已直接啟動檢查成功；`tests/native_preview.png` 是匯出資源包的實際 NPC 畫面。沒有停用整台電腦網路或修改防火牆；離線依賴檢查與原生包啟動測試，不等於實體斷網實測。
