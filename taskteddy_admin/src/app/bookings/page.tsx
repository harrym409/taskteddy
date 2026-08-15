"use client";

import { useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Drawer } from "@/components/ui/drawer";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { StatusBadge } from "@/components/ui/status-badge";
import { InitialAvatar, PartyCell } from "@/components/ui/avatar";
import { EmptyState, ErrorBanner, SuccessBanner, TableSkeleton } from "@/components/ui/feedback";
import {
  getBookings,
  cancelBooking,
  assignBookingTasker,
  completeBooking,
  getUsers,
} from "@/lib/api";
import { exportCsv } from "@/lib/csv";
import { formatDate, formatCurrency } from "@/lib/utils";
import { Booking, User } from "@/types";
import {
  AlertCircle,
  CalendarCheck,
  Check,
  Download,
  MapPin,
  RefreshCw,
  Search,
  StickyNote,
  UserPlus,
  Wallet,
  X,
} from "lucide-react";

const STATUS_FILTERS = ["all", "pending", "confirmed", "completed", "cancelled"] as const;

function isActionable(b: Booking): boolean {
  return b.status === "pending" || b.status === "confirmed";
}

function isUnassigned(b: Booking): boolean {
  return isActionable(b) && !b.tasker;
}

export default function BookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<Booking | null>(null);

  // Taskers for the assign dropdown
  const [taskers, setTaskers] = useState<User[]>([]);

  // Operations state
  const [showAssign, setShowAssign] = useState(false);
  const [selectedTaskerId, setSelectedTaskerId] = useState("");
  const [assigning, setAssigning] = useState(false);
  const [opsError, setOpsError] = useState<string | null>(null);

  const [cancelTarget, setCancelTarget] = useState<Booking | null>(null);
  const [cancelling, setCancelling] = useState(false);
  const [completeTarget, setCompleteTarget] = useState<Booking | null>(null);
  const [completing, setCompleting] = useState(false);

  const fetchBookings = async (): Promise<Booking[]> => {
    setLoading(true);
    setError(null);
    try {
      const data = await getBookings();
      setBookings(data);
      return data;
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load bookings");
      return [];
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBookings();
    getUsers("tasker")
      .then(setTaskers)
      .catch(() => setTaskers([]));
  }, []);

  /** Refetch the list and keep the drawer in sync with the updated booking. */
  const refreshAfterAction = async (bookingId: string, keepDrawer: boolean) => {
    const data = await fetchBookings();
    if (keepDrawer) {
      setSelected(data.find((b) => b.id === bookingId) ?? null);
    } else {
      setSelected(null);
    }
  };

  const openDrawer = (booking: Booking) => {
    setSelected(booking);
    setShowAssign(false);
    setSelectedTaskerId("");
    setOpsError(null);
  };

  const handleAssign = async () => {
    if (!selected || !selectedTaskerId) return;
    setAssigning(true);
    setOpsError(null);
    try {
      const res = await assignBookingTasker(selected.id, selectedTaskerId);
      setNotice(`Tasker ${res.tasker.name} assigned to ${res.booking_id}`);
      setShowAssign(false);
      setSelectedTaskerId("");
      await refreshAfterAction(selected.id, true);
    } catch (err) {
      setOpsError(err instanceof Error ? err.message : "Failed to assign tasker");
    } finally {
      setAssigning(false);
    }
  };

  const confirmComplete = async () => {
    if (!completeTarget) return;
    setCompleting(true);
    try {
      const res = await completeBooking(completeTarget.id);
      setCompleteTarget(null);
      setNotice(`Booking ${res.booking_id} marked as completed`);
      await refreshAfterAction(completeTarget.id, true);
    } catch (err) {
      setCompleteTarget(null);
      setError(err instanceof Error ? err.message : "Failed to complete booking");
    } finally {
      setCompleting(false);
    }
  };

  const confirmCancel = async () => {
    if (!cancelTarget) return;
    setCancelling(true);
    try {
      const res = await cancelBooking(cancelTarget.id);
      setCancelTarget(null);
      setNotice(
        res.refunded > 0
          ? `Booking ${cancelTarget.booking_id} cancelled — ${formatCurrency(
              res.refunded
            )} refunded to the customer's wallet`
          : `Booking ${cancelTarget.booking_id} cancelled`
      );
      await refreshAfterAction(cancelTarget.id, false);
    } catch (err) {
      setCancelTarget(null);
      setError(err instanceof Error ? err.message : "Failed to cancel booking");
    } finally {
      setCancelling(false);
    }
  };

  const query = search.trim().toLowerCase();
  const matchesQuery = (b: Booking) =>
    !query ||
    b.booking_id.toLowerCase().includes(query) ||
    b.service.name.toLowerCase().includes(query) ||
    (b.customer?.name?.toLowerCase().includes(query) ?? false) ||
    (b.tasker?.name?.toLowerCase().includes(query) ?? false);

  const filtered = bookings
    .filter((b) => statusFilter === "all" || b.status === statusFilter)
    .filter(matchesQuery);

  const countFor = (status: string) =>
    (status === "all"
      ? bookings
      : bookings.filter((b) => b.status === status)
    ).filter(matchesQuery).length;

  const availableTaskers = taskers.filter((t) => !t.is_suspended);

  const handleExport = () => {
    exportCsv(
      "bookings",
      ["Booking ID", "Service", "Category", "Customer", "Tasker", "Scheduled", "Amount", "Status", "Address"],
      filtered.map((b) => [
        b.booking_id,
        b.service.name,
        b.service.category,
        b.customer?.name,
        b.tasker?.name,
        b.scheduled_at,
        b.total_amount,
        b.status,
        b.address,
      ])
    );
  };

  const assignOpen = selected ? isUnassigned(selected) || showAssign : false;

  return (
    <AppShell>
      <PageHeader
        title="Bookings"
        subtitle="Track and manage service bookings across the platform"
        action={
          <>
            <Button variant="outline" size="sm" onClick={fetchBookings}>
              <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
              Refresh
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={handleExport}
              disabled={loading || filtered.length === 0}
            >
              <Download className="mr-1.5 h-3.5 w-3.5" />
              Export CSV
            </Button>
          </>
        }
      />

      {error && <ErrorBanner message={error} onRetry={fetchBookings} />}
      {notice && <SuccessBanner message={notice} onDismiss={() => setNotice(null)} />}

      {/* Search */}
      <div className="mb-4">
        <div className="relative max-w-md">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <Input
            placeholder="Search by booking ID, service, customer, or tasker..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-10"
          />
        </div>
      </div>

      {/* Status filter row */}
      <div className="mb-6 flex flex-wrap gap-2">
        {STATUS_FILTERS.map((status) => (
          <button
            key={status}
            onClick={() => setStatusFilter(status)}
            className={`rounded-full px-4 py-1.5 text-sm font-medium capitalize transition-colors ${
              statusFilter === status
                ? "bg-[#6384DB] text-white shadow-sm"
                : "border border-slate-300 bg-white text-slate-600 hover:bg-slate-50"
            }`}
          >
            {status === "all" ? "All" : status}
            <span
              className={`ml-1.5 text-xs ${
                statusFilter === status ? "text-white/80" : "text-slate-400"
              }`}
            >
              {countFor(status)}
            </span>
          </button>
        ))}
      </div>

      {/* Bookings Table */}
      <Card className="overflow-hidden">
        {loading ? (
          <div className="p-6">
            <TableSkeleton rows={6} />
          </div>
        ) : filtered.length === 0 ? (
          <EmptyState
            icon={CalendarCheck}
            title="No bookings found"
            description={
              statusFilter === "all"
                ? "Bookings will appear here as customers book services"
                : `No ${statusFilter} bookings`
            }
          />
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Booking ID</TableHead>
                <TableHead>Service</TableHead>
                <TableHead>Customer</TableHead>
                <TableHead>Tasker</TableHead>
                <TableHead>Scheduled</TableHead>
                <TableHead>Amount</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filtered.map((booking) => (
                <TableRow
                  key={booking.id}
                  className="cursor-pointer"
                  onClick={() => openDrawer(booking)}
                >
                  <TableCell className="font-mono text-xs text-slate-500">
                    {booking.booking_id}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      {booking.service.emoji && <span>{booking.service.emoji}</span>}
                      <span className="font-medium text-slate-900">
                        {booking.service.name}
                      </span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <PartyCell name={booking.customer?.name} size="sm" />
                  </TableCell>
                  <TableCell>
                    {isUnassigned(booking) ? (
                      <StatusBadge status="unassigned" />
                    ) : (
                      <PartyCell name={booking.tasker?.name} size="sm" />
                    )}
                  </TableCell>
                  <TableCell className="text-slate-500">
                    {formatDate(booking.scheduled_at)}
                  </TableCell>
                  <TableCell className="font-medium text-slate-900">
                    {formatCurrency(booking.total_amount)}
                  </TableCell>
                  <TableCell>
                    <StatusBadge status={booking.status} />
                  </TableCell>
                  <TableCell className="text-right">
                    {isActionable(booking) && (
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={(e) => {
                          e.stopPropagation();
                          setCancelTarget(booking);
                        }}
                      >
                        <X className="mr-1 h-4 w-4" />
                        Cancel
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Card>

      {/* Cancel confirmation */}
      <ConfirmDialog
        open={!!cancelTarget}
        title="Cancel booking"
        message={
          <>
            Are you sure you want to cancel booking{" "}
            <span className="font-mono font-semibold text-slate-900">
              {cancelTarget?.booking_id}
            </span>
            ? The customer and tasker will be notified.
            {cancelTarget?.paid_with_wallet && (
              <>
                {" "}
                <span className="font-semibold text-slate-900">
                  {formatCurrency(cancelTarget.total_amount)}
                </span>{" "}
                will be refunded to the customer&apos;s wallet.
              </>
            )}
          </>
        }
        confirmLabel="Cancel booking"
        cancelLabel="Keep booking"
        loading={cancelling}
        onCancel={() => setCancelTarget(null)}
        onConfirm={confirmCancel}
      />

      {/* Complete confirmation */}
      <ConfirmDialog
        open={!!completeTarget}
        title="Mark booking completed"
        variant="primary"
        message={
          <>
            Mark booking{" "}
            <span className="font-mono font-semibold text-slate-900">
              {completeTarget?.booking_id}
            </span>{" "}
            as completed? This confirms the service was delivered.
          </>
        }
        confirmLabel="Mark completed"
        loading={completing}
        onCancel={() => setCompleteTarget(null)}
        onConfirm={confirmComplete}
      />

      {/* Booking details drawer */}
      <Drawer
        open={!!selected}
        onClose={() => setSelected(null)}
        title={
          selected ? (
            <span className="font-mono text-sm">{selected.booking_id}</span>
          ) : (
            "Booking"
          )
        }
      >
        {selected && (
          <div className="space-y-5">
            {/* Service */}
            <div className="flex items-center justify-between rounded-lg border border-slate-200 p-4">
              <div className="flex items-center gap-3">
                {selected.service.emoji && (
                  <span className="text-2xl">{selected.service.emoji}</span>
                )}
                <div>
                  <p className="text-sm font-semibold text-slate-900">
                    {selected.service.name}
                  </p>
                  <p className="text-xs capitalize text-slate-500">
                    {selected.service.category}
                  </p>
                </div>
              </div>
              <StatusBadge status={selected.status} />
            </div>

            {/* Parties */}
            <div className="grid grid-cols-2 gap-2">
              <div className="rounded-lg border border-slate-200 p-3">
                <p className="mb-1.5 text-[10px] uppercase tracking-wide text-slate-400">
                  Customer
                </p>
                <PartyCell name={selected.customer?.name} size="sm" />
              </div>
              <div className="rounded-lg border border-slate-200 p-3">
                <p className="mb-1.5 text-[10px] uppercase tracking-wide text-slate-400">
                  Tasker
                </p>
                {isUnassigned(selected) ? (
                  <StatusBadge status="unassigned" />
                ) : (
                  <PartyCell name={selected.tasker?.name} size="sm" />
                )}
              </div>
            </div>

            {/* Schedule / address / notes */}
            <div className="space-y-3 text-sm">
              <div className="flex items-start gap-2">
                <CalendarCheck className="mt-0.5 h-4 w-4 shrink-0 text-slate-400" />
                <div>
                  <p className="text-xs text-slate-400">Scheduled</p>
                  <p className="text-slate-900">{formatDate(selected.scheduled_at)}</p>
                </div>
              </div>
              <div className="flex items-start gap-2">
                <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-slate-400" />
                <div>
                  <p className="text-xs text-slate-400">Address</p>
                  <p className="text-slate-900">{selected.address || "-"}</p>
                </div>
              </div>
              {selected.notes && (
                <div className="flex items-start gap-2">
                  <StickyNote className="mt-0.5 h-4 w-4 shrink-0 text-slate-400" />
                  <div>
                    <p className="text-xs text-slate-400">Notes</p>
                    <p className="text-slate-900">{selected.notes}</p>
                  </div>
                </div>
              )}
            </div>

            {/* Amount */}
            <div className="flex items-center justify-between rounded-lg bg-slate-50 p-4">
              <div>
                <p className="text-xs text-slate-500">Total amount</p>
                <p className="text-lg font-bold text-slate-900">
                  {formatCurrency(selected.total_amount)}
                </p>
              </div>
              {selected.paid_with_wallet && (
                <span className="flex items-center gap-1 rounded-full bg-[#6384DB]/10 px-2.5 py-1 text-xs font-medium text-[#6384DB]">
                  <Wallet className="h-3 w-3" />
                  Paid with wallet
                </span>
              )}
            </div>

            {/* Operations */}
            {isActionable(selected) && (
              <div className="space-y-3 rounded-lg border border-slate-200 p-4">
                <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                  Operations
                </p>

                {opsError && (
                  <div className="flex items-center gap-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700">
                    <AlertCircle className="h-3.5 w-3.5 shrink-0" />
                    {opsError}
                  </div>
                )}

                {/* Assigned tasker + reassign affordance */}
                {selected.tasker && !showAssign && (
                  <div className="flex items-center justify-between gap-2 rounded-lg bg-slate-50 p-3">
                    <div className="flex min-w-0 items-center gap-2.5">
                      <InitialAvatar name={selected.tasker.name} size="sm" />
                      <div className="min-w-0">
                        <p className="truncate text-sm font-medium text-slate-900">
                          {selected.tasker.name}
                        </p>
                        <p className="text-xs text-slate-500">Assigned tasker</p>
                      </div>
                    </div>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => {
                        setShowAssign(true);
                        setSelectedTaskerId("");
                        setOpsError(null);
                      }}
                    >
                      Reassign
                    </Button>
                  </div>
                )}

                {/* Assign / reassign dropdown */}
                {assignOpen && (
                  <div className="space-y-2">
                    <label
                      htmlFor="booking-tasker"
                      className="text-sm font-medium text-slate-700"
                    >
                      {selected.tasker ? "Reassign tasker" : "Assign tasker"}
                    </label>
                    <div className="flex gap-2">
                      <select
                        id="booking-tasker"
                        value={selectedTaskerId}
                        onChange={(e) => setSelectedTaskerId(e.target.value)}
                        className="min-w-0 flex-1 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-700 focus:border-[#6384DB] focus:outline-none focus:ring-2 focus:ring-[#6384DB]/25"
                      >
                        <option value="">Select a tasker...</option>
                        {availableTaskers.map((t) => (
                          <option key={t.id} value={t.id}>
                            {t.name}
                            {t.rating > 0 ? ` (${t.rating.toFixed(1)} rating)` : ""}
                          </option>
                        ))}
                      </select>
                      <Button
                        onClick={handleAssign}
                        disabled={!selectedTaskerId || assigning}
                      >
                        <UserPlus className="mr-1 h-4 w-4" />
                        {assigning ? "Assigning..." : selected.tasker ? "Reassign" : "Assign"}
                      </Button>
                    </div>
                    {selected.tasker && (
                      <button
                        type="button"
                        onClick={() => setShowAssign(false)}
                        className="text-xs font-medium text-slate-500 hover:text-slate-700"
                      >
                        Keep current tasker
                      </button>
                    )}
                    {availableTaskers.length === 0 && (
                      <p className="text-xs text-slate-400">
                        No active taskers available to assign.
                      </p>
                    )}
                  </div>
                )}

                <div className="flex gap-2 border-t border-slate-100 pt-3">
                  <Button
                    className="flex-1"
                    onClick={() => setCompleteTarget(selected)}
                  >
                    <Check className="mr-1 h-4 w-4" />
                    Mark completed
                  </Button>
                  <Button
                    variant="destructive"
                    className="flex-1"
                    onClick={() => setCancelTarget(selected)}
                  >
                    <X className="mr-1 h-4 w-4" />
                    Cancel booking
                  </Button>
                </div>
              </div>
            )}
          </div>
        )}
      </Drawer>
    </AppShell>
  );
}
