"use client";

import { useCallback, useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { StatusBadge } from "@/components/ui/status-badge";
import { InitialAvatar } from "@/components/ui/avatar";
import {
  EmptyState,
  ErrorBanner,
  SuccessBanner,
  TableSkeleton,
} from "@/components/ui/feedback";
import { getSafetyReports, suspendUser, updateReportStatus } from "@/lib/api";
import { formatDate } from "@/lib/utils";
import { ReportStatus, SafetyReport } from "@/types";
import {
  ArrowRight,
  Ban,
  CheckCheck,
  Eye,
  ShieldAlert,
  RefreshCw,
  XCircle,
} from "lucide-react";

const STATUS_FILTERS = ["open", "reviewed", "actioned", "dismissed", "all"] as const;
type StatusFilter = (typeof STATUS_FILTERS)[number];

const REASON_LABELS: Record<string, string> = {
  inappropriate_behaviour: "Inappropriate behaviour",
  no_show: "No-show",
  safety_concern: "Safety concern",
  fraud_or_scam: "Fraud or scam",
  poor_quality: "Poor quality",
  spam: "Spam",
  other: "Other",
};

function reasonLabel(reason: string): string {
  return REASON_LABELS[reason] ?? "Other";
}

const FILTER_LABELS: Record<StatusFilter, string> = {
  open: "Open",
  reviewed: "Reviewed",
  actioned: "Actioned",
  dismissed: "Dismissed",
  all: "All",
};

// The status transitions an admin can apply, with the button styling for each.
const STATUS_ACTIONS: {
  status: ReportStatus;
  label: string;
  icon: typeof Eye;
}[] = [
  { status: "reviewed", label: "Reviewed", icon: Eye },
  { status: "actioned", label: "Actioned", icon: CheckCheck },
  { status: "dismissed", label: "Dismissed", icon: XCircle },
];

export default function SafetyReportsPage() {
  const [reports, setReports] = useState<SafetyReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("open");

  // Status-change confirmation
  const [statusTarget, setStatusTarget] = useState<{
    report: SafetyReport;
    status: ReportStatus;
  } | null>(null);
  const [updatingStatus, setUpdatingStatus] = useState(false);

  // Suspend confirmation
  const [suspendTarget, setSuspendTarget] = useState<SafetyReport | null>(null);
  const [suspending, setSuspending] = useState(false);

  const fetchReports = useCallback(async (): Promise<SafetyReport[]> => {
    setLoading(true);
    setError(null);
    try {
      const data = await getSafetyReports(statusFilter);
      setReports(data);
      return data;
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load reports");
      return [];
    } finally {
      setLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    fetchReports();
  }, [fetchReports]);

  const confirmStatus = async () => {
    if (!statusTarget) return;
    setUpdatingStatus(true);
    try {
      await updateReportStatus(statusTarget.report.id, statusTarget.status);
      const label = STATUS_ACTIONS.find(
        (a) => a.status === statusTarget.status
      )?.label;
      setStatusTarget(null);
      setNotice(`Report marked as ${label?.toLowerCase() ?? statusTarget.status}`);
      await fetchReports();
    } catch (err) {
      setStatusTarget(null);
      setError(err instanceof Error ? err.message : "Failed to update report");
    } finally {
      setUpdatingStatus(false);
    }
  };

  const confirmSuspend = async () => {
    if (!suspendTarget) return;
    setSuspending(true);
    try {
      await suspendUser(suspendTarget.reported.id);
      const name = suspendTarget.reported.name;
      setSuspendTarget(null);
      setNotice(`${name} has been suspended`);
      await fetchReports();
    } catch (err) {
      setSuspendTarget(null);
      setError(err instanceof Error ? err.message : "Failed to suspend user");
    } finally {
      setSuspending(false);
    }
  };

  return (
    <AppShell>
      <PageHeader
        title="Safety reports"
        subtitle="User-submitted safety and abuse reports awaiting review"
        action={
          <Button variant="outline" size="sm" onClick={fetchReports}>
            <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
            Refresh
          </Button>
        }
      />

      {error && <ErrorBanner message={error} onRetry={fetchReports} />}
      {notice && (
        <SuccessBanner message={notice} onDismiss={() => setNotice(null)} />
      )}

      {/* Status filter row */}
      <div className="mb-6 flex flex-wrap gap-2">
        {STATUS_FILTERS.map((status) => (
          <button
            key={status}
            onClick={() => setStatusFilter(status)}
            className={`inline-flex items-center rounded-full px-4 py-1.5 text-sm font-medium transition-colors ${
              statusFilter === status
                ? "bg-[#6384DB] text-white shadow-sm"
                : "border border-slate-300 bg-white text-slate-600 hover:bg-slate-50"
            }`}
          >
            {FILTER_LABELS[status]}
          </button>
        ))}
      </div>

      {/* Reports list */}
      {loading ? (
        <Card className="p-6">
          <TableSkeleton rows={5} />
        </Card>
      ) : reports.length === 0 ? (
        <Card>
          <EmptyState
            icon={ShieldAlert}
            title="No reports found"
            description={
              statusFilter === "open"
                ? "Safety reports raised in the app will appear here"
                : `No ${statusFilter === "all" ? "" : statusFilter + " "}reports`
            }
          />
        </Card>
      ) : (
        <div className="space-y-4">
          {reports.map((report) => (
            <Card key={report.id} className="p-5">
              {/* Header: reason + status + timestamp */}
              <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
                <div className="flex items-center gap-2.5">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-red-50">
                    <ShieldAlert className="h-5 w-5 text-red-600" />
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-slate-900">
                      {reasonLabel(report.reason)}
                    </p>
                    <p className="text-xs text-slate-400">
                      {formatDate(report.created_at)}
                    </p>
                  </div>
                </div>
                <StatusBadge status={report.status} />
              </div>

              {/* Reporter -> Reported */}
              <div className="mb-4 flex flex-wrap items-center gap-3 rounded-lg border border-slate-200 bg-slate-50 p-3">
                <div className="flex min-w-0 flex-1 items-center gap-2.5">
                  <InitialAvatar name={report.reporter.name} size="sm" />
                  <div className="min-w-0">
                    <p className="truncate text-sm font-medium text-slate-900">
                      {report.reporter.name}
                    </p>
                    <div className="mt-0.5 flex items-center gap-1.5">
                      <StatusBadge status={report.reporter.user_type} />
                      {report.reporter.is_suspended && (
                        <StatusBadge status="suspended" />
                      )}
                    </div>
                  </div>
                </div>

                <ArrowRight className="h-4 w-4 shrink-0 text-slate-400" />

                <div className="flex min-w-0 flex-1 items-center gap-2.5">
                  <InitialAvatar name={report.reported.name} size="sm" />
                  <div className="min-w-0">
                    <p className="truncate text-sm font-medium text-slate-900">
                      {report.reported.name}
                    </p>
                    <div className="mt-0.5 flex items-center gap-1.5">
                      <StatusBadge status={report.reported.user_type} />
                      {report.reported.is_suspended && (
                        <StatusBadge status="suspended" />
                      )}
                    </div>
                  </div>
                </div>
              </div>

              {/* Detail */}
              {report.detail && (
                <div className="mb-4 rounded-lg border-l-4 border-slate-300 bg-slate-50 p-4">
                  <p className="whitespace-pre-wrap text-sm leading-relaxed text-slate-700">
                    {report.detail}
                  </p>
                </div>
              )}

              {/* Related task */}
              {report.task_id && (
                <p className="mb-4 text-xs text-slate-500">
                  Related task:{" "}
                  <span className="font-mono text-slate-700">{report.task_id}</span>
                </p>
              )}

              {/* Actions */}
              <div className="flex flex-wrap items-center gap-2 border-t border-slate-100 pt-4">
                {STATUS_ACTIONS.map((action) => (
                  <Button
                    key={action.status}
                    variant="outline"
                    size="sm"
                    disabled={report.status === action.status}
                    onClick={() =>
                      setStatusTarget({ report, status: action.status })
                    }
                  >
                    <action.icon className="mr-1.5 h-3.5 w-3.5" />
                    {action.label}
                  </Button>
                ))}
                <div className="ml-auto">
                  <Button
                    variant="destructive"
                    size="sm"
                    disabled={report.reported.is_suspended}
                    onClick={() => setSuspendTarget(report)}
                  >
                    <Ban className="mr-1.5 h-3.5 w-3.5" />
                    {report.reported.is_suspended
                      ? "User suspended"
                      : "Suspend reported user"}
                  </Button>
                </div>
              </div>
            </Card>
          ))}
        </div>
      )}

      {/* Status-change confirmation */}
      <ConfirmDialog
        open={!!statusTarget}
        title="Update report status"
        variant="primary"
        message={
          <>
            Mark this report as{" "}
            <span className="font-semibold text-slate-900">
              {statusTarget?.status}
            </span>
            ?
          </>
        }
        confirmLabel="Update status"
        loading={updatingStatus}
        onCancel={() => setStatusTarget(null)}
        onConfirm={confirmStatus}
      />

      {/* Suspend confirmation */}
      <ConfirmDialog
        open={!!suspendTarget}
        title="Suspend reported user"
        message={
          <>
            Suspend{" "}
            <span className="font-semibold text-slate-900">
              {suspendTarget?.reported.name}
            </span>
            ? They will lose access to the app until unsuspended.
          </>
        }
        confirmLabel="Suspend user"
        cancelLabel="Keep active"
        loading={suspending}
        onCancel={() => setSuspendTarget(null)}
        onConfirm={confirmSuspend}
      />
    </AppShell>
  );
}
