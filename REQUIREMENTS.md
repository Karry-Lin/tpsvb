# 台北市運動中心場地預約查詢 App 需求文件

**專案代號：** tpsvb (Taipei Public Sports Venue Booking)
**平台：** Android (Flutter)
**文件版本：** v2.0
**建立日期：** 2026-02-27
**最後更新：** 2026-02-28

---

## 1. 背景與問題描述

### 1.1 現況問題

台北市公立運動中心統一預約系統（https://booking-tpsc.sporetrofit.com/）雖提供線上預約功能，但使用體驗極差：

- 每次僅能查看**單一運動中心、單一運動類型、單一日期、單一時段**的場地狀態
- 使用者必須重複點擊才能跨場館、跨日期查詢是否有空位
- 無法一次總覽多個場館、多個時段的可預約狀況
- 對於想在空閒時間出門運動的使用者，找到合適時段需要花費大量時間

### 1.2 目標使用者

- 台北市民，習慣於台北各公立運動中心從事羽球、籃球、桌球、壁球、撞球、高爾夫球等運動
- 希望快速找出「近期哪個時段、哪個場館有空位」的使用者
- 有明確運動偏好（特定運動項目），希望比較多家場館的使用者

---

## 2. 專案目標

開發一款 Android App，透過呼叫台北市運動中心預約系統的後端 API，**一次撈取多個場館、多個日期的時段可用狀態**，以清晰的總覽畫面呈現，讓使用者能快速找到可預約的場地。

---

## 3. 功能需求

### 3.1 核心功能

#### F-01｜啟動首頁（Splash / Landing Page）

- App 啟動後顯示專屬首頁，內容包含：
  - 系統全名：**臺北市公立運動場地預約查詢系統**
  - 副標題或說明文字（例：快速瀏覽各運動中心場地預約狀況）
  - **開始查詢**按鈕
- 點擊畫面任意位置**或**點擊「開始查詢」按鈕，皆可進入查詢主畫面
- 首頁不做自動跳轉計時器，讓使用者主動決定何時進入

#### F-02｜場館總覽（查詢主畫面）

- 以**場館（列）× 日期（欄）**矩陣式表格，同時顯示多筆場地的可用狀態
- 狀態以顏色區分：
  - **可預約（綠色）**
  - **已額滿（紅色）**
  - **未開放預約（灰色）**
  - **載入中（骨架屏動畫）**
- **逐步顯示**：哪個場館的資料先回來就先顯示，不等全部完成，格子從「載入中」逐一更新為實際狀態
- 篩選摘要列顯示目前查詢條件（球類、場館數、天數、時段、最後更新時間）
- 畫面固定顯示**場地預約須知入口**（詳見 F-08）

#### F-03｜資料來源：API 串接

- 透過呼叫 `booking-tpsc.sporetrofit.com` 後端 API 取得場地預約狀態資料
- 支援同時查詢多個場館（支援以下 11 個行政區的運動中心）：
  - 中正、內湖、北投、大安、大同、士林、松山、萬華、文山、信義、中山
- **每次查詢固定為單一球類**，涵蓋範圍：使用者選定運動類型 + 今天起 1～14 天（可自訂）+ 全天各時段
- 資料強調即時性，**不做背景預取**，每次查詢都向伺服器取得最新狀態

#### F-04｜篩選與搜尋

- **運動類型篩選**：羽球（Badminton）、籃球（Basketball）、撞球（Billiard）、高爾夫球（Golf）、壁球（Squash）、桌球（TableTennis）
- **場館選擇**：可勾選要查詢的特定場館（預設：全選 11 館）
- **日期範圍選擇**：Slider 可選 1～14 天（預設：今天起 14 天）
- **時段篩選**：全天 / 早上（06:00–12:00）/ 下午（12:00–18:00）/ 晚上（18:00–22:00）
- 篩選設定儲存於本機（SharedPreferences），下次開啟自動套用

#### F-05｜快速跳轉預約

- 點擊某一「可預約」或「已額滿」的時段格，彈出底部 Sheet 顯示詳細時段清單（場地名稱、時間、費用、狀態）
- Sheet 中點擊「前往官方網站預約」，以外部瀏覽器開啟對應預約頁面

#### F-06｜資料快取

- 查詢結果**短暫**記憶體快取（快取時效：5 分鐘），防止使用者誤觸重新查詢時重複打 API
- 快取時效刻意設短，確保資料接近即時（預約名額隨時可能因取消而釋出）
- 使用者可手動下拉強制更新，清除快取重新取得最新資料

#### F-07｜我的偏好設定

- 儲存常用的運動類型、場館、日期天數、時段偏好，下次開啟自動套用
- 設定儲存於本機（SharedPreferences）

#### F-08｜場地預約須知

- 查詢主畫面右上角「須知」按鈕，點擊後以 App 內建 WebView 開啟官方預約須知頁面：
  `https://booking-tpsc.sporetrofit.com/Home/BookingInformation#1`
- 以 WebView 呈現（而非跳出外部瀏覽器），讓使用者看完後可直接返回 App
- 注入 JavaScript 將頁面英文 h1 標題改為對應中文區名（12 個區）：
  Beitou→北投、Datong→大同、Neihu→內湖、Wanhua→萬華、Songshan→松山、Shihlin→士林、Zhongshan→中山、Jhongjheng→中正、Nangang→南港、Xinyi→信義、Da'an→大安、Wunshan→文山

---

## 4. 非功能需求

### 4.1 效能

- 畫面首次出現內容（第一個場館資料）：≤ 2 秒
- 全部場館資料載入完成：≤ 10 秒（11 場館並發，視網路狀況）
- 有快取時畫面立即呈現（≤ 0.5 秒），快取時效 5 分鐘
- **API-01（11 館）：全部同時並發，無限制**
- **API-02：全域 Semaphore 最大並發數 15**（11 館 × 14 天最多 154 個請求，15 並發在速度與伺服器負荷間取得平衡）
- 偶發 302 / 429 / 5xx / 逾時：自動重試最多 2 次，間隔 400ms × attempt

### 4.2 可用性

- 支援 Android 8.0（API Level 26）以上
- 支援手機直向使用（主要）；平板橫向可用（次要）
- 空狀態提示（無可預約場地時顯示友善訊息）
- 錯誤狀態持續顯示在畫面底部（橙色 `_ErrorSummaryBar`，不自動消失）
- 查詢時最後更新時間以 Chip 形式顯示（台北時間 UTC+8，格式 `更新 HH:mm`，綠色）

### 4.3 安全性與合規

- 本 App 僅**讀取**公開可查詢的預約狀態資料，不執行任何預約或付款操作
- 不收集、不儲存使用者個人資料
- 請求行為須符合對方網站的 robots.txt 及使用規範；請求頻率應合理，避免對伺服器造成過大負荷

---

## 5. 目標場館清單

| 行政區 | 場館名稱 | LID 代號 |
|--------|----------|----------|
| 中正區 | 中正運動中心 | JJSC |
| 內湖區 | 內湖運動中心 | NHSC |
| 北投區 | 北投運動中心 | BTSC |
| 大安區 | 大安運動中心 | DASC |
| 大同區 | 大同運動中心 | DTSC |
| 士林區 | 士林運動中心 | SLSC |
| 松山區 | 松山運動中心 | SSSC |
| 萬華區 | 萬華運動中心 | WHSC |
| 文山區 | 文山運動中心 | WSSC |
| 信義區 | 信義運動中心 | XYSC |
| 中山區 | 中山運動中心 | ZSSC |

---

## 6. 使用者流程（User Flow）

```
App 啟動
    │
    ▼
【啟動首頁】
  顯示系統名稱：臺北市公立運動場地預約查詢系統
  + 開始查詢按鈕
    │
    │ 點擊任意位置 或 點擊「開始查詢」
    ▼
【查詢主畫面（場館總覽）】
    │ 預設套用上次偏好設定，立即開始載入
    ▼
顯示「場館 × 日期」可用狀態矩陣（逐步填入，骨架屏過渡）
    │
    ├── 使用者點擊右上角「⚙ 篩選」
    │       │
    │       ▼
    │   篩選 Bottom Sheet（球類 / 場館 / Slider 天數 / 時段）
    │       │
    │       ▼
    │   套用後重新查詢 → 更新畫面
    │
    ├── 點擊可預約 / 已額滿 格
    │       │
    │       ▼
    │   底部 Sheet：時段清單（場地名、時間、費用、狀態）
    │       │
    │       ▼
    │   點擊「前往官方網站預約」→ 外部瀏覽器
    │
    ├── 點擊右上角「須知」按鈕
    │       │
    │       ▼
    │   【須知頁面（WebView）】
    │   載入 booking-tpsc.sporetrofit.com/Home/BookingInformation
    │   JS 注入將英文 h1 標題替換為中文區名
    │   使用者閱讀後按返回 ← 回到查詢主畫面
    │
    └── 下拉刷新
            │
            ▼
        清除快取，重新查詢所有場館
```

---

## 7. 畫面設計草稿

### 7.1 啟動首頁（Landing Page）

```
┌─────────────────────────────────────────┐
│                                         │
│        臺北市公立運動場地               │
│          預約查詢系統                   │
│                                         │
│    快速瀏覽各運動中心場地預約狀況        │
│                                         │
│         ┌─────────────────┐             │
│         │    開始查詢      │             │
│         └─────────────────┘             │
│                                         │
│      點擊畫面任意位置也可進入            │
│                                         │
└─────────────────────────────────────────┘
```

### 7.2 查詢主畫面（場館總覽）

```
┌─────────────────────────────────────────┐
│  場地查詢                須知 ？  ⚙     │
├─────────────────────────────────────────┤
│  [羽球] [11場館] [14天] [全天] [更新14:23]│  ← 篩選摘要 Chips
├─────────────────────────────────────────┤
│  ████████████████  載入中 5 / 11 場館   │  ← 進度條（載入中才顯示）
├────────┬──────┬──────┬──────┬──────────┤
│        │ 今天 │ 明天 │ 後天 │  ...      │
│        │ 2/28 │  3/1 │  3/2 │          │
├────────┼──────┼──────┼──────┼──────────┤
│ 中山   │  ●可 │  ✗滿 │  ●可 │           │  ← 已載入
│ 中正   │░░░░░░│░░░░░░│░░░░░░│           │  ← 骨架屏
│ 內湖   │  ─未 │  ─未 │  ─未 │           │  ← 未開放
│  ...   │      │      │      │           │
└────────┴──────┴──────┴──────┴──────────┘
  ● 可預約  ✗ 已額滿  ─ 未開放
├─────────────────────────────────────────┤
│ ⚠ 2 個場館查詢失敗                      │  ← ErrorSummaryBar（橙色）
│ • 萬華運動中心：連線逾時，請確認網路     │
└─────────────────────────────────────────┘
```

### 7.3 時段詳細資訊（點擊後彈出 Bottom Sheet）

```
┌──────────────────────────────────────────┐
│  中山運動中心  羽球  2026/02/28（六）      │
│  3 個可預約時段                           │
├──────────────────────────────────────────┤
│  4F羽球A   06:00–07:00  可預約  NT$300   │
│  4F羽球B   07:00–08:00  已額滿  NT$300   │
│  4F羽球A   14:00–15:00  可預約  NT$300   │
├──────────────────────────────────────────┤
│         [ 前往官方網站預約 ]              │
└──────────────────────────────────────────┘
```

### 7.4 場地預約須知（WebView 頁面）

```
┌─────────────────────────────────────────┐
│  ← 返回        場地預約須知              │
├─────────────────────────────────────────┤
│  [官方網站內容 - WebView 顯示]          │
│  # 北投區（JS 注入將英文改中文）         │
│  場地預約須知                           │
│  1. 場地預約開放時間：...               │
│  ...                                    │
└─────────────────────────────────────────┘
```

---

## 8. 技術架構

### 8.1 技術選型

| 層次 | 技術 |
|------|------|
| 框架 | Flutter (Dart) |
| 目標平台 | Android（minSdk = 26） |
| 網路請求 | `dio` 套件 |
| 狀態管理 | `flutter_riverpod`（StateNotifier + family） |
| 本地快取 | 記憶體快取（TTL 5 分鐘，`QueryCache` 類別） |
| 偏好設定儲存 | `shared_preferences` |
| 外部連結 | `url_launcher` |
| App 內 WebView | `webview_flutter` |

### 8.2 資料流

```
使用者操作（選定球類 + 場館）
    │
    ▼
Riverpod Provider（各場館獨立 StateNotifier）
    │ 同時觸發 11 個場館的查詢流程（全部並發）
    ▼
【第一階段：並發 API-01 × 11 場館（無限制，全同時）】
    │ 每個場館各自回傳有效日期清單
    │ 無開放日期 → 該場館所有格子立即標記為「未開放（灰色）」
    ▼
【第二階段：並發 API-02（全域 Semaphore，最大同時 15 個）】
    │ 每完成一個請求 → 立即更新對應場館格子（逐步顯示）
    │ 偶發 302/429/5xx/逾時 → 自動重試最多 2 次（間隔 400ms × attempt）
    │ 全部完成 → 顯示「更新 HH:mm」時間戳 Chip（UTC+8）
    ▼
BookingRepository
    ├── 寫入記憶體快取（TTL 5 分鐘）
    └── 回傳 Domain Model 給 StateNotifier
```

### 8.3 主要資料模型

```dart
enum SlotStatus { available, full, unavailable, loading, error }

class SlotAvailability {
  final String venueId;
  final String venueName;     // 例：4F羽球A
  final String sportCenterId;
  final DateTime date;
  final String startTime;     // 例：14:00
  final String endTime;       // 例：15:00
  final SlotStatus status;
  final int? price;
  final String? directBookingUrl;
}

class DayVenueResult {
  final String sportCenterId;
  final DateTime date;
  final List<SlotAvailability> slots;
  final SlotStatus overallStatus;
}

class SportCenterQueryState {
  final String sportCenterId;
  final Map<String, DayVenueResult> resultsByDate; // key: yyyy-MM-dd
  final bool isLoading;
  final String? errorMessage;
}
```

### 8.4 目錄結構

```
lib/
├── main.dart
├── models/
│   ├── sport_center.dart        # 11 個場館常數（LID、名稱、行政區）
│   ├── sport_type.dart          # 6 種運動類型
│   ├── slot_availability.dart   # SlotStatus enum + Domain Model
│   └── api_response.dart        # API 原始回應解析
├── services/
│   ├── booking_api_service.dart # Dio 呼叫、重試機制（302/429/5xx/逾時）
│   ├── booking_repository.dart  # 兩段式查詢、全域 Semaphore(15)、快取
│   ├── query_cache.dart         # 記憶體快取 TTL 5 分鐘
│   └── preferences_service.dart # SharedPreferences 讀寫
├── providers/
│   ├── service_providers.dart
│   ├── query_providers.dart     # 日期（UTC+8）、天數、球類、時段、場館
│   └── center_query_provider.dart
├── screens/
│   ├── splash_screen.dart
│   ├── query_screen.dart        # 矩陣 UI、骨架屏、篩選摘要列、錯誤列
│   └── booking_info_screen.dart # WebView + JS 注入（英文→中文區名）
└── widgets/
    ├── filter_sheet.dart        # 篩選 Bottom Sheet（Slider 天數、時段）
    └── slot_detail_sheet.dart   # 時段詳情 Bottom Sheet
```

---

## 9. API 規格（已確認）

### 9.1 API Endpoint 一覽

所有 API 均透過 POST 請求呼叫，Base URL：`https://booking-tpsc.sporetrofit.com`

共用請求 Headers：
```
User-Agent: Mozilla/5.0 (Android; Mobile) tpsvb/1.0
Accept: application/json, text/javascript, */*; q=0.01
Referer: https://booking-tpsc.sporetrofit.com/
X-Requested-With: XMLHttpRequest
```

#### API-01｜查詢特定場館、球類在日期區間內開放預約的日期

```
POST /Location/findAllowBookingCalendars
Content-Type: application/x-www-form-urlencoded

Form Data:
  LID=<場地代號>        // 例：ZSSC
  categoryId=<球類>     // 例：Badminton
  start=<yyyy-MM-dd>    // 例：2026-02-28
  end=<yyyy-MM-dd>      // 例：2026-03-14
```

**回傳格式（陣列）：**
```json
[
  {"title":"開放預約","start":"2026-03-08","allDay":true,"color":"#5F6AAA"},
  ...
]
```
> 注意：日期欄位為 `start`（非 `date`）

**用途：** 取得哪些日期有開放預約，可用來過濾無需查詢的日期，減少後續請求數量。

#### API-02｜查詢特定場館、球類、特定日期的場地與時段清單

```
POST /Location/findAllowBookingList?LID=<場地代號>&categoryId=<球類>&useDate=<yyyy-MM-dd>
Content-Type: application/x-www-form-urlencoded

Form Data:
  rows=200
  page=1
  sord=asc
```

**回傳格式（物件含 rows 陣列）：**
```json
{
  "rows": [
    {
      "LSID": "ZS4FBadmintonA",
      "LSIDName": "4F羽球A",
      "StartTime": {"Hours": 6, "Minutes": 0, "Seconds": 0, ...},
      "EndTime":   {"Hours": 7, "Minutes": 0, "Seconds": 0, ...},
      "allowBooking": "Y",
      "TotalPrice": 300
    },
    ...
  ]
}
```

> 注意：
> - 時間為物件格式 `{"Hours":H,"Minutes":M,...}`，非字串
> - `allowBooking == "Y"` 表示可預約；`"N"` 表示已額滿

**用途：** 取得指定日期下所有可預約的場地名稱、時段與費用（最多 200 筆）。

### 9.2 球類 categoryId 對照表

| 中文名稱 | categoryId |
|----------|------------|
| 羽球 | Badminton |
| 籃球 | Basketball |
| 撞球 | Billiard |
| 高爾夫球 | Golf |
| 壁球 | Squash |
| 桌球 | TableTennis |

### 9.3 場館 LID 對照表

| 行政區 | LID |
|--------|-----|
| 中正區 | JJSC |
| 內湖區 | NHSC |
| 北投區 | BTSC |
| 大安區 | DASC |
| 大同區 | DTSC |
| 士林區 | SLSC |
| 松山區 | SSSC |
| 萬華區 | WHSC |
| 文山區 | WSSC |
| 信義區 | XYSC |
| 中山區 | ZSSC |

### 9.4 請求量化分析（預設 14 天）

#### 最壞情況

```
11 場館 × 14 天 = 154 次 API-02 請求
+ 11 場館 × 1 次 API-01 = 11 次
─────────────────────────────────
總計最多 165 次請求
```

#### 兩段式查詢優化後

```
第一階段：11 次 API-01（全部同時並發）
  → 取得各場館在 14 天內有哪些日期有開放
  → 假設平均每館有 7 個有效日期

第二階段：11 場館 × 7 有效日期 ≈ 77 次 API-02
  → 全域 Semaphore 最大 15 並發
  → 跳過未開放日期，避免無效請求

實際總請求數：約 77～154 次（視各場館開放程度）
```

### 9.5 體驗優化策略

#### 策略一：逐步顯示（Progressive Loading）

- 每個場館對應獨立的 `StateNotifier`（Riverpod family），各自管理載入狀態
- 哪個場館 API 回傳結果，該場館格子立即更新，不等其他場館

#### 策略二：分批並發（Semaphore 控制）

```
第一階段（API-01）：11 個請求全部同時並發

第二階段（API-02）：
  全域 _Semaphore(15)，最多同時 15 個請求在途
  哪個請求完成就立即更新對應場館的畫面格子
```

#### 策略三：優先顯示「無需等待」結果

- API-01 回傳「無開放日期」的場館 → 立即將所有格子標記為灰色，使用者可快速跳過
- 已確認可預約的時段優先顯示，不需等待所有資料

#### 策略四：進度指示

- 畫面上方顯示進度條（「載入中 N / 11 場館」），全部完成後消失
- 完成後顯示「更新 HH:mm」Chip（台北時間 UTC+8，綠色）

#### 策略五：自動重試

- 偶發 302（限流重定向）/ 429 / 5xx / 連線逾時 → 自動重試最多 2 次
- 重試間隔：400ms × attempt（第 1 次 400ms，第 2 次 800ms）
- 若重試後仍失敗，該場館顯示錯誤狀態，不影響其他場館

---

## 10. 開發里程碑

| 階段 | 內容 | 狀態 |
|------|------|------|
| ~~Phase 0~~ | ~~API 研究與文件化（逆向工程）~~ | ✅ 完成 |
| ~~Phase 1~~ | ~~專案架構建立、資料模型、API Service Layer~~ | ✅ 完成 |
| ~~Phase 2~~ | ~~啟動首頁 UI~~ | ✅ 完成 |
| ~~Phase 3~~ | ~~查詢主畫面 UI（總覽矩陣）+ 狀態管理~~ | ✅ 完成 |
| ~~Phase 4~~ | ~~篩選功能（Slider 天數）、偏好設定、快取機制~~ | ✅ 完成 |
| ~~Phase 5~~ | ~~時段詳情彈窗、外部連結跳轉~~ | ✅ 完成 |
| ~~Phase 6~~ | ~~場地預約須知 WebView + JS 注入中文區名~~ | ✅ 完成 |
| ~~Phase 7~~ | ~~錯誤處理（重試機制）、ErrorSummaryBar、骨架屏~~ | ✅ 完成 |
| Phase 8 | 測試、優化、打包 | 進行中 |

---

## 11. 風險與限制

| 風險 | 說明 | 因應策略 |
|------|------|---------|
| API 結構可能變動 | 官方可能隨時改版 endpoint 或參數 | 架構中抽離 API 解析層（`api_response.dart`），方便快速更新 |
| 請求頻率限制 | 最多 165 次請求，可能觸發伺服器限流 | 兩段式查詢 + Semaphore(15) 控制並發；自動重試 302/429 |
| 偶發 302 重定向 | 伺服器高並發時對部分請求回傳 302（限流/session 問題） | `followRedirects: false` + `_postWithRetry` 重試機制 |
| 各場館球類不同 | 非每個場館都有全部 6 種球類 | 以 API-01 回傳結果動態判斷，無支援時標記灰色 |
| 查詢結果與官網不符 | 已加入 `[Repo]`/`[API]` debug log，需實機觀察 logcat 確認 | 待實機執行後根據 log 診斷 |
| 網路環境差時載入緩慢 | 弱網環境下可能等很久 | 逐步顯示 + 超時後顯示錯誤並可重試 |

---

## 12. 範疇外（Out of Scope）

以下功能**不在**本版本開發範圍內：

- 直接在 App 內完成預約（需整合登入與付款，法律與安全風險高）
- iOS 版本
- 推播通知（有空位時通知）—— 可列為 v2.0 功能
- 用戶帳號系統
- 游泳池即時人數查詢（雖官網有此功能，但屬附加功能）
