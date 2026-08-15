"use client";

import { useCallback, useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState, ErrorBanner, Skeleton } from "@/components/ui/feedback";
import { AreaChart, BarChart, MultiLineChart } from "@/components/charts";
import { StatusBadge } from "@/components/ui/status-badge";
import {
  getAnalyticsCategories,
  getAnalyticsSummary,
  getAnalyticsTimeseries,
} from "@/lib/api";
import { formatCurrency } from "@/lib/utils";
import {
  AnalyticsCategory,
  AnalyticsSummary,
  AnalyticsTimeseries,
} from "@/types";
import {
  Users,
  UserCheck,
  CalendarCheck,
  IndianRupee,
  Wallet,
  TrendingUp,
  TrendingDown,
  RefreshCw,
  Tags,
  BadgeCheck,
  CircleCheckBig,
} from "lucide-react";

const RANGE_OPTIONS = [7, 30, 90] as const;
type Range = (typeof RANGE_OPTIONS)[number];

const CUSTOMER_COLOR = "#6384DB";
const TASKER_COLOR = "#14b8a6";

export default function AnalyticsPage() {
  const [summary, setSummary] = useState<AnalyticsSummary | null>(null);
  const [summaryLoading, setSummaryLoading] = useState(true);
  const [summaryError, setSummaryError] = useState<string | null>(null);

  const [range, setRange] = useState<Range>(30);
  const [series, setSeries] = useState<AnalyticsTimeseries | null>(null);
  const [seriesLoading, setSeriesLoading] = useState(true);
  const [seriesError, setSeriesError] = useState<string | null>(null);

  const [categories, setCategories] = useState<AnalyticsCategory[]>([]);
  const [categoriesLoading, setCategoriesLoading] = useState(true);
  const [categoriesError, setCategoriesError] = useState<string | null>(null);

  const [reloadKey, setReloadKey] = useState(0);

  const loadSummary = useCallback(() => {
    setSummaryLoading(true);
    setSummaryError(null);
    getAnalyticsSummary()
      .then(setSummary)
      .catch((err) =>
        setSummaryError(err instanceof Error ? err.message : "Failed to load summary")
      )
      .finally(() => setSummaryLoading(false));
  }, []);

  const loadCategories = useCallback(() => {
    setCategoriesLoading(true);
    setCategoriesError(null);
    getAnalyticsCategories()
      .then(setCategories)
      .catch((err) =>
        setCategoriesError(err instanceof Error ? err.message : "Failed to load categories")
      )
      .finally(() => setCategoriesLoading(false));
  }, []);

  useEffect(() => {
    loadSummary();
    loadCategories();
  }, [loadSummary, loadCategories, reloadKey]);

  useEffect(() => {
    setSeriesLoading(true);
    setSeriesError(null);
    getAnalyticsTimeseries(range)
      .then(setSeries)
      .catch((err) =>
        setSeriesError(err instanceof Error ? err.message : "Failed to load charts")
      )
      .finally(() => setSeriesLoading(false));
  }, [range, reloadKey]);

  const growth = summary?.bookings_growth_percent ?? 0;
  const growthUp = growth >= 0;

  const kpiCards: {
    title: string;
    value: string | number;
    icon: typeof Users;
    delta: string;
  }[] = [
    {
      title: "Total Customers",
      value: summary?.total_customers ?? 0,
      icon: Users,
      delta: "Registered customers",
    },
    {
      title: "Total Taskers",
      value: summary?.total_taskers ?? 0,
      icon: UserCheck,
      delta: `${summary?.verified_taskers ?? 0} verified`,
    },
    {
      title: "Total Bookings",
      value: summary?.total_bookings ?? 0,
      icon: CalendarCheck,
      delta: `${summary?.completed_bookings ?? 0} completed`,
    },
    {
      title: "GMV",
      value: formatCurrency(summary?.gmv ?? 0),
      icon: IndianRupee,
      delta: "Gross booking value",
    },
    {
      title: "Platform Revenue",
      value: formatCurrency(summary?.platform_revenue ?? 0),
      icon: BadgeCheck,
      delta: `${summary?.commission_percent ?? 0}% commission`,
    },
    {
      title: "Pending Payouts",
      value: formatCurrency(summary?.pending_payout_amount ?? 0),
      icon: Wallet,
      delta: `${summary?.pending_withdrawals ?? 0} awaiting review`,
    },
  ];

  const maxCategoryCount = Math.max(1, ...categories.map((c) => c.count));

  return (
    <AppShell>
      <PageHeader
        title="Analytics"
        subtitle="Platform performance, growth and revenue trends"
        action={
          <Button variant="outline" size="sm" onClick={() => setReloadKey((k) => k + 1)}>
            <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
            Refresh
          </Button>
        }
      />

      {summaryError && (
        <ErrorBanner message={summaryError} onRetry={() => setReloadKey((k) => k + 1)} />
      )}

      {/* KPI grid */}
      <div className="mb-6 grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
        {kpiCards.map((stat) => (
          <div
            key={stat.title}
            className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm"
          >
            <div className="flex items-start justify-between">
              <div className="min-w-0">
                <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">
                  {stat.title}
                </p>
                {summaryLoading ? (
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

      {/* Growth callout */}
      <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">
            Bookings (last 7 days)
          </p>
          <div className="mt-2 flex items-baseline gap-3">
            {summaryLoading ? (
              <Skeleton className="h-8 w-32" />
            ) : (
              <>
                <span className="text-2xl font-bold text-slate-900">
                  {summary?.bookings_last_7d ?? 0}
                </span>
                <span
                  className={`inline-flex items-center gap-1 text-sm font-semibold ${
                    growthUp ? "text-emerald-600" : "text-red-600"
                  }`}
                >
                  {growthUp ? (
                    <TrendingUp className="h-4 w-4" />
                  ) : (
                    <TrendingDown className="h-4 w-4" />
                  )}
                  {growthUp ? "+" : ""}
                  {growth.toFixed(1)}%
                </span>
              </>
            )}
          </div>
          <p className="mt-1 text-xs text-slate-400">
            Compared with the previous 7-day period
          </p>
        </div>
        <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">
            Completion rate
          </p>
          <div className="mt-2 flex items-baseline gap-2">
            {summaryLoading ? (
              <Skeleton className="h-8 w-24" />
            ) : (
              <span className="inline-flex items-center gap-2 text-2xl font-bold text-slate-900">
                <CircleCheckBig className="h-5 w-5 text-emerald-500" />
                {summary && summary.total_bookings > 0
                  ? `${((summary.completed_bookings / summary.total_bookings) * 100).toFixed(0)}%`
                  : "0%"}
              </span>
            )}
          </div>
          <p className="mt-1 text-xs text-slate-400">
            {summary?.completed_bookings ?? 0} of {summary?.total_bookings ?? 0} bookings
            completed
          </p>
        </div>
      </div>

      {/* Range switcher */}
      <div className="mb-4 flex items-center justify-between gap-3">
        <h2 className="text-sm font-semibold uppercase tracking-wider text-slate-500">
          Trends
        </h2>
        <div className="inline-flex rounded-lg border border-slate-200 bg-white p-1 shadow-sm">
          {RANGE_OPTIONS.map((opt) => (
            <button
              key={opt}
              onClick={() => setRange(opt)}
              className={`rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${
                range === opt
                  ? "bg-[#6384DB] text-white shadow-sm"
                  : "text-slate-600 hover:bg-slate-50"
              }`}
            >
              {opt}d
            </button>
          ))}
        </div>
      </div>

      {seriesError && (
        <ErrorBanner message={seriesError} onRetry={() => setReloadKey((k) => k + 1)} />
      )}

      {/* Time-series charts */}
      <div className="mb-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader className="flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-base">Bookings</CardTitle>
            <span className="text-xs font-medium text-slate-400">Last {range} days</span>
          </CardHeader>
          <CardContent>
            {seriesLoading ? (
              <Skeleton className="h-[220px] w-full" />
            ) : (
              <BarChart data={series?.bookings ?? []} />
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-base">Platform revenue</CardTitle>
            <span className="text-xs font-medium text-slate-400">Last {range} days</span>
          </CardHeader>
          <CardContent>
            {seriesLoading ? (
              <Skeleton className="h-[220px] w-full" />
            ) : (
              <AreaChart data={series?.revenue ?? []} />
            )}
          </CardContent>
        </Card>
      </div>

      {/* User growth + categories */}
      <div className="mb-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader className="flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-base">User growth</CardTitle>
            <span className="text-xs font-medium text-slate-400">New signups</span>
          </CardHeader>
          <CardContent>
            {seriesLoading ? (
              <Skeleton className="h-[220px] w-full" />
            ) : (
              <MultiLineChart
                series={[
                  {
                    name: "New customers",
                    color: CUSTOMER_COLOR,
                    data: series?.new_customers ?? [],
                  },
                  {
                    name: "New taskers",
                    color: TASKER_COLOR,
                    data: series?.new_taskers ?? [],
                  },
                ]}
              />
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-base">Bookings by category</CardTitle>
            <span className="text-xs font-medium text-slate-400">Volume and value</span>
          </CardHeader>
          <CardContent>
            {categoriesLoading ? (
              <div className="space-y-3 pt-1">
                {[0, 1, 2, 3].map((i) => (
                  <Skeleton key={i} className="h-10 w-full" />
                ))}
              </div>
            ) : categoriesError ? (
              <div className="flex h-[180px] items-center justify-center text-sm text-red-600">
                {categoriesError}
              </div>
            ) : categories.length === 0 ? (
              <EmptyState
                icon={Tags}
                title="No category data yet"
                description="Booking categories will appear here"
              />
            ) : (
              <div className="space-y-3">
                {categories.map((cat) => (
                  <div key={cat.category}>
                    <div className="mb-1 flex items-center justify-between gap-3">
                      <p className="truncate text-sm font-medium capitalize text-slate-700">
                        {cat.category}
                      </p>
                      <span className="shrink-0 text-xs text-slate-500">
                        <span className="font-semibold text-slate-700">{cat.count}</span>{" "}
                        · {formatCurrency(cat.value)}
                      </span>
                    </div>
                    <div className="h-2 w-full overflow-hidden rounded-full bg-slate-100">
                      <div
                        className="h-full rounded-full bg-[#6384DB]"
                        style={{
                          width: `${Math.max(
                            (cat.count / maxCategoryCount) * 100,
                            cat.count > 0 ? 4 : 0
                          )}%`,
                        }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Verified taskers strip */}
      {summary && (
        <Card>
          <CardContent className="flex flex-wrap items-center gap-x-8 gap-y-3 p-5">
            <div className="flex items-center gap-2 text-sm text-slate-600">
              <StatusBadge status="verified" />
              <span>
                <span className="font-semibold text-slate-900">
                  {summary.verified_taskers}
                </span>{" "}
                of {summary.total_taskers} taskers verified
              </span>
            </div>
            <div className="text-sm text-slate-600">
              GMV{" "}
              <span className="font-semibold text-slate-900">
                {formatCurrency(summary.gmv)}
              </span>{" "}
              · Revenue{" "}
              <span className="font-semibold text-slate-900">
                {formatCurrency(summary.platform_revenue)}
              </span>{" "}
              at {summary.commission_percent}% commission
            </div>
          </CardContent>
        </Card>
      )}
    </AppShell>
  );
}
