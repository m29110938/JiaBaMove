# 呷飽來動 JiaBaMove

> 個人用的 iPhone 健身規劃 + AI 拍照算熱量 App。開源、免費、資料只存在你自己的手機。

用 Flutter 打造，主要目標平台是 iPhone。拍一張餐點照片，AI 營養師幫你估算熱量與三大營養素，再搭配依身體數據產生的訓練菜單與每日熱量目標。

## 功能

| 分頁 | 內容 |
|---|---|
| **今日紀錄** | 今日熱量進度、蛋白質 / 碳水 / 脂肪攝取、餐點清單 (左滑刪除)、今日運動打卡 |
| **健身菜單** | 依部位推薦動作、自訂課表、每日訓練清單、GIF / Lottie 動作示範、組間休息計時器 (鎖屏也會通知) |
| **拍照分析** | 拍照或選相簿，由 Google Gemini 辨識餐點、份量、熱量與營養素，一鍵加入今日紀錄 |
| **會員中心** | 身高體重等個人資料，自動計算 BMR / TDEE / 每日熱量與營養素目標；API Key 與 AI 模型設定 |

## 隱私與費用

- **不需要伺服器、不需要註冊**：所有資料 (個人資料、課表、飲食紀錄) 只存在手機的 iOS Keychain。
- **使用你自己的 Gemini API Key**：照片只會傳送到 Google Gemini API 做分析。Gemini 有免費額度，一般個人使用足夠。
- **程式碼裡沒有任何金鑰**：CI 會掃描並拒絕含有明文 API Key 的提交。

## 安裝到 iPhone (免費、不需要 Mac)

因為沒有上架 App Store，需要用「側載」的方式，以你自己的免費 Apple ID 簽名安裝。

1. 到本專案的 [Releases](../../releases) 下載最新的 `JiaBaMove-vX.Y.Z-unsigned.ipa`。
2. 在電腦 (Windows 或 Mac) 安裝以下任一工具：
   - [Sideloadly](https://sideloadly.io/)：最簡單，接上 iPhone、拖入 .ipa、輸入 Apple ID 即可。
   - [AltStore](https://altstore.io/)：可在同一個 Wi-Fi 下自動續簽。
3. 用 USB 連接 iPhone，用工具把 .ipa 安裝上去。
4. 在 iPhone 開啟 **設定 → 一般 → VPN 與裝置管理**，信任你的 Apple ID。
5. iOS 16 以上需要開啟 **設定 → 隱私權與安全性 → 開發者模式**。

> **免費 Apple ID 的限制**：簽名有效期 7 天，到期後 App 會打不開 (資料不會消失)，重新用工具安裝一次即可。同一時間最多 3 個側載 App。

### 設定 Gemini API Key

1. 到 [Google AI Studio](https://aistudio.google.com/apikey) 用 Google 帳號免費建立 API Key。
2. 打開 App →「會員中心」→ API Key 設定，貼上並儲存。

## 自行建置

### 用 GitHub Actions (不需要 Mac)

Fork 本專案後：

- 到 **Actions → Build Unsigned iOS IPA → Run workflow**，完成後在該次執行的 Artifacts 下載 .ipa；或
- 推送一個 `v*` 標籤 (例如 `git tag v1.0.0 && git push origin v1.0.0`)，.ipa 會自動附加到 Release。

公開 repo 的 GitHub Actions 免費。

### 本機開發

需求：Flutter 3.47.x (Dart 3.3+)。編譯 iOS 需要 macOS + Xcode。

```bash
flutter pub get
flutter test
flutter run            # 接上 iPhone 或開啟模擬器
flutter run -d chrome  # 也可以用網頁版快速預覽
```

## 專案結構

採 feature-first 的 Clean Architecture，狀態管理使用 Riverpod。

```
lib/
├── core/                  # 主題、常數、網路 (Dio)、Keychain 存儲
└── features/
    ├── auth/              # 本機使用者 (暱稱)，無登入
    ├── home/              # 今日紀錄首頁
    ├── fitness_recommendations/  # 健身菜單、課表、休息計時器
    ├── vision_nutrition/  # Gemini 拍照營養分析、飲食紀錄
    ├── profile/           # 個人資料與 BMR / TDEE 計算
    └── settings/          # API Key 與 AI 模型設定
```

## 免責聲明

AI 估算的熱量與營養素僅供參考，可能有誤差，不能取代專業營養師或醫師的建議。

## 授權

[MIT License](LICENSE)
