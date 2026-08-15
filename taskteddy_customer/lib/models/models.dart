// ─── Enums ────────────────────────────────────────────────

enum TaskStatus {
  pendingReview,
  open,
  assigned,
  inProgress,
  completed,
  cancelled,
  rejected,
}

enum TaskCategory {
  cleaning,
  repair,
  delivery,
  errands,
  moving,
  cooking,
  tutoring,
  tech,
  photography,
  painting,
  gardening,
  other,
}

extension TaskCategoryX on TaskCategory {
  String get label {
    const m = {
      TaskCategory.cleaning: 'Cleaning',
      TaskCategory.repair: 'Repair',
      TaskCategory.delivery: 'Delivery',
      TaskCategory.errands: 'Errands',
      TaskCategory.moving: 'Moving',
      TaskCategory.cooking: 'Cooking',
      TaskCategory.tutoring: 'Tutoring',
      TaskCategory.tech: 'Tech Help',
      TaskCategory.photography: 'Photography',
      TaskCategory.painting: 'Painting',
      TaskCategory.gardening: 'Gardening',
      TaskCategory.other: 'Other',
    };
    return m[this]!;
  }
}

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pendingReview:
        return 'Under Review';
      case TaskStatus.open:
        return 'Open';
      case TaskStatus.assigned:
        return 'Assigned';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
      case TaskStatus.rejected:
        return 'Not Approved';
    }
  }
}

// ─── Models ───────────────────────────────────────────────

/// Public reputation summary for a tasker, surfaced on offers and profiles.
/// All fields are null-safe: older payloads omit the whole object.
class Reputation {
  /// One of: new | bronze | silver | gold | pro.
  final String level;

  /// Display text for the level (e.g. "Gold").
  final String levelLabel;

  /// Reliability score, 0-100.
  final int reliability;

  /// Lifetime completed tasks.
  final int completedTasks;

  /// Lifetime cancellations.
  final int cancelCount;

  /// Completed-task threshold for the next tier, when known.
  final int? nextLevelAt;

  const Reputation({
    required this.level,
    required this.levelLabel,
    required this.reliability,
    required this.completedTasks,
    required this.cancelCount,
    this.nextLevelAt,
  });
}

class UserModel {
  final int id;
  final String? remoteId;
  final String name, email;
  final String? phone, avatarUrl;
  final double rating;
  final int totalReviews, coins;
  final bool isVerified;
  final int completedTasks;
  final Reputation? reputation;
  const UserModel({
    required this.id,
    this.remoteId,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.rating = 5.0,
    this.totalReviews = 0,
    this.coins = 0,
    this.isVerified = false,
    this.completedTasks = 0,
    this.reputation,
  });
}

class TaskModel {
  final int id;
  final String? remoteId;
  final String title, description, location;
  final TaskCategory category;
  final TaskStatus status;
  final double budget;
  final DateTime deadline, createdAt;
  final UserModel postedBy;
  final UserModel? assignedTo;
  final int applicantsCount;
  final String? completionOtp;
  // Live-tracking + cancellation metadata surfaced by the backend.
  final DateTime? onTheWayAt;
  final double? latitude;
  final double? longitude;
  final String? cancelReason;
  final String? cancelledBy;
  // Reason surfaced by the backend when a posted task is declined during
  // review (status == rejected).
  final String? reviewReason;
  // True when the current viewer has already left a review for this task
  // (used to hide the "Rate" button once a review exists).
  final bool reviewed;
  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.status,
    required this.budget,
    required this.deadline,
    required this.createdAt,
    required this.postedBy,
    this.assignedTo,
    this.applicantsCount = 0,
    this.completionOtp,
    this.remoteId,
    this.onTheWayAt,
    this.latitude,
    this.longitude,
    this.cancelReason,
    this.cancelledBy,
    this.reviewReason,
    this.reviewed = false,
  });
}

/// Live location snapshot for an assigned tasker who is on the way, from
/// GET /tasks/{id}/tasker-location. All fields are optional because the tasker
/// may not have shared a coordinate yet.
class TaskerLocation {
  final String taskId;
  final DateTime? onTheWayAt;
  final double? latitude;
  final double? longitude;
  final DateTime? lastLocationAt;
  final String? taskerName;
  final String? taskerAvatarUrl;
  const TaskerLocation({
    required this.taskId,
    this.onTheWayAt,
    this.latitude,
    this.longitude,
    this.lastLocationAt,
    this.taskerName,
    this.taskerAvatarUrl,
  });
}

class ApplicationModel {
  final int id;
  final String? remoteId;
  final String? taskId;
  final TaskModel? task;
  final UserModel applicant;
  final double bidAmount;
  final String coverLetter, status;
  final DateTime appliedAt;
  const ApplicationModel({
    required this.id,
    this.remoteId,
    this.taskId,
    this.task,
    required this.applicant,
    required this.bidAmount,
    required this.coverLetter,
    required this.status,
    required this.appliedAt,
  });
}

class ServiceModel {
  final int id;
  final String name, emoji, category, description;
  final String? iconAsset;
  final double price, originalPrice, rating;
  final int reviewCount;
  final bool isHot, isNew;
  final List<String> includes;
  const ServiceModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.description,
    this.iconAsset,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviewCount,
    this.isHot = false,
    this.isNew = false,
    this.includes = const [],
  });
}

class BookingModel {
  final int id;
  // Raw backend id (uuid) — required for cancel/detail API calls.
  final String? remoteId;
  final ServiceModel service;
  final UserModel customer;
  final DateTime scheduledAt;
  final String address, status, bookingId;
  final double amount;
  final String notes;
  final bool paidWithWallet;
  const BookingModel({
    required this.id,
    this.remoteId,
    required this.service,
    required this.customer,
    required this.scheduledAt,
    required this.address,
    required this.status,
    required this.bookingId,
    required this.amount,
    this.notes = '',
    this.paidWithWallet = false,
  });
}

class MessageModel {
  final int id;
  final String text;
  final bool isMine;
  final DateTime sentAt;
  const MessageModel({
    required this.id,
    required this.text,
    required this.isMine,
    required this.sentAt,
  });
}

class ConversationModel {
  final int id;
  final UserModel other;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final TaskModel? relatedTask;
  const ConversationModel({
    required this.id,
    required this.other,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.relatedTask,
  });
}

class NotifModel {
  final int id;
  // Raw backend id (may be a uuid) — required for read/delete API calls.
  final String? remoteId;
  final String title, body, emoji, type;
  final String? relatedId;
  final DateTime createdAt;
  final bool isRead;
  const NotifModel({
    required this.id,
    this.remoteId,
    required this.title,
    required this.body,
    required this.emoji,
    required this.type,
    this.relatedId,
    required this.createdAt,
    this.isRead = false,
  });

  NotifModel copyWith({bool? isRead}) => NotifModel(
        id: id,
        remoteId: remoteId,
        title: title,
        body: body,
        emoji: emoji,
        type: type,
        relatedId: relatedId,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );
}

class ReviewModel {
  final int id;
  final UserModel reviewer;
  final double rating;
  final String comment;
  final DateTime createdAt;
  const ReviewModel({
    required this.id,
    required this.reviewer,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

class EarningModel {
  final int id;
  final TaskModel task;
  final double gross, fee, net;
  final DateTime paidAt;
  const EarningModel({
    required this.id,
    required this.task,
    required this.gross,
    required this.fee,
    required this.net,
    required this.paidAt,
  });
}

// ─── CategoryModel ────────────────────────────────────────
class CategoryModel {
  final int id;
  final String name, emoji, slug;
  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.slug,
  });
}

// ─── AddressModel ─────────────────────────────────────────
// Mirrors the backend /addresses record used for reusable checkout addresses.
class AddressModel {
  final String id;
  final String label;
  final String address;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  const AddressModel({
    required this.id,
    required this.label,
    required this.address,
    this.landmark,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    final label = json['label']?.toString().trim();
    final landmark = json['landmark']?.toString().trim();
    return AddressModel(
      id: json['id'].toString(),
      label: (label != null && label.isNotEmpty) ? label : 'Home',
      address: json['address']?.toString() ?? '',
      landmark: (landmark != null && landmark.isNotEmpty) ? landmark : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['is_default'] == true,
    );
  }
}

// ─── FavoriteItem ─────────────────────────────────────────
// A saved service or tasker from the /favorites endpoint. Exactly one of
// [service] / [tasker] is populated depending on [targetType].
class FavoriteItem {
  final String id;
  final String targetType; // 'service' | 'tasker'
  final String targetId;
  final ServiceModel? service;
  final UserModel? tasker;
  final bool taskerVerified;
  const FavoriteItem({
    required this.id,
    required this.targetType,
    required this.targetId,
    this.service,
    this.tasker,
    this.taskerVerified = false,
  });
}
