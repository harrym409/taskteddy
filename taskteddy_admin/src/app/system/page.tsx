"use client";

import { useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { StatusBadge } from "@/components/ui/status-badge";
import { ErrorBanner, Skeleton } from "@/components/ui/feedback";
import { formatDate } from "@/lib/utils";
import { getSystemHealth } from "@/lib/api";
import { SystemHealth } from "@/types";
import {
  Bell,
  CalendarCheck,
  Database,
  ListTodo,
  RefreshCw,
  ScrollText,
  Server,
  Users,
  Wrench,
  Zap,
} from "lucide-react";

export default function SystemPage() {
  const [health, setHealth] = useState<SystemHealth | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    setLoading(true);
    setError(null);
    getSystemHealth()
      .then(setHealth)
      .catch((err) =>
        setError(err instanceof Error ? err.message : "Failed to load system health")
      )
      .finally(() => setLoading(false));
  }, [reloadKey]);

  const statusCards = [
    {
      title: "Environment",
      icon: Server,
      status: health?.environment ?? "-",
      isBadge: false,
      description: "Runtime configuration",
    },
    {
      title: "Database",
      icon: Database,
      status: health?.database ?? "-",
      isBadge: true,
      description: "Primary data store",
    },
    {
      title: "Redis",
      icon: Zap,
      status: health?.redis ?? "-",
      isBadge: true,
      description: "Cache and queues",
    },
  ];

  const countTiles = [
    { label: "Users", value: health?.counts.users, icon: Users },
    { label: "Services", value: health?.counts.services, icon: Wrench },
    { label: "Bookings", value: health?.counts.bookings, icon: CalendarCheck },
    { label: "Tasks", value: health?.counts.tasks, icon: ListTodo },
    { label: "Notifications", value: health?.counts.notifications, icon: Bell },
    { label: "Audit logs", value: health?.counts.audit_logs, icon: ScrollText },
  ];

  return (
    <AppShell>
      <PageHeader
        title="System health"
        subtitle="Live status of the platform's core infrastructure"
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

      {/* Status cards */}
      <div className="mb-6 grid grid-cols-1 gap-4 md:grid-cols-3">
        {statusCards.map((card) => (
          <div
            key={card.title}
            className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <div className="flex items-start justify-between">
              <div className="min-w-0">
                <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">
                  {card.title}
                </p>
                {loading ? (
                  <Skeleton className="mt-2 h-6 w-24" />
                ) : card.isBadge ? (
                  <div className="mt-2">
                    <StatusBadge status={card.status} />
                  </div>
                ) : (
                  <p className="mt-1.5 truncate text-xl font-bold capitalize text-slate-900">
                    {card.status}
                  </p>
                )}
              </div>
              <div className="ml-4 flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-blue-50">
                <card.icon className="h-5 w-5 text-[#6384DB]" />
              </div>
            </div>
            <p className="mt-2 truncate text-xs text-slate-400">{card.description}</p>
          </div>
        ))}
      </div>

      {/* Counts grid */}
      <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-6">
        {countTiles.map((tile) => (
          <div
            key={tile.label}
            className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm"
          >
            <div className="flex items-center gap-2">
              <tile.icon className="h-4 w-4 shrink-0 text-slate-400" />
              <p className="truncate text-xs font-semibold uppercase tracking-wider text-slate-500">
                {tile.label}
              </p>
            </div>
            {loading ? (
              <Skeleton className="mt-2 h-7 w-16" />
            ) : (
              <p className="mt-1.5 text-2xl font-bold text-slate-900">
                {(tile.value ?? 0).toLocaleString("en-IN")}
              </p>
            )}
          </div>
        ))}
      </div>

      {/* Checked at */}
      {health?.checked_at && !loading && (
        <p className="mt-4 text-xs text-slate-400">
          Checked at {formatDate(health.checked_at)}
        </p>
      )}
    </AppShell>
  );
}
