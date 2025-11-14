import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import '../../color.dart';
import '../../models/case.dart';
import '../../models/case_message.dart';
import '../../config/serverApi.dart';
import '../../notifier_models/user_model.dart';
import '../../services/s3_upload_service.dart';

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
  Timer? _pollingTimer; // 輪詢定時器

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // 開始輪詢消息
  void _startPolling() {
    print('[CaseMessage] 開始輪詢消息，每3秒一次');
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _refreshMessages();
    });
  }
  
  // 停止輪詢消息
  void _stopPolling() {
    if (_pollingTimer != null) {
      print('[CaseMessage] 停止輪詢消息');
      _pollingTimer!.cancel();
      _pollingTimer = null;
    }
  }
  
  // 刷新消息（輪詢使用，靜默刷新）
  void _refreshMessages() async {
    // 不顯示 loading 狀態，靜默刷新
    final fetchedMessages = await _fetchMessages();
    
    if (fetchedMessages != null && mounted) {
      // 只有在消息數量或內容改變時才更新
      if (fetchedMessages.length != messages.length || 
          _hasNewMessages(fetchedMessages)) {
        setState(() {
          final wasAtBottom = _isAtBottom();
          messages = fetchedMessages;
          
          // 如果之前在底部，則滾動到新消息
          if (wasAtBottom) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        });
        
        // 標記消息為已讀
        await _markMessagesAsRead();
      }
    }
  }
  
  // 檢查是否有新消息
  bool _hasNewMessages(List<CaseMessage> newMessages) {
    if (messages.isEmpty) return newMessages.isNotEmpty;
    if (newMessages.isEmpty) return false;
    
    // 比較最新消息的 ID
    return newMessages.last.id != messages.last.id;
  }
  
  // 檢查是否在底部
  bool _isAtBottom() {
    if (!_scrollController.hasClients) return true;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    return currentScroll >= maxScroll - 100; // 100px 的容差
  }

  // 載入消息列表
  void _loadMessages() async {
    setState(() {
      isLoading = true;
    });

    // 獲取消息列表
    final fetchedMessages = await _fetchMessages();
    
    if (fetchedMessages != null) {
      setState(() {
        messages = fetchedMessages;
        isLoading = false;
      });
      
      // 標記消息為已讀
      await _markMessagesAsRead();
      
      _scrollToBottom();
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('載入消息失敗'),
          duration: Duration(milliseconds: 800),
        ));
    }
  }

  // 發送消息
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      isSending = true;
    });

    // 調用 API 發送文字消息
    final success = await _sendTextMessage(content);
    
    if (success) {
      // 重新獲取消息列表以顯示最新消息
      final fetchedMessages = await _fetchMessages();
      if (fetchedMessages != null) {
        setState(() {
          messages = fetchedMessages;
          isSending = false;
        });
        _scrollToBottom();
        
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('訊息已發送'),
            duration: Duration(milliseconds: 800),
          ));
      } else {
        setState(() {
          isSending = false;
        });
      }
    } else {
      setState(() {
        isSending = false;
      });
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('發送失敗，請重試'),
          duration: Duration(milliseconds: 800),
        ));
    }
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
    final userModel = context.read<UserModel>();
    // 使用當前登錄用戶的真實 ID 進行判斷
    return message.sender == userModel.user?.id;
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
    // 為圖片消息添加詳細 log
    if (message.messageType == 'image') {
      print('[UI渲染] 圖片消息 ID: ${message.id}');
      print('[UI渲染] Image URL: ${message.imageUrl}');
      print('[UI渲染] 是否為 HTTP URL: ${message.imageUrl?.startsWith('http')}');
      print('[UI渲染] 是我的消息: $isMyMessage');
    }
    
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
        ..showSnackBar(const SnackBar(
          content: Text('選擇圖片失敗'),
          duration: Duration(milliseconds: 800),
        ));
    }
  }

  // 圖片上傳流程（使用真實 S3 上傳）
  Future<void> _uploadImageAndSendMessage(XFile imageFile) async {
    try {
      final userModel = context.read<UserModel>();
      
      // 步驟1: 直接上傳圖片到 S3
      print('[圖片上傳] 開始上傳到 S3...');
      final uploadResult = await S3UploadService.uploadImage(
        filePath: imageFile.path,
        caseId: widget.theCase.id!,
        userId: userModel.user!.id!,
      );
      
      if (uploadResult == null) {
        throw Exception('上傳到S3失敗');
      }
      
      print('[圖片上傳] S3 上傳成功');
      print('[圖片上傳] Image Key: ${uploadResult['image_key']}');
      print('[圖片上傳] Image URL: ${uploadResult['image_url']}');
      
      // 步驟2: 告知服務器圖片已上傳，創建消息記錄
      final messageCreated = await _createImageMessage(
        uploadResult['image_key']!,
        uploadResult['image_url']!,
        '', // 可選的圖片說明
      );
      
      if (!messageCreated) {
        throw Exception('創建消息記錄失敗');
      }
      
      // 重新獲取消息列表以顯示最新消息
      final fetchedMessages = await _fetchMessages();
      if (fetchedMessages != null) {
        setState(() {
          messages = fetchedMessages;
          isSending = false;
        });
        _scrollToBottom();
        
        print('[圖片上傳] 圖片消息發送成功');
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('圖片已發送'),
            duration: Duration(milliseconds: 800),
          ));
      } else {
        setState(() {
          isSending = false;
        });
      }
        
    } catch (e) {
      print('[圖片上傳] 上傳錯誤: $e');
      setState(() {
        isSending = false;
      });
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('圖片上傳失敗'),
          duration: Duration(milliseconds: 800),
        ));
    }
  }


  // API: 創建圖片消息記錄
  Future<bool> _createImageMessage(String imageKey, String imageUrl, String content) async {
    try {
      print('[API] 創建圖片消息記錄...');
      print('[API] Image Key: $imageKey');
      print('[API] Image URL: $imageUrl');
      
      final userModel = context.read<UserModel>();
      final path = ServerApi.PATH_CASE_MESSAGE_CREATE.replaceAll('{case_id}', widget.theCase.id.toString());
      
      final requestBody = {
        'message_type': 'image',
        'image_key': imageKey,
        'image_url': imageUrl,
        'content': content,
      };
      
      print('[API] 請求路徑: $path');
      print('[API] 請求體: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        ServerApi.standard(path: path),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${userModel.token}',
        },
        body: jsonEncode(requestBody),
      );
      
      print('[API] 響應狀態碼: ${response.statusCode}');
      print('[API] 響應內容: ${response.body}');
      
      if (response.statusCode == 201) {
        print('[API] ✅ 創建圖片消息成功');
        return true;
      } else {
        print('[API] ❌ 創建圖片消息失敗: ${response.statusCode}');
        return false;
      }
      
    } catch (e) {
      print('[API] ❌ 創建圖片消息錯誤: $e');
      return false;
    }
  }

  // API: 發送文字消息
  Future<bool> _sendTextMessage(String content) async {
    try {
      print('[API] 發送文字消息...');
      
      final userModel = context.read<UserModel>();
      final path = ServerApi.PATH_CASE_MESSAGE_CREATE.replaceAll('{case_id}', widget.theCase.id.toString());
      
      final response = await http.post(
        ServerApi.standard(path: path),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${userModel.token}',
        },
        body: jsonEncode({
          'message_type': 'text',
          'content': content,
        }),
      );
      
      print('[API] 發送文字消息響應: ${response.statusCode}');
      print('[API] 響應內容: ${response.body}');
      
      if (response.statusCode == 201) {
        print('[API] 發送文字消息成功');
        return true;
      } else {
        print('[API] 發送文字消息失敗: ${response.body}');
        return false;
      }
      
    } catch (e) {
      print('[API] 發送文字消息錯誤: $e');
      return false;
    }
  }

  // API: 獲取消息列表
  Future<List<CaseMessage>?> _fetchMessages() async {
    try {
      print('[API] 獲取消息列表...');
      
      final userModel = context.read<UserModel>();
      final path = ServerApi.PATH_CASE_MESSAGE_LIST.replaceAll('{case_id}', widget.theCase.id.toString());
      
      final response = await http.get(
        ServerApi.standard(path: path),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${userModel.token}',
        },
      );
      
      print('[API] 獲取消息列表響應: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.body.runes.toList()));
        print('[API] 獲取到 ${data['count']} 條消息');
        print('[消息] 當前用戶ID: ${userModel.user?.id}');
        
        final List<CaseMessage> messageList = [];
        int imageCount = 0;
        int textCount = 0;
        
        for (var item in data['results']) {
          final message = CaseMessage.fromJson(item);
          messageList.add(message);
          
          if (message.messageType == 'image') {
            imageCount++;
            print('[圖片消息 $imageCount]');
            print('  ID: ${message.id}');
            print('  Sender: ${message.sender} (${message.senderName})');
            print('  Image URL: ${message.imageUrl}');
            print('  Image Key: ${message.imageKey}');
            print('  Created At: ${message.createdAt}');
          } else if (message.messageType == 'text') {
            textCount++;
          }
        }
        
        print('[消息統計] 文字: $textCount, 圖片: $imageCount, 總計: ${messageList.length}');
        
        // 反轉列表，讓最舊的消息在上面，最新的在下面
        return messageList.reversed.toList();
      } else {
        print('[API] 獲取消息列表失敗: ${response.body}');
        return null;
      }
      
    } catch (e) {
      print('[API] 獲取消息列表錯誤: $e');
      return null;
    }
  }

  // API: 標記消息為已讀
  Future<bool> _markMessagesAsRead() async {
    try {
      print('[API] 標記消息為已讀...');
      
      final userModel = context.read<UserModel>();
      final path = ServerApi.PATH_CASE_MESSAGE_MARK_READ.replaceAll('{case_id}', widget.theCase.id.toString());
      
      final response = await http.post(
        ServerApi.standard(path: path),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${userModel.token}',
        },
      );
      
      print('[API] 標記消息為已讀響應: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.body.runes.toList()));
        print('[API] 標記消息為已讀成功，更新了 ${data['updated_count']} 條消息');
        return true;
      } else {
        print('[API] 標記消息為已讀失敗: ${response.body}');
        return false;
      }
      
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

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadImage(context),
          ),
        ],
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

  Future<void> _downloadImage(BuildContext context) async {
    try {
      // 檢查權限狀態
      bool hasPermission = false;
      
      if (Platform.isAndroid) {
        final deviceInfoPlugin = DeviceInfoPlugin();
        final deviceInfo = await deviceInfoPlugin.androidInfo;
        final sdkInt = deviceInfo.version.sdkInt;
        
        if (sdkInt < 29) {
          hasPermission = await Permission.storage.status.isGranted;
        } else {
          hasPermission = true; // Android 10+ 不需要特殊權限
        }
      } else {
        // iOS - 檢查添加到相簿的權限
        hasPermission = await Permission.photosAddOnly.status.isGranted;
      }

      // 如果沒有權限，提示用戶並提供跳轉到設定的選項
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('需要相簿權限才能保存圖片'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: '開啟設定',
                textColor: Colors.white,
                onPressed: () {
                  openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      // 顯示保存中提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('正在保存圖片...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      SaveResult result;
      final fileName = "taxi_dispatch_${DateTime.now().millisecondsSinceEpoch}.jpg";
      
      if (imageUrl.startsWith('http')) {
        // 下載並保存網絡圖片
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          result = await SaverGallery.saveImage(
            Uint8List.fromList(response.bodyBytes),
            quality: 100,
            fileName: fileName,
            androidRelativePath: "Pictures/TaxiDispatch",
            skipIfExists: false,
          );
        } else {
          throw Exception('下載圖片失敗');
        }
      } else {
        // 保存本地圖片
        final bytes = await File(imageUrl).readAsBytes();
        result = await SaverGallery.saveImage(
          Uint8List.fromList(bytes),
          quality: 100,
          fileName: fileName,
          androidRelativePath: "Pictures/TaxiDispatch",
          skipIfExists: false,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 圖片已保存到相簿'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ 保存圖片失敗: ${result.errorMessage ?? "未知錯誤"}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 保存圖片失敗: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

