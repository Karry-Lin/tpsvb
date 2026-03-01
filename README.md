# 場訂 — 台北市公立運動場地預約查詢

> 一鍵查詢台北市 11 座公立運動中心的場地預約狀況，快速找出有空位的時段並直接跳轉官方系統完成預約。

- **平台：** Android 8.0+（minSdk 26）
- **版本：** 1.0.0+1
- **語言：** Dart / Flutter

---

## 功能特色

- **速覽頁（Tab 0）**：以場館卡片 + 綠色日期標籤方式，僅列出當前有可預約時段的場館，一眼看出哪裡有空
- **完整查詢頁（Tab 1）**：場館（列）× 日期（欄）矩陣總覽，綠色可預約 / 紅色額滿 / 灰色未開放
- **時段詳情**：點擊任一格或日期標籤，彈出底部面板顯示場地名稱、時段、費用（NT$），並提供「前往官方網站預約」按鈕
- **篩選功能**：可依運動類型（羽球／籃球／撞球／桌球／壁球／網球）、查詢天數（1–14 天）、時段（全天／早／午／晚）、場館自由篩選
- **偏好設定持久化**：篩選條件自動儲存至裝置，下次開啟自動套用
- **快取機制**：記憶體快取（TTL 5 分鐘），避免重複發送相同查詢
- **骨架屏動畫**：查詢進行中顯示脈衝骨架屏，提升等待體驗
- **音效回饋**：搜尋中循環播放背景音、完成時播放成功音效
- **預約須知頁**：App 內 WebView 載入官方須知頁，並注入 JavaScript 將英文行政區名替換為繁體中文

---

## 支援場館

| 代碼 | 場館名稱 | 行政區 |
|------|----------|--------|
| DASC | 大安運動中心 | 大安區 |
| BTSC | 北投運動中心 | 北投區 |
| ZZSC | 中正運動中心 | 中正區 |
| ZNSC | 中山運動中心 | 中山區 |
| XZSC | 信義運動中心 | 信義區 |
| SDSC | 士林運動中心 | 士林區 |
| NKSC | 南港運動中心 | 南港區 |
| MGSC | 木柵運動中心 | 文山區 |
| NGSC | 內湖運動中心 | 內湖區 |
| WZSC | 萬芳運動中心 | 文山區 |
| STSC | 松山運動中心 | 松山區 |

---

## 技術架構

### 主要套件

| 套件 | 版本 | 用途 |
|------|------|------|
| `flutter_riverpod` | ^2.6.1 | 狀態管理 |
| `riverpod_annotation` | ^2.6.1 | Riverpod 程式碼生成 |
| `dio` | ^5.7.0 | HTTP 網路請求與重試 |
| `shared_preferences` | ^2.3.3 | 偏好設定本地儲存 |
| `url_launcher` | ^6.3.1 | 開啟外部瀏覽器 |
| `audioplayers` | ^6.1.0 | 音效播放 |
| `webview_flutter` | ^4.10.0 | App 內建 WebView |

### 狀態管理（Riverpod）

| Provider | 類型 | 說明 |
|----------|------|------|
| `selectedSportTypeProvider` | StateProvider | 當前選取的運動類型 |
| `selectedCentersProvider` | StateProvider | 選取的場館清單（預設全 11 館） |
| `dateRangeDaysProvider` | StateProvider | 查詢天數（1–14，預設 14） |
| `timeFilterProvider` | StateProvider | 時段篩選（全天／早／午／晚） |
| `activeDatesProvider` | StateProvider | 本次查詢實際使用的日期清單 |
| `sportCenterQueryProvider` | StateNotifierProvider.family | 每個場館獨立的查詢狀態 |
| `queryProgressProvider` | Provider | 整體查詢進度（done / total） |
| `lastUpdatedProvider` | StateProvider | 最後更新時間（台北時間 UTC+8） |

### 核心查詢流程

查詢採**兩段式並發**策略，兼顧速度與對官方伺服器的友善程度：

```
第一階段：11 個場館同時並發呼叫 API-01
  → 取得各館哪些日期有開放預約
  → 無開放日期 → 直接標記灰色，不發第二階段請求

第二階段：有效日期透過全域 Semaphore(10) 並發呼叫 API-02
  → 最多同時 10 個請求在途
  → 自動重試（302 / 429 / 5xx / 逾時）：最多 3 次，指數退避 500ms / 1000ms / 2000ms
  → 每完成一館 → 立即更新 UI（逐步顯示結果）
```

---

## 專案結構

```
tpsvb/
├── lib/
│   ├── main.dart                      # 進入點，ProviderScope + MaterialApp
│   ├── models/
│   │   ├── sport_center.dart          # 11 個場館常數（LID、名稱、行政區）
│   │   ├── sport_type.dart            # 6 種運動類型定義
│   │   ├── slot_availability.dart     # SlotStatus enum + Domain Model
│   │   └── api_response.dart          # API 原始回應解析
│   ├── services/
│   │   ├── booking_api_service.dart   # Dio HTTP 呼叫 + 重試機制
│   │   ├── booking_repository.dart    # 兩段式查詢 + Semaphore(10) + 快取
│   │   ├── query_cache.dart           # 記憶體快取（TTL 5 分鐘）
│   │   ├── preferences_service.dart   # SharedPreferences 讀寫
│   │   └── audio_service.dart         # 音效管理
│   ├── providers/
│   │   ├── service_providers.dart     # 全域單例（Cache / API / Repo / Prefs / Audio）
│   │   ├── query_providers.dart       # 篩選條件、日期計算、偏好套用
│   │   └── center_query_provider.dart # 各場館獨立 StateNotifier + 進度追蹤
│   ├── screens/
│   │   ├── splash_screen.dart         # 啟動頁（淡入 + 滑動動畫）
│   │   ├── main_screen.dart           # 主容器（BottomNavigationBar，2 個 Tab）
│   │   ├── available_screen.dart      # Tab 0：速覽頁
│   │   ├── query_screen.dart          # Tab 1：場館 × 日期矩陣
│   │   └── booking_info_screen.dart   # 預約須知（WebView + JS 注入）
│   └── widgets/
│       ├── filter_sheet.dart          # 篩選 Bottom Sheet
│       └── slot_detail_sheet.dart     # 時段詳情 Bottom Sheet
├── assets/
│   ├── images/                        # 11 個場館圖片
│   ├── icon/                          # App 圖示
│   ├── sounds/                        # 音效檔（button / searching / success）
│   └── font/                          # 自訂字型 ChenYuluoyan-Thin
├── android/                           # Android 原生設定與簽章金鑰
├── REQUIREMENTS.md                    # 完整需求文件 v2.0
└── pubspec.yaml
```

---

## 環境需求

| 工具 | 版本需求 |
|------|----------|
| Flutter | 3.x（Dart SDK ^3.11.0） |
| Android SDK | minSdk 26（Android 8.0+） |
| Java | 17+（Android 編譯所需） |

---

## 安裝與執行

```bash
# 1. 複製專案
git clone <repo-url>
cd tpsvb

# 2. 安裝相依套件
flutter pub get

# 3. 執行程式碼生成（Riverpod）
dart run build_runner build --delete-conflicting-outputs

# 4. 連接裝置或啟動模擬器後執行
flutter run
```

---

## 打包 Release APK

簽章設定存放於 `android/key.properties`，金鑰庫為 `android/tpsvb-release.jks`。

```bash
flutter build apk --release
```

產出路徑：`build/app/outputs/flutter-apk/app-release.apk`

---

## 資料來源與 API

本 App 串接台北市公立運動中心官方預約系統後端 API：

| API | 端點 | 用途 |
|-----|------|------|
| API-01 | `POST /Location/findAllowBookingCalendars` | 查詢場館在日期區間內有開放預約的日期清單 |
| API-02 | `POST /Location/findAllowBookingList` | 查詢場館某日所有時段與可用狀態 |

**Base URL：** `https://booking-tpsc.sporetrofit.com`

---

## 開發進度

| 階段 | 內容 | 狀態 |
|------|------|------|
| Phase 0 | API 研究與文件化 | 完成 |
| Phase 1 | 專案架構、資料模型、API Service | 完成 |
| Phase 2 | 啟動首頁 UI | 完成 |
| Phase 3 | 查詢主畫面 UI + 狀態管理 | 完成 |
| Phase 4 | 篩選功能、偏好設定、快取機制 | 完成 |
| Phase 5 | 時段詳情彈窗、外部連結 | 完成 |
| Phase 6 | WebView + JS 注入中文區名 | 完成 |
| Phase 7 | 錯誤處理、ErrorSummaryBar、骨架屏 | 完成 |
| Phase 8 | 測試、優化、打包 | 進行中 |
