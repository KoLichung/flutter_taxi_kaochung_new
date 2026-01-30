class CaseMessage {
  int? id;
  int? caseId;
  int? sender;
  String? senderName;
  String? senderNickName;
  String? messageType; // text, image, system
  String? content;
  String? imageUrl;
  String? imageKey;
  bool? isRead;
  String? readAt;
  String? createdAt;
  
  // V2 雙向已讀字段
  bool? isReadByDriver;
  String? readByDriverAt;
  bool? isReadByDispatcher;
  String? readByDispatcherAt;

  CaseMessage({
    this.id,
    this.caseId,
    this.sender,
    this.senderName,
    this.senderNickName,
    this.messageType,
    this.content,
    this.imageUrl,
    this.imageKey,
    this.isRead,
    this.readAt,
    this.createdAt,
    this.isReadByDriver,
    this.readByDriverAt,
    this.isReadByDispatcher,
    this.readByDispatcherAt,
  });

  CaseMessage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    caseId = json['case'];
    sender = json['sender'];
    senderName = json['sender_name'];
    senderNickName = json['sender_nick_name'];
    messageType = json['message_type'];
    content = json['content'];
    imageUrl = json['image_url'];
    imageKey = json['image_key'];
    isRead = json['is_read'];
    readAt = json['read_at'];
    createdAt = json['created_at'];
    
    // V2 雙向已讀字段
    isReadByDriver = json['is_read_by_driver'];
    readByDriverAt = json['read_by_driver_at'];
    isReadByDispatcher = json['is_read_by_dispatcher'];
    readByDispatcherAt = json['read_by_dispatcher_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['case'] = caseId;
    data['sender'] = sender;
    data['sender_name'] = senderName;
    data['sender_nick_name'] = senderNickName;
    data['message_type'] = messageType;
    data['content'] = content;
    data['image_url'] = imageUrl;
    data['image_key'] = imageKey;
    data['is_read'] = isRead;
    data['read_at'] = readAt;
    data['created_at'] = createdAt;
    data['is_read_by_driver'] = isReadByDriver;
    data['read_by_driver_at'] = readByDriverAt;
    data['is_read_by_dispatcher'] = isReadByDispatcher;
    data['read_by_dispatcher_at'] = readByDispatcherAt;
    return data;
  }
}

