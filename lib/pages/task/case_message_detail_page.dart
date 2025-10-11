import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../color.dart';
import '../../models/case.dart';
import '../../models/case_message.dart';
import '../../config/serverApi.dart';
import '../../notifier_models/user_model.dart';

class CaseMessageDetailPage extends StatefulWidget {
  final Case theCase;
  final int unreadCount;

  const CaseMessageDetailPage({
    Key? key,
    required this.theCase,
    required this.unreadCount,
  }) : super(key: key);

  @override
  _CaseMessageDetailPageState createState() => _CaseMessageDetailPageState();
}

class _CaseMessageDetailPageState extends State<CaseMessageDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  List<CaseMessage> messages = [];
  bool isLoading = false;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _loadFakeMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 載入假數據
  void _loadFakeMessages() {
    setState(() {
      isLoading = true;
    });

    // 模擬網絡延遲
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        messages = _generateFakeMessages();
        isLoading = false;
      });
      _scrollToBottom();
    });
  }

  // 生成假消息數據
  List<CaseMessage> _generateFakeMessages() {
    final now = DateTime.now();
    return [
      CaseMessage(
        id: 1,
        caseId: widget.theCase.id,
        sender: 101,
        senderName: widget.theCase.dispatcherNickName ?? '派單員',
        senderNickName: widget.theCase.dispatcherNickName ?? '小李',
        messageType: 'text',
        content: '您好，請問現在到哪裡了？',
        isRead: true,
        readAt: now.subtract(const Duration(minutes: 5)).toIso8601String(),
        createdAt: now.subtract(const Duration(minutes: 10)).toIso8601String(),
      ),
      CaseMessage(
        id: 2,
        caseId: widget.theCase.id,
        sender: 789, // 假設當前用戶ID是789
        senderName: '王司機',
        senderNickName: '老王',
        messageType: 'text',
        content: '我剛剛出發，大約10分鐘會到',
        isRead: true,
        readAt: now.subtract(const Duration(minutes: 4)).toIso8601String(),
        createdAt: now.subtract(const Duration(minutes: 8)).toIso8601String(),
      ),
      CaseMessage(
        id: 3,
        caseId: widget.theCase.id,
        sender: 101,
        senderName: widget.theCase.dispatcherNickName ?? '派單員',
        senderNickName: widget.theCase.dispatcherNickName ?? '小李',
        messageType: 'text',
        content: '好的，客人說他在路口等',
        isRead: true,
        readAt: now.subtract(const Duration(minutes: 3)).toIso8601String(),
        createdAt: now.subtract(const Duration(minutes: 6)).toIso8601String(),
      ),
      CaseMessage(
        id: 4,
        caseId: widget.theCase.id,
        sender: 789,
        senderName: '王司機',
        senderNickName: '老王',
        messageType: 'image',
        content: '這是位置照片',
        imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4',
        isRead: true,
        readAt: now.subtract(const Duration(minutes: 3, seconds: 30)).toIso8601String(),
        createdAt: now.subtract(const Duration(minutes: 5)).toIso8601String(),
      ),
      CaseMessage(
        id: 5,
        caseId: widget.theCase.id,
        sender: 101,
        senderName: widget.theCase.dispatcherNickName ?? '派單員',
        senderNickName: widget.theCase.dispatcherNickName ?? '小李',
        messageType: 'text',
        content: '請問客人上車了嗎？',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 2)).toIso8601String(),
      ),
      CaseMessage(
        id: 6,
        caseId: widget.theCase.id,
        sender: 101,
        senderName: widget.theCase.dispatcherNickName ?? '派單員',
        senderNickName: widget.theCase.dispatcherNickName ?? '小李',
        messageType: 'text',
        content: '如果客人還沒出現，請通知我一下',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 1)).toIso8601String(),
      ),
    ];
  }

  // 發送消息
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      isSending = true;
    });

    final newMessage = CaseMessage(
      id: messages.length + 1,
      caseId: widget.theCase.id,
      sender: 789, // 假設當前用戶ID是789
      senderName: '王司機',
      senderNickName: '老王',
      messageType: 'text',
      content: _messageController.text.trim(),
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    // 模擬網絡延遲
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        messages.add(newMessage);
        _messageController.clear();
        isSending = false;
      });
      _scrollToBottom();
      
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('訊息已發送')));
    });
  }

  // 滾動到底部
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 判斷是否為自己發送的消息
  bool _isMyMessage(CaseMessage message) {
    // 假設當前用戶ID是789（司機）
    return message.sender == 789;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('案件對話'),
        backgroundColor: AppColor.primary,
      ),
      body: Column(
        children: [
          // 任務信息卡片
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColor.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '上車地: ${widget.theCase.onAddress}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.theCase.offAddress != null && widget.theCase.offAddress!.isNotEmpty)
                        Text(
                          '下車地: ${widget.theCase.offAddress}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 消息列表
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          '還沒有消息\n開始與派單員對話吧',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMyMsg = _isMyMessage(message);
                          
                          return _buildMessageBubble(message, isMyMsg);
                        },
                      ),
          ),
          
          // 輸入框
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // 圖片按鈕
                  IconButton(
                    icon: const Icon(Icons.image, color: Colors.grey),
                    onPressed: _pickAndSendImage,
                  ),
                  
                  // 文字輸入框
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '輸入訊息...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // 發送按鈕
                  CircleAvatar(
                    backgroundColor: isSending ? Colors.grey : AppColor.primary,
                    child: IconButton(
                      icon: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(CaseMessage message, bool isMyMessage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 消息內容
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 發送者名稱
                if (!isMyMessage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      message.senderNickName ?? message.senderName ?? '未知',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                
                // 消息氣泡
                GestureDetector(
                  onTap: message.messageType == 'image' && message.imageUrl != null
                      ? () => _showImageViewer(context, message.imageUrl!)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMyMessage ? AppColor.primary : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMyMessage ? 18 : 4),
                        bottomRight: Radius.circular(isMyMessage ? 4 : 18),
                      ),
                    ),
                    child: message.messageType == 'image'
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message.imageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: message.imageUrl!.startsWith('http')
                                      ? Image.network(
                                          message.imageUrl!,
                                          width: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 200,
                                              height: 150,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.broken_image),
                                            );
                                          },
                                        )
                                      : Image.file(
                                          File(message.imageUrl!),
                                          width: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 200,
                                              height: 150,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.broken_image),
                                            );
                                          },
                                        ),
                                ),
                              if (message.content != null && message.content!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    message.content!,
                                    style: TextStyle(
                                      color: isMyMessage ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Text(
                            message.content ?? '',
                            style: TextStyle(
                              color: isMyMessage ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
                
                // 時間和已讀狀態
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt ?? ''),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      if (isMyMessage) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead == true ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead == true ? Colors.blue : Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return '剛剛';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} 分鐘前';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} 小時前';
      } else {
        return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  // 選擇拍照或從相簿選擇
  Future<void> _pickAndSendImage() async {
    // 顯示選擇對話框
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('選擇圖片來源'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColor.primary),
                title: const Text('拍照'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColor.primary),
                title: const Text('從相簿選擇'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        isSending = true;
      });

      // 調用圖片上傳流程（使用假數據）
      await _uploadImageAndSendMessage(image);
      
    } catch (e) {
      print('選擇圖片錯誤: $e');
      setState(() {
        isSending = false;
      });
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('選擇圖片失敗')));
    }
  }

  // 圖片上傳流程（使用假數據模擬）
  Future<void> _uploadImageAndSendMessage(XFile imageFile) async {
    try {
      // 步驟1: 向服務器請求上傳 URL 和 key
      final uploadInfo = await _getUploadUrl(imageFile.name);
      if (uploadInfo == null) {
        throw Exception('獲取上傳URL失敗');
      }
      
      // 步驟2: 上傳圖片到 S3
      final uploadSuccess = await _uploadToS3(
        uploadInfo['upload_url']!,
        imageFile,
      );
      
      if (!uploadSuccess) {
        throw Exception('上傳到S3失敗');
      }
      
      // 步驟3: 告知服務器圖片已上傳，創建消息記錄
      final messageCreated = await _createImageMessage(
        uploadInfo['image_key']!,
        uploadInfo['image_url']!,
        '', // 可選的圖片說明
      );
      
      if (!messageCreated) {
        throw Exception('創建消息記錄失敗');
      }
      
      // 暫時使用本地路徑顯示圖片（因為S3是假的）
      final newMessage = CaseMessage(
        id: messages.length + 1,
        caseId: widget.theCase.id,
        sender: 789, // 假設當前用戶ID是789
        senderName: '王司機',
        senderNickName: '老王',
        messageType: 'image',
        content: '',
        imageUrl: imageFile.path, // 使用本地路徑
        imageKey: uploadInfo['image_key'],
        isRead: false,
        createdAt: DateTime.now().toIso8601String(),
      );

      setState(() {
        messages.add(newMessage);
        isSending = false;
      });
      
      _scrollToBottom();
      
      print('[模擬] 圖片消息發送成功');
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('圖片已發送')));
        
    } catch (e) {
      print('上傳圖片錯誤: $e');
      setState(() {
        isSending = false;
      });
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('圖片上傳失敗')));
    }
  }

  // API: 獲取上傳 URL（使用假數據）
  Future<Map<String, String>?> _getUploadUrl(String filename) async {
    try {
      print('[API - 假數據] 步驟1: 請求上傳 URL...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      // TODO: 實際 API 調用
      // final userModel = context.read<UserModel>();
      // final path = ServerApi.PATH_CASE_MESSAGE_UPLOAD_URL.replaceAll('{case_id}', widget.theCase.id.toString());
      // final response = await http.post(
      //   ServerApi.standard(path: path),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Token ${userModel.token}',
      //   },
      //   body: jsonEncode({
      //     'filename': filename,
      //     'content_type': 'image/jpeg',
      //   }),
      // );
      // 
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(utf8.decode(response.body.runes.toList()));
      //   return {
      //     'upload_url': data['upload_url'],
      //     'image_key': data['image_key'],
      //     'image_url': data['image_url'],
      //   };
      // }
      
      // 假數據返回
      final fakeData = {
        'upload_url': 'https://fake-bucket.s3.amazonaws.com/case_messages/${widget.theCase.id}/789/fake_image.jpg',
        'image_key': 'case_messages/${widget.theCase.id}/789/fake_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        'image_url': 'https://fake-bucket.s3.amazonaws.com/case_messages/${widget.theCase.id}/789/fake_image.jpg',
      };
      
      print('[API - 假數據] 獲取上傳URL成功: ${fakeData['upload_url']}');
      return fakeData;
      
    } catch (e) {
      print('[API] 獲取上傳URL錯誤: $e');
      return null;
    }
  }

  // API: 上傳圖片到 S3（使用假數據）
  Future<bool> _uploadToS3(String uploadUrl, XFile imageFile) async {
    try {
      print('[API - 假數據] 步驟2: 上傳圖片到 S3...');
      await Future.delayed(const Duration(seconds: 1));
      
      // TODO: 實際 API 調用
      // final bytes = await imageFile.readAsBytes();
      // final response = await http.put(
      //   Uri.parse(uploadUrl),
      //   headers: {
      //     'Content-Type': 'image/jpeg',
      //   },
      //   body: bytes,
      // );
      // 
      // if (response.statusCode == 200) {
      //   print('[API] 上傳到 S3 成功');
      //   return true;
      // }
      
      // 假數據：模擬上傳成功
      print('[API - 假數據] 上傳到 S3 成功');
      return true;
      
    } catch (e) {
      print('[API] 上傳到S3錯誤: $e');
      return false;
    }
  }

  // API: 創建圖片消息記錄（使用假數據）
  Future<bool> _createImageMessage(String imageKey, String imageUrl, String content) async {
    try {
      print('[API - 假數據] 步驟3: 創建圖片消息記錄...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      // TODO: 實際 API 調用
      // final userModel = context.read<UserModel>();
      // final path = ServerApi.PATH_CASE_MESSAGE_CREATE.replaceAll('{case_id}', widget.theCase.id.toString());
      // final response = await http.post(
      //   ServerApi.standard(path: path),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Token ${userModel.token}',
      //   },
      //   body: jsonEncode({
      //     'message_type': 'image',
      //     'image_key': imageKey,
      //     'image_url': imageUrl,
      //     'content': content,
      //   }),
      // );
      // 
      // if (response.statusCode == 201) {
      //   print('[API] 創建圖片消息成功');
      //   return true;
      // }
      
      // 假數據：模擬創建成功
      print('[API - 假數據] 創建圖片消息成功');
      return true;
      
    } catch (e) {
      print('[API] 創建圖片消息錯誤: $e');
      return false;
    }
  }

  // API: 發送文字消息（使用假數據）
  Future<bool> _sendTextMessage(String content) async {
    try {
      print('[API - 假數據] 發送文字消息...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      // TODO: 實際 API 調用
      // final userModel = context.read<UserModel>();
      // final path = ServerApi.PATH_CASE_MESSAGE_CREATE.replaceAll('{case_id}', widget.theCase.id.toString());
      // final response = await http.post(
      //   ServerApi.standard(path: path),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Token ${userModel.token}',
      //   },
      //   body: jsonEncode({
      //     'message_type': 'text',
      //     'content': content,
      //   }),
      // );
      // 
      // if (response.statusCode == 201) {
      //   print('[API] 發送文字消息成功');
      //   return true;
      // }
      
      // 假數據：模擬發送成功
      print('[API - 假數據] 發送文字消息成功');
      return true;
      
    } catch (e) {
      print('[API] 發送文字消息錯誤: $e');
      return false;
    }
  }

  // API: 獲取消息列表（使用假數據）
  Future<List<CaseMessage>?> _fetchMessages() async {
    try {
      print('[API - 假數據] 獲取消息列表...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      // TODO: 實際 API 調用
      // final userModel = context.read<UserModel>();
      // final path = ServerApi.PATH_CASE_MESSAGE_CREATE.replaceAll('{case_id}', widget.theCase.id.toString());
      // final response = await http.get(
      //   ServerApi.standard(path: path),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Token ${userModel.token}',
      //   },
      // );
      // 
      // if (response.statusCode == 200) {
      //   final data = jsonDecode(utf8.decode(response.body.runes.toList()));
      //   final List<CaseMessage> messages = [];
      //   for (var item in data['results']) {
      //     messages.add(CaseMessage.fromJson(item));
      //   }
      //   return messages;
      // }
      
      // 假數據：返回生成的假消息
      return _generateFakeMessages();
      
    } catch (e) {
      print('[API] 獲取消息列表錯誤: $e');
      return null;
    }
  }

  // API: 標記消息為已讀（使用假數據）
  Future<bool> _markMessagesAsRead() async {
    try {
      print('[API - 假數據] 標記消息為已讀...');
      await Future.delayed(const Duration(milliseconds: 200));
      
      // TODO: 實際 API 調用
      // final userModel = context.read<UserModel>();
      // final path = ServerApi.PATH_CASE_MESSAGE_MARK_READ.replaceAll('{case_id}', widget.theCase.id.toString());
      // final response = await http.post(
      //   ServerApi.standard(path: path),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Token ${userModel.token}',
      //   },
      // );
      // 
      // if (response.statusCode == 200) {
      //   print('[API] 標記消息為已讀成功');
      //   return true;
      // }
      
      // 假數據：模擬標記成功
      print('[API - 假數據] 標記消息為已讀成功');
      return true;
      
    } catch (e) {
      print('[API] 標記消息為已讀錯誤: $e');
      return false;
    }
  }

  // 查看圖片（全屏顯示）
  void _showImageViewer(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }
}

// 全屏圖片查看器
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        // 向上偏移 100px，使圖片在視覺中心偏上
        padding: const EdgeInsets.only(bottom: 100),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 100,
                          color: Colors.white,
                        ),
                      );
                    },
                  )
                : Image.file(
                    File(imageUrl),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 100,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

