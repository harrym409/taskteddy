"use client";

import { useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Drawer } from "@/components/ui/drawer";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { StatusBadge } from "@/components/ui/status-badge";
import { InitialAvatar, PartyCell } from "@/components/ui/avatar";
import { EmptyState, ErrorBanner, Skeleton, SuccessBanner, TableSkeleton } from "@/components/ui/feedback";
import { getUsers, deleteUser, getUserOverview, suspendUser, unsuspendUser, verifyUser, unverifyUser } from "@/lib/api";
import { exportCsv } from "@/lib/csv";
import { formatCurrency, formatDate } from "@/lib/utils";
import { User, UserOverview } from "@/types";
import {
  Search,
  Trash2,
  Eye,
  Users as UsersIcon,
  Star,
  Coins,
  Wallet,
  MailCheck,
  PhoneCall,
  ChevronLeft,
  ChevronRight,
  Download,
  RefreshCw,
  Ban,
  ShieldCheck,
  ShieldOff,
  UserCheck,
  Award,
  CheckCircle2,
  XCircle,
} from "lucide-react";

const PAGE_SIZE = 10;

// Reputation tier colors (chip background). Text is white for legibility.
const REPUTATION_COLORS: Record<string, string> = {
  new: "#94A3B8",
  bronze: "#CD7F32",
  silver: "#9CA3AF",
  gold: "#F5A623",
  pro: "#6384DB",
};

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [typeFilter, setTypeFilter] = useState<"all" | "customer" | "tasker" | "pending_verification">("all");
  const [page, setPage] = useState(1);

  // Delete confirmation state
  const [deleteTarget, setDeleteTarget] = useState<User | null>(null);
  const [deleting, setDeleting] = useState(false);

  // Suspend / reactivate confirmation state
  const [suspendTarget, setSuspendTarget] = useState<{
    user: User;
    action: "suspend" | "unsuspend";
  } | null>(null);
  const [suspending, setSuspending] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);

  // Verify / revoke verification confirmation state
  const [verifyTarget, setVerifyTarget] = useState<{
    user: User;
    action: "verify" | "unverify";
  } | null>(null);
  const [verifying, setVerifying] = useState(false);

  // Drawer state
  const [drawerUser, setDrawerUser] = useState<User | null>(null);
  const [overview, setOverview] = useState<UserOverview | null>(null);
  const [overviewLoading, setOverviewLoading] = useState(false);
  const [overviewError, setOverviewError] = useState<string | null>(null);
  const [drawerTab, setDrawerTab] = useState<"bookings" | "tasks" | "transactions">("bookings");

  const fetchUsers = async (searchOverride?: string) => {
    setLoading(true);
    setError(null);
    try {
      const type =
        typeFilter === "all"
          ? undefined
          : typeFilter === "pending_verification"
            ? "tasker"
            : typeFilter;
      const q = searchOverride ?? search;
      const data = await getUsers(type, q || undefined);
      setUsers(data);
      setPage(1);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load users");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // Support deep-linking / header search via ?q= param.
    if (typeof window !== "undefined") {
      const q = new URLSearchParams(window.location.search).get("q");
      if (q && !search) {
        setSearch(q);
        fetchUsers(q);
        return;
      }
    }
    fetchUsers();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [typeFilter]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    fetchUsers();
  };

  const confirmDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await deleteUser(deleteTarget.id);
      setDeleteTarget(null);
      fetchUsers();
    } catch (err) {
      setDeleteTarget(null);
      setError(err instanceof Error ? err.message : "Failed to delete user");
    } finally {
      setDeleting(false);
    }
  };

  const confirmSuspendAction = async () => {
    if (!suspendTarget) return;
    const { user, action } = suspendTarget;
    setSuspending(true);
    try {
      if (action === "suspend") {
        await suspendUser(user.id);
      } else {
        await unsuspendUser(user.id);
      }
      const newValue = action === "suspend";
      setSuspendTarget(null);
      setNotice(
        action === "suspend"
          ? `${user.name} suspended — they are blocked from logging in`
          : `${user.name} reactivated — they can log in again`
      );
      // Keep the open drawer in sync without a full reload.
      setDrawerUser((u) => (u && u.id === user.id ? { ...u, is_suspended: newValue } : u));
      setOverview((o) =>
        o && o.user.id === user.id
          ? { ...o, user: { ...o.user, is_suspended: newValue } }
          : o
      );
      fetchUsers();
    } catch (err) {
      setSuspendTarget(null);
      setError(
        err instanceof Error
          ? err.message
          : `Failed to ${action === "suspend" ? "suspend" : "reactivate"} user`
      );
    } finally {
      setSuspending(false);
    }
  };

  const confirmVerifyAction = async () => {
    if (!verifyTarget) return;
    const { user, action } = verifyTarget;
    setVerifying(true);
    try {
      if (action === "verify") {
        await verifyUser(user.id);
      } else {
        await unverifyUser(user.id);
      }
      const newValue = action === "verify";
      setVerifyTarget(null);
      setNotice(
        action === "verify"
          ? `${user.name} verified — customers will see a verified badge`
          : `Verification revoked for ${user.name}`
      );
      setDrawerUser((u) => (u && u.id === user.id ? { ...u, is_verified: newValue } : u));
      setOverview((o) =>
        o && o.user.id === user.id
          ? { ...o, user: { ...o.user, is_verified: newValue } }
          : o
      );
      fetchUsers();
    } catch (err) {
      setVerifyTarget(null);
      setError(
        err instanceof Error
          ? err.message
          : `Failed to ${action === "verify" ? "verify" : "revoke verification for"} user`
      );
    } finally {
      setVerifying(false);
    }
  };

  const handleExport = () => {
    exportCsv(
      "users",
      ["ID", "Name", "Email", "Phone", "Type", "Rating", "Wallet Balance", "Suspended", "Verified", "Joined"],
      visibleUsers.map((u) => [
        u.id,
        u.name,
        u.email,
        u.phone,
        u.user_type,
        u.rating > 0 ? u.rating.toFixed(1) : "",
        u.wallet_balance,
        u.is_suspended ? "yes" : "no",
        u.is_verified ? "yes" : "no",
        u.created_at,
      ])
    );
  };

  const openDrawer = (user: User) => {
    setDrawerUser(user);
    setDrawerTab("bookings");
    setOverview(null);
    setOverviewError(null);
    setOverviewLoading(true);
    getUserOverview(user.id)
      .then(setOverview)
      .catch((err) =>
        setOverviewError(err instanceof Error ? err.message : "Failed to load overview")
      )
      .finally(() => setOverviewLoading(false));
  };

  const visibleUsers =
    typeFilter === "pending_verification" ? users.filter((u) => !u.is_verified) : users;
  const totalPages = Math.max(1, Math.ceil(visibleUsers.length / PAGE_SIZE));
  const currentPage = Math.min(page, totalPages);
  const pageStart = (currentPage - 1) * PAGE_SIZE;
  const pageUsers = visibleUsers.slice(pageStart, pageStart + PAGE_SIZE);
  const rangeFrom = visibleUsers.length === 0 ? 0 : pageStart + 1;
  const rangeTo = Math.min(pageStart + PAGE_SIZE, visibleUsers.length);

  const ov = overview;
  // Overview payload may not carry the flag; fall back to the list row.
  const drawerSuspended = ov?.user.is_suspended ?? drawerUser?.is_suspended ?? false;
  const drawerVerified = ov?.user.is_verified ?? drawerUser?.is_verified ?? false;
  const drawerIsTasker = (ov?.user.user_type ?? drawerUser?.user_type) === "tasker";
  // Overview payload may not carry reputation; fall back to the list row.
  const drawerReputation = ov?.user.reputation ?? drawerUser?.reputation ?? null;

  return (
    <AppShell>
      <PageHeader
        title="Users"
        subtitle="Manage customers and taskers across the platform"
        action={
          <>
            <Button variant="outline" size="sm" onClick={() => fetchUsers()}>
              <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
              Refresh
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={handleExport}
              disabled={loading || visibleUsers.length === 0}
            >
              <Download className="mr-1.5 h-3.5 w-3.5" />
              Export CSV
            </Button>
          </>
        }
      />

      {error && <ErrorBanner message={error} onRetry={() => fetchUsers()} />}
      {notice && <SuccessBanner message={notice} onDismiss={() => setNotice(null)} />}

      {/* Filters */}
      <Card className="mb-6">
        <CardContent className="p-4">
          <form onSubmit={handleSearch} className="flex flex-wrap gap-3">
            <div className="relative min-w-56 flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <Input
                placeholder="Search by name, email, or phone..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-10"
              />
            </div>
            <div className="flex overflow-hidden rounded-lg border border-slate-300">
              {(
                [
                  { key: "all", label: "All" },
                  { key: "customer", label: "Customers" },
                  { key: "tasker", label: "Taskers" },
                  { key: "pending_verification", label: "Pending verification" },
                ] as const
              ).map((opt) => (
                <button
                  key={opt.key}
                  type="button"
                  onClick={() => setTypeFilter(opt.key)}
                  className={`px-4 py-2 text-sm font-medium transition-colors ${
                    typeFilter === opt.key
                      ? "bg-[#6384DB] text-white"
                      : "bg-white text-slate-600 hover:bg-slate-50"
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
            <Button type="submit">Search</Button>
          </form>
        </CardContent>
      </Card>

      {/* Users Table */}
      <Card className="overflow-hidden">
        {loading ? (
          <div className="p-6">
            <TableSkeleton rows={6} />
          </div>
        ) : visibleUsers.length === 0 ? (
          <EmptyState
            icon={UsersIcon}
            title="No users found"
            description="Try adjusting your search or filters"
          />
        ) : (
          <>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Phone</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Rating</TableHead>
                  <TableHead>Wallet</TableHead>
                  <TableHead>Joined</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {pageUsers.map((user) => (
                  <TableRow
                    key={user.id}
                    className="cursor-pointer"
                    onClick={() => openDrawer(user)}
                  >
                    <TableCell>
                      <div className="flex items-center gap-2">
                        <PartyCell
                          name={user.name}
                          avatarUrl={user.avatar_url}
                          meta={user.email || user.phone || undefined}
                        />
                        {user.is_verified && <StatusBadge status="verified" />}
                        {user.is_suspended && <StatusBadge status="suspended" />}
                      </div>
                    </TableCell>
                    <TableCell>{user.phone || "-"}</TableCell>
                    <TableCell>
                      <StatusBadge status={user.user_type} />
                    </TableCell>
                    <TableCell>
                      {user.rating > 0 ? (
                        <span className="inline-flex items-center gap-1">
                          <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
                          {user.rating.toFixed(1)}
                        </span>
                      ) : (
                        <span className="text-slate-400">-</span>
                      )}
                    </TableCell>
                    <TableCell className="font-medium text-slate-900">
                      {formatCurrency(user.wallet_balance)}
                    </TableCell>
                    <TableCell className="text-slate-500">
                      {formatDate(user.created_at)}
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-1">
                        <Button
                          variant="ghost"
                          size="icon"
                          title="View details"
                          onClick={(e) => {
                            e.stopPropagation();
                            openDrawer(user);
                          }}
                        >
                          <Eye className="h-4 w-4" />
                        </Button>
                        {user.is_suspended ? (
                          <Button
                            variant="ghost"
                            size="icon"
                            title="Reactivate user"
                            onClick={(e) => {
                              e.stopPropagation();
                              setSuspendTarget({ user, action: "unsuspend" });
                            }}
                          >
                            <UserCheck className="h-4 w-4 text-emerald-600" />
                          </Button>
                        ) : (
                          <Button
                            variant="ghost"
                            size="icon"
                            title="Suspend user"
                            onClick={(e) => {
                              e.stopPropagation();
                              setSuspendTarget({ user, action: "suspend" });
                            }}
                          >
                            <Ban className="h-4 w-4 text-red-500" />
                          </Button>
                        )}
                        {user.user_type === "tasker" &&
                          (user.is_verified ? (
                            <Button
                              variant="ghost"
                              size="icon"
                              title="Revoke verification"
                              onClick={(e) => {
                                e.stopPropagation();
                                setVerifyTarget({ user, action: "unverify" });
                              }}
                            >
                              <ShieldOff className="h-4 w-4 text-slate-400" />
                            </Button>
                          ) : (
                            <Button
                              variant="ghost"
                              size="icon"
                              title="Verify tasker"
                              onClick={(e) => {
                                e.stopPropagation();
                                setVerifyTarget({ user, action: "verify" });
                              }}
                            >
                              <ShieldCheck className="h-4 w-4 text-emerald-600" />
                            </Button>
                          ))}
                        <Button
                          variant="ghost"
                          size="icon"
                          title="Delete user"
                          onClick={(e) => {
                            e.stopPropagation();
                            setDeleteTarget(user);
                          }}
                        >
                          <Trash2 className="h-4 w-4 text-slate-400" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>

            {/* Pagination */}
            <div className="flex items-center justify-between border-t border-slate-100 px-4 py-3">
              <p className="text-sm text-slate-500">
                {rangeFrom}&ndash;{rangeTo} of {visibleUsers.length}
              </p>
              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  disabled={currentPage <= 1}
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                >
                  <ChevronLeft className="mr-1 h-4 w-4" />
                  Prev
                </Button>
                <span className="text-sm text-slate-500">
                  Page {currentPage} of {totalPages}
                </span>
                <Button
                  variant="outline"
                  size="sm"
                  disabled={currentPage >= totalPages}
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                >
                  Next
                  <ChevronRight className="ml-1 h-4 w-4" />
                </Button>
              </div>
            </div>
          </>
        )}
      </Card>

      {/* Delete confirmation */}
      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete user"
        message={
          <>
            Are you sure you want to delete{" "}
            <span className="font-semibold text-slate-900">
              {deleteTarget?.name || "this user"}
            </span>
            ? This action cannot be undone.
          </>
        }
        confirmLabel="Delete user"
        loading={deleting}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={confirmDelete}
      />

      {/* Suspend / reactivate confirmation */}
      <ConfirmDialog
        open={!!suspendTarget}
        title={suspendTarget?.action === "suspend" ? "Suspend user" : "Reactivate user"}
        variant={suspendTarget?.action === "suspend" ? "danger" : "primary"}
        message={
          suspendTarget?.action === "suspend" ? (
            <>
              Suspend{" "}
              <span className="font-semibold text-slate-900">
                {suspendTarget?.user.name}
              </span>
              ? The user will be blocked from logging in until reactivated.
            </>
          ) : (
            <>
              Reactivate{" "}
              <span className="font-semibold text-slate-900">
                {suspendTarget?.user.name}
              </span>
              ? The user will be able to log in again.
            </>
          )
        }
        confirmLabel={suspendTarget?.action === "suspend" ? "Suspend user" : "Reactivate"}
        loading={suspending}
        onCancel={() => setSuspendTarget(null)}
        onConfirm={confirmSuspendAction}
      />

      {/* Verify / revoke confirmation */}
      <ConfirmDialog
        open={!!verifyTarget}
        title={verifyTarget?.action === "verify" ? "Verify tasker" : "Revoke verification"}
        variant={verifyTarget?.action === "verify" ? "primary" : "danger"}
        message={
          verifyTarget?.action === "verify" ? (
            <>
              Customers will see a verified badge on{" "}
              <strong className="text-slate-900">{verifyTarget?.user.name}</strong>.
            </>
          ) : (
            <>
              <strong className="text-slate-900">{verifyTarget?.user.name}</strong> will
              lose their verified badge.
            </>
          )
        }
        confirmLabel={verifyTarget?.action === "verify" ? "Verify" : "Revoke"}
        loading={verifying}
        onCancel={() => setVerifyTarget(null)}
        onConfirm={confirmVerifyAction}
      />

      {/* User 360 Drawer */}
      <Drawer open={!!drawerUser} onClose={() => setDrawerUser(null)} title="User overview">
        {overviewLoading ? (
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <Skeleton className="h-14 w-14 rounded-full" />
              <div className="flex-1 space-y-2">
                <Skeleton className="h-4 w-1/2" />
                <Skeleton className="h-3 w-1/3" />
              </div>
            </div>
            <Skeleton className="h-20 w-full" />
            <Skeleton className="h-40 w-full" />
          </div>
        ) : overviewError ? (
          <ErrorBanner
            message={overviewError}
            onRetry={() => drawerUser && openDrawer(drawerUser)}
          />
        ) : ov ? (
          <div className="space-y-5">
            {/* Profile header */}
            <div className="flex items-start gap-3">
              <div className="relative">
                <InitialAvatar name={ov.user.name} avatarUrl={ov.user.avatar_url} size="lg" />
                <span
                  className={`absolute bottom-0.5 right-0.5 h-3 w-3 rounded-full border-2 border-white ${
                    ov.user.is_online ? "bg-emerald-500" : "bg-slate-300"
                  }`}
                  title={ov.user.is_online ? "Online" : "Offline"}
                />
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2">
                  <p className="truncate text-base font-semibold text-slate-900">
                    {ov.user.name}
                  </p>
                  <StatusBadge status={ov.user.user_type} />
                  {drawerVerified && <StatusBadge status="verified" />}
                  {drawerSuspended && <StatusBadge status="suspended" />}
                </div>
                <p className="truncate text-sm text-slate-500">
                  {ov.user.email || ov.user.phone || "No contact info"}
                </p>
                {ov.user.location && (
                  <p className="truncate text-xs text-slate-400">{ov.user.location}</p>
                )}
              </div>
            </div>

            {/* Verification badges */}
            <div className="flex flex-wrap gap-2">
              <span
                className={`flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium ${
                  ov.user.email_verified
                    ? "bg-emerald-50 text-emerald-700"
                    : "bg-slate-100 text-slate-500"
                }`}
              >
                <MailCheck className="h-3 w-3" />
                Email {ov.user.email_verified ? "verified" : "unverified"}
              </span>
              <span
                className={`flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium ${
                  ov.user.phone_verified
                    ? "bg-emerald-50 text-emerald-700"
                    : "bg-slate-100 text-slate-500"
                }`}
              >
                <PhoneCall className="h-3 w-3" />
                Phone {ov.user.phone_verified ? "verified" : "unverified"}
              </span>
            </div>

            {/* Account actions */}
            <div className="flex gap-2">
              {drawerSuspended ? (
                <Button
                  variant="outline"
                  size="sm"
                  className="flex-1"
                  onClick={() =>
                    drawerUser && setSuspendTarget({ user: drawerUser, action: "unsuspend" })
                  }
                >
                  <UserCheck className="mr-1.5 h-4 w-4 text-emerald-600" />
                  Reactivate account
                </Button>
              ) : (
                <Button
                  variant="outline"
                  size="sm"
                  className="flex-1 border-red-200 text-red-600 hover:bg-red-50"
                  onClick={() =>
                    drawerUser && setSuspendTarget({ user: drawerUser, action: "suspend" })
                  }
                >
                  <Ban className="mr-1.5 h-4 w-4" />
                  Suspend account
                </Button>
              )}
              {drawerIsTasker &&
                (drawerVerified ? (
                  <Button
                    variant="outline"
                    size="sm"
                    className="flex-1"
                    onClick={() =>
                      drawerUser && setVerifyTarget({ user: drawerUser, action: "unverify" })
                    }
                  >
                    <ShieldOff className="mr-1.5 h-4 w-4 text-slate-400" />
                    Revoke verification
                  </Button>
                ) : (
                  <Button
                    variant="outline"
                    size="sm"
                    className="flex-1 border-emerald-200 text-emerald-700 hover:bg-emerald-50"
                    onClick={() =>
                      drawerUser && setVerifyTarget({ user: drawerUser, action: "verify" })
                    }
                  >
                    <ShieldCheck className="mr-1.5 h-4 w-4" />
                    Verify tasker
                  </Button>
                ))}
            </div>

            {/* Wallet / coins / rating */}
            <div className="grid grid-cols-3 gap-2">
              <div className="rounded-lg border border-slate-200 p-3 text-center">
                <Wallet className="mx-auto mb-1 h-4 w-4 text-[#6384DB]" />
                <p className="text-sm font-semibold text-slate-900">
                  {formatCurrency(ov.user.wallet_balance)}
                </p>
                <p className="text-[10px] uppercase tracking-wide text-slate-400">Wallet</p>
              </div>
              <div className="rounded-lg border border-slate-200 p-3 text-center">
                <Coins className="mx-auto mb-1 h-4 w-4 text-[#6384DB]" />
                <p className="text-sm font-semibold text-slate-900">{ov.user.coins}</p>
                <p className="text-[10px] uppercase tracking-wide text-slate-400">Coins</p>
              </div>
              <div className="rounded-lg border border-slate-200 p-3 text-center">
                <Star className="mx-auto mb-1 h-4 w-4 text-[#6384DB]" />
                <p className="text-sm font-semibold text-slate-900">
                  {ov.user.rating > 0 ? ov.user.rating.toFixed(1) : "-"}
                </p>
                <p className="text-[10px] uppercase tracking-wide text-slate-400">
                  {ov.user.total_reviews} reviews
                </p>
              </div>
            </div>

            {/* Tasker reputation */}
            {drawerIsTasker && drawerReputation && (
              <div className="rounded-lg border border-slate-200 p-3">
                <div className="mb-3 flex items-center justify-between gap-2">
                  <span className="inline-flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-slate-400">
                    <Award className="h-3.5 w-3.5" />
                    Reputation
                  </span>
                  <span
                    className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold text-white"
                    style={{
                      backgroundColor:
                        REPUTATION_COLORS[drawerReputation.level] ??
                        REPUTATION_COLORS.new,
                    }}
                  >
                    {drawerReputation.level_label}
                  </span>
                </div>
                <div className="grid grid-cols-3 gap-2 text-center">
                  <div>
                    <p className="text-sm font-semibold text-slate-900">
                      {Math.round(drawerReputation.reliability)}%
                    </p>
                    <p className="text-[10px] uppercase tracking-wide text-slate-400">
                      Reliability
                    </p>
                  </div>
                  <div>
                    <p className="inline-flex items-center gap-1 text-sm font-semibold text-slate-900">
                      <CheckCircle2 className="h-3.5 w-3.5 text-emerald-500" />
                      {drawerReputation.completed_tasks}
                    </p>
                    <p className="text-[10px] uppercase tracking-wide text-slate-400">
                      Completed
                    </p>
                  </div>
                  <div>
                    <p className="inline-flex items-center gap-1 text-sm font-semibold text-slate-900">
                      <XCircle className="h-3.5 w-3.5 text-red-500" />
                      {drawerReputation.cancel_count}
                    </p>
                    <p className="text-[10px] uppercase tracking-wide text-slate-400">
                      Cancelled
                    </p>
                  </div>
                </div>
                {drawerReputation.next_level_at != null && (
                  <p className="mt-2 text-center text-[11px] text-slate-400">
                    {drawerReputation.next_level_at} completed jobs to next level
                  </p>
                )}
              </div>
            )}

            {/* Stats line */}
            <p className="text-xs text-slate-500">
              {ov.stats.reviews_received} reviews received · avg{" "}
              {ov.stats.avg_rating_received > 0
                ? ov.stats.avg_rating_received.toFixed(1)
                : "-"}{" "}
              · {ov.stats.pending_withdrawals} pending withdrawal
              {ov.stats.pending_withdrawals === 1 ? "" : "s"} · joined{" "}
              {formatDate(ov.user.created_at)}
            </p>

            {/* Tabs */}
            <div className="flex gap-1 rounded-lg bg-slate-100 p-1">
              {(
                [
                  { key: "bookings", label: `Bookings (${ov.bookings.length})` },
                  { key: "tasks", label: `Tasks (${ov.tasks.length})` },
                  { key: "transactions", label: `Txns (${ov.transactions.length})` },
                ] as const
              ).map((tab) => (
                <button
                  key={tab.key}
                  onClick={() => setDrawerTab(tab.key)}
                  className={`flex-1 rounded-md px-2 py-1.5 text-xs font-medium transition-colors ${
                    drawerTab === tab.key
                      ? "bg-white text-slate-900 shadow-sm"
                      : "text-slate-500 hover:text-slate-700"
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>

            {/* Tab content */}
            <div className="space-y-2">
              {drawerTab === "bookings" &&
                (ov.bookings.length === 0 ? (
                  <p className="py-4 text-center text-sm text-slate-500">No bookings</p>
                ) : (
                  ov.bookings.map((b) => (
                    <div
                      key={b.id}
                      className="flex items-center justify-between rounded-lg border border-slate-200 p-3"
                    >
                      <div className="min-w-0">
                        <p className="truncate text-sm font-medium text-slate-900">
                          {b.service_name}
                        </p>
                        <p className="text-xs text-slate-500">{formatDate(b.scheduled_at)}</p>
                      </div>
                      <div className="ml-3 shrink-0 text-right">
                        <p className="text-sm font-semibold text-slate-900">
                          {formatCurrency(b.total_amount)}
                        </p>
                        <StatusBadge status={b.status} className="mt-0.5" />
                      </div>
                    </div>
                  ))
                ))}

              {drawerTab === "tasks" &&
                (ov.tasks.length === 0 ? (
                  <p className="py-4 text-center text-sm text-slate-500">No tasks</p>
                ) : (
                  ov.tasks.map((t) => (
                    <div
                      key={t.id}
                      className="flex items-center justify-between rounded-lg border border-slate-200 p-3"
                    >
                      <div className="min-w-0">
                        <p className="truncate text-sm font-medium text-slate-900">{t.title}</p>
                        <p className="text-xs capitalize text-slate-500">
                          {t.role} · {formatDate(t.created_at)}
                        </p>
                      </div>
                      <div className="ml-3 shrink-0 text-right">
                        <p className="text-sm font-semibold text-slate-900">
                          {formatCurrency(t.budget)}
                        </p>
                        <StatusBadge status={t.status} className="mt-0.5" />
                      </div>
                    </div>
                  ))
                ))}

              {drawerTab === "transactions" &&
                (ov.transactions.length === 0 ? (
                  <p className="py-4 text-center text-sm text-slate-500">No transactions</p>
                ) : (
                  ov.transactions.map((tx) => (
                    <div
                      key={tx.id}
                      className="flex items-center justify-between rounded-lg border border-slate-200 p-3"
                    >
                      <div className="min-w-0">
                        <p className="truncate text-sm font-medium capitalize text-slate-900">
                          {tx.type}
                        </p>
                        <p className="truncate text-xs text-slate-500">
                          {tx.description || formatDate(tx.created_at)}
                        </p>
                      </div>
                      <p
                        className={`ml-3 shrink-0 text-sm font-semibold ${
                          tx.amount > 0 ? "text-emerald-600" : "text-red-600"
                        }`}
                      >
                        {tx.amount > 0 ? "+" : ""}
                        {formatCurrency(tx.amount)}
                      </p>
                    </div>
                  ))
                ))}
            </div>
          </div>
        ) : null}
      </Drawer>
    </AppShell>
  );
}
