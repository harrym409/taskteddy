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
import { getSupportTickets, replySupportTicket } from "@/lib/api";
import { formatDate } from "@/lib/utils";
import { SupportTicket } from "@/types";
import { LifeBuoy, MessageSquareReply, RefreshCw, Send } from "lucide-react";

const STATUS_FILTERS = ["all", "open", "resolved"] as const;
type StatusFilter = (typeof STATUS_FILTERS)[number];

export default function SupportPage() {
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");
  const [openCount, setOpenCount] = useState<number | null>(null);

  // Drawer + reply state
  const [selected, setSelected] = useState<SupportTicket | null>(null);
  const [replyText, setReplyText] = useState("");
  const [resolveOnReply, setResolveOnReply] = useState(true);
  const [confirmingReply, setConfirmingReply] = useState(false);
  const [sending, setSending] = useState(false);
  const [replyError, setReplyError] = useState<string | null>(null);

  const fetchTickets = useCallback(async (): Promise<SupportTicket[]> => {
    setLoading(true);
    setError(null);
    try {
      const data = await getSupportTickets(
        statusFilter === "all" ? undefined : statusFilter
      );
      setTickets(data);
      if (statusFilter === "all") {
        setOpenCount(data.filter((t) => t.status === "open").length);
      } else if (statusFilter === "open") {
        setOpenCount(data.length);
      }
      return data;
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to load support tickets"
      );
      return [];
    } finally {
      setLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    fetchTickets();
  }, [fetchTickets]);

  const openDrawer = (ticket: SupportTicket) => {
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
      const res = await replySupportTicket(
        selected.id,
        replyText.trim(),
        resolveOnReply
      );
      setConfirmingReply(false);
      setNotice(
        res.status === "resolved"
          ? "Reply sent and ticket resolved"
          : "Reply sent"
      );
      // Refetch and keep the drawer in sync with the updated ticket.
      const data = await fetchTickets();
      const updated = data.find((t) => t.id === selected.id);
      setSelected(
        updated ?? { ...selected, reply: replyText.trim(), status: res.status }
      );
      setReplyText("");
    } catch (err) {
      setConfirmingReply(false);
      setReplyError(
        err instanceof Error ? err.message : "Failed to send reply"
      );
    } finally {
      setSending(false);
    }
  };

  const replyValid = replyText.trim().length > 0;

  return (
    <AppShell>
      <PageHeader
        title="Support"
        subtitle="Help-centre tickets from app users"
        action={
          <Button variant="outline" size="sm" onClick={fetchTickets}>
            <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
            Refresh
          </Button>
        }
      />

      {error && <ErrorBanner message={error} onRetry={fetchTickets} />}
      {notice && (
        <SuccessBanner message={notice} onDismiss={() => setNotice(null)} />
      )}

      {/* Status filter row */}
      <div className="mb-6 flex flex-wrap gap-2">
        {STATUS_FILTERS.map((status) => (
          <button
            key={status}
            onClick={() => setStatusFilter(status)}
            className={`inline-flex items-center rounded-full px-4 py-1.5 text-sm font-medium capitalize transition-colors ${
              statusFilter === status
                ? "bg-[#6384DB] text-white shadow-sm"
                : "border border-slate-300 bg-white text-slate-600 hover:bg-slate-50"
            }`}
          >
            {status === "all" ? "All" : status}
            {status === "open" && openCount !== null && openCount > 0 && (
              <span className="ml-1.5 inline-flex items-center rounded-full border border-amber-200 bg-amber-50 px-1.5 py-px text-[10px] font-semibold text-amber-700">
                {openCount}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Tickets table */}
      <Card className="overflow-hidden">
        {loading ? (
          <div className="p-6">
            <TableSkeleton rows={6} />
          </div>
        ) : tickets.length === 0 ? (
          <EmptyState
            icon={LifeBuoy}
            title="No tickets found"
            description={
              statusFilter === "all"
                ? "Support tickets raised in the app will appear here"
                : `No ${statusFilter} tickets`
            }
          />
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>User</TableHead>
                <TableHead>Subject</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Created</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {tickets.map((ticket) => (
                <TableRow
                  key={ticket.id}
                  className="cursor-pointer"
                  onClick={() => openDrawer(ticket)}
                >
                  <TableCell>
                    <PartyCell
                      name={ticket.user.name}
                      meta={ticket.user.phone}
                      size="sm"
                    />
                  </TableCell>
                  <TableCell>
                    <span className="line-clamp-1 max-w-md font-medium text-slate-900">
                      {ticket.subject}
                    </span>
                  </TableCell>
                  <TableCell>
                    <StatusBadge status={ticket.status} />
                  </TableCell>
                  <TableCell className="whitespace-nowrap text-slate-500">
                    {formatDate(ticket.created_at)}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Card>

      {/* Ticket drawer */}
      <Drawer
        open={!!selected}
        onClose={() => setSelected(null)}
        title="Support ticket"
      >
        {selected && (
          <div className="space-y-5">
            {/* User header */}
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

            {/* Subject + message */}
            <div>
              <p className="mb-1 text-[10px] uppercase tracking-wide text-slate-400">
                Subject
              </p>
              <p className="text-sm font-semibold text-slate-900">
                {selected.subject}
              </p>
              <p className="mt-1 text-xs text-slate-400">
                Raised {formatDate(selected.created_at)}
              </p>
            </div>

            <div className="rounded-lg border-l-4 border-slate-300 bg-slate-50 p-4">
              <p className="whitespace-pre-wrap text-sm leading-relaxed text-slate-700">
                {selected.message}
              </p>
            </div>

            {/* Existing reply */}
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

            {/* Reply form (open tickets only) */}
            {selected.status === "open" && (
              <div className="space-y-3 border-t border-slate-200 pt-4">
                {replyError && <ErrorBanner message={replyError} />}
                <label
                  htmlFor="ticket-reply"
                  className="text-xs font-medium uppercase tracking-wide text-slate-500"
                >
                  {selected.reply ? "Send another reply" : "Reply"}
                </label>
                <textarea
                  id="ticket-reply"
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
            <span className="font-semibold text-slate-900">
              {selected?.user.name}
            </span>
            ?{" "}
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
