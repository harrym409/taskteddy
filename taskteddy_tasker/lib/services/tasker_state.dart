import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import 'api_service.dart';

class TaskerState extends ChangeNotifier {
  static final TaskerState _instance = TaskerState._internal();
  factory TaskerState() => _instance;
  TaskerState._internal();

  // ── Cross-screen navigation + refresh hub ─────────────────────────────
  // Lets any screen ask the shell to switch tabs (e.g. jump to "Applied"
  // after a bid) and signal that the applications list changed so the
  // kept-alive Applied tab reloads instead of showing stale data.
  int _requestedTab = -1;
  int get requestedTab => _requestedTab;
  void requestTab(int index) {
    _requestedTab = index;
    notifyListeners();
  }

  void consumeTabRequest() => _requestedTab = -1;

  int _applicationsRevision = 0;
  int get applicationsRevision => _applicationsRevision;

  /// Call after a bid/withdraw so the Applied tab refetches next time it shows.
  void notifyApplicationsChanged() {
    _applicationsRevision++;
    notifyListeners();
  }

  // Neutral placeholder until the real profile loads via loadUser().
  UserModel _user = const UserModel(
    id: 0,
    name: 'TaskTeddy User',
    email: '',
    rating: 0.0,
    totalReviews: 0,
    coins: 0,
  );
  UserModel get user => _user;

  Future<void> loadUser() async {
    final sessionUser = await Session.getUser();
    if (sessionUser != null) {
      _applyUser(sessionUser);
      notifyListeners();
    }
    // Refresh with the latest profile (real rating/reviews/coins) from the API.
    try {
      final fresh = await ApiService.getProfile();
      _applyUser(fresh);
      notifyListeners();
    } catch (_) {
      // Keep the cached session values if the refresh fails/offline.
    }
  }

  void _applyUser(Map<String, dynamic> data) {
    final avatar = data['avatar_url']?.toString();
    final repRaw = data['reputation'];
    ReputationModel? reputation;
    if (repRaw is Map) {
      reputation = ReputationModel.fromJson(Map<String, dynamic>.from(repRaw));
    }
    // Fall back to a top-level completed_tasks if reputation is present but its
    // own count is missing, or synthesize a minimal reputation from it.
    final topCompleted = (data['completed_tasks'] as num?)?.toInt();
    if (reputation != null &&
        reputation.completedTasks == 0 &&
        topCompleted != null) {
      reputation = ReputationModel(
        level: reputation.level,
        levelLabel: reputation.levelLabel,
        reliability: reputation.reliability,
        completedTasks: topCompleted,
        cancelCount: reputation.cancelCount,
        nextLevelAt: reputation.nextLevelAt,
      );
    }
    _user = UserModel(
      id: int.tryParse(data['id']?.toString() ?? '0') ?? 0,
      name: data['name']?.toString() ?? 'Unknown User',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      avatarUrl: ApiService.resolveMediaUrl(avatar),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (data['total_reviews'] as num?)?.toInt() ?? 0,
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      reputation: reputation ?? _user.reputation,
    );
    if (data.containsKey('bio')) {
      _bio = data['bio']?.toString() ?? '';
    }
    if (data.containsKey('is_online')) {
      _isAvailable = data['is_online'] == true;
    }
  }

  // Empty until the tasker writes their own; never a fabricated default.
  String _bio = '';
  String get bio => _bio;

  List<String> _skills = ['Repair', 'Tech', 'Cleaning', 'Delivery'];
  List<String> get skills => _skills;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  // Verification document statuses (default: nothing submitted yet).
  final Map<String, String> _verificationStatuses = {
    'aadhaar': 'not_submitted',
    'pan': 'not_submitted',
    'address': 'not_submitted',
    'selfie': 'not_submitted',
  };
  Map<String, String> get verificationStatuses => _verificationStatuses;

  // Payout methods (added by the user; none seeded).
  final List<Map<String, dynamic>> _payoutMethods = [];
  List<Map<String, dynamic>> get payoutMethods => _payoutMethods;

  // Wallet — real data loaded from the backend via loadWallet().
  double _walletBalance = 0.0;
  double get walletBalance => _walletBalance;

  double _totalEarnings = 0.0;
  double get totalEarnings => _totalEarnings;

  double _thisMonthEarnings = 0.0;
  double get thisMonthEarnings => _thisMonthEarnings;

  int _completedTaskCount = 0;
  int get completedTaskCount => _completedTaskCount;

  bool _walletLoading = false;
  bool get walletLoading => _walletLoading;

  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> get transactions => _transactions;

  /// Load real wallet balance, transactions and earnings totals from the backend.
  Future<void> loadWallet() async {
    // NB: no eager notifyListeners() here. loadWallet() is called from
    // WalletScreen.initState while the shell's IndexedStack is still building
    // every tab; notifying synchronously would fire a listener's setState mid
    // build ("setState called during build"). The finally block notifies once
    // the data is in, which is all the UI actually needs.
    _walletLoading = true;
    try {
      final results = await Future.wait([
        ApiService.getWalletBalance(),
        ApiService.getWalletTransactions(),
        ApiService.getEarnings(),
      ]);
      _walletBalance = results[0] as double;
      final txns = (results[1] as List).cast<Map<String, dynamic>>();
      _transactions = txns
          .map((t) => {
                'type': t['type'],
                'desc': t['description'] ?? '',
                'amount': (t['amount'] as num?)?.toDouble() ?? 0.0,
                'time': DateTime.tryParse(t['created_at']?.toString() ?? '') ??
                    DateTime.now(),
              })
          .toList();
      final earnings = results[2] as Map<String, dynamic>;
      _totalEarnings = (earnings['total_earnings'] as num?)?.toDouble() ?? 0.0;
      _thisMonthEarnings =
          (earnings['this_month_earnings'] as num?)?.toDouble() ?? 0.0;
      _completedTaskCount = (earnings['completed_tasks'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('loadWallet error: $e');
    } finally {
      _walletLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({required String name, required String email, required String phone, required String city}) async {
    try {
      await ApiService.updateMe(name: name, phone: phone, email: email);
      _user = _user.copyWith(
        name: name,
        email: email,
        phone: phone,
      );
      notifyListeners();
    } catch (e) {
      // Re-throw so UI can show error
      rethrow;
    }
  }

  /// Persist the bio to the backend. Optimistically updates local state and
  /// reverts on failure. Returns an error message, or null on success.
  Future<String?> updateBio(String bio) async {
    final previous = _bio;
    _bio = bio;
    notifyListeners();
    try {
      await ApiService.patchProfile({'bio': bio});
      return null;
    } catch (e) {
      _bio = previous;
      notifyListeners();
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  void updateSkills(List<String> skills) {
    _skills = List.from(skills);
    notifyListeners();
  }

  /// Persist availability to the backend so it survives app restarts.
  /// Optimistically toggles and reverts on failure. Returns an error message,
  /// or null on success.
  Future<String?> setAvailability(bool available) async {
    final previous = _isAvailable;
    _isAvailable = available;
    notifyListeners();
    try {
      await ApiService.setOnline(available);
      return null;
    } catch (e) {
      _isAvailable = previous;
      notifyListeners();
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Upload a new avatar photo and persist it. Returns an error message, or
  /// null on success.
  Future<String?> uploadAvatar(XFile file) async {
    try {
      final url = await ApiService.uploadAvatar(file);
      _user = _user.copyWith(avatarUrl: ApiService.resolveMediaUrl(url));
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  void addPayoutMethod(Map<String, dynamic> method) {
    if (method['isDefault'] == true) {
      for (var m in _payoutMethods) {
        m['isDefault'] = false;
      }
    }
    _payoutMethods.add(method);
    notifyListeners();
  }

  void removePayoutMethod(String name) {
    final index = _payoutMethods.indexWhere((m) => m['name'] == name);
    if (index != -1) {
      final wasDefault = _payoutMethods[index]['isDefault'] == true;
      _payoutMethods.removeAt(index);
      if (wasDefault && _payoutMethods.isNotEmpty) {
        _payoutMethods.first['isDefault'] = true;
      }
      notifyListeners();
    }
  }

  void setDefaultPayoutMethod(String name) {
    for (var m in _payoutMethods) {
      m['isDefault'] = m['name'] == name;
    }
    notifyListeners();
  }

  void uploadDocument(String key, String status) {
    _verificationStatuses[key] = status;
    notifyListeners();
  }

  bool redeemCoins(int amount) {
    if (_user.coins >= amount) {
      final newCoins = _user.coins - amount;
      _user = _user.copyWith(coins: newCoins);
      
      _transactions.insert(0, {
        'type': 'earning',
        'desc': 'Redeemed $amount TaskCoins',
        'amount': amount.toDouble(),
        'time': DateTime.now(),
      });
      
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Request a real withdrawal via the backend. Returns null on success, or an
  /// error message to show the user. Refreshes the wallet on success.
  Future<String?> withdraw(
    double amount, {
    String method = 'bank',
    String? details,
  }) async {
    try {
      final defaultMethod = _payoutMethods.firstWhere(
        (m) => m['isDefault'] == true,
        orElse: () => _payoutMethods.isNotEmpty ? _payoutMethods.first : {},
      );
      await ApiService.requestWithdrawal(
        amount: amount,
        method: (defaultMethod['type'] ?? method).toString(),
        details: details ?? defaultMethod['details']?.toString(),
      );
      await loadWallet();
      return null;
    } on UnauthorizedException {
      return 'Session expired. Please log in again.';
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}
