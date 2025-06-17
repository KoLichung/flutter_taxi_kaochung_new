# AWS S3 配置說明

## 第一步：獲得 AWS 憑證

### 1. 登入 AWS Console
前往 [AWS Console](https://console.aws.amazon.com/) 並登入您的帳戶

### 2. 進入 IAM 服務
- 在 AWS Console 搜尋框輸入 "IAM"
- 點選 "IAM" 服務

### 3. 創建新用戶
1. 在左側選單點選 **"Users"**
2. 點選 **"Create user"** 按鈕
3. 輸入用戶名稱 (例如: `taxi-app-user`)
4. 選擇 **"Programmatic access"**

### 4. 設定權限
1. 選擇 **"Attach policies directly"**
2. 搜尋並選擇 **"AmazonS3FullAccess"** 政策
3. 點選 **"Next"** 然後 **"Create user"**

### 5. 獲取憑證
- 複製 **Access Key ID** 
- 複製 **Secret Access Key**
- ⚠️ **重要**: Secret Access Key 只會顯示一次，請務必保存

## 第二步：配置應用程式

### 1. 編輯 AWS 配置文件
打開 `lib/config/aws_config.dart` 文件：

```dart
class AWSConfig {
  // 將您的實際憑證填入這裡
  static const String accessKey = 'YOUR_ACCESS_KEY_ID';
  static const String secretKey = 'YOUR_SECRET_ACCESS_KEY';
  
  // 其他配置保持不變...
}
```

### 2. 安全提醒
- ⚠️ **絕對不要將實際的 AWS 憑證提交到 Git**
- 建議在 `.gitignore` 中添加 `lib/config/aws_config.dart`
- 或使用環境變數來管理敏感信息

## 第三步：S3 Bucket 配置

### 1. 創建 S3 Bucket
1. 前往 AWS S3 Console
2. 點選 **"Create bucket"**
3. 輸入 Bucket 名稱: `taxi-routes`
4. 選擇地區: **"Asia Pacific (Tokyo) ap-northeast-1"**
5. 保持其他設定為預設值，點選 **"Create bucket"**

### 2. 設定 Bucket 權限
1. 選擇您剛創建的 bucket
2. 前往 **"Permissions"** 標籤
3. 根據需要調整存取權限

## 路線匯出功能

當司機完成任務時，應用程式會：
1. 從 SQLite 資料庫讀取位置記錄
2. 將資料庫文件上傳到 S3
3. 文件路徑格式: `routes/case_{任務ID}_{用戶ID}.db`

## 故障排除

### 常見錯誤
1. **403 Forbidden**: 檢查 IAM 用戶權限
2. **Bucket not found**: 確認 bucket 名稱和地區設定
3. **Invalid credentials**: 檢查 Access Key 和 Secret Key

### 檢查清單
- [ ] AWS 憑證正確填入
- [ ] S3 bucket 已創建
- [ ] IAM 用戶具有 S3 權限
- [ ] 地區設定正確 (ap-northeast-1) 