目前 BGM 使用使用者提供的 `game BGM.mp3`，複製為 `game_bgm.mp3`。

- `game_bgm.mp3`：目前使用的背景音樂，完整循環播放。
- `wuxia_theme.wav`：先前自行合成的 32 秒五聲音階背景音樂，保留為備用素材。
- `choice_click.wav`：確認對話選項的短音效，滑鼠與鍵盤共用。

執行 `python tools/generate_audio.py` 可重建自行合成的 WAV 素材，不會覆寫 MP3。播放與音量設定位於
`scripts/game_audio.gd`；BGM 使用全域 Autoload，換地圖時持續播放。
