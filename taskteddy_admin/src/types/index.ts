// Tasker reputation (public serializer)
export type ReputationLevel = "new" | "bronze" | "silver" | "gold" | "pro";

export interface Reputation {
  level: ReputationLevel;
  level_label: string;
  reliability: number;
  completed_tasks: number;
  cancel_count: number;
  next_level_at: number | null;
}

// User types
export interface User {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  user_type: "customer" | "tasker";
  title: string | null;
  gender: string | null;
  avatar_url: string | null;
  location: string | null;
  bio: string | null;
  rating: number;
  total_reviews: number;
  coins: number;
  wallet_balance: number;
  is_online: boolean;
  is_suspended?: boolean;
  is_verified?: boolean;
  email_verified: boolean;
  phone_verified: boolean;
  completed_tasks?: number;
  reputation?: Reputation | null;
  created_at: string;
  updated_at: string;
}

// Task types
export interface Task {
  id: string;
  title: string;
  description: string;
  category: string;
  budget: number;
  location: string;
  deadline: string;
  images: string[];
  status:
    | "open"
    | "assigned"
    | "inProgress"
    | "completed"
    | "cancelled"
    | "pending_review"
    | "rejected";
  posted_by: User | null;
  assigned_to: User | null;
  applicants_count: number;
  completion_otp: string | null;
  review_reason?: string | null;
  cancel_reason?: string | null;
  created_at: string;
  updated_at: string;
}

// Review queue (content moderation) types
export interface ReviewTaskPoster {
  name: string;
  email?: string | null;
  phone?: string | null;
}

export interface ReviewTask {
  id: string;
  title: string;
  description: string;
  category: string;
  budget: number;
  location: string;
  images: string[];
  posted_by: ReviewTaskPoster | null;
  created_at: string;
  status: string;
  review_reason: string | null;
}

// Service types
export interface Service {
  id: string;
  name: string;
  emoji: string | null;
  icon_asset: string | null;
  category: string;
  description: string;
  price: number;
  original_price: number;
  rating: number;
  review_count: number;
  is_hot: boolean;
  is_new: boolean;
  includes: string[];
  tasker_id: string;
  is_active: boolean;
  created_at: string;
}

// Booking types
export interface BookingParty {
  id: string;
  name: string;
}

export interface Booking {
  id: string;
  booking_id: string;
  customer_id: string;
  tasker_id: string;
  service_id: string;
  service: {
    id: string;
    name: string;
    price: number;
    category: string;
    emoji: string | null;
  };
  customer: BookingParty | null;
  tasker: BookingParty | null;
  scheduled_at: string;
  address: string;
  notes: string | null;
  status: "pending" | "confirmed" | "completed" | "cancelled";
  total_amount: number;
  paid_with_wallet?: boolean;
  created_at: string;
  updated_at: string;
}

// Review types
export interface Review {
  id: string;
  task_id: string;
  reviewer_id: string;
  reviewed_user_id: string;
  reviewer_name?: string | null;
  reviewed_user_name?: string | null;
  rating: number;
  comment: string;
  created_at: string;
}

// Transaction types
export interface Transaction {
  id: string;
  user_id: string;
  user_name?: string | null;
  type: string;
  amount: number;
  description: string | null;
  task_id: string | null;
  related_user_id: string | null;
  created_at: string;
}

// Withdrawal types
export interface Withdrawal {
  id: string;
  user_id: string;
  user_name?: string | null;
  amount: number;
  method: string;
  details: Record<string, unknown>;
  status: "pending" | "approved" | "rejected" | "completed";
  created_at: string;
}

// Timeseries stats
export interface TimeseriesPoint {
  date: string;
  bookings: number;
  booking_value: number;
  new_users: number;
}

export interface TimeseriesResponse {
  days: number;
  series: TimeseriesPoint[];
}

// User 360 overview
export interface UserOverviewBooking {
  id: string;
  booking_id: string;
  service_name: string;
  scheduled_at: string;
  status: string;
  total_amount: number;
  paid_with_wallet: boolean;
}

export interface UserOverviewTask {
  id: string;
  title: string;
  status: string;
  budget: number;
  role: string;
  created_at: string;
}

export interface UserOverviewTransaction {
  id: string;
  type: string;
  amount: number;
  description: string | null;
  created_at: string;
}

export interface UserOverviewProfile {
  id: string;
  name: string;
  email: string | null;
  phone: string | null;
  user_type: "customer" | "tasker";
  avatar_url: string | null;
  location: string | null;
  bio: string | null;
  rating: number;
  total_reviews: number;
  coins: number;
  wallet_balance: number;
  is_online: boolean;
  is_suspended?: boolean;
  is_verified?: boolean;
  email_verified: boolean;
  phone_verified: boolean;
  completed_tasks?: number;
  reputation?: Reputation | null;
  created_at: string;
  last_login_at: string | null;
}

export interface UserOverview {
  user: UserOverviewProfile;
  bookings: UserOverviewBooking[];
  tasks: UserOverviewTask[];
  transactions: UserOverviewTransaction[];
  stats: {
    reviews_received: number;
    avg_rating_received: number;
    pending_withdrawals: number;
  };
}

// Service create/update payload
export interface ServicePayload {
  name: string;
  emoji: string;
  category: string;
  description: string;
  price: number;
  original_price?: number;
  includes: string[];
  is_hot: boolean;
  is_new: boolean;
}

// Dashboard stats
export interface DashboardStats {
  total_customers: number;
  total_taskers: number;
  total_tasks: number;
  total_bookings: number;
  total_revenue: number;
  pending_withdrawals: number;
}

// Live queue counts (sidebar badges)
export interface QueueCounts {
  review_queue: number;
  flagged_tasks: number;
  safety_reports: number;
  pending_withdrawals: number;
  open_tickets: number;
  total: number;
}

// API Response types
export interface ApiResponse<T> {
  data: T;
  message?: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}

// Announcement types
export type AnnouncementAudience = "all" | "customers" | "taskers";

export interface AnnouncementPayload {
  title: string;
  body: string;
  audience: AnnouncementAudience;
}

export interface AnnouncementResult {
  message: string;
  recipients: number;
  pushed: number;
  audience: string;
}

// Task application types
export interface TaskApplicant {
  id: string;
  name: string;
  rating: number;
  is_verified: boolean;
  avatar_url?: string | null;
}

export interface TaskApplication {
  id: string;
  applicant: TaskApplicant;
  bid_amount: number;
  cover_letter: string;
  status: string;
  created_at: string;
}

// Insights (dashboard)
export interface InsightTopService {
  name: string;
  bookings: number;
  value: number;
}

export interface InsightCategory {
  category: string;
  bookings: number;
}

export interface InsightTopTasker {
  id: string;
  name: string;
  rating: number;
  is_verified: boolean;
  completed_bookings: number;
}

export interface InsightsResponse {
  top_services: InsightTopService[];
  categories: InsightCategory[];
  top_taskers: InsightTopTasker[];
}

// Audit log
export interface AuditLog {
  id: string;
  admin_email: string;
  action: string;
  target_type: string;
  target_id: string;
  detail: string | null;
  created_at: string;
}

// System health
export interface SystemHealth {
  environment: string;
  database: "connected" | "error";
  redis: "connected" | "disabled" | "error";
  counts: {
    users: number;
    services: number;
    bookings: number;
    tasks: number;
    notifications: number;
    audit_logs: number;
  };
  checked_at: string;
}

// KYC verification types
export type KycDocType = "aadhaar" | "pan" | "address" | "selfie";
export type KycDocStatus = "pending" | "approved" | "rejected";

export interface KycDocument {
  id: string;
  doc_type: KycDocType;
  file_url: string;
  status: KycDocStatus;
  reason: string | null;
  updated_at: string;
}

export interface KycSubmissionUser {
  id: string;
  name: string;
  user_type: "customer" | "tasker";
  is_verified: boolean;
  phone: string | null;
}

export interface KycSubmission {
  user: KycSubmissionUser;
  documents: KycDocument[];
}

// Result of manually setting a tasker's Aadhaar/PAN numbers during KYC review.
// Only the masked last-4 is ever returned; the raw numbers are write-only.
export interface KycNumbersResult {
  message: string;
  aadhaar_masked: string | null;
  pan_masked: string | null;
}

// Support ticket types
export interface SupportTicketUser {
  id: string;
  name: string;
  user_type: "customer" | "tasker";
  phone: string | null;
}

export interface SupportTicket {
  id: string;
  user: SupportTicketUser;
  subject: string;
  message: string;
  status: "open" | "resolved";
  reply: string | null;
  created_at: string;
  updated_at: string;
}

// Safety report types
export type ReportStatus = "open" | "reviewed" | "actioned" | "dismissed";

export interface ReportUserBrief {
  id: string;
  name: string;
  user_type: "customer" | "tasker";
  phone: string | null;
  is_suspended: boolean;
}

export interface SafetyReport {
  id: string;
  reason: string;
  detail: string | null;
  status: ReportStatus;
  task_id: string | null;
  created_at: string;
  reporter: ReportUserBrief;
  reported: ReportUserBrief;
}

// Analytics (ops layer)
export interface AnalyticsSummary {
  total_customers: number;
  total_taskers: number;
  verified_taskers: number;
  total_bookings: number;
  completed_bookings: number;
  gmv: number;
  platform_revenue: number;
  commission_percent: number;
  pending_withdrawals: number;
  pending_payout_amount: number;
  bookings_last_7d: number;
  bookings_growth_percent: number;
}

export interface AnalyticsSeriesPoint {
  date: string;
  value: number;
}

export interface AnalyticsTimeseries {
  days: number;
  bookings: AnalyticsSeriesPoint[];
  gmv: AnalyticsSeriesPoint[];
  revenue: AnalyticsSeriesPoint[];
  new_customers: AnalyticsSeriesPoint[];
  new_taskers: AnalyticsSeriesPoint[];
}

export interface AnalyticsCategory {
  category: string;
  count: number;
  value: number;
}

export interface PayoutStatusRollup {
  count: number;
  amount: number;
}

export interface AnalyticsPayouts {
  by_status: Record<string, PayoutStatusRollup>;
  total_paid_out: number;
  total_tasker_earnings: number;
}

// Auth types
export type AdminRole = "superadmin" | "admin" | "support";

export interface Admin {
  id: string;
  email: string;
  name: string;
  role?: AdminRole;
}

export interface TeamMember {
  id: string;
  email: string;
  name: string;
  role: AdminRole;
  is_active: boolean;
  created_at: string;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
  admin: Admin;
}