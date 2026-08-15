"use client";

import { useCallback, useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Drawer } from "@/components/ui/drawer";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { StatusBadge } from "@/components/ui/status-badge";
import { InitialAvatar, PartyCell } from "@/components/ui/avatar";
import {
  EmptyState,
  ErrorBanner,
  SuccessBanner,
  TableSkeleton,
} from "@/components/ui/feedback";
import {
  cancelBooking,
  getBookings,
  getSupportTickets,
  replySupportTicket,
} from "@/lib/api";
import { formatCurrency, formatDate } from "@/lib/utils";
import { Booking, SupportTicket } from "@/types";
import {
  CalendarCheck,
  LifeBuoy,
  MessageSquareReply,
  RefreshCw,
  Send,
  Undo2,
  Wallet,
  X,
} from "lucide-react";

const TABS = [
  { key: "refunds", label: "Refunds & cancellations", icon: Undo2 },
  { key: "tickets", label: "Open tickets", icon: LifeBuoy },
] as const;
type Tab = (typeof TABS)[number]["key"];

function isRefundable(b: Booking): boolean {
  return b.status === "pending" || b.status === "confirmed";
}

export default function DisputesPage() {
  const [tab, setTab] = useState<Tab>("refunds");
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  // Bookings
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [bookingsLoading, setBookingsLoading] = useState(true);
  const [cancelTarget, setCancelTarget] = useState<Booking | null>(null);
  const [cancelling, setCancelling] = useState(false);

  // Tickets
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [ticketsLoading, setTicketsLoading] = useState(true);
  const [selected, setSelected] = useState<SupportTicket | null>(null);
  const [replyText, setReplyText] = useState("");
  const [resolveOnReply, setResolveOnReply] = useState(true);
  const [confirmingReply, setConfirmingReply] = useState(false);
  const [sending, setSending] = useState(false);
  const [replyError, setReplyError] = useState<string | null>(null);

  const fetchBookings = useCallback(async (): Promise<Booking[]> => {
    setBookingsLoading(true);
    setError(null);
    try {
      const data = await getBookings();
      const refundable = data.filter(isRefundable);
      setBookings(refundable);
      return refundable;
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load bookings");
      return [];
    } finally {
      setBookingsLoading(false);
    }
  }, []);

  const fetchTickets = useCallback(async (): Promise<SupportTicket[]> => {
    setTicketsLoading(true);
    setError(null);
    try {
      const data = await getSupportTickets("open");
      setTickets(data);
      return data;
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load tickets");
      return [];
    } finally {
      setTicketsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchBookings();
    fetchTickets();
  }, [fetchBookings, fetchTickets]);

  const confirmCancel = async () => {
    if (!cancelTarget) return;
    setCancelling(true);
    try {
      const res = await cancelBooking(cancelTarget.id);
      const id = cancelTarget.booking_id;
      setCancelTarget(null);
      setNotice(
        res.refunded > 0
          ? `Booking ${id} cancelled — ${formatCurrency(
              res.refunded
            )} refunded to the customer's wallet`
          : `Booking ${id} cancelled`
      );
      await fetchBookings();
    } catch (err) {
      setCancelTarget(null);
      setError(err instanceof Error ? err.message : "Failed to cancel booking");
    } finally {
      setCancelling(false);
    }
  };

  const openTicket = (ticket: SupportTicket) => {
    setSelected(ticket);
    setReplyText("");
    setResolveOnReply(true);
    setReplyError(null);
  };

  const confirmReply = async () => {
    if (!selected || !replyText.trim()) return;
    setSending(true);
    setReplyError(null);
    try {
      const res = await replySupportTicket(selected.id, replyText.trim(), resolveOnReply);
      setConfirmingReply(false);
      setNotice(res.status === "resolved" ? "Reply sent and ticket resolved" : "Reply sent");
      const data = await fetchTickets();
      const updated = data.find((t) => t.id === selected.id);
      if (updated) {
        setSelected(updated);
      } else {
        // Resolved tickets drop out of the open list — close the drawer.
        setSelected(null);
      }
      setReplyText("");
    } catch (err) {
      setConfirmingReply(false);
      setReplyError(err instanceof Error ? err.message : "Failed to send reply");
    } finally {
      setSending(false);
    }
  };

  const replyValid = replyText.trim().length > 0;

  return (
    <AppShell>
      <PageHeader
        title="Dispute & refund center"
        subtitle="Cancel or refund bookings and resolve open support tickets in one place"
        action={
          <Button
            variant="outline"
            size="sm"
            onClick={() => {
              fetchBookings();
              fetchTickets();
            }}
          >
            <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
            Refresh
          </Button>
        }
      />

      {error && (
        <ErrorBanner
          message={error}
          onRetry={() => {
            fetchBookings();
            fetchTickets();
          }}
        />
      )}
      {notice && <SuccessBanner message={notice} onDismiss={() => setNotice(null)} />}

      {/* Tabs */}
      <div className="mb-6 inline-flex rounded-lg border border-slate-200 bg-white p-1 shadow-sm">
        {TABS.map((t) => {
          const count = t.key === "refunds" ? bookings.length : tickets.length;
          return (
            <button
              key={t.key}
              onClick={() => setTab(t.key)}
              className={`flex items-center gap-2 rounded-md px-4 py-2 text-sm font-medium transition-colors ${
                tab === t.key
                  ? "bg-[#6384DB] text-white shadow-sm"
                  : "text-slate-600 hover:bg-slate-50"
              }`}
            >
              <t.icon className="h-4 w-4" />
              {t.label}
              <span
                className={`ml-0.5 text-xs ${
                  tab === t.key ? "text-white/80" : "text-slate-400"
                }`}
              >
                {count}
              </span>
            </button>
          );
        })}
      </div>

      {/* Refunds & cancellations */}
      {tab === "refunds" && (
        <Card className="overflow-hidden">
          {bookingsLoading ? (
            <div className="p-6">
              <TableSkeleton rows={6} />
            </div>
          ) : bookings.length === 0 ? (
            <EmptyState
              icon={CalendarCheck}
              title="No refundable bookings"
              description="Pending and confirmed bookings that can be cancelled or refunded will appear here"
            />
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Booking ID</TableHead>
                  <TableHead>Service</TableHead>
                  <TableHead>Customer</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead>Payment</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {bookings.map((b) => (
                  <TableRow key={b.id}>
                    <TableCell className="font-mono text-xs text-slate-500">
                      {b.booking_id}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2">
                        {b.service.emoji && <span>{b.service.emoji}</span>}
                        <span className="font-medium text-slate-900">{b.service.name}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <PartyCell name={b.customer?.name} size="sm" />
                    </TableCell>
                    <TableCell className="font-medium text-slate-900">
                      {formatCurrency(b.total_amount)}
                    </TableCell>
                    <TableCell>
                      {b.paid_with_wallet ? (
                        <span className="inline-flex items-center gap-1 text-xs font-medium text-[#6384DB]">
                          <Wallet className="h-3 w-3" />
                          Wallet
                        </span>
                      ) : (
                        <span className="text-xs text-slate-400">Direct</span>
                      )}
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={b.status} />
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        variant="destructive"
                        size="sm"
                        onClick={() => setCancelTarget(b)}
                      >
                        <X className="mr-1 h-4 w-4" />
                        Cancel & refund
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </Card>
      )}

      {/* Open tickets */}
      {tab === "tickets" && (
        <Card className="overflow-hidden">
          {ticketsLoading ? (
            <div className="p-6">
              <TableSkeleton rows={6} />
            </div>
          ) : tickets.length === 0 ? (
            <EmptyState
              icon={LifeBuoy}
              title="No open tickets"
              description="Open support tickets awaiting a reply will appear here"
            />
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Subject</TableHead>
                  <TableHead>Created</TableHead>
                  <TableHead className="text-right">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {tickets.map((ticket) => (
                  <TableRow
                    key={ticket.id}
                    className="cursor-pointer"
                    onClick={() => openTicket(ticket)}
                  >
                    <TableCell>
                      <PartyCell name={ticket.user.name} meta={ticket.user.phone} size="sm" />
                    </TableCell>
                    <TableCell>
                      <span className="line-clamp-1 max-w-md font-medium text-slate-900">
                        {ticket.subject}
                      </span>
                    </TableCell>
                    <TableCell className="whitespace-nowrap text-slate-500">
                      {formatDate(ticket.created_at)}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={(e) => {
                          e.stopPropagation();
                          openTicket(ticket);
                        }}
                      >
                        <MessageSquareReply className="mr-1 h-4 w-4" />
                        Reply
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </Card>
      )}

      {/* Cancel & refund confirmation */}
      <ConfirmDialog
        open={!!cancelTarget}
        title="Cancel & refund booking"
        message={
          <>
            Cancel booking{" "}
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
        confirmLabel="Cancel & refund"
        cancelLabel="Keep booking"
        loading={cancelling}
        onCancel={() => setCancelTarget(null)}
        onConfirm={confirmCancel}
      />

      {/* Ticket drawer */}
      <Drawer open={!!selected} onClose={() => setSelected(null)} title="Support ticket">
        {selected && (
          <div className="space-y-5">
            <div className="flex items-center justify-between rounded-lg border border-slate-200 p-4">
              <div className="flex min-w-0 items-center gap-3">
                <InitialAvatar name={selected.user.name} />
                <div className="min-w-0">
                  <p className="truncate text-sm font-semibold text-slate-900">
                    {selected.user.name}
                  </p>
                  <p className="truncate text-xs text-slate-500">
                    {selected.user.phone || "-"}
                  </p>
                </div>
              </div>
              <StatusBadge status={selected.user.user_type} />
            </div>

            <div>
              <p className="mb-1 text-[10px] uppercase tracking-wide text-slate-400">Subject</p>
              <p className="text-sm font-semibold text-slate-900">{selected.subject}</p>
              <p className="mt-1 text-xs text-slate-400">
                Raised {formatDate(selected.created_at)}
              </p>
            </div>

            <div className="rounded-lg border-l-4 border-slate-300 bg-slate-50 p-4">
              <p className="whitespace-pre-wrap text-sm leading-relaxed text-slate-700">
                {selected.message}
              </p>
            </div>

            {selected.reply && (
              <div className="rounded-lg border-l-4 border-[#6384DB] bg-[#6384DB]/5 p-4">
                <p className="mb-1 flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-wide text-[#6384DB]">
                  <MessageSquareReply className="h-3.5 w-3.5" />
                  Admin reply
                </p>
                <p className="whitespace-pre-wrap text-sm leading-relaxed text-slate-700">
                  {selected.reply}
                </p>
              </div>
            )}

            {selected.status === "open" && (
              <div className="space-y-3 border-t border-slate-200 pt-4">
                {replyError && <ErrorBanner message={replyError} />}
                <label
                  htmlFor="dispute-reply"
                  className="text-xs font-medium uppercase tracking-wide text-slate-500"
                >
                  {selected.reply ? "Send another reply" : "Reply"}
                </label>
                <textarea
                  id="dispute-reply"
                  value={replyText}
                  onChange={(e) => setReplyText(e.target.value)}
                  rows={4}
                  placeholder="Write a reply to the user..."
                  className="w-full resize-none rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-[#6384DB] focus:outline-none focus:ring-2 focus:ring-[#6384DB]/20"
                />
                <div className="flex items-center justify-between gap-3">
                  <label className="flex cursor-pointer items-center gap-2 text-sm text-slate-600">
                    <input
                      type="checkbox"
                      checked={resolveOnReply}
                      onChange={(e) => setResolveOnReply(e.target.checked)}
                      className="h-4 w-4 rounded border-slate-300 accent-[#6384DB]"
                    />
                    Resolve on reply
                  </label>
                  <Button
                    size="sm"
                    disabled={!replyValid || sending}
                    onClick={() => setConfirmingReply(true)}
                  >
                    <Send className="mr-1.5 h-3.5 w-3.5" />
                    Send
                  </Button>
                </div>
              </div>
            )}
          </div>
        )}
      </Drawer>

      {/* Reply confirmation */}
      <ConfirmDialog
        open={confirmingReply}
        title="Send reply"
        variant="primary"
        message={
          <>
            Send this reply to{" "}
            <span className="font-semibold text-slate-900">{selected?.user.name}</span>?{" "}
            {resolveOnReply
              ? "The ticket will be marked as resolved."
              : "The ticket will stay open."}{" "}
            The user is notified in-app.
          </>
        }
        confirmLabel="Send reply"
        loading={sending}
        onCancel={() => setConfirmingReply(false)}
        onConfirm={confirmReply}
      />
    </AppShell>
  );
}
