---
name: commit
description: 根據當前 Git 變更狀態 (git status / git diff)，自動分析改動並給出高品質、結構化的 Conventional Commits 建議訊息。
---

# Git Commit 建議產生器 (Skill Instructions)

當使用者輸入 `/commit` 或要求給出 commit 建議時觸發此 Skill。

---

## 執行流程

1. **自動檢視 Git 狀態**：
   - 執行 `git status -s` 與 `git diff --stat` 取得當前工作目錄的異動檔案清單。
   - 針對關鍵異動檔案檢視 `git diff`，深入理解本次修改的根本原因、架構重構與功能亮點。

2. **產出結構化 Commit 建議**：
   每次詢問時，**固定只提供以下兩種方案**供使用者選擇：

   ### 📌 方案A：完整詳細版（一次 git add 所有檔案）
   - **適用場景**：將本次所有關聯變更合併為單一完整提交。
   - **指令與內容**：
     - 一次性加入所有檔案：`git add .`（或指定全部異動檔案）。
     - 包含主標題（符合 Conventional Commits 規範，如 `feat(alarm): ...` 或 `refactor(alarm_pill): ...`）。
     - 詳細條列具體變更項目（模組、修訂項目、改善效益）。

   ### 🧩 方案B：分功能版（根據不同功能，分段 git add 檔案）
   - **適用場景**：將不同性質的改動（如：後端 API 邏輯、前端元件與樣式重構、設定檔等）拆分為多個獨立乾淨的提交。
   - **指令與內容**：
     - 根據變更主題拆分為 2~3 個功能區塊。
     - 每個功能區塊皆提供：
       1. 專屬的檔案暫存指令：`git add <該主題相關檔案>`
       2. 專屬的 Conventional Commit 訊息：`git commit -m "..."`

---

## ⚠️ 執行限制原則 (Strict Execution Rules)

1. **嚴禁主動執行 Git 指令**：
   - 絕對**不要**自動代為執行 `git add` 或 `git commit`。
   - 僅提供結構化的指令碼區塊與 Commit 訊息建議。
2. **等候使用者確認**：
   - 給出「方案A」與「方案B」建議後，等候使用者回覆想要的方案或進一步指示。

