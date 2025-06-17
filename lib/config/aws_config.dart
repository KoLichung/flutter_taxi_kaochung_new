/// AWS S3 設定檔案
/// 請將 AWS 憑證填入下方的常數中
class AWSConfig {
  
  // ⚠️ 請將您的 AWS 憑證填入這裡，不要提交到 Git！
  static const String accessKey = 'YOUR_ACCESS_KEY_HERE';
  static const String secretKey = 'YOUR_SECRET_KEY_HERE';
  
  // S3 配置
  static const String bucketName = 'taxi-routes';  // 您的 bucket 名稱
  static const String region = 'ap-northeast-1';    // 東京區域
  
  // S3 文件夾結構
  static const String routesFolder = 'routes/';  // 存放路線檔案的資料夾
  
  /// 取得 S3 物件的完整 URL
  static String getS3Url(String key) {
    return 'https://$bucketName.s3.$region.amazonaws.com/$key';
  }
  
  /// 產生路線檔案的 S3 Key
  static String generateRouteKey(int caseId, String userId) {
    return '$routesFolder/case_${caseId}_${userId}.db';
  }
} 