# 在 GitHub 上遊玩

這個專案使用 GitHub Pages 發布 Godot Web 版本。遊戲網址預計為：

https://24626982.github.io/wuxia/

**啟用前提：** GitHub Free 只能在公開儲存庫使用 Pages；要讓 `wuxia` 維持私人儲存庫並使用 Pages，需由擁有者升級到支援私人儲存庫 Pages 的方案。兩種情況下，發布後的 Pages 網站本身都會公開。不要為了開啟 Pages 而在未檢查完整 Git 歷史前直接把儲存庫改成公開。

首次啟用時，請到 GitHub 儲存庫的 **Settings → Pages**，將 **Build and deployment → Source** 設為 **GitHub Actions**，再將含有 `.github/workflows/pages.yml` 的程式碼推送到 `main`。Actions 完成時，網址即可開啟。變更 Pages 設定需要儲存庫管理權限。

往後每次將遊戲修改推送到 `main`，GitHub Actions 都會以 Godot 4.7.2 重新匯出並部署 Web 版本。只修改本機檔案不會觸發更新。可在儲存庫的 **Actions** 頁面查看進度和錯誤。部署成功後重新整理遊戲頁面即可取得新版。

Web 匯出採單執行緒模式，適合 GitHub Pages 這種無法自訂回應標頭的靜態託管。瀏覽器需支援 WebAssembly 與 WebGL 2。桌面版仍可依原方式使用。

## 發布前的安全檢查

1. 把 `data/`、`assets/`、遊戲畫面與文字都當成公開內容檢查。GitHub Pages 網站是公開的，即使儲存庫是私人也一樣。不要把 API 金鑰、密碼、未公開劇情或個人資料放進遊戲資源。
2. 執行 `git status` 與 `git diff --check`，確認只會提交預期的修改；不要用 `git add .` 跳過檢查。`.env`、金鑰與本機匯出檔已列在 `.gitignore`，但如果敏感資料曾被提交過，忽略規則無法移除歷史紀錄，還需要撤銷該憑證。
3. 若方案支援，在 **Settings → Environments → github-pages** 限制只有 `main` 可以部署。工作流程本身也已限制只有 `main` 可部署。建議對 `main` 啟用保護規則，要求合併前審查；帳號應開啟雙因素驗證。
4. 首次推送後，到 **Actions** 確認 `Publish game to GitHub Pages` 成功，再開啟 Pages 網址實際試玩。若看到失敗訊息，先檢查 Actions 記錄，不要直接增加工作流程權限。

工作流程的建置工作只取得儲存庫讀取權限；部署工作才取得 Pages 寫入權限及部署所需的身分權杖。它不需要建立個人存取權杖或存放 GitHub 密鑰。
