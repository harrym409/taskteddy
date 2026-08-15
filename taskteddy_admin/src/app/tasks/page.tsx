"use client";

import { useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Modal } from "@/components/ui/modal";
import { Drawer } from "@/components/ui/drawer";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { StatusBadge } from "@/components/ui/status-badge";
import { InitialAvatar, PartyCell } from "@/components/ui/avatar";
import { EmptyState, ErrorBanner, TableSkeleton } from "@/components/ui/feedback";
import {
  getTasks,
  assignTask,
  updateTaskStatus,
  approveTask,
  rejectTask,
  getUsers,
  getTaskApplications,
  fileUrl,
} from "@/lib/api";
import { cn, formatDate, formatRelativeTime, formatCurrency } from "@/lib/utils";
import { Task, TaskApplication, User } from "@/types";
import {
  Search,
  UserPlus,
  Check,
  X,
  ListTodo,
  RefreshCw,
  Play,
  Star,
  Gavel,
  Inbox,
  Image as ImageIcon,
  ImageOff,
  FolderOpen,
  Loader,
  CircleCheck,
  MapPin,
  Copy,
  CheckCheck,
  Tag,
  Wallet,
  Clock,
  CalendarClock,
  Ban,
  ShieldCheck,
} from "lucide-react";

/** Small monospace reference badge for a task id with click-to-copy. */
function TaskIdBadge({ id, size = "sm" }: { id: string; size?: "sm" | "md" }) {
  const [copied, setCopied] = useState(false);

  const copy = async (e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      await navigator.clipboard.writeText(id);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      // Clipboard may be unavailable (e.g. insecure context); ignore silently.
    }
  };

  return (
    <button
      type="button"
      onClick={copy}
      title="Copy task ID"
      className={cn(
        "group inline-flex items-center gap-1 rounded-md border border-slate-200 bg-slate-50 font-mono text-slate-600 transition-colors hover:border-[#6384DB]/40 hover:bg-[#6384DB]/5 hover:text-[#6384DB]",
        size === "md" ? "px-2 py-1 text-xs" : "px-1.5 py-0.5 text-[11px]"
      )}
    >
      {id}
      {copied ? (
        <CheckCheck className="h-3 w-3 shrink-0 text-emerald-600" />
      ) : (
        <Copy className="h-3 w-3 shrink-0 text-slate-400 group-hover:text-[#6384DB]" />
      )}
      {copied && <span className="text-[10px] font-sans font-medium text-emerald-600">Copied</span>}
    </button>
  );
}

export default function TasksPage() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [taskers, setTaskers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");
  const [assigningTask, setAssigningTask] = useState<Task | null>(null);
  const [selectedTasker, setSelectedTasker] = useState("");
  const [assigning, setAssigning] = useState(false);
  const [viewingTask, setViewingTask] = useState<Task | null>(null);
  const [applications, setApplications] = useState<TaskApplication[]>([]);
  const [appsLoading, setAppsLoading] = useState(false);
  const [appsError, setAppsError] = useState<string | null>(null);

  // Management-action flows for the detail drawer
  const [pendingAction, setPendingAction] = useState<
    | { kind: "status"; status: string; label: string; danger?: boolean }
    | { kind: "approve" }
    | null
  >(null);
  const [actionBusy, setActionBusy] = useState(false);

  // Reject-with-reason flow
  const [rejectOpen, setRejectOpen] = useState(false);
  const [rejectReason, setRejectReason] = useState("");
  const [confirmReject, setConfirmReject] = useState(false);
  const [rejectBusy, setRejectBusy] = useState(false);

  const loadApplications = (task: Task) => {
    setApplications([]);
    setAppsError(null);
    setAppsLoading(true);
    getTaskApplications(task.id)
      .then(setApplications)
      .catch((err) =>
        setAppsError(err instanceof Error ? err.message : "Failed to load applications")
      )
      .finally(() => setAppsLoading(false));
  };

  const openDetail = (task: Task) => {
    setViewingTask(task);
    loadApplications(task);
  };

  const fetchTasks = async () => {
    setLoading(true);
    setError(null);
    try {
      const status = statusFilter === "all" ? undefined : statusFilter;
      const data = await getTasks(status, search || undefined);
      setTasks(data);
      // Keep the open drawer in sync with the freshly loaded list.
      setViewingTask((current) =>
        current ? data.find((t) => t.id === current.id) ?? null : current
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load tasks");
    } finally {
      setLoading(false);
    }
  };

  const fetchTaskers = async () => {
    try {
      const data = await getUsers("tasker");
      setTaskers(data);
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchTasks();
    fetchTaskers();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    fetchTasks();
  };

  const handleAssign = async () => {
    if (!assigningTask || !selectedTasker) return;
    setAssigning(true);
    try {
      await assignTask(assigningTask.id, selectedTasker);
      setAssigningTask(null);
      setSelectedTasker("");
      await fetchTasks();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to assign task");
      setAssigningTask(null);
    } finally {
      setAssigning(false);
    }
  };

  const handleStatusChange = async (taskId: string, status: string) => {
    try {
      await updateTaskStatus(taskId, status);
      await fetchTasks();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to update task");
    }
  };

  // Confirmed status change from the detail drawer.
  const runPendingAction = async () => {
    if (!viewingTask || !pendingAction) return;
    setActionBusy(true);
    try {
      if (pendingAction.kind === "approve") {
        await approveTask(viewingTask.id);
      } else {
        await updateTaskStatus(viewingTask.id, pendingAction.status);
      }
      setPendingAction(null);
      await fetchTasks();
      if (viewingTask) loadApplications(viewingTask);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to update task");
      setPendingAction(null);
    } finally {
      setActionBusy(false);
    }
  };

  const handleReject = async () => {
    if (!viewingTask || !rejectReason.trim()) return;
    setRejectBusy(true);
    try {
      await rejectTask(viewingTask.id, rejectReason.trim());
      setConfirmReject(false);
      setRejectOpen(false);
      setRejectReason("");
      await fetchTasks();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to reject task");
      setConfirmReject(false);
    } finally {
      setRejectBusy(false);
    }
  };

  return (
    <AppShell>
      <PageHeader
        title="Tasks"
        subtitle="Assign taskers and track task progress"
        action={
          <Button variant="outline" size="sm" onClick={fetchTasks}>
            <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
            Refresh
          </Button>
        }
      />

      {error && <ErrorBanner message={error} onRetry={fetchTasks} />}

      {/* Overview */}
      <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
        {[
          { label: "Total", value: tasks.length, icon: FolderOpen, tint: "text-slate-600 bg-slate-100" },
          { label: "Open", value: tasks.filter((t) => t.status === "open").length, icon: ListTodo, tint: "text-[#6384DB] bg-[#6384DB]/10" },
          { label: "In progress", value: tasks.filter((t) => t.status === "assigned" || t.status === "inProgress").length, icon: Loader, tint: "text-amber-600 bg-amber-100" },
          { label: "Completed", value: tasks.filter((t) => t.status === "completed").length, icon: CircleCheck, tint: "text-emerald-600 bg-emerald-100" },
        ].map((s) => (
          <Card key={s.label}>
            <CardContent className="flex items-center gap-3 p-4">
              <span className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${s.tint}`}>
                <s.icon className="h-5 w-5" />
              </span>
              <div className="min-w-0">
                <p className="text-2xl font-bold leading-none text-slate-900">{s.value}</p>
                <p className="mt-1 truncate text-xs font-medium text-slate-500">{s.label}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Filters */}
      <Card className="mb-6">
        <CardContent className="p-4">
          <form onSubmit={handleSearch} className="flex flex-wrap gap-3">
            <div className="relative min-w-56 flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <Input
                placeholder="Search by ID, title, category or location…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-10"
              />
            </div>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-700 focus:border-[#6384DB] focus:outline-none focus:ring-2 focus:ring-[#6384DB]/25"
            >
              <option value="all">All Status</option>
              <option value="pending_review">Pending review</option>
              <option value="open">Open</option>
              <option value="assigned">Assigned</option>
              <option value="inProgress">In Progress</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
              <option value="rejected">Rejected</option>
            </select>
            <Button type="submit">Search</Button>
          </form>
        </CardContent>
      </Card>

      {/* Tasks Table */}
      <Card className="overflow-hidden">
        {loading ? (
          <div className="p-6">
            <TableSkeleton rows={6} />
          </div>
        ) : tasks.length === 0 ? (
          <EmptyState
            icon={ListTodo}
            title="No tasks found"
            description="Try adjusting your search or filters"
          />
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Task</TableHead>
                <TableHead>Category</TableHead>
                <TableHead>Photos</TableHead>
                <TableHead>Budget</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Posted By</TableHead>
                <TableHead>Assigned To</TableHead>
                <TableHead>Deadline</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {tasks.map((task) => (
                <TableRow
                  key={task.id}
                  className="cursor-pointer"
                  onClick={() => openDetail(task)}
                >
                  <TableCell className="max-w-sm">
                    <div onClick={(e) => e.stopPropagation()} className="mb-1 inline-block">
                      <TaskIdBadge id={task.id} />
                    </div>
                    <p className="truncate font-medium text-slate-900">
                      {task.title}
                    </p>
                    {task.description && (
                      <p className="mt-0.5 line-clamp-1 text-xs text-slate-500">
                        {task.description}
                      </p>
                    )}
                    {task.location && (
                      <p className="mt-0.5 flex items-center gap-1 truncate text-xs text-slate-400">
                        <MapPin className="h-3 w-3 shrink-0" />
                        {task.location}
                      </p>
                    )}
                  </TableCell>
                  <TableCell className="capitalize">{task.category}</TableCell>
                  <TableCell>
                    {task.images && task.images.length > 0 ? (
                      <span className="inline-flex items-center gap-1 rounded-full bg-[#6384DB]/10 px-2 py-0.5 text-xs font-medium text-[#6384DB]">
                        <ImageIcon className="h-3.5 w-3.5" />
                        {task.images.length}
                      </span>
                    ) : (
                      <span className="text-xs text-slate-300">—</span>
                    )}
                  </TableCell>
                  <TableCell className="font-medium text-slate-900">
                    {formatCurrency(task.budget)}
                  </TableCell>
                  <TableCell>
                    <StatusBadge status={task.status} />
                  </TableCell>
                  <TableCell>
                    <PartyCell
                      name={task.posted_by?.name}
                      avatarUrl={task.posted_by?.avatar_url}
                      meta={task.posted_by?.email || undefined}
                      size="sm"
                    />
                  </TableCell>
                  <TableCell>
                    <PartyCell
                      name={task.assigned_to?.name}
                      avatarUrl={task.assigned_to?.avatar_url}
                      meta={task.assigned_to?.email || undefined}
                      size="sm"
                    />
                  </TableCell>
                  <TableCell className="text-slate-500">
                    {formatDate(task.deadline)}
                  </TableCell>
                  <TableCell className="text-right" onClick={(e) => e.stopPropagation()}>
                    <div className="flex justify-end gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => openDetail(task)}
                      >
                        <Gavel className="mr-1 h-3.5 w-3.5" />
                        Details
                      </Button>
                      {task.status === "open" && (
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => setAssigningTask(task)}
                        >
                          <UserPlus className="mr-1 h-4 w-4" />
                          Assign
                        </Button>
                      )}
                      {task.status === "assigned" && (
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleStatusChange(task.id, "inProgress")}
                        >
                          <Play className="mr-1 h-3.5 w-3.5" />
                          Start
                        </Button>
                      )}
                      {task.status === "inProgress" && (
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleStatusChange(task.id, "completed")}
                        >
                          <Check className="mr-1 h-4 w-4" />
                          Complete
                        </Button>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Card>

      {/* Assign Modal */}
      <Modal
        open={!!assigningTask}
        onClose={() => setAssigningTask(null)}
        title="Assign Task"
      >
        {assigningTask && (
          <div className="space-y-4">
            <div className="rounded-lg border border-slate-200 bg-slate-50 p-3">
              <p className="text-xs uppercase tracking-wide text-slate-400">Task</p>
              <p className="mt-0.5 text-sm font-medium text-slate-900">
                {assigningTask.title}
              </p>
              <div className="mt-1.5">
                <TaskIdBadge id={assigningTask.id} />
              </div>
            </div>
            <div className="space-y-1.5">
              <label htmlFor="tasker" className="text-sm font-medium text-slate-700">
                Select Tasker
              </label>
              <select
                id="tasker"
                value={selectedTasker}
                onChange={(e) => setSelectedTasker(e.target.value)}
                className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-700 focus:border-[#6384DB] focus:outline-none focus:ring-2 focus:ring-[#6384DB]/25"
              >
                <option value="">Select a tasker...</option>
                {taskers.map((tasker) => (
                  <option key={tasker.id} value={tasker.id}>
                    {tasker.name}
                    {tasker.rating > 0 ? ` (${tasker.rating.toFixed(1)} rating)` : ""}
                  </option>
                ))}
              </select>
            </div>
            <div className="flex justify-end gap-2 border-t border-slate-100 pt-4">
              <Button type="button" variant="outline" onClick={() => setAssigningTask(null)}>
                Cancel
              </Button>
              <Button onClick={handleAssign} disabled={!selectedTasker || assigning}>
                {assigning ? "Assigning..." : "Assign Task"}
              </Button>
            </div>
          </div>
        )}
      </Modal>

      {/* Task detail / management Drawer */}
      <Drawer
        open={!!viewingTask}
        onClose={() => setViewingTask(null)}
        widthClassName="sm:max-w-lg"
        title={
          <div className="min-w-0">
            <p className="truncate">Task details</p>
            {viewingTask && (
              <p className="truncate text-xs font-normal text-slate-500">
                {viewingTask.title}
              </p>
            )}
          </div>
        }
      >
        {viewingTask && (
          <div className="space-y-6">
            {/* Header: id + title + status */}
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <TaskIdBadge id={viewingTask.id} size="md" />
                <StatusBadge status={viewingTask.status} />
              </div>
              <h2 className="mt-2 text-lg font-semibold leading-snug text-slate-900">
                {viewingTask.title}
              </h2>
            </div>

            {/* Review / cancel reason */}
            {viewingTask.status === "rejected" && viewingTask.review_reason && (
              <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800">
                <span className="font-medium">Rejection reason: </span>
                {viewingTask.review_reason}
              </div>
            )}
            {viewingTask.status === "pending_review" && viewingTask.review_reason && (
              <div className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">
                <span className="font-medium">Flagged: </span>
                {viewingTask.review_reason}
              </div>
            )}
            {viewingTask.status === "cancelled" && viewingTask.cancel_reason && (
              <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800">
                <span className="font-medium">Cancellation reason: </span>
                {viewingTask.cancel_reason}
              </div>
            )}

            {/* Description */}
            <div>
              <p className="mb-1 text-xs font-semibold uppercase tracking-wide text-slate-400">
                Description
              </p>
              <p className="whitespace-pre-wrap text-sm leading-relaxed text-slate-700">
                {viewingTask.description || "No description provided."}
              </p>
            </div>

            {/* Details grid */}
            <div className="grid grid-cols-2 gap-3">
              <DetailItem icon={Tag} label="Category">
                <span className="capitalize">{viewingTask.category || "—"}</span>
              </DetailItem>
              <DetailItem icon={Wallet} label="Budget">
                <span className="font-medium text-slate-900">
                  {formatCurrency(viewingTask.budget)}
                </span>
              </DetailItem>
              <DetailItem icon={MapPin} label="Location">
                {viewingTask.location || "—"}
              </DetailItem>
              <DetailItem icon={CalendarClock} label="Deadline">
                {viewingTask.deadline ? formatDate(viewingTask.deadline) : "—"}
              </DetailItem>
              <DetailItem icon={Clock} label="Created">
                {viewingTask.created_at ? formatRelativeTime(viewingTask.created_at) : "—"}
              </DetailItem>
              <DetailItem icon={RefreshCw} label="Last updated">
                {viewingTask.updated_at ? formatRelativeTime(viewingTask.updated_at) : "—"}
              </DetailItem>
            </div>

            {/* Parties */}
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div>
                <p className="mb-1.5 text-xs font-semibold uppercase tracking-wide text-slate-400">
                  Posted by
                </p>
                <PartyCell
                  name={viewingTask.posted_by?.name}
                  avatarUrl={viewingTask.posted_by?.avatar_url}
                  meta={viewingTask.posted_by?.email || undefined}
                  size="sm"
                />
              </div>
              <div>
                <p className="mb-1.5 text-xs font-semibold uppercase tracking-wide text-slate-400">
                  Assigned to
                </p>
                {viewingTask.assigned_to ? (
                  <PartyCell
                    name={viewingTask.assigned_to.name}
                    avatarUrl={viewingTask.assigned_to.avatar_url}
                    meta={viewingTask.assigned_to.email || undefined}
                    size="sm"
                  />
                ) : (
                  <StatusBadge status="unassigned" />
                )}
              </div>
            </div>

            {/* Photos */}
            <div>
              <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">
                Photos ({viewingTask.images?.length || 0})
              </p>
              {viewingTask.images && viewingTask.images.length > 0 ? (
                <div className="flex flex-wrap gap-2">
                  {viewingTask.images.map((img, i) => (
                    <a
                      key={i}
                      href={fileUrl(img)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block h-20 w-20 overflow-hidden rounded-lg border border-slate-200 transition-shadow hover:shadow-md"
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

            {/* Management actions */}
            <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
              <p className="mb-3 text-xs font-semibold uppercase tracking-wide text-slate-400">
                Manage task
              </p>
              <div className="flex flex-wrap gap-2">
                {viewingTask.status === "pending_review" && (
                  <>
                    <Button
                      size="sm"
                      onClick={() => setPendingAction({ kind: "approve" })}
                    >
                      <ShieldCheck className="mr-1.5 h-4 w-4" />
                      Approve
                    </Button>
                    <Button
                      size="sm"
                      variant="destructive"
                      onClick={() => {
                        setRejectReason("");
                        setConfirmReject(false);
                        setRejectOpen(true);
                      }}
                    >
                      <X className="mr-1.5 h-4 w-4" />
                      Reject
                    </Button>
                  </>
                )}
                {viewingTask.status === "open" && (
                  <Button size="sm" onClick={() => setAssigningTask(viewingTask)}>
                    <UserPlus className="mr-1.5 h-4 w-4" />
                    Assign
                  </Button>
                )}
                {viewingTask.status === "assigned" && (
                  <Button
                    size="sm"
                    onClick={() =>
                      setPendingAction({
                        kind: "status",
                        status: "inProgress",
                        label: "Start",
                      })
                    }
                  >
                    <Play className="mr-1.5 h-4 w-4" />
                    Start
                  </Button>
                )}
                {viewingTask.status === "inProgress" && (
                  <Button
                    size="sm"
                    onClick={() =>
                      setPendingAction({
                        kind: "status",
                        status: "completed",
                        label: "Complete",
                      })
                    }
                  >
                    <Check className="mr-1.5 h-4 w-4" />
                    Complete
                  </Button>
                )}
                {["open", "assigned", "inProgress"].includes(viewingTask.status) && (
                  <Button
                    size="sm"
                    variant="destructive"
                    onClick={() =>
                      setPendingAction({
                        kind: "status",
                        status: "cancelled",
                        label: "Cancel task",
                        danger: true,
                      })
                    }
                  >
                    <Ban className="mr-1.5 h-4 w-4" />
                    Cancel task
                  </Button>
                )}
                {["completed", "cancelled", "rejected"].includes(viewingTask.status) && (
                  <p className="text-sm text-slate-500">
                    This task is {viewingTask.status} — no further actions available.
                  </p>
                )}
              </div>
            </div>

            {/* Applications / bids */}
            <div>
              <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">
                Applications ({applications.length})
              </p>
              {appsError && (
                <ErrorBanner
                  message={appsError}
                  onRetry={() => viewingTask && loadApplications(viewingTask)}
                />
              )}
              {appsLoading ? (
                <TableSkeleton rows={3} />
              ) : !appsError && applications.length === 0 ? (
                <EmptyState
                  icon={Inbox}
                  title="No applications yet"
                  description="Bids from taskers will appear here once they apply"
                />
              ) : (
                <div className="space-y-3">
                  {applications.map((app) => (
                    <div
                      key={app.id}
                      className="rounded-xl border border-slate-200 bg-white p-4"
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div className="flex min-w-0 items-center gap-2.5">
                          <InitialAvatar
                            name={app.applicant.name}
                            avatarUrl={app.applicant.avatar_url}
                            size="md"
                          />
                          <div className="min-w-0">
                            <div className="flex items-center gap-2">
                              <p className="truncate text-sm font-medium text-slate-900">
                                {app.applicant.name}
                              </p>
                              {app.applicant.is_verified && (
                                <StatusBadge status="verified" />
                              )}
                            </div>
                            <p className="mt-0.5 inline-flex items-center gap-1 text-xs text-slate-500">
                              <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
                              <span className="font-medium text-slate-700">
                                {app.applicant.rating.toFixed(1)}
                              </span>
                              <span>/ 5</span>
                            </p>
                          </div>
                        </div>
                        <StatusBadge status={app.status} />
                      </div>
                      <div className="mt-3 flex items-center justify-between gap-3 rounded-lg border border-slate-100 bg-slate-50 px-3 py-2">
                        <span className="text-xs uppercase tracking-wide text-slate-400">
                          Bid amount
                        </span>
                        <span className="text-sm font-semibold text-slate-900">
                          {formatCurrency(app.bid_amount)}
                        </span>
                      </div>
                      {app.cover_letter && (
                        <p className="mt-3 whitespace-pre-wrap text-sm leading-relaxed text-slate-600">
                          {app.cover_letter}
                        </p>
                      )}
                      <p className="mt-3 text-xs text-slate-400">
                        Applied {formatDate(app.created_at)}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}
      </Drawer>

      {/* Confirm status-change / approve from the detail drawer */}
      <ConfirmDialog
        open={!!pendingAction}
        title={
          pendingAction?.kind === "approve"
            ? "Approve task"
            : pendingAction?.label ?? "Confirm"
        }
        variant={
          pendingAction?.kind === "status" && pendingAction.danger ? "danger" : "primary"
        }
        confirmLabel={
          pendingAction?.kind === "approve"
            ? "Approve and publish"
            : pendingAction?.label ?? "Confirm"
        }
        loading={actionBusy}
        message={
          <>
            {pendingAction?.kind === "approve" ? (
              <>Approve and publish this task? It will become visible to taskers.</>
            ) : (
              <>
                {pendingAction?.label} for{" "}
                <span className="font-medium text-slate-900">
                  {viewingTask?.title}
                </span>
                ?
              </>
            )}
          </>
        }
        onCancel={() => setPendingAction(null)}
        onConfirm={runPendingAction}
      />

      {/* Reject-with-reason drawer */}
      <Drawer
        open={rejectOpen}
        onClose={() => {
          if (rejectBusy) return;
          setRejectOpen(false);
          setRejectReason("");
        }}
        title={
          <div className="min-w-0">
            <p className="truncate">Reject task</p>
            {viewingTask && (
              <p className="truncate text-xs font-normal text-slate-500">
                {viewingTask.title}
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
            <label htmlFor="task-reject-reason" className="text-sm font-medium text-slate-700">
              Rejection reason
            </label>
            <textarea
              id="task-reject-reason"
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
                setRejectOpen(false);
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
            <span className="font-medium text-slate-900">{viewingTask?.title}</span> and
            notify the customer? This cannot be undone.
          </>
        }
        onCancel={() => setConfirmReject(false)}
        onConfirm={handleReject}
      />
    </AppShell>
  );
}

function DetailItem({
  icon: Icon,
  label,
  children,
}: {
  icon: React.ComponentType<{ className?: string }>;
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="rounded-lg border border-slate-100 bg-white px-3 py-2">
      <p className="mb-0.5 inline-flex items-center gap-1.5 text-xs font-medium text-slate-400">
        <Icon className="h-3.5 w-3.5" />
        {label}
      </p>
      <p className="text-sm text-slate-700">{children}</p>
    </div>
  );
}
