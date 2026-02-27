# API
### 查詢特定場館、特定球類、特定日期區間內開放預約的日期
- https://booking-tpsc.sporetrofit.com/Location/findAllowBookingCalendars
    - Form Data
    LID=<場地代號>&categoryId=<球類>&start=<yyyy-mm-dd>&end=<yyyy-mm-dd>
### 查詢特定場館、特定球類、特定日期的前200筆結果(場地位置、時段)
- https://booking-tpsc.sporetrofit.com/Location/findAllowBookingList?LID=<場地代號>&categoryId=<球類>&useDate=<yyyy-mm-dd>
    - Form Data
    rows=200&page=1&sord=asc



# 球類
- 羽球 Badminton
- 籃球 Basketball
- 撞球 Billiard
- 高爾夫球 Golf
- 壁球 Squash
- 桌球 TableTennis

# 場地
- 中正 JJSC
- 內湖 NHSC
- 北投 BTSC
- 大安 DASC
- 大同 DTSC
- 士林 SLSC
- 松山 SSSC
- 萬華 WHSC
- 文山 WSSC
- 信義 XYSC
- 中山 ZSSC
