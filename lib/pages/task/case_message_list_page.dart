import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../color.dart';
import '../../config/serverApi.dart';
import '../../models/case.dart';
import '../../models/case_message.dart';
import '../../notifier_models/user_model.dart';
import 'case_message_detail_page.dart';

class CaseMessageListPage extends StatefulWidget {
  const CaseMessageListPage({Key? key}) : super(key: key);

  @override
  State<CaseMessageListPage> createState() => _CaseMessageListPageState();
}

class _CaseMessageListPageState extends State<CaseMessageListPage> {
  final ScrollController _scrollController = ScrollController();
  List<CaseMessageListItem> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _nextPageUrl;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchList(refresh: true);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchList());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _fetchList({bool refresh = false}) async {
    if (!mounted) return;
    if (refresh) {
      setState(() => _isLoading = true);
    }
    try {
      final userModel = context.read<UserModel>();
      final response = await http.get(
        ServerApi.standard(path: ServerApi.PATH_CASE_MESSAGES),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${userModel.token}',
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.body.runes.toList()));
        final List<CaseMessageListItem> items = (data['results'] as List)
            .map((e) => CaseMessageListItem.fromJson(e))
            .toList();
        setState(() {
          _items = items;
          _nextPageUrl = data['next'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _nextPageUrl == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final userModel = context.read<UserModel>();
      final response = await http.get(
        Uri.parse(_nextPageUrl!),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${userModel.token}',
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.body.runes.toList()));
        final List<CaseMessageListItem> more = (data['results'] as List)
            .map((e) => CaseMessageListItem.fromJson(e))
            .toList();
        setState(() {
          _items.addAll(more);
          _nextPageUrl = data['next'];
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _openDetail(CaseMessageListItem item) async {
    _timer?.cancel();
    final theCase = Case(
      id: item.id,
      onAddress: item.onAddress,
      offAddress: '',
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseMessageDetailPage(
          theCase: theCase,
          unreadCount: item.unreadCount,
        ),
      ),
    );
    if (!mounted) return;
    _fetchList(refresh: true);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchList());
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return DateFormat('MM/dd HH:mm').format(dt);
  }

  String _caseStateText(String state) {
    switch (state) {
      case 'way_to_catch': return '前往接客';
      case 'on_road': return '行程中';
      case 'catched': return '任務中';
      case 'arrived': return '已到達';
      case 'finished': return '已完成';
      case 'canceled': return '已取消';
      default: return state;
    }
  }

  Color _caseStateColor(String state) {
    switch (state) {
      case 'way_to_catch': return Colors.orange;
      case 'on_road':
      case 'catched': return AppColor.primary;
      case 'arrived': return AppColor.green;
      case 'finished': return Colors.grey;
      case 'canceled': return AppColor.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('案件訊息'),
        centerTitle: true,
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('暫無案件訊息',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _fetchList(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _items.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return _buildItem(_items[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildItem(CaseMessageListItem item) {
    final hasUnread = item.unreadCount > 0;
    return InkWell(
      onTap: () => _openDetail(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.caseNumber,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _caseStateColor(item.caseState)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _caseStateText(item.caseState),
                          style: TextStyle(
                            fontSize: 11,
                            color: _caseStateColor(item.caseState),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.headset_mic,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _dispatcherLabel(item),
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _latestMessagePreview(item),
                    style: TextStyle(
                      fontSize: 14,
                      color: item.latestMessage == null
                          ? Colors.grey.shade400
                          : (hasUnread
                              ? Colors.black87
                              : Colors.grey.shade600),
                      fontWeight:
                          hasUnread ? FontWeight.w500 : FontWeight.normal,
                      fontStyle: item.latestMessage == null
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(item.latestMessage?.createdAt ?? item.createTime),
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (hasUnread) ...[
                  const SizedBox(height: 8),
                  _buildUnreadBadge(item.unreadCount),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dispatcherLabel(CaseMessageListItem item) {
    final nick = item.dispatcherNickName.trim();
    final name = item.dispatcherName.trim();
    if (nick.isNotEmpty && name.isNotEmpty) return '$nick（$name）';
    if (nick.isNotEmpty) return nick;
    if (name.isNotEmpty) return name;
    return '（無派單員資料）';
  }

  Widget _buildUnreadBadge(int count) {
    final label = count > 99 ? '99+' : '$count';
    final isMultiDigit = count > 9;
    return Container(
      height: 22,
      constraints: isMultiDigit
          ? const BoxConstraints(minWidth: 22)
          : const BoxConstraints(minWidth: 22, maxWidth: 22),
      padding: EdgeInsets.symmetric(horizontal: isMultiDigit ? 6 : 0),
      decoration: BoxDecoration(
        color: AppColor.red,
        shape: isMultiDigit ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isMultiDigit ? BorderRadius.circular(11) : null,
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _latestMessagePreview(CaseMessageListItem item) {
    final msg = item.latestMessage;
    if (msg == null) return '暫無訊息';
    if (msg.messageType == 'image') return '[圖片] ${msg.content}'.trim();
    return msg.content;
  }
}
