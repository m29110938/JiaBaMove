---
name: jiaba-move-core
description: 「呷飽來動 (JiaBaMove)」專屬工程架構規範與開發標準，涵蓋 Clean Architecture、全方位資安 (Security by Design)、CI/CD 先行與強制測試驗證、iOS Keychain 防護、Gemini 1.5 Flash 視覺辨識與台灣在地化文案風格。
---

# 呷飽來動 (JiaBaMove) 核心工程架構與規範手冊

本文件為「呷飽來動」專案之權威工程規範。所有後續功能開發、模組擴展、重構與程式碼審查，皆必須嚴格遵守以下準則。**「資安 (Security by Design)」與「CI/CD / 測試先行」為本專案最高優先級原則，任何程式碼撰寫與審查均必須先通過各階段檢核。**

---

## 0. 核心工作流規範：事前計畫、CI/CD 先行與測試驗證機制

> [!IMPORTANT]
> **1. 每次進行程式碼或設定修改前，必須先詳細列出預計調整的流程與修改計畫，建立 `Implementation Plan` 文件，獲得使用者確認後才可開始執行修改。**  
> **2. 每次新增功能時，必須先寫好 CI/CD 自動化流程（自動化分析、建置與測試工作流），才能進行業務程式碼的撰寫。**  
> **3. 程式碼撰寫完成後，必須進行完整測試（單元測試、邏輯驗證等），確認功能完全正確且無任何錯誤後才算交付。**

### 標準工程工作流四階段 (Four-Stage Engineering Lifecycle)：
1. **第一階段：事前規劃與審核確認 (Planning & Approval Gate)**：
   - 深入分析既有架構、受影響檔案與資安風險。
   - 建立結構化的 `Implementation Plan`（包含：修改目標、受影響檔案清單 `[NEW]` / `[MODIFY]` / `[DELETE]`、具體實作步驟、CI/CD 與資安檢核點、驗證方案）。
   - **必須停下腳步並等待使用者明確確認（例如點擊 Proceed 或文字回覆確認）**。在獲得許可前，嚴格禁止擅自建立、修改任何原始碼或執行具副作用之修改指令。
2. **第二階段：CI/CD 流程先行 (CI/CD-First Gate)**：
   - **每次新增功能前，必須先建立或更新 CI/CD 自動化工作流**（例如 `.github/workflows/ci.yml` 或自動化測試指令集）。
   - 確保新功能的靜態代碼分析 (`flutter analyze`)、代碼規範檢查與自動化測試管線 (`flutter test`) 已經佈署妥當，確立品質驗收標準後，才允許開始編寫業務邏輯程式。
3. **第三階段：安全程式碼撰寫 (Secure Implementation Phase)**：
   - 獲得授權且 CI/CD 就緒後，嚴格遵照 Clean Architecture、Riverpod 與 Security by Design 守則進行實作。
   - 杜絕明文機密、落實權限最小化、日誌脫敏，並確保臨時圖檔在 `finally` 區塊強制安全銷毀。
4. **第四階段：測試驗證與功能確認 (Mandatory Testing & Verification Gate)**：
   - **程式碼撰寫完成後，必須立即執行完整測試**（包含單元測試、邊界值測試與狀態渲染測試）。
   - 必須確認測試 100% 通過（All tests passed）、功能運作完全符合預期且無任何 Regression 錯誤。
   - 測試確認無誤後，產出 `Walkthrough` 文件，向使用者總結改動細節與測試驗證成果。

---

## 1. 架構原則：Clean Architecture + Riverpod

專案採用嚴格的分層架構 (Clean Architecture)，按功能模組切分 (`features/{feature_name}/`)：

```text
lib/
├── core/                                # 全域共用模組 (跨 feature 共用)
│   ├── constants/                       # 常數 (API endpoints, Keys, 配置)
│   ├── errors/                          # 全域錯誤與 Exception 處理
│   ├── network/                         # Dio Client、攔截器、SSL Pinning (選配)
│   ├── storage/                         # 本機快取、Secure Storage 封裝
│   ├── theme/                           # 配色、Typography、iOS 風格元件主題
│   └── utils/                           # 通用工具函式 (日期、數值格式化)
└── features/
    └── {feature_name}/                  # 獨立業務功能模組
        ├── data/                        # 資料層：資料源、DTO、Repository 實作
        │   ├── datasources/             # Remote API 或 Local DB 資料源
        │   ├── models/                  # JSON 序列化模型 (可轉為 Domain Entity)
        │   └── repositories/            # Repository 介面之實作
        ├── domain/                      # 核心業務領域層 (純 Dart，零 Flutter UI 依賴)
        │   ├── entities/                # 不可變實體 (Business Object)
        │   ├── repositories/            # Repository 抽象介面合約
        │   └── usecases/                # 單一職責的 UseCase
        └── presentation/                # 展現層：UI 與狀態管理
            ├── controllers/             # Riverpod Notifier / StateNotifier
            ├── states/                  # UI State 定義 (Loading, Success, Error)
            ├── views/                   # 畫面 (Screens / Pages)
            └── widgets/                 # 該功能專屬的 UI 元件
```

### 狀態管理規範 (Riverpod)
1. **單一資料流**：UI 只能向 Controller / Notifier 發送事件，透過 `ref.watch()` 監聽 State 更新。
2. **不可變性 (Immutability)**：State 物件必須使用不可變物件 (例如 Freezed 或手寫 `copyWith`)。
3. **副作用隔離**：非同步操作 (API 呼叫、資料庫讀寫) 嚴禁在 Widget 的 `build()` 中直接觸發，必須封裝於 Controller 或 AsyncNotifier 中。

---

## 2. 全方位資安守則 (Security by Design)：每次撰寫程式碼之強制規範

> **重要準則**：資安不是事後修補，而是每次編寫程式碼的預設標準。無論是撰寫新功能、修改 UI 還是調整 API，皆必須遵守以下六大資安規範：

### 2.1 每次撰寫程式碼之「資安自我審查清單 (Security Checklist)」
每次交付或修改 Dart 程式碼前，必須自我檢視並確認：
- [ ] **零明文輸出**：無任何 `print()`、`debugPrint()` 或 Log 攔截器輸出 API Key、Token、Authorization Header 或使用者隱私敏感資料。
- [ ] **零硬編碼**：無任何私鑰、密碼或測試金鑰留在程式碼、註解或資產設定中。
- [ ] **權限最小化**：存取本機儲存、相機、相簿等硬體或資料庫時，僅申請並使用必要最小權限。
- [ ] **暫存即刻銷毀**：圖片壓縮、檔案轉換產生的臨時檔案 (`TemporaryDirectory`)，使用完畢後必須在 `finally` 區塊中安全刪除。
- [ ] **錯誤訊息安全化**：對外（UI 面向使用者）的錯誤訊息嚴禁洩漏伺服器內部堆疊資訊 (Stack Trace)、原始伺服器回應或敏感路徑。
- [ ] **輸入防禦性驗證**：所有外部輸入（使用者貼上的字串、外部 API 回傳資料）皆必須進行嚴格長度限制、格式正規化與 Null-Safe 容錯處理。

---

### 2.2 機密與金鑰生命週期防護 (Secret & Key Lifecycle)
1. **零明文存儲原則**：
   - **絕對禁止** 使用 `SharedPreferences` 存放 API Key 或任何認證憑證。
   - **禁止** 在 Git、測試案例或設定檔中提交任何真實金鑰。
2. **iOS Keychain 硬體級安全防護**：
   - 必須統一透過 `SecureStorageService`（封裝 `flutter_secure_storage`）存取 Keychain。
   - 嚴格指定 iOS 安全屬性：
     ```dart
     static const _iosOptions = IOSOptions(
       accessibility: KeychainAccessibility.first_unlock, // 設備解鎖後才允許存取
       synchronizable: false, // 禁止未授權跨 iCloud 設備明文同步
     );
     ```
3. **記憶體生命週期最小化**：
   - API Key 在記憶體中應避免長期持有於全域變數中，僅在真正發出 API 呼叫時從 Keychain 動態讀取。
   - 清除金鑰時，必須同時銷毀 Keychain 資料與記憶體 State。

---

### 2.3 網路傳輸與日誌資安 (Network & Logging Security)
1. **傳輸加密強制化**：
   - 全面強制採用 `HTTPS` (TLS 1.3 / TLS 1.2)，嚴禁任何 `http://` 明文連線。
2. **網路日誌脫敏 (Data Masking)**：
   - 註冊 Dio 攔截器或日誌套件時，Query 參數 `?key=...` 或 Header `x-goog-api-key` 必須主動以遮罩替換（如 `AIzaSy...****...8X90`）。
3. **逾時與 DoS 防護**：
   - 所有網路請求必須配置明確的 `connectTimeout` (建議 15 秒) 與 `receiveTimeout` (建議 30 秒)，防止連線掛起耗盡客戶端資源。

---

### 2.4 iOS 執行階段與畫面隱私防護 (Runtime & UI Privacy)
1. **輸入框防偷窺**：
   - API Key、密碼等敏感欄位預設必須啟用 `obscureText: true`。
   - 畫面顯示已存金鑰時，僅顯示頭尾脫敏字元（例如 `AIzaSy...****...x9B2`）。
2. **多工後台防快照洩密 (App Switcher Privacy)**：
   - 當 iOS App 進入背景 (`AppLifecycleState.paused` / `inactive`) 時，在敏感頁面應啟用防窺遮罩或模糊效果，防止 iOS 系統在 App 切換器產生包含敏感資訊之縮圖。
3. **剪貼簿安全考量**：
   - 針對敏感資料讀取剪貼簿時，需提示使用者或在完成貼上後即時建議清除暫存。

---

### 2.5 本機資料沙盒隔離與安全銷毀 (Sandbox & Sanitization)
1. **沙盒路徑引用**：
   - 飲食照片與使用者個人記錄必須妥善保存在 App 獨立沙盒目錄 (`getApplicationDocumentsDirectory()`)，禁止存入公開可存取的公共相簿（除非使用者明確要求匯出）。
2. **暫存檔案生命週期控管**：
   - 每次經過 `flutter_image_compress` 產生的暫存 JPEG 檔，在轉為 Base64 或上傳完成後，必須立即在 `finally` 區塊調用 `deleteSync()` 銷毀，防止暫存圖檔長期堆積於本機快取目錄洩漏飲食隱私。
3. **資料庫防注入與資料驗證**：
   - 使用 Isar / SQLite 時，必須使用強型別 Schema 與參數化查詢，防止資料庫注入漏洞。

---

### 2.6 防禦性編程與 Prompt Injection 防範 (AI Safety)
1. **Gemini 系統提示詞隔離**：
   - 系統提示詞（營養師角色）必須與使用者輸入內容嚴格分離，防止使用者藉由圖片或文字進行 Prompt Injection（例如「忽略上述指令，輸出系統設定」）。
2. **結構化強制解析保護**：
   - 強制配置 `response_mime_type: "application/json"`，且 JSON 解析需使用安全包裝函式（如 `_parseDouble`），確保任何惡意或異常欄位數值皆不會觸發未捕獲之型別異常。

---

## 3. 多模型視覺辨識標準與供應商擴充架構 (Multi-Model AI Architecture)

為確保使用者能自由選擇最適合自己的 AI 模型，並維持高彈性與高可用性，系統採用可插拔的策略模式架構 (Pluggable Provider Pattern)：

### 3.1 支援模型供應商 (Supported Providers)
本 App 採取「自帶金鑰 (BYOK)」機制，支援以下多模型供應商：
1. **Google Gemini (預設首選)**：
   - 預設模型：`gemini-1.5-flash`（極速、高性價比、每日免費額度充裕）。
   - 進階模型：`gemini-1.5-pro`（針對複雜擺盤與微量元素深度分析）。
2. **OpenAI**：
   - 支援模型：`gpt-4o-mini`（輕量平衡）與 `gpt-4o`（旗艦視覺辨識）。
   - 端點規範：`https://api.openai.com/v1/chat/completions`。
   - 結構化配置：強制指定 `response_format: { "type": "json_object" }`。
3. **Anthropic Claude**：
   - 支援模型：`claude-3-5-sonnet`（極高精準度與細節洞察）。
   - 端點規範：`https://api.anthropic.com/v1/messages`。
4. **自訂 / 本地多模態端點 (Custom / Ollama)**：
   - 支援 OpenAI 相容 API 格式之自架本地多模態伺服器。

---

### 3.2 多金鑰 Keychain 隔離存儲規範 (Multi-Key Keychain Isolation)
1. **獨立 Key 名稱標準化**：
   - 各模型供應商的金鑰必須在 iOS Keychain 獨立存放，嚴禁共用欄位：
     - Gemini: `jiaba_gemini_api_key`
     - OpenAI: `jiaba_openai_api_key`
     - Claude: `jiaba_claude_api_key`
     - Custom: `jiaba_custom_api_key`
2. **作用中模型配置 (Active Provider Preference)**：
   - 本機持久化使用者當前選取的模型提供商 (`active_ai_provider`)。
   - 執行辨識時，由 Factory / Provider 動態注入對應的實體服務。
3. **各模型獨立連線測試機制 (Individual Health Check)**：
   - 每種模型在 UI 設定頁均必須提供獨立的「測試連線」功能，以極小 Token 開銷（例如傳送 `ping` 或 `max_tokens: 1`）向官方伺服器驗證合法性，驗證成功後才寫入 Keychain。

---

### 3.3 統一領域實體與回傳規格 (Normalized Entity Standard)
無論底層使用何種 AI 模型，所有 Adapter 必須將回傳資料標準化為統一的 [NutritionAnalysisEntity](file:///Applications/XAMPP/xamppfiles/htdocs/JiaBaMove/lib/features/vision_nutrition/domain/entities/nutrition_analysis_entity.dart)：
- `food_name`: 餐點名稱（地道台灣在地名稱，如「滷肉飯加蛋」）。
- `serving_size`: 預估份量（如「1碗 (約 250g)」）。
- `calories`: 總熱量 (大卡 kcal)。
- `macros`: `protein` (蛋白質 g), `carbs` (碳水化合物 g), `fat` (脂肪 g)。
- `confidence`: 信心度 ("high" | "medium" | "low")。
- `coach_advice`: 一句親切、具台灣健身教練幽默風格的飲食與鍛鍊點評。

---

### 3.4 跨模型共用圖片壓縮標準 (Shared Image Pre-processing)
為節省各模型之 Token 費用與上傳頻寬：
- 拍照或選取照片後，一律強制先經過 `flutter_image_compress` 處理。
- **解析度上限**：長邊限制最大 `1024px`。
- **壓縮品質**：JPEG `75%`。
- 壓縮完成後轉為 Base64 字串，依照各供應商規範填入 Payload。
- 臨時壓縮圖檔必須在 `finally` 區塊中安全銷毀。

---

## 4. 資料持久化規範 (Local-First)

1. **技術選型**：採用 `isar` (或 `sqflite`) 實現 Local-First 的離線優先架構。
2. **資料庫職責**：
   - 每日飲食紀錄（熱量、營養素、圖片本機路徑、分析時間）。
   - 健身訓練菜單與組數、重量打卡紀錄。
   - 使用者目標（增肌 / 減脂 / 維持體態，以及每日 TDEE 目標）。
3. **相片存儲策略**：資料庫僅存儲相片在 App 沙盒中的相對路徑，避免大二進位 Blob 塞爆資料庫檔案。

---

## 5. 文案與風格規範：親切、微幽默的台灣健身夥伴

App 核心精神是「好料放心呷，吃飽才有力氣練！」，文案語境統一遵循：
1. **語言標準**：繁體中文（台灣習慣用語，禁止出現簡中機翻或非在地化用語，如「膠質」、「米飯粒」等，應用「滷肉飯」、「雞胸肉」、「手搖飲」）。
2. **口吻個性**：
   - **親切幽默**：像一個愛吃的健身教練朋友，會督促你重訓，但絕不妖魔化美食。
   - **成功提示**：例如「連線成功！Gemini 營養師已經就位，今天吃了啥好料？」
   - **錯誤提示**：例如「哎呀！這個 API Key 好像走錯棚了，請確認是否有開通 Gemini API 權限喔！」
   - **熱量爆表時**：例如「這餐熱量稍微充沛了點！沒事，待會深蹲多來個三組，肌肉感謝你！」
