import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:aws_common/aws_common.dart';
import '../config/aws_config.dart';

/// 路線匯出服務
/// 負責：
/// 1. 管理 SQLite 資料庫中的位置記錄 (僅 lat, lng, case_id)
/// 2. 匯出特定案件的路線資料
/// 3. 上傳資料庫檔案到 AWS S3
class RouteExportService {
  static Database? _database;
  static const String _tableName = 'locations';
  
  /// 初始化資料庫
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }
  
  /// 初始化資料庫，使用版本管理來處理結構變更
  static Future<Database> _initDB() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, 'route_export.db');
      
      debugPrint('[RouteExport] 資料庫路徑: $path');
      
      return await openDatabase(
        path,
        version: 2, // 版本號增加到 2，以觸發 onUpgrade
        onCreate: (db, version) async {
          await _createTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // 如果是從舊版本升級，刪除舊表，建立新表
          if (oldVersion < 2) {
            await db.execute('DROP TABLE IF EXISTS $_tableName');
            await _createTable(db);
            debugPrint('[RouteExport] 資料庫已升級至版本 $newVersion');
          }
        },
      );
    } catch (e) {
      debugPrint('[RouteExport] 資料庫初始化錯誤: $e');
      rethrow;
    }
  }
  
  /// 建立資料庫表格 (僅 lat, lng, case_id)
  static Future<void> _createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        case_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    debugPrint('[RouteExport] 資料庫表格已使用簡化結構 (lat, lng, case_id) 創建');
  }

  /// (Requirement 2) 儲存來自背景插件的位置記錄 (只儲存 lat, lng)
  static Future<void> saveLocationFromBg(bg.Location location, {int? caseId}) async {
    try {
      final db = await database;
      final Map<String, dynamic> data = {
        'latitude': location.coords.latitude,
        'longitude': location.coords.longitude,
        'case_id': caseId,
      };
      final id = await db.insert(_tableName, data, conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint('[RouteExport] 背景位置已儲存 (lat, lng)，ID: $id, CaseID: $caseId');
    } catch (e) {
      debugPrint('[RouteExport] 儲存背景位置錯誤: $e');
    }
  }

  /// (Requirement 3) 儲存初始位置記錄
  static Future<void> saveInitialLocation({
    required double latitude,
    required double longitude,
    int? caseId,
  }) async {
    try {
      final db = await database;
      final Map<String, dynamic> data = {
        'latitude': latitude,
        'longitude': longitude,
        'case_id': caseId,
      };
      final id = await db.insert(_tableName, data, conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint('[RouteExport] 初始位置已儲存 (lat, lng)，ID: $id, CaseID: $caseId');
    } catch (e) {
      debugPrint('[RouteExport] 儲存初始位置錯誤: $e');
    }
  }
  
  /// (Requirement 1) 清空特定案件 ID 的所有位置記錄
  static Future<void> clearLocationsByCaseId(int caseId) async {
    try {
      final db = await database;
      final count = await db.delete(_tableName, where: 'case_id = ?', whereArgs: [caseId]);
      debugPrint('[RouteExport] 已為 case_id $caseId 清空 $count 筆記錄');
    } catch (e) {
      debugPrint('[RouteExport] 清空案件 $caseId 的記錄時發生錯誤: $e');
    }
  }

  /// 匯出路線記錄並上傳到 S3
  static Future<bool> exportAndUploadRoute({
    required int caseId,
    required String userId,
  }) async {
    debugPrint('[RouteExport] 開始匯出案件 $caseId 的路線記錄...');
    
    try {
      // 1. 查詢該案件的所有位置資料
      final locations = await _getLocationsByCaseId(caseId);
      
      if (locations.isEmpty) {
        debugPrint('[RouteExport] 案件 $caseId 沒有位置資料可匯出，視為成功。');
        return true; // 沒有資料也算成功，直接結束
      }
      
      debugPrint('[RouteExport] 為案件 $caseId 找到 ${locations.length} 筆位置記錄');
      
      // 2. 創建臨時資料庫檔案
      final dbFile = await _createTempDatabase(locations, caseId, userId);
      
      // 3. 上傳到 S3
      final success = await _uploadToS3(dbFile, caseId, userId);
      
      // 4. 清理臨時檔案
      await _cleanupTempFile(dbFile);
      
      // 5. 如果上傳成功，清空主資料庫中該案件的記錄
      if (success) {
        await clearLocationsByCaseId(caseId);
        debugPrint('[RouteExport] 案件 $caseId 匯出成功並已清空本機記錄');
      } else {
        debugPrint('[RouteExport] 案件 $caseId S3 上傳失敗，將保留本機記錄');
      }
      
      return success;
      
    } catch (e) {
      debugPrint('[RouteExport] 匯出路線記錄失敗: $e');
      return false;
    }
  }
  
  /// 根據 caseId 查詢位置資料
  static Future<List<Map<String, dynamic>>> _getLocationsByCaseId(int caseId) async {
    final db = await database;
    try {
      return await db.query(
        _tableName,
        where: 'case_id = ?',
        whereArgs: [caseId],
        orderBy: 'created_at ASC',
      );
    } catch (e) {
      debugPrint('[RouteExport] 根據 Case ID 查詢位置時出錯: $e');
      return [];
    }
  }

  /// 創建臨時資料庫檔案
  static Future<File> _createTempDatabase(
    List<Map<String, dynamic>> locations,
    int caseId,
    String userId,
  ) async {
    final directory = await getTemporaryDirectory();
    final fileName = 'case_${caseId}_${userId}_${DateTime.now().millisecondsSinceEpoch}.db';
    final file = File(join(directory.path, fileName));
    
    final tempDb = await openDatabase(
      file.path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE route_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            case_id INTEGER,
            user_id TEXT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
    
    for (final location in locations) {
      await tempDb.insert('route_data', {
        'case_id': caseId,
        'user_id': userId,
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        'timestamp': location['created_at'], // 使用原始的創建時間
      });
    }
    
    await tempDb.close();
    debugPrint('[RouteExport] 臨時資料庫已創建: ${file.path}');
    
    return file;
  }
  
  /// 上傳檔案到 S3
  static Future<bool> _uploadToS3(File dbFile, int caseId, String userId) async {
    final s3Key = AWSConfig.generateRouteKey(caseId, userId);
    debugPrint('[RouteExport] 開始使用 Amplify 上傳檔案到 S3，Key: $s3Key');

    try {
      final uploadFileOperation = Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(dbFile.path),
        key: s3Key,
        onProgress: (progress) {
          debugPrint('[RouteExport] 上傳進度: ${(progress.fractionCompleted * 100).toStringAsFixed(2)}%');
        },
        options: const StorageUploadFileOptions(
          accessLevel: StorageAccessLevel.guest, // guest level 允許公開存取
          // Amplify guest level 檔案預設就是公開的，但需要正確的 S3 設定
        ),
      );
      
      final result = await uploadFileOperation.result;
      debugPrint('[RouteExport] Amplify 上傳成功: Key = ${result.uploadedItem.key}');
      return true;

    } on StorageException catch (e) {
      debugPrint('[RouteExport] Amplify 上傳失敗，錯誤: ${e.message}');
      debugPrint('[RouteExport] 詳細資訊: ${e.underlyingException}');
      return false;
    } catch (e) {
      debugPrint('[RouteExport] 發生未預期的上傳錯誤: $e');
      return false;
    }
  }
  
  /// 清理臨時檔案
  static Future<void> _cleanupTempFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        debugPrint('[RouteExport] 臨時檔案已清理');
      }
    } catch (e) {
      debugPrint('[RouteExport] 清理臨時檔案錯誤: $e');
    }
  }
} 