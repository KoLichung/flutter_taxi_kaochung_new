# Case Message API 文档

## 概述

Case Message API 提供派单者和司机之间针对某个 Case 进行对话的功能，支持文字和图片消息。

**Base URL**: `/api/dispatch/`

**认证方式**: Token Authentication

**请求头**:
```
Authorization: Token {your_token_here}
Content-Type: application/json
```

---

## API 端点列表

### 0. 系统消息列表（DispatchMessage）

获取当前用户的系统消息列表，同时返回 Case 消息的未读总数。

**端点**: `GET /api/dispatch/messages/`

**分页**: 每页 20 条

**请求参数**:
- `page` (可选): 页码，默认为 1
- `q` (可选): 搜索内容

**示例请求**:
```bash
GET /api/dispatch/messages/?page=1
Authorization: Token abc123...
```

**响应示例**:
```json
{
    "count": 150,
    "next": "http://example.com/api/dispatch/messages/?page=2",
    "previous": null,
    "case_message_unread_count": 8,
    "results": [
        {
            "id": 1,
            "content": "派單成功，正在尋找駕駛...",
            "sender": null,
            "recipient": 101,
            "sender_details": null,
            "recipient_details": {
                "id": 101,
                "name": "李派单",
                "phone": "0912345678",
                "nick_name": "小李"
            },
            "is_from_server": true,
            "created_at": "2025-01-10T14:30:00+08:00"
        }
    ]
}
```

**响应字段说明**:
- `count`: 总消息数
- `next`: 下一页 URL
- `previous`: 上一页 URL
- **`case_message_unread_count`**: 当前 dispatch 在所有 Case 中的未读消息总数（重要！）
- `results`: 系统消息列表

**说明**:
- `case_message_unread_count` 显示派单者在所有派出的 Case 中，收到的未读消息总数
- 可用于在 UI 上显示小红点或未读数字徽章

---

### 1. Case 聊天列表页面

获取当前派单者（dispatch）派出的所有 Case 列表，每个 Case 显示最新一条消息和未读数。

**重要**: 
- 只返回当前用户作为 **dispatch** 派出的 Case，不包括作为司机接单的 Case
- 返回所有派出的 Case，包括有消息和没有消息的 Case
- 派单者可以主动发讯给司机，不需要等司机先发消息

**端点**: `GET /api/dispatch/case-messages/`

**分页**: 固定每页 20 条

**请求参数**:
- `page` (可选): 页码，默认为 1

**示例请求**:
```bash
GET /api/dispatch/case-messages/?page=1
Authorization: Token abc123...
```

**响应示例**:
```json
{
    "count": 45,
    "next": "http://example.com/api/dispatch/case-messages/?page=2",
    "previous": null,
    "results": [
        {
            "id": 123,
            "case_number": "高雄車隊 ❤️20250110.001❤️",
            "case_state": "on_road",
            "driver_name": "王司机",
            "driver_nick_name": "老王",
            "dispatch_name": "李派单",
            "dispatch_nick_name": "小李",
            "latest_message": {
                "id": 456,
                "message_type": "text",
                "content": "已到达上车点",
                "image_url": null,
                "sender_id": 789,
                "sender_name": "王司机",
                "created_at": "2025-01-10T14:30:25.123456+08:00"
            },
            "unread_count": 3,
            "create_time": "2025-01-10T14:00:00+08:00"
        },
        {
            "id": 124,
            "case_number": "高雄車隊 ❤️20250110.002❤️",
            "case_state": "way_to_catch",
            "driver_name": "张司机",
            "driver_nick_name": "小张",
            "dispatch_name": "李派单",
            "dispatch_nick_name": "小李",
            "latest_message": {
                "id": 457,
                "message_type": "image",
                "content": "这是位置照片",
                "image_url": "https://your-bucket.s3.amazonaws.com/case_messages/124/...",
                "sender_id": 790,
                "sender_name": "张司机",
                "created_at": "2025-01-10T14:25:15.654321+08:00"
            },
            "unread_count": 0,
            "create_time": "2025-01-10T14:10:00+08:00"
        }
    ]
}
```

**响应字段说明**:
- `count`: 总共有多少个 Case（所有 dispatch 是当前用户的 Case，包括有消息和无消息的）
- `next`: 下一页的 URL（如果没有则为 null）
- `previous`: 上一页的 URL（如果没有则为 null）
- `results`: Case 列表数组（仅包含 dispatch 是当前用户的 Case）
  - `id`: Case ID
  - `case_number`: 单号
  - `case_state`: Case 状态
  - `driver_name`: 司机姓名
  - `driver_nick_name`: 司机昵称
  - `dispatch_name`: 派单者姓名
  - `dispatch_nick_name`: 派单者昵称
  - `latest_message`: 最新一条消息（**如果没有消息则为 null**）
    - `message_type`: 消息类型 (`text`, `image`, `system`)
    - `content`: 文字内容
    - `image_url`: 图片 URL（如果是图片消息）
    - `sender_id`: 发送者 ID
    - `sender_name`: 发送者姓名
    - `created_at`: 创建时间
  - `unread_count`: 未读消息数量（没有消息时为 0）
  - `create_time`: Case 创建时间

**排序规则**:
- 有消息的 Case：按最后消息时间降序（newest first）
- 无消息的 Case：按 Case 创建时间降序
- 整体效果：有新消息的排最前面，然后是旧消息的，最后是没有消息但是新建的 Case

---

### 2. 获取某个 Case 的消息列表

获取某个 Case 的所有消息，按时间从新到旧排序。

**端点**: `GET /api/dispatch/cases/{case_id}/messages/`

**分页**: 固定每页 30 条

**路径参数**:
- `case_id`: Case ID

**请求参数**:
- `page` (可选): 页码，默认为 1

**示例请求**:
```bash
GET /api/dispatch/cases/123/messages/?page=1
Authorization: Token abc123...
```

**响应示例**:
```json
{
    "count": 85,
    "next": "http://example.com/api/dispatch/cases/123/messages/?page=2",
    "previous": null,
    "results": [
        {
            "id": 456,
            "case": 123,
            "sender": 789,
            "sender_name": "王司机",
            "sender_nick_name": "老王",
            "message_type": "text",
            "content": "已到达上车点",
            "image_url": null,
            "image_key": null,
            "is_read": false,
            "read_at": null,
            "created_at": "2025-01-10T14:30:25.123456+08:00"
        },
        {
            "id": 455,
            "case": 123,
            "sender": 101,
            "sender_name": "李派单",
            "sender_nick_name": "小李",
            "message_type": "text",
            "content": "请问客人到了吗？",
            "image_url": null,
            "image_key": null,
            "is_read": true,
            "read_at": "2025-01-10T14:30:00+08:00",
            "created_at": "2025-01-10T14:29:45.654321+08:00"
        },
        {
            "id": 454,
            "case": 123,
            "sender": 789,
            "sender_name": "王司机",
            "sender_nick_name": "老王",
            "message_type": "image",
            "content": "这是位置照片",
            "image_url": "https://your-bucket.s3.amazonaws.com/case_messages/123/789/20250110_142500_a1b2c3d4.jpg",
            "image_key": "case_messages/123/789/20250110_142500_a1b2c3d4.jpg",
            "is_read": true,
            "read_at": "2025-01-10T14:25:30+08:00",
            "created_at": "2025-01-10T14:25:15.111222+08:00"
        }
    ]
}
```

**响应字段说明**:
- `count`: 总消息数
- `next`: 下一页 URL
- `previous`: 上一页 URL
- `results`: 消息列表
  - `id`: 消息 ID
  - `case`: Case ID
  - `sender`: 发送者 User ID
  - `sender_name`: 发送者姓名
  - `sender_nick_name`: 发送者昵称
  - `message_type`: 消息类型 (`text`, `image`, `system`)
  - `content`: 文字内容（可选）
  - `image_url`: 图片完整 URL（图片消息时有值）
  - `image_key`: S3 图片 key（图片消息时有值）
  - `is_read`: 是否已读
  - `read_at`: 已读时间
  - `created_at`: 创建时间

---

### 3. 发送文字消息

创建一条新的文字消息。

**端点**: `POST /api/dispatch/cases/{case_id}/messages/`

**路径参数**:
- `case_id`: Case ID（会自动关联到消息的 case 字段）

**请求体**:
```json
{
    "message_type": "text",
    "content": "请问客人在哪里？"
}
```

**请求字段说明**:
- `message_type`: 必填，固定为 `"text"`
- `content`: 必填，消息内容

**自动设置的字段**（不需要在请求体中提供）:
- `case`: 自动从 URL 路径参数 `case_id` 获取
- `sender`: 自动设置为当前认证用户
- `created_at`: 自动设置为当前时间

**响应示例**:
```json
{
    "id": 458,
    "case": 123,
    "sender": 101,
    "sender_name": "李派单",
    "sender_nick_name": "小李",
    "message_type": "text",
    "content": "请问客人在哪里？",
    "image_url": null,
    "image_key": null,
    "is_read": false,
    "read_at": null,
    "created_at": "2025-01-10T14:35:00.123456+08:00"
}
```

---

### 4. 上传图片（使用 AWS Amplify SDK）

**重要**: 前端使用 AWS Amplify SDK 直接上传图片到 S3，不需要调用后端 API 获取上传 URL。

**Flutter 端实现步骤**:

1. **配置 AWS Amplify**:
```dart
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';

// 在 main.dart 中配置
await Amplify.addPlugins([
  AmplifyStorageS3()
]);
await Amplify.configure(amplifyconfig);
```

2. **上传图片**:
```dart
Future<Map<String, String>> uploadImage(File imageFile, int caseId, int userId) async {
  // 生成 S3 key
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final filename = path.basename(imageFile.path);
  final ext = path.extension(filename).toLowerCase();
  final s3Key = 'case_messages/$caseId/$userId/${timestamp}_$ext';
  
  try {
    // 使用 Amplify Storage 上传
    final result = await Amplify.Storage.uploadFile(
      localFile: AWSFile.fromPath(imageFile.path),
      key: s3Key,
      options: StorageUploadFileOptions(
        accessLevel: StorageAccessLevel.guest,
        metadata: {
          'caseId': caseId.toString(),
          'userId': userId.toString(),
        }
      )
    );
    
    // 获取图片 URL
    final urlResult = await Amplify.Storage.getUrl(key: s3Key);
    
    return {
      'image_key': s3Key,
      'image_url': urlResult.url.toString(),
    };
  } catch (e) {
    print('Upload error: $e');
    throw e;
  }
}
```

3. **创建图片消息**（见下一节）

**S3 Key 格式建议**:
```
case_messages/{case_id}/{user_id}/{timestamp}_{random}.{ext}
```

示例：`case_messages/123/456/1729415625000_photo.jpg`

---

### 5. 发送图片消息

使用 AWS Amplify SDK 上传图片成功后，创建一条图片消息记录。

**端点**: `POST /api/dispatch/cases/{case_id}/messages/`

**路径参数**:
- `case_id`: Case ID（会自动关联到消息的 case 字段）

**请求体**:
```json
{
    "message_type": "image",
    "image_key": "case_messages/123/456/1729415625000_photo.jpg",
    "image_url": "https://your-bucket-name.s3.ap-northeast-1.amazonaws.com/case_messages/123/456/1729415625000_photo.jpg",
    "content": "这是位置照片"
}
```

**请求字段说明**:
- `message_type`: 必填，固定为 `"image"`
- `image_key`: 必填，从 AWS Amplify 上传后获得的 S3 key
- `image_url`: 必填，从 AWS Amplify 上传后获得的图片 URL
- `content`: 可选，图片说明文字

**自动设置的字段**（不需要在请求体中提供）:
- `case`: 自动从 URL 路径参数 `case_id` 获取
- `sender`: 自动设置为当前认证用户
- `created_at`: 自动设置为当前时间

**完整 Flutter 示例**:
```dart
// 1. 上传图片到 S3
final uploadResult = await uploadImage(imageFile, caseId, userId);

// 2. 创建图片消息
final response = await http.post(
  Uri.parse('$baseUrl/api/dispatch/cases/$caseId/messages/'),
  headers: {
    'Authorization': 'Token $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'message_type': 'image',
    'image_key': uploadResult['image_key'],
    'image_url': uploadResult['image_url'],
    'content': '位置照片',
  }),
);
```

**响应示例**:
```json
{
    "id": 459,
    "case": 123,
    "sender": 789,
    "sender_name": "王司机",
    "sender_nick_name": "老王",
    "message_type": "image",
    "content": "这是位置照片",
    "image_url": "https://your-bucket.s3.amazonaws.com/case_messages/123/456/20250110_143025_a1b2c3d4.jpg",
    "image_key": "case_messages/123/456/20250110_143025_a1b2c3d4.jpg",
    "is_read": false,
    "read_at": null,
    "created_at": "2025-01-10T14:30:30.123456+08:00"
}
```

---

### 6. 标记消息为已读

打开某个 Case 的聊天页面时，调用此 API 标记所有消息为已读。

**端点**: `POST /api/dispatch/cases/{case_id}/messages/mark-read/`

**路径参数**:
- `case_id`: Case ID

**请求体**: 无需请求体

**响应示例**:
```json
{
    "message": "Messages marked as read",
    "updated_count": 3
}
```

**响应字段说明**:
- `message`: 操作结果消息
- `updated_count`: 标记为已读的消息数量

---

### 7. 获取未读消息数量

获取某个 Case 的未读消息数量。

**端点**: `GET /api/dispatch/cases/{case_id}/messages/unread-count/`

**路径参数**:
- `case_id`: Case ID

**示例请求**:
```bash
GET /api/dispatch/cases/123/messages/unread-count/
Authorization: Token abc123...
```

**响应示例**:
```json
{
    "case_id": 123,
    "unread_count": 3
}
```

**响应字段说明**:
- `case_id`: Case ID
- `unread_count`: 未读消息数量

---

## 错误响应

所有 API 在出错时会返回适当的 HTTP 状态码和错误信息。

**示例错误响应**:
```json
{
    "error": "filename is required"
}
```

**常见 HTTP 状态码**:
- `200 OK`: 请求成功
- `201 Created`: 创建成功
- `400 Bad Request`: 请求参数错误
- `401 Unauthorized`: 未认证
- `403 Forbidden`: 权限不足
- `404 Not Found`: 资源不存在
- `500 Internal Server Error`: 服务器错误

---

## 数据模型

### CaseMessage

| 字段 | 类型 | 说明 |
|------|------|------|
| id | Integer | 消息 ID |
| case | Integer (FK) | 关联的 Case ID |
| sender | Integer (FK) | 发送者 User ID |
| message_type | String | 消息类型: `text`, `image`, `system` |
| content | Text | 文字内容（可选） |
| image_url | String | 图片 URL（可选） |
| image_key | String | S3 图片 key（可选） |
| is_read | Boolean | 是否已读 |
| read_at | DateTime | 已读时间（可选） |
| created_at | DateTime | 创建时间 |
| updated_at | DateTime | 更新时间 |

---

## 使用场景示例

### 场景 1: 发送文字消息

```javascript
// 1. 发送文字消息
fetch('/api/dispatch/cases/123/messages/', {
    method: 'POST',
    headers: {
        'Authorization': 'Token abc123...',
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        message_type: 'text',
        content: '请问客人在哪里？'
    })
});
```

### 场景 2: 发送图片消息（Flutter + AWS Amplify）

```dart
// 1. 使用 AWS Amplify 上传图片到 S3
Future<void> sendImageMessage(File imageFile, int caseId) async {
  try {
    // 生成 S3 key
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = path.extension(imageFile.path).toLowerCase();
    final s3Key = 'case_messages/$caseId/$userId/$timestamp$ext';
    
    // 上传到 S3
    final uploadResult = await Amplify.Storage.uploadFile(
      localFile: AWSFile.fromPath(imageFile.path),
      key: s3Key,
    );
    
    // 获取图片 URL
    final urlResult = await Amplify.Storage.getUrl(key: s3Key);
    final imageUrl = urlResult.url.toString();
    
    // 2. 创建图片消息记录
    final response = await http.post(
      Uri.parse('$baseUrl/api/dispatch/cases/$caseId/messages/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message_type': 'image',
        'image_key': s3Key,
        'image_url': imageUrl,
        'content': '位置照片',
      }),
    );
    
    if (response.statusCode == 201) {
      print('图片消息发送成功');
    }
  } catch (e) {
    print('发送图片失败: $e');
  }
}
```

### 场景 3: 打开聊天页面

```javascript
// 1. 获取消息列表
const response = await fetch('/api/dispatch/cases/123/messages/?page=1', {
    headers: {
        'Authorization': 'Token abc123...'
    }
});
const data = await response.json();

// 2. 标记消息为已读
await fetch('/api/dispatch/cases/123/messages/mark-read/', {
    method: 'POST',
    headers: {
        'Authorization': 'Token abc123...'
    }
});
```

### 场景 4: 显示聊天列表（带未读数）

```javascript
// 获取当前 dispatch 派出的所有有消息的 Case 列表
const response = await fetch('/api/dispatch/case-messages/?page=1', {
    headers: {
        'Authorization': 'Token abc123...'
    }
});
const data = await response.json();

// data.results 包含:
// - 每个 Case 的基本信息
// - 最新一条消息
// - 每个 Case 的未读消息数量

// 注意：只返回 dispatch 是当前用户的 Case
```

### 场景 5: 获取 Case 消息总未读数（用于显示徽章）

```javascript
// 获取系统消息列表时，同时获取 Case 消息的总未读数
const response = await fetch('/api/dispatch/messages/?page=1', {
    headers: {
        'Authorization': 'Token abc123...'
    }
});
const data = await response.json();

// 显示在 UI 上
console.log(`系统消息: ${data.count} 条`);
console.log(`Case 消息未读: ${data.case_message_unread_count} 条`);

// 用于显示小红点或数字徽章
if (data.case_message_unread_count > 0) {
    // 显示红点或数字
    showBadge(data.case_message_unread_count);
}

// data 结构:
// {
//     "count": 150,
//     "next": "...",
//     "previous": null,
//     "case_message_unread_count": 8,  // ← 重要！所有 Case 的未读消息总数
//     "results": [...]
// }
```

---

## 注意事项

1. **认证**: 所有 API 都需要 Token 认证
2. **分页**: 
   - 聊天列表固定每页 20 条
   - 消息列表固定每页 30 条
3. **排序**: 
   - 聊天列表按最新消息时间排序（从新到旧）
   - 消息列表按创建时间排序（从新到旧）
4. **图片上传**: 
   - **前端使用 AWS Amplify SDK 直接上传到 S3**
   - 后端不处理图片上传，只记录消息
   - 上传流程：Flutter Amplify 上传 → 获取 URL 和 key → 调用后端创建消息
   - `upload-url` 端点已废弃（返回 410 Gone）
5. **权限**: 
   - Case 消息列表: 只显示 dispatch 是当前用户的 Case
   - Case 消息详情: 只有 Case 的 dispatch 或 driver 可以查看和发送消息
   - 自动标记非自己发送的消息为已读
6. **图片限制**: 
   - 建议图片大小限制在 5MB 以内
   - 支持的格式: JPEG, PNG, GIF
   - S3 key 格式: `case_messages/{case_id}/{user_id}/{timestamp}.{ext}`

---

## 司机端 API 集成

### 案件状态查询 API（含未读消息数）

司机端调用案件状态查询 API 时，也会返回未读案件消息数。

**端点**: `GET /api/case_state_with_next_case?case_id={case_id}`

**所属模块**: `taxiApi`（司机端 API）

**请求参数**:
- `case_id`: 当前 Case ID

**响应示例**:
```json
{
    "current_case_state": "on_road",
    "query_next_case": null,
    "confirmed_next_case": null,
    "case_message_unread_count": 5
}
```

**响应字段说明**:
- `current_case_state`: 当前 Case 的状态
- `query_next_case`: 待确认的下一个 Case（如果有）
- `confirmed_next_case`: 已确认的下一个 Case（目前功能已关闭）
- **`case_message_unread_count`**: 司机收到的未读案件消息总数

**未读消息计算逻辑**:
- 统计司机作为接单司机（`case.user`）的所有 Case
- 排除司机自己发送的消息
- 只计算未读消息（`is_read=False`）

**用途**:
- 司机 app 在查询案件状态时，同时获取未读消息数
- 可用于在司机端 UI 显示消息通知徽章
- 与派单端的 `case_message_unread_count` 类似，但针对司机端

---

## 更新日志

- **2025-10-21 v1.4**: 司机端集成
  - **新增**: 司机端 API `/api/case_state_with_next_case` 现在也返回 `case_message_unread_count`
  - **司机端**: 统计司机作为接单司机的所有 Case 中的未读消息数
  - **用途**: 司机端 app 可以在查询案件状态时同时获取未读消息数
  - **文档**: 添加司机端 API 集成说明

- **2025-10-21 v1.3**: 图片上传架构调整
  - **重大变更**: 图片上传改为前端直接使用 AWS Amplify SDK
  - **废弃**: `upload-url` 端点已废弃（返回 410 Gone）
  - **简化**: 后端不再处理图片上传，只记录消息
  - **文档**: 添加完整的 Flutter + Amplify 示例代码

- **2025-10-20 v1.2**: 重要更新
  - **变更**: Case 消息列表现在返回所有派出的 Case（包括无消息的 Case）
  - **优化**: 派单者可以主动发讯给司机，不需要等司机先发消息
  - **排序**: 有消息的按最后消息时间排序，无消息的按 Case 创建时间排序
  - `latest_message` 字段在没有消息时为 null

- **2025-10-10 v1.1**: 重要更新
  - **新增**: DispatchMessage API 返回 `case_message_unread_count` 字段
  - **变更**: Case 消息列表只返回 dispatch 是当前用户的 Case
  - 可用于在 UI 上显示 Case 消息的未读数字徽章
  
- **2025-10-10 v1.0**: 初版 API 文档
  - 支持文字和图片消息
  - 支持消息分页查询
  - 支持未读消息标记和计数
  - 支持聊天列表显示

