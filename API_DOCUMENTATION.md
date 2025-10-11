# Case Message API 文档

## 概述

Case Message API 提供派单者和司机之间针对某个 Case 进行对话的功能，支持文字和图片消息。

**Base URL**: `/api/dispatcher/`

**认证方式**: Token Authentication

**请求头**:
```
Authorization: Token {your_token_here}
Content-Type: application/json
```

---

## API 端点列表

### 1. 聊天列表页面

获取当前用户所有有消息的 Case 列表，每个 Case 显示最新一条消息和未读数。

**端点**: `GET /api/dispatcher/case-messages/`

**分页**: 固定每页 20 条

**请求参数**:
- `page` (可选): 页码，默认为 1

**示例请求**:
```bash
GET /api/dispatcher/case-messages/?page=1
Authorization: Token abc123...
```

**响应示例**:
```json
{
    "count": 45,
    "next": "http://example.com/api/dispatcher/case-messages/?page=2",
    "previous": null,
    "results": [
        {
            "id": 123,
            "case_number": "高雄車隊 ❤️20250110.001❤️",
            "case_state": "on_road",
            "driver_name": "王司机",
            "driver_nick_name": "老王",
            "dispatcher_name": "李派单",
            "dispatcher_nick_name": "小李",
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
            "dispatcher_name": "李派单",
            "dispatcher_nick_name": "小李",
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
- `count`: 总共有多少个有消息的 Case
- `next`: 下一页的 URL（如果没有则为 null）
- `previous`: 上一页的 URL（如果没有则为 null）
- `results`: Case 列表数组
  - `id`: Case ID
  - `case_number`: 单号
  - `case_state`: Case 状态
  - `driver_name`: 司机姓名
  - `driver_nick_name`: 司机昵称
  - `dispatcher_name`: 派单者姓名
  - `dispatcher_nick_name`: 派单者昵称
  - `latest_message`: 最新一条消息
    - `message_type`: 消息类型 (`text`, `image`, `system`)
    - `content`: 文字内容
    - `image_url`: 图片 URL（如果是图片消息）
    - `sender_id`: 发送者 ID
    - `sender_name`: 发送者姓名
    - `created_at`: 创建时间
  - `unread_count`: 未读消息数量
  - `create_time`: Case 创建时间

---

### 2. 获取某个 Case 的消息列表

获取某个 Case 的所有消息，按时间从新到旧排序。

**端点**: `GET /api/dispatcher/cases/{case_id}/messages/`

**分页**: 固定每页 30 条

**路径参数**:
- `case_id`: Case ID

**请求参数**:
- `page` (可选): 页码，默认为 1

**示例请求**:
```bash
GET /api/dispatcher/cases/123/messages/?page=1
Authorization: Token abc123...
```

**响应示例**:
```json
{
    "count": 85,
    "next": "http://example.com/api/dispatcher/cases/123/messages/?page=2",
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

**端点**: `POST /api/dispatcher/cases/{case_id}/messages/`

**路径参数**:
- `case_id`: Case ID

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

### 4. 获取图片上传 URL

在上传图片之前，先调用此 API 获取 S3 上传 URL 和 image_key。

**端点**: `POST /api/dispatcher/cases/{case_id}/messages/upload-url/`

**路径参数**:
- `case_id`: Case ID

**请求体**:
```json
{
    "filename": "location.jpg",
    "content_type": "image/jpeg"
}
```

**请求字段说明**:
- `filename`: 必填，原始文件名
- `content_type`: 可选，MIME 类型，默认为 `"image/jpeg"`

**响应示例**:
```json
{
    "upload_url": "https://your-bucket.s3.ap-northeast-1.amazonaws.com/case_messages/123/456/20250110_143025_a1b2c3d4.jpg",
    "image_key": "case_messages/123/456/20250110_143025_a1b2c3d4.jpg",
    "image_url": "https://your-bucket.s3.ap-northeast-1.amazonaws.com/case_messages/123/456/20250110_143025_a1b2c3d4.jpg",
    "expires_in": 300,
    "note": "S3 configuration pending - URL is placeholder"
}
```

**响应字段说明**:
- `upload_url`: S3 预签名上传 URL（用于 PUT 请求上传文件）
- `image_key`: S3 文件 key（创建消息时需要）
- `image_url`: 访问图片的 URL（创建消息时需要）
- `expires_in`: URL 有效期（秒）
- `note`: 提示信息（实际使用时此字段会移除）

**使用流程**:
1. 调用此 API 获取上传 URL
2. 使用 PUT 方法将图片上传到 `upload_url`
3. 上传成功后，调用创建图片消息 API

---

### 5. 发送图片消息

图片上传成功后，创建一条图片消息记录。

**端点**: `POST /api/dispatcher/cases/{case_id}/messages/`

**路径参数**:
- `case_id`: Case ID

**请求体**:
```json
{
    "message_type": "image",
    "image_key": "case_messages/123/456/20250110_143025_a1b2c3d4.jpg",
    "image_url": "https://your-bucket.s3.amazonaws.com/case_messages/123/456/20250110_143025_a1b2c3d4.jpg",
    "content": "这是位置照片"
}
```

**请求字段说明**:
- `message_type`: 必填，固定为 `"image"`
- `image_key`: 必填，从 upload-url API 获取的 key
- `image_url`: 必填，从 upload-url API 获取的 URL
- `content`: 可选，图片说明文字

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

**端点**: `POST /api/dispatcher/cases/{case_id}/messages/mark-read/`

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

**端点**: `GET /api/dispatcher/cases/{case_id}/messages/unread-count/`

**路径参数**:
- `case_id`: Case ID

**示例请求**:
```bash
GET /api/dispatcher/cases/123/messages/unread-count/
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
fetch('/api/dispatcher/cases/123/messages/', {
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

### 场景 2: 发送图片消息

```javascript
// 1. 获取上传 URL
const uploadResponse = await fetch('/api/dispatcher/cases/123/messages/upload-url/', {
    method: 'POST',
    headers: {
        'Authorization': 'Token abc123...',
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        filename: 'location.jpg',
        content_type: 'image/jpeg'
    })
});
const { upload_url, image_key, image_url } = await uploadResponse.json();

// 2. 上传图片到 S3
await fetch(upload_url, {
    method: 'PUT',
    headers: {
        'Content-Type': 'image/jpeg'
    },
    body: imageFile  // File or Blob 对象
});

// 3. 创建图片消息记录
await fetch('/api/dispatcher/cases/123/messages/', {
    method: 'POST',
    headers: {
        'Authorization': 'Token abc123...',
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({
        message_type: 'image',
        image_key: image_key,
        image_url: image_url,
        content: '这是位置照片'
    })
});
```

### 场景 3: 打开聊天页面

```javascript
// 1. 获取消息列表
const response = await fetch('/api/dispatcher/cases/123/messages/?page=1', {
    headers: {
        'Authorization': 'Token abc123...'
    }
});
const data = await response.json();

// 2. 标记消息为已读
await fetch('/api/dispatcher/cases/123/messages/mark-read/', {
    method: 'POST',
    headers: {
        'Authorization': 'Token abc123...'
    }
});
```

### 场景 4: 显示聊天列表（带未读数）

```javascript
// 获取所有有消息的 Case 列表
const response = await fetch('/api/dispatcher/case-messages/?page=1', {
    headers: {
        'Authorization': 'Token abc123...'
    }
});
const data = await response.json();

// data.results 包含:
// - 每个 Case 的基本信息
// - 最新一条消息
// - 未读消息数量
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
4. **S3 配置**: 
   - 目前 `upload-url` API 返回的是占位符 URL
   - 实际使用时需要配置真实的 AWS S3 credentials
   - 图片上传流程：获取 URL → 上传到 S3 → 创建消息记录
5. **权限**: 
   - 只有 Case 的 dispatcher 或 driver 可以查看和发送消息
   - 自动标记非自己发送的消息为已读
6. **图片**: 
   - 建议图片大小限制在 5MB 以内
   - 支持的格式: JPEG, PNG, GIF

---

## 更新日志

- **2025-01-10**: 初版 API 文档
  - 支持文字和图片消息
  - 支持消息分页查询
  - 支持未读消息标记和计数
  - 支持聊天列表显示

