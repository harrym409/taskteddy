import {
  Admin,
  AdminRole,
  TeamMember,
  AnalyticsCategory,
  AnalyticsPayouts,
  AnalyticsSummary,
  AnalyticsTimeseries,
  AnnouncementPayload,
  AnnouncementResult,
  AuditLog,
  Booking,
  DashboardStats,
  InsightsResponse,
  KycNumbersResult,
  KycSubmission,
  QueueCounts,
  Review,
  ReviewTask,
  SafetyReport,
  Service,
  ServicePayload,
  SupportTicket,
  SystemHealth,
  Task,
  TaskApplication,
  TimeseriesResponse,
  Transaction,
  User,
  UserOverview,
  Withdrawal,
} from "@/types";

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

/** Resolve a server-relative upload path (e.g. "/uploads/kyc/x.jpg") to a full URL. */
export function fileUrl(path: string): string {
  if (!path) return "";
  if (path.startsWith("http://") || path.startsWith("https://")) return path;
  return `${API_BASE}${path.startsWith("/") ? "" : "/"}${path}`;
}

// Get auth token from cookie or localStorage
async function getAuthHeaders(): Promise<HeadersInit> {
  if (typeof window === "undefined") {
    return { "Content-Type": "application/json" };
  }
  
  const token = localStorage.getItem("admin_token");
  return {
    "Content-Type": "application/json",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
}

function handleResponse<T>(res: Response): Promise<T> {
  if (!res.ok) {
    // Only an invalid/expired token (401) logs the user out. A 403 is a
    // permission denial (RBAC) for a valid session — surface it as an error,
    // don't bounce the user to login.
    if (res.status === 401 && typeof window !== "undefined") {
      localStorage.removeItem("admin_token");
      localStorage.removeItem("admin");
      if (window.location.pathname !== "/login") {
        window.location.href = "/login";
      }
    }
    return res
      .json()
      .catch(() => ({}))
      .then((err) => {
        const detail = (err as { detail?: unknown }).detail;
        let message = "Request failed";
        if (typeof detail === "string") {
          message = detail;
        } else if (Array.isArray(detail)) {
          // FastAPI 422 validation errors: [{loc, msg, type}, ...]
          message = detail
            .map((e) =>
              e && typeof e === "object" && "msg" in e
                ? String((e as { msg: unknown }).msg)
                : String(e)
            )
            .join("; ");
        }
        throw new Error(message);
      });
  }
  return res.json();
}

export function isAuthenticated(): boolean {
  if (typeof window === "undefined") return false;
  return !!localStorage.getItem("admin_token");
}

// ========== AUTH ==========

export async function adminLogin(email: string, password: string) {
  const res = await fetch(`${API_BASE}/api/admin/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
  
  const data = await handleResponse<{ access_token: string; admin: Admin }>(res);
  
  if (typeof window !== "undefined") {
    localStorage.setItem("admin_token", data.access_token);
    localStorage.setItem("admin", JSON.stringify(data.admin));
  }
  
  return data;
}

export async function adminLogout() {
  if (typeof window !== "undefined") {
    localStorage.removeItem("admin_token");
    localStorage.removeItem("admin");
  }
}

export async function getCurrentAdmin(): Promise<Admin | null> {
  if (typeof window === "undefined") return null;

  const adminStr = localStorage.getItem("admin");
  if (!adminStr) return null;

  try {
    return JSON.parse(adminStr);
  } catch {
    return null;
  }
}

/** Current portal role, read from the stored admin object. */
export function getAdminRole(): AdminRole | null {
  if (typeof window === "undefined") return null;
  try {
    const a = localStorage.getItem("admin");
    if (!a) return null;
    return (JSON.parse(a).role as AdminRole) ?? null;
  } catch {
    return null;
  }
}

// ========== TEAM MANAGEMENT (super admin only) ==========

export async function getTeam(): Promise<TeamMember[]> {
  const res = await fetch(`${API_BASE}/api/admin/team`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<TeamMember[]>(res);
}

export async function createTeamMember(body: {
  email: string;
  name: string;
  password: string;
  role: "admin" | "support";
}): Promise<TeamMember> {
  const res = await fetch(`${API_BASE}/api/admin/team`, {
    method: "POST",
    headers: await getAuthHeaders(),
    body: JSON.stringify(body),
  });
  return handleResponse<TeamMember>(res);
}

export async function updateTeamMember(
  id: string,
  body: { name?: string; role?: "admin" | "support"; is_active?: boolean }
): Promise<TeamMember> {
  const res = await fetch(`${API_BASE}/api/admin/team/${id}`, {
    method: "PATCH",
    headers: await getAuthHeaders(),
    body: JSON.stringify(body),
  });
  return handleResponse<TeamMember>(res);
}

export async function resetTeamPassword(
  id: string,
  password: string
): Promise<{ message: string }> {
  const res = await fetch(`${API_BASE}/api/admin/team/${id}/reset-password`, {
    method: "POST",
    headers: await getAuthHeaders(),
    body: JSON.stringify({ password }),
  });
  return handleResponse<{ message: string }>(res);
}

export async function deleteTeamMember(id: string): Promise<{ message: string }> {
  const res = await fetch(`${API_BASE}/api/admin/team/${id}`, {
    method: "DELETE",
    headers: await getAuthHeaders(),
  });
  return handleResponse<{ message: string }>(res);
}

// ========== DASHBOARD ==========

export async function getDashboardStats(): Promise<DashboardStats> {
  const res = await fetch(`${API_BASE}/api/admin/stats`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<DashboardStats>(res);
}

export async function getStatsTimeseries(days = 14): Promise<TimeseriesResponse> {
  const res = await fetch(`${API_BASE}/api/admin/stats/timeseries?days=${days}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<TimeseriesResponse>(res);
}

export async function getInsights(): Promise<InsightsResponse> {
  const res = await fetch(`${API_BASE}/api/admin/stats/insights`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<InsightsResponse>(res);
}

// ========== QUEUE COUNTS (sidebar badges) ==========

export async function getQueueCounts(): Promise<QueueCounts> {
  const res = await fetch(`${API_BASE}/api/admin/queue-counts`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<QueueCounts>(res);
}

// ========== ANALYTICS ==========

export async function getAnalyticsSummary(): Promise<AnalyticsSummary> {
  const res = await fetch(`${API_BASE}/api/admin/analytics/summary`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<AnalyticsSummary>(res);
}

export async function getAnalyticsTimeseries(days = 30): Promise<AnalyticsTimeseries> {
  const res = await fetch(`${API_BASE}/api/admin/analytics/timeseries?days=${days}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<AnalyticsTimeseries>(res);
}

export async function getAnalyticsCategories(): Promise<AnalyticsCategory[]> {
  const res = await fetch(`${API_BASE}/api/admin/analytics/categories`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<AnalyticsCategory[]>(res);
}

export async function getAnalyticsPayouts(): Promise<AnalyticsPayouts> {
  const res = await fetch(`${API_BASE}/api/admin/analytics/payouts`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<AnalyticsPayouts>(res);
}

// ========== USERS ==========

export async function getUsers(type?: "customer" | "tasker", search?: string) {
  const params = new URLSearchParams();
  if (type) params.set("type", type);
  if (search) params.set("search", search);
  
  const res = await fetch(`${API_BASE}/api/admin/users?${params}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<User[]>(res);
}

export async function getUserById(id: string): Promise<User> {
  const res = await fetch(`${API_BASE}/api/admin/users/${id}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<User>(res);
}

export async function getUserOverview(id: string): Promise<UserOverview> {
  const res = await fetch(`${API_BASE}/api/admin/users/${id}/overview`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<UserOverview>(res);
}

export async function updateUser(id: string, data: Partial<User>): Promise<User> {
  const res = await fetch(`${API_BASE}/api/admin/users/${id}`, {
    method: "PATCH",
    headers: await getAuthHeaders(),
    body: JSON.stringify(data),
  });
  return handleResponse<User>(res);
}

export async function deleteUser(id: string): Promise<void> {
  const res = await fetch(`${API_BASE}/api/admin/users/${id}`, {
    method: "DELETE",
    headers: await getAuthHeaders(),
  });
  if (!res.ok) {
    throw new Error("Failed to delete user");
  }
}

export async function suspendUser(id: string): Promise<{ message: string; id: string }> {
  const res = await fetch(`${API_BASE}/api/admin/users/${id}/suspend`, {
    method: "POST",
    headers: await getAuthHeaders(),
  });
  return handleResponse<{ message: string; id: string }>(res);
}

export async function unsuspendUser(id: string): Promise<{ message: string; id: string }> {
  const res = await fetch(`${API_BASE}/api/admin/users/${id}/unsuspend`, {
    method: "POST",
    headers: await getAuthHeaders(),
  });
  return handleResponse<{ message: string; id: string }>(res);
}

export async function verifyUser(id: string): Promise<{ message: string; id: string }> {
  const res = await fetch(`${API_BASE}/api/admin/users/${id}/verify`, {
    method: "POST",
    headers: await getAuthHeaders(),
  });
  return handleResponse<{ message: string; id: string }>(res);
}

export async function unverifyUser(id: string): Promise<{ message: string; id: string }> {
  const res = await fetch(`${API_BASE}/api/admin/users/${id}/unverify`, {
    method: "POST",
    headers: await getAuthHeaders(),
  });
  return handleResponse<{ message: string; id: string }>(res);
}

// ========== ANNOUNCEMENTS ==========

export async function sendAnnouncement(
  data: AnnouncementPayload
): Promise<AnnouncementResult> {
  const res = await fetch(`${API_BASE}/api/admin/announcements`, {
    method: "POST",
    headers: await getAuthHeaders(),
    body: JSON.stringify(data),
  });
  return handleResponse<AnnouncementResult>(res);
}

/**
 * Send a typed, deep-linking notification to one user or an audience. The
 * `type` (e.g. "verify_email", "bonus") tells the app which screen to open when
 * the alert is tapped.
 */
export async function sendNotification(data: {
  title: string;
  body: string;
  type: string;
  audience?: "all" | "customers" | "taskers";
  user_id?: string;
  related_id?: string;
}): Promise<{ message: string; recipients: number; type: string }> {
  const res = await fetch(`${API_BASE}/api/admin/notify`, {
    method: "POST",
    headers: await getAuthHeaders(),
    body: JSON.stringify(data),
  });
  return handleResponse<{ message: string; recipients: number; type: string }>(
    res
  );
}

// ========== TASKS ==========

export async function getTasks(status?: string, search?: string) {
  const params = new URLSearchParams();
  if (status) params.set("status", status);
  if (search) params.set("search", search);
  
  const res = await fetch(`${API_BASE}/api/admin/tasks?${params}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<Task[]>(res);
}

export async function getTaskById(id: string): Promise<Task> {
  const res = await fetch(`${API_BASE}/api/admin/tasks/${id}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<Task>(res);
}

export async function assignTask(taskId: string, taskerId: string): Promise<Task> {
  const res = await fetch(`${API_BASE}/api/admin/tasks/${taskId}/assign`, {
    method: "POST",
    headers: await getAuthHeaders(),
    body: JSON.stringify({ tasker_id: taskerId }),
  });
  return handleResponse<Task>(res);
}

export async function getTaskApplications(taskId: string): Promise<TaskApplication[]> {
  const res = await fetch(`${API_BASE}/api/admin/tasks/${taskId}/applications`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<TaskApplication[]>(res);
}

export async function updateTaskStatus(taskId: string, status: string): Promise<Task> {
  const res = await fetch(`${API_BASE}/api/admin/tasks/${taskId}`, {
    method: "PATCH",
    headers: await getAuthHeaders(),
    body: JSON.stringify({ status }),
  });
  return handleResponse<Task>(res);
}

// ========== REVIEW QUEUE (moderation) ==========

export async function getReviewQueue(): Promise<ReviewTask[]> {
  const res = await fetch(`${API_BASE}/api/admin/review-queue`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<ReviewTask[]>(res);
}

export async function approveTask(
  id: string
): Promise<{ message: string; status: string }> {
  const res = await fetch(`${API_BASE}/api/admin/tasks/${id}/approve`, {
    method: "PATCH",
    headers: await getAuthHeaders(),
  });
  return handleResponse<{ message: string; status: string }>(res);
}

export async function rejectTask(
  id: string,
  reason: string
): Promise<{ message: string; status: string }> {
  const res = await fetch(`${API_BASE}/api/admin/tasks/${id}/reject`, {
    method: "PATCH",
    headers: await getAuthHeaders(),
    body: JSON.stringify({ reason }),
  });
  return handleResponse<{ message: string; status: string }>(res);
}

// ========== SERVICES ==========

export async function getServices(category?: string) {
  const params = new URLSearchParams();
  if (category) params.set("category", category);
  
  const res = await fetch(`${API_BASE}/api/admin/services?${params}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<Service[]>(res);
}

export async function createService(
  data: ServicePayload
): Promise<{ id: string; message: string }> {
  const res = await fetch(`${API_BASE}/api/admin/services`, {
    method: "POST",
    headers: await getAuthHeaders(),
    body: JSON.stringify(data),
  });
  return handleResponse<{ id: string; message: string }>(res);
}

export async function updateService(id: string, data: Partial<Service>): Promise<Service> {
  const res = await fetch(`${API_BASE}/api/admin/services/${id}`, {
    method: "PATCH",
    headers: await getAuthHeaders(),
    body: JSON.stringify(data),
  });
  return handleResponse<Service>(res);
}

export async function deleteService(id: string): Promise<void> {
  const res = await fetch(`${API_BASE}/api/admin/services/${id}`, {
    method: "DELETE",
    headers: await getAuthHeaders(),
  });
  if (!res.ok) {
    if (res.status === 401 && typeof window !== "undefined") {
      localStorage.removeItem("admin_token");
      localStorage.removeItem("admin");
      if (window.location.pathname !== "/login") {
        window.location.href = "/login";
      }
    }
    throw new Error("Failed to delete service");
  }
}

// ========== BOOKINGS ==========

export async function getBookings(status?: string) {
  const params = new URLSearchParams();
  if (status) params.set("status", status);
  
  const res = await fetch(`${API_BASE}/api/admin/bookings?${params}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<Booking[]>(res);
}

export async function cancelBooking(
  id: string
): Promise<{ message: string; refunded: number }> {
  const res = await fetch(`${API_BASE}/api/admin/bookings/${id}/cancel`, {
    method: "POST",
    headers: await getAuthHeaders(),
  });
  return handleResponse<{ message: string; refunded: number }>(res);
}

export async function assignBookingTasker(
  id: string,
  taskerId: string
): Promise<{ message: string; booking_id: string; tasker: { id: string; name: string } }> {
  const res = await fetch(`${API_BASE}/api/admin/bookings/${id}/assign`, {
    method: "POST",
    headers: await getAuthHeaders(),
    body: JSON.stringify({ tasker_id: taskerId }),
  });
  return handleResponse<{
    message: string;
    booking_id: string;
    tasker: { id: string; name: string };
  }>(res);
}

export async function completeBooking(
  id: string
): Promise<{ message: string; booking_id: string }> {
  const res = await fetch(`${API_BASE}/api/admin/bookings/${id}/complete`, {
    method: "POST",
    headers: await getAuthHeaders(),
  });
  return handleResponse<{ message: string; booking_id: string }>(res);
}

// ========== TRANSACTIONS ==========

export async function getTransactions(limit = 50) {
  const res = await fetch(`${API_BASE}/api/admin/transactions?limit=${limit}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<Transaction[]>(res);
}

// ========== WITHDRAWALS ==========

export async function getWithdrawals(status?: string) {
  const params = new URLSearchParams();
  if (status) params.set("status", status);
  
  const res = await fetch(`${API_BASE}/api/admin/withdrawals?${params}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<Withdrawal[]>(res);
}

export async function approveWithdrawal(id: string): Promise<Withdrawal> {
  const res = await fetch(`${API_BASE}/api/admin/withdrawals/${id}/approve`, {
    method: "POST",
    headers: await getAuthHeaders(),
  });
  return handleResponse<Withdrawal>(res);
}

export async function rejectWithdrawal(id: string): Promise<Withdrawal> {
  const res = await fetch(`${API_BASE}/api/admin/withdrawals/${id}/reject`, {
    method: "POST",
    headers: await getAuthHeaders(),
  });
  return handleResponse<Withdrawal>(res);
}

// ========== REVIEWS ==========

export async function getReviews(): Promise<Review[]> {
  const res = await fetch(`${API_BASE}/api/admin/reviews`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<Review[]>(res);
}

export async function deleteReview(id: string): Promise<{ message: string; id: string }> {
  const res = await fetch(`${API_BASE}/api/admin/reviews/${id}`, {
    method: "DELETE",
    headers: await getAuthHeaders(),
  });
  return handleResponse<{ message: string; id: string }>(res);
}

// ========== AUDIT LOGS ==========

export async function getAuditLogs(limit = 100): Promise<AuditLog[]> {
  const res = await fetch(`${API_BASE}/api/admin/audit-logs?limit=${limit}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<AuditLog[]>(res);
}

// ========== SYSTEM ==========

export async function getSystemHealth(): Promise<SystemHealth> {
  const res = await fetch(`${API_BASE}/api/admin/system`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<SystemHealth>(res);
}

// ========== KYC VERIFICATIONS ==========

export async function getKycSubmissions(status?: string): Promise<KycSubmission[]> {
  const params = new URLSearchParams();
  if (status) params.set("status_filter", status);

  const res = await fetch(`${API_BASE}/api/admin/kyc?${params}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<KycSubmission[]>(res);
}

export async function approveKycDocument(
  id: string
): Promise<{ message: string; id: string; auto_verified?: boolean }> {
  const res = await fetch(`${API_BASE}/api/admin/kyc/${id}/approve`, {
    method: "POST",
    headers: await getAuthHeaders(),
  });
  return handleResponse<{ message: string; id: string; auto_verified?: boolean }>(res);
}

export async function rejectKycDocument(
  id: string,
  reason: string
): Promise<{ message: string; id: string }> {
  const res = await fetch(`${API_BASE}/api/admin/kyc/${id}/reject`, {
    method: "POST",
    headers: await getAuthHeaders(),
    body: JSON.stringify({ reason }),
  });
  return handleResponse<{ message: string; id: string }>(res);
}

/**
 * Manually set a tasker's Aadhaar and/or PAN numbers during KYC review.
 * Send a field as "" or omit it to leave the stored value untouched; send a
 * value to overwrite. Only the masked last-4 is returned to the admin/tasker.
 */
export async function setKycNumbers(
  userId: string,
  body: { aadhaar_number?: string; pan_number?: string }
): Promise<KycNumbersResult> {
  const res = await fetch(`${API_BASE}/api/admin/users/${userId}/kyc-numbers`, {
    method: "PATCH",
    headers: await getAuthHeaders(),
    body: JSON.stringify(body),
  });
  return handleResponse<KycNumbersResult>(res);
}

// ========== SUPPORT ==========

export async function getSupportTickets(status?: string): Promise<SupportTicket[]> {
  const params = new URLSearchParams();
  if (status) params.set("status_filter", status);

  const res = await fetch(`${API_BASE}/api/admin/support?${params}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<SupportTicket[]>(res);
}

export async function replySupportTicket(
  id: string,
  reply: string,
  resolve: boolean
): Promise<{ message: string; id: string; status: "open" | "resolved" }> {
  const res = await fetch(`${API_BASE}/api/admin/support/${id}/reply`, {
    method: "POST",
    headers: await getAuthHeaders(),
    body: JSON.stringify({ reply, resolve }),
  });
  return handleResponse<{ message: string; id: string; status: "open" | "resolved" }>(res);
}

// ========== SAFETY REPORTS ==========

export async function getSafetyReports(status?: string): Promise<SafetyReport[]> {
  const params = new URLSearchParams();
  if (status) params.set("status_filter", status);

  const res = await fetch(`${API_BASE}/api/admin/reports?${params}`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<SafetyReport[]>(res);
}

export async function updateReportStatus(
  id: string,
  status: string
): Promise<{ message: string; status: string }> {
  const res = await fetch(`${API_BASE}/api/admin/reports/${id}`, {
    method: "PATCH",
    headers: await getAuthHeaders(),
    body: JSON.stringify({ status }),
  });
  return handleResponse<{ message: string; status: string }>(res);
}

// ========== SETTINGS ==========

export async function getSettings(): Promise<Record<string, string>> {
  const res = await fetch(`${API_BASE}/api/admin/settings`, {
    headers: await getAuthHeaders(),
  });
  return handleResponse<Record<string, string>>(res);
}

export async function updateSettings(
  data: Record<string, string>
): Promise<Record<string, string>> {
  const res = await fetch(`${API_BASE}/api/admin/settings`, {
    method: "PUT",
    headers: await getAuthHeaders(),
    body: JSON.stringify(data),
  });
  return handleResponse<Record<string, string>>(res);
}