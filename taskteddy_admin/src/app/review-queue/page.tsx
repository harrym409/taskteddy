"use client";

import { useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { StatusBadge } from "@/components/ui/status-badge";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { Drawer } from "@/components/ui/drawer";
import {
  EmptyState,
  ErrorBanner,
  SuccessBanner,
  TableSkeleton,
} from "@/components/ui/feedback";
import { getReviewQueue, approveTask, rejectTask, fileUrl } from "@/lib/api";
import { cn, formatCurrency, formatRelativeTime } from "@/lib/utils";
import { ReviewTask } from "@/types";
import {
  RefreshCw,
  ShieldCheck,
  Check,
  X,
  MapPin,
  Wallet,
  Tag,
  User as UserIcon,
  Clock,
  ImageOff,
  AlertTriangle,
} from "lucide-react";

// Auto-moderation flags a task with a reason like: Auto-flagged: contains "scam".
function isAutoFlagged(task: ReviewTask): boolean {
  return !!task.review_reason?.toLowerCase().startsWith("auto-flagged");
}

export default function ReviewQueuePage() {
  const [tasks, setTasks] = useState<ReviewTask[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  // Approve flow
  const [approvingTask, setApprovingTask] = useState<ReviewTask | null>(null);
  const [approveBusy, setApproveBusy] = useState(false);

  // Reject flow
  const [rejectingTask, setRejectingTask] = useState<ReviewTask | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [confirmReject, setConfirmReject] = useState(false);
  const [rejectBusy, setRejectBusy] = useState(false);

  const fetchQueue = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await getReviewQueue();
      setTasks(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load review queue");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchQueue();
  }, []);

  const handleApprove = async () => {
    if (!approvingTask) return;
    setApproveBusy(true);
    try {
      await approveTask(approvingTask.id);
      setTasks((prev) => prev.filter((t) => t.id !== approvingTask.id));
      setSuccess(`"${approvingTask.title}" approved and is now live.`);
      setApprovingTask(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to approve task");
    } finally {
      setApproveBusy(false);
    }
  };

  const openReject = (task: ReviewTask) => {
    setRejectingTask(task);
    setRejectReason("");
    setConfirmReject(false);
  };

  const handleReject = async () => {
    if (!rejectingTask || !rejectReason.trim()) return;
    setRejectBusy(true);
    try {
      await rejectTask(rejectingTask.id, rejectReason.trim());
      setTasks((prev) => prev.filter((t) => t.id !== rejectingTask.id));
      setSuccess(`"${rejectingTask.title}" rejected. The customer has been notified.`);
      setConfirmReject(false);
      setRejectingTask(null);
      setRejectReason("");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to reject task");
      setConfirmReject(false);
    } finally {
      setRejectBusy(false);
    }
  };

  const pending = tasks.length;

  return (
    <AppShell>
      <PageHeader
        title="Review queue"
        subtitle="Moderate customer-posted tasks before they go live"
        action={
          <>
            <span className="inline-flex items-center gap-1.5 rounded-full border border-amber-200 bg-amber-50 px-3 py-1 text-xs font-semibold text-amber-700">
              <Clock className="h-3.5 w-3.5" />
              {pending} awaiting review
            </span>
            <Button variant="outline" size="sm" onClick={fetchQueue}>
              <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
              Refresh
            </Button>
          </>
        }
      />

      {error && <ErrorBanner message={error} onRetry={fetchQueue} />}
      {success && <SuccessBanner message={success} onDismiss={() => setSuccess(null)} />}

      {loading ? (
        <Card>
          <CardContent className="p-6">
            <TableSkeleton rows={4} />
          </CardContent>
        </Card>
      ) : tasks.length === 0 ? (
        <Card>
          <EmptyState
            icon={ShieldCheck}
            title="No tasks awaiting review — you're all caught up"
            description="New customer-posted tasks will appear here for moderation."
          />
        </Card>
      ) : (
        <div className="space-y-4">
          {tasks.map((task) => {
            const flagged = isAutoFlagged(task);
            return (
            <Card
              key={task.id}
              className={cn(
                "overflow-hidden",
                flagged && "border-red-300 ring-1 ring-red-200"
              )}
            >
              <CardContent className="p-5">
                {/* Auto-flag warning: pushed to the very top so moderators can't miss it */}
                {flagged && (
                  <div className="mb-4 flex items-start gap-2.5 rounded-lg border border-red-300 bg-red-50 px-3 py-2.5">
                    <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-red-600" />
                    <div className="min-w-0">
                      <p className="text-sm font-semibold text-red-700">
                        Auto-flagged by moderation
                      </p>
                      <p className="mt-0.5 text-sm text-red-700/90">
                        {task.review_reason}
                      </p>
                    </div>
                  </div>
                )}

                {/* Header */}
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <h2 className="text-base font-semibold text-slate-900">
                        {task.title}
                      </h2>
                      <StatusBadge status={task.status} />
                    </div>
                    <p className="mt-1 inline-flex items-center gap-1.5 text-xs text-slate-500">
                      <Clock className="h-3.5 w-3.5" />
                      Waiting for {formatRelativeTime(task.created_at)}
                    </p>
                  </div>
                  <div className="flex shrink-0 flex-wrap items-center gap-2">
                    <Button size="sm" onClick={() => setApprovingTask(task)}>
                      <Check className="mr-1.5 h-4 w-4" />
                      Approve
                    </Button>
                    <Button
                      size="sm"
                      variant="destructive"
                      onClick={() => openReject(task)}
                    >
                      <X className="mr-1.5 h-4 w-4" />
                      Reject
                    </Button>
                  </div>
                </div>

                {/* Meta row */}
                <div className="mt-4 flex flex-wrap gap-x-5 gap-y-2 text-sm">
                  <span className="inline-flex items-center gap-1.5 text-slate-600">
                    <Tag className="h-4 w-4 text-slate-400" />
                    <span className="capitalize">{task.category}</span>
                  </span>
                  <span className="inline-flex items-center gap-1.5 font-medium text-slate-900">
                    <Wallet className="h-4 w-4 text-slate-400" />
                    {formatCurrency(task.budget)}
                  </span>
                  <span className="inline-flex items-center gap-1.5 text-slate-600">
                    <MapPin className="h-4 w-4 text-slate-400" />
                    {task.location || "No location"}
                  </span>
                  <span className="inline-flex items-center gap-1.5 text-slate-600">
                    <UserIcon className="h-4 w-4 text-slate-400" />
                    {task.posted_by?.name || "Unknown"}
                  </span>
                </div>

                {/* Flag reason (non-auto reasons; auto-flags render at the top) */}
                {task.review_reason && !flagged && (
                  <div className="mt-4 rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">
                    <span className="font-medium">Flagged: </span>
                    {task.review_reason}
                  </div>
                )}

                {/* Description */}
                <div className="mt-4">
                  <p className="mb-1 text-xs font-semibold uppercase tracking-wide text-slate-400">
                    Description
                  </p>
                  <p className="whitespace-pre-wrap text-sm leading-relaxed text-slate-700">
                    {task.description || "No description provided."}
                  </p>
                </div>

                {/* Photos */}
                <div className="mt-4">
                  <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">
                    Photos ({task.images?.length || 0})
                  </p>
                  {task.images && task.images.length > 0 ? (
                    <div className="flex flex-wrap gap-2">
                      {task.images.map((img, i) => (
                        <a
                          key={i}
                          href={fileUrl(img)}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="block h-24 w-24 overflow-hidden rounded-lg border border-slate-200 transition-shadow hover:shadow-md"
                          title="Open full size"
                        >
                          {/* eslint-disable-next-line @next/next/no-img-element */}
                          <img
                            src={fileUrl(img)}
                            alt={`Task photo ${i + 1}`}
                            className="h-full w-full object-cover"
                          />
                        </a>
                      ))}
                    </div>
                  ) : (
                    <p className="inline-flex items-center gap-1.5 text-xs text-slate-400">
                      <ImageOff className="h-3.5 w-3.5" />
                      No photos attached
                    </p>
                  )}
                </div>
              </CardContent>
            </Card>
            );
          })}
        </div>
      )}

      {/* Approve confirm */}
      <ConfirmDialog
        open={!!approvingTask}
        title="Approve task"
        variant="primary"
        confirmLabel="Approve and publish"
        loading={approveBusy}
        message={
          <>
            Approve{" "}
            <span className="font-medium text-slate-900">
              {approvingTask?.title}
            </span>
            ? It will go live and become visible to taskers.
          </>
        }
        onCancel={() => setApprovingTask(null)}
        onConfirm={handleApprove}
      />

      {/* Reject reason drawer */}
      <Drawer
        open={!!rejectingTask}
        onClose={() => {
          if (rejectBusy) return;
          setRejectingTask(null);
          setRejectReason("");
        }}
        title={
          <div className="min-w-0">
            <p className="truncate">Reject task</p>
            {rejectingTask && (
              <p className="truncate text-xs font-normal text-slate-500">
                {rejectingTask.title}
              </p>
            )}
          </div>
        }
      >
        <div className="space-y-4">
          <p className="text-sm text-slate-600">
            Give the customer a clear reason for the rejection. This message is sent to
            them, so keep it specific and respectful.
          </p>
          <div className="space-y-1.5">
            <label
              htmlFor="reject-reason"
              className="text-sm font-medium text-slate-700"
            >
              Rejection reason
            </label>
            <textarea
              id="reject-reason"
              value={rejectReason}
              onChange={(e) => setRejectReason(e.target.value)}
              rows={5}
              placeholder="e.g. The photos include inappropriate content that violates our community guidelines."
              className="w-full resize-none rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-700 focus:border-[#6384DB] focus:outline-none focus:ring-2 focus:ring-[#6384DB]/25"
            />
          </div>
          <div className="flex justify-end gap-2 border-t border-slate-100 pt-4">
            <Button
              variant="outline"
              onClick={() => {
                setRejectingTask(null);
                setRejectReason("");
              }}
              disabled={rejectBusy}
            >
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={() => setConfirmReject(true)}
              disabled={!rejectReason.trim() || rejectBusy}
            >
              Reject task
            </Button>
          </div>
        </div>
      </Drawer>

      {/* Reject confirm */}
      <ConfirmDialog
        open={confirmReject}
        title="Reject and notify customer"
        variant="danger"
        confirmLabel="Reject task"
        loading={rejectBusy}
        message={
          <>
            Reject{" "}
            <span className="font-medium text-slate-900">{rejectingTask?.title}</span> and
            notify the customer? This cannot be undone.
          </>
        }
        onCancel={() => setConfirmReject(false)}
        onConfirm={handleReject}
      />
    </AppShell>
  );
}
