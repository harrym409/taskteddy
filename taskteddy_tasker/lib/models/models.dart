// ─── Enums ────────────────────────────────────────────────

enum TaskStatus { open, assigned, inProgress, completed, cancelled }
enum TaskCategory {
  cleaning, repair, delivery, errands, moving, cooking,
  tutoring, tech, photography, painting, gardening, other,
}

extension TaskCategoryX on TaskCategory {
  String get label {
    const m = {
      TaskCategory.cleaning: 'Cleaning',   TaskCategory.repair: 'Repair',
      TaskCategory.delivery: 'Delivery',   TaskCategory.errands: 'Errands',
      TaskCategory.moving: 'Moving',       TaskCategory.cooking: 'Cooking',
      TaskCategory.tutoring: 'Tutoring',   TaskCategory.tech: 'Tech Help',
      TaskCategory.photography: 'Photography', TaskCategory.painting: 'Painting',
      TaskCategory.gardening: 'Gardening', TaskCategory.other: 'Other',
    };
    return m[this]!;
  }
}

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.open: return 'Open';
      case TaskStatus.assigned: return 'Assigned';
      case TaskStatus.inProgress: return 'In Progress';
      case TaskStatus.completed: return 'Completed';
      case TaskStatus.cancelled: return 'Cancelled';
    }
  }
}

// ─── Models ───────────────────────────────────────────────

/// A tasker's own reputation/level, from the backend `reputation` object on
/// the profile / cached user. All fields null-safe; `nextLevelAt` is null once
/// the tasker reaches the top (Pro) level.
class ReputationModel {
  final String level;       // new | bronze | silver | gold | pro
  final String levelLabel;  // human-readable label, e.g. "Silver"
  final double reliability; // 0–100
  final int completedTasks;
  final int cancelCount;
  final int? nextLevelAt;   // completed-jobs count for the next tier; null at Pro

  const ReputationModel({
    this.level = 'new',
    this.levelLabel = 'New',
    this.reliability = 0,
    this.completedTasks = 0,
    this.cancelCount = 0,
    this.nextLevelAt,
  });

  static ReputationModel? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final rawLevel = json['level']?.toString().trim().toLowerCase();
    return ReputationModel(
      level: (rawLevel == null || rawLevel.isEmpty) ? 'new' : rawLevel,
      levelLabel: json['level_label']?.toString().trim().isNotEmpty == true
          ? json['level_label'].toString()
          : 'New',
      reliability: (json['reliability'] as num?)?.toDouble() ?? 0,
      completedTasks: (json['completed_tasks'] as num?)?.toInt() ?? 0,
      cancelCount: (json['cancel_count'] as num?)?.toInt() ?? 0,
      nextLevelAt: (json['next_level_at'] as num?)?.toInt(),
    );
  }
}

class UserModel {
  final int id;
  final String? remoteId;
  final String name, email;
  final String? phone, avatarUrl;
  final double rating;
  final int totalReviews, coins;
  final ReputationModel? reputation;
  const UserModel({
    required this.id, this.remoteId, required this.name, required this.email,
    this.phone, this.avatarUrl, this.rating = 5.0,
    this.totalReviews = 0, this.coins = 0, this.reputation,
  });

  double get walletBalance => coins.toDouble();

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    double? rating,
    int? totalReviews,
    int? coins,
    ReputationModel? reputation,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      coins: coins ?? this.coins,
      reputation: reputation ?? this.reputation,
    );
  }
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
  // Photos the customer attached when posting the task (server URLs, may be
  // relative like /uploads/tasks/... — resolve with ApiService.resolveMediaUrl).
  final List<String> images;
  const TaskModel({
    required this.id, required this.title, required this.description,
    required this.location, required this.category, required this.status,
    required this.budget, required this.deadline, required this.createdAt,
    required this.postedBy, this.assignedTo, this.applicantsCount = 0,
    this.completionOtp, this.remoteId, this.images = const [],
  });
}

class ApplicationModel {
  final int id;
  final String? remoteId;
  final TaskModel? task;
  final UserModel applicant;
  final double bidAmount;
  final String coverLetter, status;
  final DateTime appliedAt;
  
  const ApplicationModel({
    required this.id, 
    this.remoteId,
    this.task, 
    required this.applicant,
    required this.bidAmount, 
    required this.coverLetter,
    required this.status, 
    required this.appliedAt,
  });
}

class MessageModel {
  final int id;
  final String text;
  final bool isMine;
  final DateTime sentAt;
  const MessageModel({
    required this.id, required this.text,
    required this.isMine, required this.sentAt,
  });
}

class ReviewModel {
  final int id;
  final UserModel reviewer;
  final double rating;
  final String comment;
  final DateTime createdAt;
  const ReviewModel({
    required this.id, required this.reviewer, required this.rating,
    required this.comment, required this.createdAt,
  });
}

class EarningModel {
  final int id;
  final TaskModel task;
  final double gross, fee, net;
  final DateTime paidAt;
  const EarningModel({
    required this.id, required this.task,
    required this.gross, required this.fee, required this.net,
    required this.paidAt,
  });
}

// ─── Mock Data ────────────────────────────────────────────

const mockCustomer = UserModel(
  id: 1, name: 'Harry Malhotra', email: 'harry@example.com',
  phone: '9876543210', rating: 4.8, totalReviews: 12, coins: 150,
);

const mockTasker = UserModel(
  id: 2, name: 'Rajesh Kumar', email: 'rajesh@example.com',
  phone: '9812345678', rating: 4.9, totalReviews: 87, coins: 340,
);

const mockTasker2 = UserModel(
  id: 3, name: 'Priya Sharma', email: 'priya@example.com',
  phone: '9801234567', rating: 4.7, totalReviews: 45, coins: 210,
);

final List<TaskModel> mockTasks = [
  TaskModel(id:1, title:'Deep clean my 2BHK apartment', category:TaskCategory.cleaning,
    description:'Need thorough cleaning of 2BHK — kitchen, bathrooms, living room. Eco-friendly supplies required. Approx 3-4 hours.',
    status:TaskStatus.open, budget:600, location:'Phagwara Road, Ludhiana',
    deadline:DateTime.now().add(const Duration(days:2)),
    createdAt:DateTime.now().subtract(const Duration(hours:3)),
    postedBy:mockCustomer, applicantsCount:4, completionOtp:'7823'),
  TaskModel(id:2, title:'Fix leaking bathroom tap', category:TaskCategory.repair,
    description:'Bathroom tap leaking for 2 days. Need experienced plumber. Materials provided. 1 hour job.',
    status:TaskStatus.open, budget:350, location:'Model Town, Ludhiana',
    deadline:DateTime.now().add(const Duration(days:1)),
    createdAt:DateTime.now().subtract(const Duration(hours:1)),
    postedBy:mockCustomer, applicantsCount:2, completionOtp:'4519'),
  TaskModel(id:3, title:'Grocery pickup from Big Bazaar', category:TaskCategory.errands,
    description:'Pick up groceries and deliver home. List of 20 items. Budget includes delivery charges.',
    status:TaskStatus.open, budget:200, location:'Sarabha Nagar, Ludhiana',
    deadline:DateTime.now().add(const Duration(hours:4)),
    createdAt:DateTime.now().subtract(const Duration(minutes:30)),
    postedBy:mockCustomer, applicantsCount:6, completionOtp:'2341'),
  TaskModel(id:4, title:'Help move furniture to new flat', category:TaskCategory.moving,
    description:'Moving this Sunday. Need 2-3 people for furniture and boxes. 3rd floor, lift available.',
    status:TaskStatus.assigned, budget:1500, location:'BRS Nagar, Ludhiana',
    deadline:DateTime.now().add(const Duration(days:4)),
    createdAt:DateTime.now().subtract(const Duration(hours:5)),
    postedBy:mockCustomer, assignedTo:mockTasker, applicantsCount:3, completionOtp:'9067'),
  TaskModel(id:5, title:'Maths tutor for class 10', category:TaskCategory.tutoring,
    description:'Experienced maths tutor for class 10. Algebra + geometry focus. 2hrs/day, weekdays.',
    status:TaskStatus.open, budget:1000, location:'Dugri, Ludhiana',
    deadline:DateTime.now().add(const Duration(days:7)),
    createdAt:DateTime.now().subtract(const Duration(hours:8)),
    postedBy:mockCustomer, applicantsCount:3, completionOtp:'3388'),
  TaskModel(id:6, title:'Cook dinner for family of 4', category:TaskCategory.cooking,
    description:'Cook for one evening. North Indian food. 4 people. All groceries provided.',
    status:TaskStatus.inProgress, budget:500, location:'Civil Lines, Ludhiana',
    deadline:DateTime.now().add(const Duration(hours:6)),
    createdAt:DateTime.now().subtract(const Duration(hours:2)),
    postedBy:mockCustomer, assignedTo:mockTasker2, applicantsCount:5, completionOtp:'1122'),
  TaskModel(id:7, title:'Set up new laptop and install software', category:TaskCategory.tech,
    description:'New laptop needs OS setup, MS Office, Zoom, antivirus. Basic file migration from old laptop.',
    status:TaskStatus.open, budget:400, location:'Rishi Nagar, Ludhiana',
    deadline:DateTime.now().add(const Duration(days:3)),
    createdAt:DateTime.now().subtract(const Duration(hours:4)),
    postedBy:mockCustomer, applicantsCount:1, completionOtp:'5590'),
  TaskModel(id:8, title:'Garden cleanup and plant trimming', category:TaskCategory.gardening,
    description:'Small garden needs cleanup. Trim hedges, remove weeds, water plants. 2-3 hours.',
    status:TaskStatus.open, budget:300, location:'Haibowal, Ludhiana',
    deadline:DateTime.now().add(const Duration(days:2)),
    createdAt:DateTime.now().subtract(const Duration(hours:6)),
    postedBy:mockCustomer, applicantsCount:2, completionOtp:'8844'),
  TaskModel(id:9, title:'Paint bedroom walls (2 walls)', category:TaskCategory.painting,
    description:'2 bedroom walls need painting. Paint and tools provided. Premium finish required.',
    status:TaskStatus.open, budget:800, location:'Gurdev Nagar, Ludhiana',
    deadline:DateTime.now().add(const Duration(days:5)),
    createdAt:DateTime.now().subtract(const Duration(hours:10)),
    postedBy:mockCustomer, applicantsCount:0, completionOtp:'6612'),
  TaskModel(id:10, title:'Deliver parcel to Jalandhar', category:TaskCategory.delivery,
    description:'Small parcel (2kg) needs to be delivered to Jalandhar by evening. Door-to-door.',
    status:TaskStatus.open, budget:450, location:'Ludhiana to Jalandhar',
    deadline:DateTime.now().add(const Duration(hours:8)),
    createdAt:DateTime.now().subtract(const Duration(minutes:45)),
    postedBy:mockCustomer, applicantsCount:3, completionOtp:'9901'),
];

final List<ApplicationModel> mockMyApplications = [];

final List<EarningModel> mockEarnings = [
  EarningModel(id:1, task:mockTasks[0], gross:600, fee:90, net:510,
    paidAt:DateTime.now().subtract(const Duration(days:1))),
  EarningModel(id:2, task:mockTasks[5], gross:500, fee:75, net:425,
    paidAt:DateTime.now().subtract(const Duration(days:3))),
  EarningModel(id:3, task:mockTasks[3], gross:1500, fee:225, net:1275,
    paidAt:DateTime.now().subtract(const Duration(days:5))),
  EarningModel(id:4, task:mockTasks[1], gross:350, fee:52.5, net:297.5,
    paidAt:DateTime.now().subtract(const Duration(days:7))),
];
