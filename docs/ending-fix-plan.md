# 六結局可達性：修正規格

給實作者的工作單。前置調查已完成，結論是**六種結局目前都能達成，沒有會完全擋死結局的 bug**；
以下三項是實測找出的單向陷阱與缺乏防護的程式碼路徑。請照項目順序實作，每項都附驗收條件。

調查方式：靜態追 `ending_record()` → `Rules.value(route)` → `endings.table` 的判定鏈，
再以兩支新增的模擬測試跑 320 場完整通關（200 場全隨機選項、120 場隨機中途按 Esc 取消）。
現有 12 支測試與這兩支新測試目前全部 PASS，**修改後必須維持全綠**。

---

## 項目 1（必做）聽風崖的竹管搜查是單向窗口

### 問題

`scripts/story_director.gd` 的 `enter_map()`（第 27–38 行）在玩家踏上地圖的當下就會啟動
`trigger: "enter"` 的事件。議事廳回訪（`hall_revisit`）結束後 `suspect_known` 與 `monologue`
成立，n5 立刻符合條件，於是玩家一走上聽風崖就直接進入與嚴承的對質，**沒有機會先去互動搜查竹管**。

n5 的 `entry_choices` 只有「動手」與「跟他談」，沒有離開選項，所以這個窗口一旦錯過就永久關閉。

實測輸出（先設好全武路線 + 議事廳已完成的旗標，再呼叫 `enter_map()`）：

```
after entering cliff -> busy=true dialogue=true     ← 一踏上崖就開打 N5
n5_result=fight hide_spot=<null> got_manual=false
ending=ending_exiled
```

### 影響

`hide_spot` 在談判路線會由小滿（`data/bamboo_station.json`）或沈禾（`data/wind_cliff.json`）
的對話自動給予，但**在 n3、n4 都選動手的存檔裡，唯一來源是 `cliff_search` 謎題**。
錯過搜查 → `hide_spot` 為 false → n5 不會出現取回劍譜的詢問 → `manual_secured` 從未設定 →
`after_battle` 走 else 分支 → `got_manual` 恆為 false。

結果是**全武路線只剩 `ending_exiled` 一種結局，`ending_tyrant`（篡政者）在該存檔中變成不可達**。
`scripts/story_guide.gd:46` 的提示文字有寫「離崖前也可以搜查竹管」，但沒有任何機制阻止玩家錯過。

### 改法

在對質開始前補一個詢問，讓仍可搜查時玩家能就地搜查。放在 `run_node()` 內可沿用既有的交易語意
（中途取消 → `aborted` → `run_event` 整筆回滾），不要改 `enter_map()` 的觸發時機。

**1a. `data/game_logic.json`**：在 `nodes.n5` 的 `"retrieval_prompt"`（第 799 行）**之前**插入兩個鍵：

```json
      "search_prompt": {
        "speaker": "少俠",
        "text": "（避風石後面那幾根竹管，還沒查過。要先搜一遍嗎？上了崖就沒有回頭的機會。）"
      },
      "search_choices": [
        {
          "id": "search",
          "label": "先搜查竹管，再與嚴承對質。"
        },
        {
          "id": "skip",
          "label": "不搜了，直接上前對質。"
        }
      ],
```

**1b. `scripts/story_director.gd`**：把 `run_node()` 開頭（第 123–128 行）

```gdscript
func run_node(id: String) -> void:
	var node: Dictionary = logic.nodes[id]
	if id == "n5" and world.story_flags.get("hide_spot", false):
```

改為

```gdscript
func run_node(id: String) -> void:
	var node: Dictionary = logic.nodes[id]
	# 崖上的對質沒有離開選項，所以還能搜查的竹管必須在這裡問，否則藏處永久錯過。
	if id == "n5" and not world.story_flags.get("hide_spot", false) and search_available():
		var search := await menu(node.search_prompt, node.search_choices)
		if search.is_empty(): return
		if search.id == "search": await puzzle("cliff_search")
	if id == "n5" and world.story_flags.get("hide_spot", false):
```

**1c. `scripts/story_director.gd`**：新增輔助函式（建議放在 `run_node()` 正上方），
條件直接沿用 `cliff_search` 事件自己的 `requires`，不要另外寫死條件：

```gdscript
func search_available() -> bool:
	for event in logic.events:
		if event.get("id") == "cliff_search":
			return Rules.matches(world.story_flags, event.get("requires", {}))
	return false
```

注意：`puzzle()` 已經會檢查 `aborted`，搜查中途按 Esc 會讓後續的 `play(node.intro)` 回傳 false、
`run_node` 直接返回、`run_event` 回滾旗標，行為正確，不需要額外處理。

### 驗收

- 全武存檔（`n1`–`n4` 皆 fight、`chen_bai_nails` 與 `explore_wind_cliff_record` 已有、
  議事廳已完成、`hide_spot` 未取得）走上聽風崖時，先出現搜查詢問；選「先搜查」後能取得
  `hide_spot`，接著才出現取回劍譜的詢問，最終可達 `ending_tyrant`。
- 選「不搜了」時行為與現在完全一致（`ending_exiled`）。
- `hide_spot` 已取得、或 `cliff_search` 條件不成立（例如缺 `explore_wind_cliff_record`）時，
  **不得**出現這個詢問。

### 這份改法已經驗證過

上述 patch 實際套用後，以 `tests/ending_fuzz_test.gd` 移除預先觸發謎題的兩行
（第 83、87 行的 `fire("cliff_search")`）跑 200 場隨機通關，做過 A/B 對照：

| 版本 | 結果 |
|---|---|
| 未修正 | `ERROR: Unreachable ending: ending_tyrant`，200 場一次都沒出現 |
| 套用本修正 | `ending_tyrant` 出現，`PASS (0 failures over 200 runs)`，六種結局到齊 |

驗證後 patch 已還原，`scripts/story_director.gd` 與 `data/game_logic.json` 目前是未修改的原始狀態，
`tests/ending_fuzz_test.gd` 的那兩行也保留著（維持現有套件全綠）。請由你實作正式版本。

---

## 項目 2（必做）`ending_record()` 找不到對應時會讓結局當掉

### 問題

`scripts/story_director.gd:273-276`：

```gdscript
func ending_record() -> Dictionary:
	for ending in logic.endings.table:
		if ending.route == Rules.value(world.story_flags, "route") and ending.got_manual == world.story_flags.get("got_manual", false): return ending
	return {}
```

呼叫端 `run_event()`（第 93–98 行）直接取 `ending.id` 與 `ending.title`：

```gdscript
			if id == "@ending":
				var ending := ending_record()
				if await play(ending.id):
```

空字典上取 `.id` 會噴 `Invalid access to property`，玩家會卡在庭院的最後一幕、永遠看不到結局。
目前 `endings.table` 的六格（talk/fight/mixed × true/false）剛好完整涵蓋 `route` 的三個可能值，
所以碰不到，但**完全沒有防護**：日後只要新增一個 route 值或漏填一格，第一個踩到的人就是玩家。

### 改法

把 `ending_record()` 改成永遠回傳可播放的結局，並在資料不完整時留下錯誤紀錄：

```gdscript
func ending_record() -> Dictionary:
	var route = Rules.value(world.story_flags, "route")
	var manual: bool = world.story_flags.get("got_manual", false)
	for ending in logic.endings.table:
		if ending.route == route and ending.got_manual == manual: return ending
	# 結局表有缺口時寧可播同路線的結局，也不要讓玩家卡在最後一幕。
	push_error("No ending for route=%s got_manual=%s" % [str(route), str(manual)])
	for ending in logic.endings.table:
		if ending.route == route: return ending
	return logic.endings.table[0]
```

### 驗收

- 六種正常組合回傳的 `id` 與現在完全相同（`tests/story_campaign_test.gd` 已逐一比對，必須維持 PASS）。
- 暫時把 `endings.table` 其中一格改掉來手動驗證：結局仍會播放、不會拋錯，且 console 有 `push_error` 訊息。驗證完把資料改回來。

---

## 項目 3（建議）把兩支模擬測試納入回歸

`tests/ending_fuzz_test.gd` 與 `tests/ending_cancel_test.gd` 已經新增在 repo 裡：

- `ending_fuzz_test`：200 場全隨機選項通關，斷言六種結局**全部**出現、無死結、
  `ending_record()` 不為空、`ending_title` 正確寫入。
- `ending_cancel_test`：120 場隨機按 Esc 取消（含結局本身），斷言每個橋段取消後仍可重來、
  `finale_pending` 在取消結局後保留、最終仍能收尾。

請在項目 1 完成後，刪掉 `tests/ending_fuzz_test.gd` 第 83 行與第 87 行的
`if rng.randf() < 0.6: fire("cliff_search")` / `if rng.randf() < 0.5: fire("cliff_search")`。

這兩行讓測試主動先跑謎題，正好掩蓋了項目 1 的問題；拿掉之後，`ending_tyrant` 就只能靠
項目 1 新增的搜查詢問達成，這支測試才真正具備防守能力。**拿掉這兩行後測試必須仍是 PASS**
（未修正的版本會在這裡失敗，見項目 1 的 A/B 對照）。

### 執行方式

```
<godot> --headless --path <repo> --script tests/ending_fuzz_test.gd
<godot> --headless --path <repo> --script tests/ending_cancel_test.gd
```

兩支都要印出 `PASS (0 failures ...)`。同時重跑既有套件，全部必須維持 PASS：

```
story_campaign_test  story_events_test  story_progression_test  choices_test
clue_journal_test    map_access_test    maps_test               expansion_test
residence_test       seven_maps_test
```

---

## 請不要更動的部分

以下是刻意設計，調查時已確認**不會**擋住任何結局，不要「順手修掉」：

- **n5 攻心階段在玩家沒有任何 `heart_*` 旗標時只剩錯誤選項、談判必定失敗。**
  `data/game_logic.json` 的 `heart_stage.note` 已註明是刻意設計。失敗會走
  `on_fail`，該分支一定會設定 `n5_result`，結局照常產生。
- **n3 在「n1 動手且沒拿到 `heart_brother`」時說服必定不成立。**
  `success_rule` 的 else 分支需要 `brother` 選項，而該選項需要 `heart_brother`。
  這由 `leave_hint_when_impossible` 明確提示，且動手選項始終存在，路線不會斷。
- **按 Esc 會回滾整段遭遇（含結局），這是 `run_event()` 的交易語意。**
  已驗證取消結局後 `finale_pending` 會保留、離開庭院再回來可重播，行為正確。
- **`endings.table` 的六格內容與 `route` / `got_manual` 的判定規則**
  （`scripts/story_rules.gd:5-20`）。`tried_then_fight` 計入 `fight_count` 但不計入
  `route == "fight"` 是刻意的，`data/game_logic.json` 的 `derived` 區塊有註明。
