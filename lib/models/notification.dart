// components/AppContext.tsx (Notification interface) 변환
enum NotificationType {
  like,
  comment,
  reply,
  follow,
  news,
  system,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String content;
  final String timestamp;
  final bool isRead;
  final String? avatar;
  final String? actionUser;
  final String? relatedContent;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.avatar,
    this.actionUser,
    this.relatedContent,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: _typeFromString(json['type'] as String),
      title: json['title'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] as String,
      isRead: json['isRead'] as bool,
      avatar: json['avatar'] as String?,
      actionUser: json['actionUser'] as String?,
      relatedContent: json['relatedContent'] as String?,
    );
  }

  static NotificationType _typeFromString(String type) {
    switch (type) {
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      case 'reply':
        return NotificationType.reply;
      case 'follow':
        return NotificationType.follow;
      case 'news':
        return NotificationType.news;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'content': content,
      'timestamp': timestamp,
      'isRead': isRead,
      'avatar': avatar,
      'actionUser': actionUser,
      'relatedContent': relatedContent,
    };
  }

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? content,
    String? timestamp,
    bool? isRead,
    String? avatar,
    String? actionUser,
    String? relatedContent,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      avatar: avatar ?? this.avatar,
      actionUser: actionUser ?? this.actionUser,
      relatedContent: relatedContent ?? this.relatedContent,
    );
  }
}
