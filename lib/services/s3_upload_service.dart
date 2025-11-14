import 'dart:io';
import 'dart:typed_data';
import 'package:minio/minio.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../config/aws_credentials.dart';

class S3UploadService {
  static const String _bucket = 'taxi-24-dispatch-images';
  static const String _region = 'ap-northeast-1';
  static const String _accessKey = AWSCredentials.accessKey;
  static const String _secretKey = AWSCredentials.secretKey;
  static const String _endpoint = 's3.ap-northeast-1.amazonaws.com';

  // 初始化 Minio 客户端
  static Minio _getClient() {
    return Minio(
      endPoint: _endpoint,
      accessKey: _accessKey,
      secretKey: _secretKey,
      useSSL: true,
      region: _region,
    );
  }

  /// 上传图片到 S3
  /// 
  /// [filePath] 本地文件路径
  /// [caseId] 案件 ID
  /// [userId] 用户 ID
  /// 
  /// 返回上传后的图片 URL 和 key
  static Future<Map<String, String>?> uploadImage({
    required String filePath,
    required int caseId,
    required int userId,
  }) async {
    try {
      print('[S3] 开始上传图片...');
      print('[S3] 文件路径: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        print('[S3] 错误：文件不存在');
        return null;
      }

      // 获取文件扩展名
      final extension = path.extension(filePath).toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = DateTime.now().microsecond.toRadixString(16);
      
      // 生成 S3 key: case_messages/{case_id}/{user_id}/timestamp_random.jpg
      final objectKey = 'case_messages/$caseId/$userId/${timestamp}_$random$extension';
      
      // 获取 MIME 类型
      String contentType = lookupMimeType(filePath) ?? 'image/jpeg';
      print('[S3] Content-Type: $contentType');
      print('[S3] Object Key: $objectKey');
      
      // 创建 Minio 客户端
      final minio = _getClient();
      
      // 读取文件内容
      final fileBytes = await file.readAsBytes();
      final fileSize = fileBytes.length;
      print('[S3] 文件大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      
      // 转换为 Uint8List 并创建 Stream
      final uint8List = Uint8List.fromList(fileBytes);
      final stream = Stream<Uint8List>.value(uint8List);
      
      await minio.putObject(
        _bucket,
        objectKey,
        stream,
        size: fileSize,
        metadata: {
          'Content-Type': contentType,
        },
      );
      
      // 生成公开访问的 URL
      final imageUrl = 'https://$_bucket.s3.$_region.amazonaws.com/$objectKey';
      
      print('[S3] 上传成功');
      print('[S3] Image URL: $imageUrl');
      
      return {
        'image_key': objectKey,
        'image_url': imageUrl,
      };
      
    } catch (e) {
      print('[S3] 上传失败: $e');
      return null;
    }
  }

  /// 删除 S3 上的图片
  /// 
  /// [imageKey] 图片的 S3 key
  static Future<bool> deleteImage(String imageKey) async {
    try {
      print('[S3] 删除图片: $imageKey');
      
      final minio = _getClient();
      await minio.removeObject(_bucket, imageKey);
      
      print('[S3] 删除成功');
      return true;
    } catch (e) {
      print('[S3] 删除失败: $e');
      return false;
    }
  }
}

