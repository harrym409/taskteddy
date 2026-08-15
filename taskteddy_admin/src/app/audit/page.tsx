"use client";

import { useEffect, useState } from "react";
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
import { EmptyState, ErrorBanner, TableSkeleton } from "@/components/ui/feedback";
import { formatDate } from "@/lib/utils";
import { getAuditLogs } from "@/lib/api";
import { AuditLog } from "@/types";
import { RefreshCw, ScrollText } from "lucide-react";

export default function AuditLogPage() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    setLoading(true);
    setError(null);
    getAuditLogs(100)
      .then(setLogs)
      .catch((err) =>
        setError(err instanceof Error ? err.message : "Failed to load audit logs")
      )
      .finally(() => setLoading(false));
  }, [reloadKey]);

  return (
    <AppShell>
      <PageHeader
        title="Audit log"
        subtitle="Every admin action, recorded"
        action={
          <Button variant="outline" size="sm" onClick={() => setReloadKey((k) => k + 1)}>
            <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
            Refresh
          </Button>
        }
      />

      {error && (
        <ErrorBanner message={error} onRetry={() => setReloadKey((k) => k + 1)} />
      )}

      <Card className="overflow-hidden">
        {loading ? (
          <div className="p-6">
            <TableSkeleton rows={8} />
          </div>
        ) : logs.length === 0 ? (
          <EmptyState
            icon={ScrollText}
            title="No audit entries yet"
            description="Admin actions will be recorded here as they happen"
          />
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Time</TableHead>
                <TableHead>Admin</TableHead>
                <TableHead>Action</TableHead>
                <TableHead>Target</TableHead>
                <TableHead>Detail</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {logs.map((log) => (
                <TableRow key={log.id}>
                  <TableCell className="whitespace-nowrap text-slate-500">
                    {formatDate(log.created_at)}
                  </TableCell>
                  <TableCell className="font-medium text-slate-900">
                    {log.admin_email}
                  </TableCell>
                  <TableCell>
                    <span className="inline-flex items-center whitespace-nowrap rounded-full border border-slate-200 bg-slate-100 px-2.5 py-0.5 font-mono text-xs font-medium text-slate-700">
                      {log.action}
                    </span>
                  </TableCell>
                  <TableCell>
                    {log.target_type || log.target_id ? (
                      <span className="text-sm">
                        <span className="capitalize text-slate-700">
                          {log.target_type}
                        </span>{" "}
                        <span className="font-mono text-xs text-slate-400">
                          {log.target_id ? log.target_id.slice(0, 8) : ""}
                        </span>
                      </span>
                    ) : (
                      <span className="text-slate-400">-</span>
                    )}
                  </TableCell>
                  <TableCell className="max-w-sm truncate text-slate-500">
                    {log.detail || <span className="text-slate-400">-</span>}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Card>
    </AppShell>
  );
}
