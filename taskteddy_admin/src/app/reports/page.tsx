"use client";

import { useCallback, useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { StatusBadge } from "@/components/ui/status-badge";
import { ErrorBanner, Skeleton, TableSkeleton } from "@/components/ui/feedback";
import { getAnalyticsPayouts, getAnalyticsSummary } from "@/lib/api";
import { exportCsv } from "@/lib/csv";
import { formatCurrency } from "@/lib/utils";
import { AnalyticsPayouts, AnalyticsSummary } from "@/types";
import {
  BadgeCheck,
  Download,
  HandCoins,
  IndianRupee,
  RefreshCw,
  Wallet,
} from "lucide-react";

// Canonical order for the withdrawal-status rollup rows.
const STATUS_ORDER = ["pending", "approved", "completed", "rejected"];

function orderedStatuses(byStatus: Record<string, { count: number; amount: number }>) {
  const known = STATUS_ORDER.filter((s) => s in byStatus);
  const extra = Object.keys(byStatus).filter((s) => !STATUS_ORDER.includes(s));
  return [...known, ...extra];
}

export default function ReportsPage() {
  const [payouts, setPayouts] = useState<AnalyticsPayouts | null>(null);
  const [summary, setSummary] = useState<AnalyticsSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [payoutsData, summaryData] = await Promise.all([
        getAnalyticsPayouts(),
        getAnalyticsSummary(),
      ]);
      setPayouts(payoutsData);
      setSummary(summaryData);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load financial report");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const statuses = payouts ? orderedStatuses(payouts.by_status) : [];
  const totalCount = statuses.reduce((sum, s) => sum + payouts!.by_status[s].count, 0);
  const totalAmount = statuses.reduce((sum, s) => sum + payouts!.by_status[s].amount, 0);

  const handleExport = () => {
    if (!payouts || !summary) return;
    const rows: (string | number)[][] = statuses.map((s) => [
      s,
      payouts.by_status[s].count,
      payouts.by_status[s].amount,
    ]);
    rows.push(["TOTAL", totalCount, totalAmount]);
    rows.push([]);
    rows.push(["Total paid out", "", payouts.total_paid_out]);
    rows.push(["Total tasker earnings", "", payouts.total_tasker_earnings]);
    rows.push(["Platform revenue", "", summary.platform_revenue]);
    rows.push(["GMV", "", summary.gmv]);
    rows.push(["Commission percent", "", summary.commission_percent]);
    exportCsv("financial-report", ["Status", "Count", "Amount"], rows);
  };

  const summaryCards = [
    {
      title: "Platform Revenue",
      value: summary ? formatCurrency(summary.platform_revenue) : "-",
      icon: BadgeCheck,
      delta: summary ? `${summary.commission_percent}% commission on GMV` : "",
    },
    {
      title: "Total Tasker Earnings",
      value: payouts ? formatCurrency(payouts.total_tasker_earnings) : "-",
      icon: IndianRupee,
      delta: "Net earnings owed to taskers",
    },
    {
      title: "Total Paid Out",
      value: payouts ? formatCurrency(payouts.total_paid_out) : "-",
      icon: HandCoins,
      delta: "Approved and completed withdrawals",
    },
    {
      title: "Pending Payouts",
      value: summary ? formatCurrency(summary.pending_payout_amount) : "-",
      icon: Wallet,
      delta: summary ? `${summary.pending_withdrawals} awaiting review` : "",
    },
  ];

  return (
    <AppShell>
      <PageHeader
        title="Financial report"
        subtitle="Revenue, tasker earnings and withdrawal payouts"
        action={
          <>
            <Button variant="outline" size="sm" onClick={fetchData}>
              <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
              Refresh
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={handleExport}
              disabled={loading || !payouts || !summary}
            >
              <Download className="mr-1.5 h-3.5 w-3.5" />
              Export CSV
            </Button>
          </>
        }
      />

      {error && <ErrorBanner message={error} onRetry={fetchData} />}

      {/* Summary cards */}
      <div className="mb-6 grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
        {summaryCards.map((stat) => (
          <div
            key={stat.title}
            className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <div className="flex items-start justify-between">
              <div className="min-w-0">
                <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">
                  {stat.title}
                </p>
                {loading ? (
                  <Skeleton className="mt-2 h-8 w-24" />
                ) : (
                  <p className="mt-1.5 truncate text-2xl font-bold text-slate-900">
                    {stat.value}
                  </p>
                )}
              </div>
              <div className="ml-4 flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-blue-50">
                <stat.icon className="h-5 w-5 text-[#6384DB]" />
              </div>
            </div>
            <p className="mt-2 truncate text-xs text-slate-400">{stat.delta}</p>
          </div>
        ))}
      </div>

      {/* Withdrawals by status */}
      <Card className="overflow-hidden">
        <CardHeader>
          <CardTitle className="text-base">Withdrawals by status</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {loading ? (
            <div className="p-6">
              <TableSkeleton rows={4} />
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Requests</TableHead>
                  <TableHead className="text-right">Amount</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {statuses.map((status) => (
                  <TableRow key={status}>
                    <TableCell>
                      <StatusBadge status={status} />
                    </TableCell>
                    <TableCell className="text-right font-medium text-slate-900">
                      {payouts!.by_status[status].count}
                    </TableCell>
                    <TableCell className="text-right font-semibold text-slate-900">
                      {formatCurrency(payouts!.by_status[status].amount)}
                    </TableCell>
                  </TableRow>
                ))}
                <TableRow className="bg-slate-50 hover:bg-slate-50">
                  <TableCell className="font-semibold text-slate-900">Total</TableCell>
                  <TableCell className="text-right font-semibold text-slate-900">
                    {totalCount}
                  </TableCell>
                  <TableCell className="text-right font-semibold text-slate-900">
                    {formatCurrency(totalAmount)}
                  </TableCell>
                </TableRow>
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </AppShell>
  );
}
