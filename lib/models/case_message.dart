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
    return data;
  }
}

