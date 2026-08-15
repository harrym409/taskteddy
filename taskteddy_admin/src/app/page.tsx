"use client";

import { useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState, ErrorBanner, Skeleton } from "@/components/ui/feedback";
import { BarChart, AreaChart } from "@/components/charts";
import Link from "next/link";
import {
  Users,
  ListTodo,
  CalendarCheck,
  UserPlus,
  Clock,
  UserCheck,
  IndianRupee,
  RefreshCw,
  Activity,
  ArrowLeftRight,
  ArrowRight,
  TriangleAlert,
  Star,
  Wrench,
  Tags,
  Award,
} from "lucide-react";
import {
  getBookings,
  getDashboardStats,
  getInsights,
  getStatsTimeseries,
  getTransactions,
  getUsers,
} from "@/lib/api";
import { formatCurrency, formatRelativeTime } from "@/lib/utils";
import { InitialAvatar } from "@/components/ui/avatar";
import { StatusBadge } from "@/components/ui/status-badge";
import { DashboardStats, InsightsResponse, TimeseriesPoint } from "@/types";

type ActivityItem = {
  id: string;
  label: string;
  createdAt: string;
  kind: "user" | "transaction";
};

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [statsError, setStatsError] = useState<string | null>(null);
  const [series, setSeries] = useState<TimeseriesPoint[]>([]);
  const [seriesLoading, setSeriesLoading] = useState(true);
  const [seriesError, setSeriesError] = useState<string | null>(null);
  const [activity, setActivity] = useState<ActivityItem[]>([]);
  const [activityLoading, setActivityLoading] = useState(true);
  const [insights, setInsights] = useState<InsightsResponse | null>(null);
  const [insightsLoading, setInsightsLoading] = useState(true);
  const [insightsError, setInsightsError] = useState<string | null>(null);
  const [unassignedCount, setUnassignedCount] = useState(0);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    getBookings()
      .then((data) =>
        setUnassignedCount(
          data.filter(
            (b) => (b.status === "pending" || b.status === "confirmed") && !b.tasker
          ).length
        )
      )
      .catch(() => setUnassignedCount(0));
  }, [reloadKey]);

  useEffect(() => {
    setLoading(true);
    setStatsError(null);
    getDashboardStats()
      .then(setStats)
      .catch((err) =>
        setStatsError(err instanceof Error ? err.message : "Failed to load stats")
      )
      .finally(() => setLoading(false));
  }, [reloadKey]);

  useEffect(() => {
    setSeriesLoading(true);
    setSeriesError(null);
    getStatsTimeseries(14)
      .then((data) => setSeries(data.series || []))
      .catch((err) =>
        setSeriesError(err instanceof Error ? err.message : "Failed to load charts")
      )
      .finally(() => setSeriesLoading(false));
  }, [reloadKey]);

  useEffect(() => {
    setInsightsLoading(true);
    setInsightsError(null);
    getInsights()
      .then(setInsights)
      .catch((err) =>
        setInsightsError(err instanceof Error ? err.message : "Failed to load insights")
      )
      .finally(() => setInsightsLoading(false));
  }, [reloadKey]);

  useEffect(() => {
    setActivityLoading(true);
    Promise.allSettled([getUsers(), getTransactions(10)])
      .then(([usersRes, txRes]) => {
        const items: ActivityItem[] = [];

        if (usersRes.status === "fulfilled") {
          for (const u of usersRes.value.slice(0, 5)) {
            items.push({
              id: `user-${u.id}`,
              label: `New ${u.user_type} registered${u.name ? ` — ${u.name}` : ""}`,
              createdAt: u.created_at,
              kind: "user",
            });
          }
        }

        if (txRes.status === "fulfilled") {
          for (const t of txRes.value.slice(0, 5)) {
            items.push({
              id: `tx-${t.id}`,
              label: t.description || `Transaction — ${formatCurrency(t.amount)}`,
              createdAt: t.created_at,
              kind: "transaction",
            });
          }
        }

        items.sort(
          (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
        );
        setActivity(items.slice(0, 6));
      })
      .catch(console.error)
      .finally(() => setActivityLoading(false));
  }, [reloadKey]);

  const bookings14d = series.reduce((sum, p) => sum + p.bookings, 0);
  const value14d = series.reduce((sum, p) => sum + p.booking_value, 0);
  const newUsers14d = series.reduce((sum, p) => sum + p.new_users, 0);

  const statCards = [
    {
      title: "Total Customers",
      value: stats?.total_customers ?? 0,
      icon: Users,
      delta: newUsers14d > 0 ? `+${newUsers14d} new users in 14 days` : "All time",
    },
    {
      title: "Total Taskers",
      value: stats?.total_taskers ?? 0,
      icon: UserCheck,
      delta: "Active service providers",
    },
    {
      title: "Total Tasks",
      value: stats?.total_tasks ?? 0,
      icon: ListTodo,
      delta: "All time",
    },
    {
      title: "Total Bookings",
      value: stats?.total_bookings ?? 0,
      icon: CalendarCheck,
      delta: bookings14d > 0 ? `+${bookings14d} in last 14 days` : "All time",
    },
    {
      title: "Total Revenue",
      value: formatCurrency(stats?.total_revenue ?? 0),
      icon: IndianRupee,
      delta:
        value14d > 0
          ? `+${formatCurrency(value14d)} booked in 14 days`
          : "Gross booking value",
    },
    {
      title: "Pending Withdrawals",
      value: stats?.pending_withdrawals ?? 0,
      icon: Clock,
      delta: "Awaiting review",
    },
  ];

  const bookingsData = series.map((p) => ({ date: p.date, value: p.bookings }));
  const valueData = series.map((p) => ({ date: p.date, value: p.booking_value }));
  const newUsersData = series.map((p) => ({ date: p.date, value: p.new_users }));
  const maxCategoryBookings = Math.max(
    1,
    ...(insights?.categories ?? []).map((c) => c.bookings)
  );

  return (
    <AppShell>
      <PageHeader
        title="Dashboard"
        subtitle="Platform activity and key metrics at a glance"
        action={
          <Button variant="outline" size="sm" onClick={() => setReloadKey((k) => k + 1)}>
            <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
            Refresh
          </Button>
        }
      />

      {statsError && (
        <ErrorBanner message={statsError} onRetry={() => setReloadKey((k) => k + 1)} />
      )}

      {/* KPI Grid */}
      <div className="mb-6 grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
        {statCards.map((stat) => (
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

      {/* Unassigned bookings callout */}
      {unassignedCount > 0 && (
        <Link
          href="/bookings"
          className="mb-6 flex items-center justify-between gap-3 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 transition-colors hover:bg-amber-100"
        >
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-amber-100">
              <TriangleAlert className="h-4 w-4 text-amber-600" />
            </div>
            <div>
              <p className="text-sm font-semibold text-amber-800">
                {unassignedCount} booking{unassignedCount === 1 ? "" : "s"} awaiting tasker
                assignment
              </p>
              <p className="text-xs text-amber-700">
                Pending and confirmed bookings without an assigned tasker
              </p>
            </div>
          </div>
          <span className="flex shrink-0 items-center gap-1 text-sm font-medium text-amber-800">
            Assign now
            <ArrowRight className="h-4 w-4" />
          </span>
        </Link>
      )}

      {/* Charts */}
      <div className="mb-6 grid grid-cols-1 gap-4 lg:grid-cols-2 xl:grid-cols-3">
        <Card>
          <CardHeader className="flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-base">Bookings</CardTitle>
            <span className="text-xs font-medium text-slate-400">Last 14 days</span>
          </CardHeader>
          <CardContent>
            {seriesLoading ? (
              <Skeleton className="h-[220px] w-full" />
            ) : seriesError ? (
              <div className="flex h-[220px] items-center justify-center text-sm text-red-600">
                {seriesError}
              </div>
            ) : bookingsData.length === 0 ? (
              <div className="flex h-[220px] items-center justify-center text-sm text-slate-500">
                No data yet
              </div>
            ) : (
              <BarChart data={bookingsData} />
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-base">Booking value</CardTitle>
            <span className="text-xs font-medium text-slate-400">Last 14 days</span>
          </CardHeader>
          <CardContent>
            {seriesLoading ? (
              <Skeleton className="h-[220px] w-full" />
            ) : seriesError ? (
              <div className="flex h-[220px] items-center justify-center text-sm text-red-600">
                {seriesError}
              </div>
            ) : valueData.length === 0 ? (
              <div className="flex h-[220px] items-center justify-center text-sm text-slate-500">
                No data yet
              </div>
            ) : (
              <AreaChart data={valueData} />
            )}
          </CardContent>
        </Card>
        <Card className="lg:col-span-2 xl:col-span-1">
          <CardHeader className="flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-base">New users</CardTitle>
            <span className="text-xs font-medium text-slate-400">Last 14 days</span>
          </CardHeader>
          <CardContent>
            {seriesLoading ? (
              <Skeleton className="h-[220px] w-full" />
            ) : seriesError ? (
              <div className="flex h-[220px] items-center justify-center text-sm text-red-600">
                {seriesError}
              </div>
            ) : newUsersData.length === 0 ? (
              <div className="flex h-[220px] items-center justify-center text-sm text-slate-500">
                No data yet
              </div>
            ) : (
              <BarChart data={newUsersData} />
            )}
          </CardContent>
        </Card>
      </div>

      {/* Insights */}
      {insightsError && (
        <ErrorBanner message={insightsError} onRetry={() => setReloadKey((k) => k + 1)} />
      )}
      <div className="mb-6 grid grid-cols-1 gap-4 lg:grid-cols-3">
        <Card>
          <CardHeader className="flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-base">Top services</CardTitle>
            <span className="text-xs font-medium text-slate-400">By bookings</span>
          </CardHeader>
          <CardContent>
            {insightsLoading ? (
              <div className="space-y-3 pt-1">
                {[0, 1, 2, 3].map((i) => (
                  <Skeleton key={i} className="h-10 w-full" />
                ))}
              </div>
            ) : !insights || insights.top_services.length === 0 ? (
              <EmptyState
                icon={Wrench}
                title="No service data yet"
                description="Top booked services will appear here"
              />
            ) : (
              <div className="space-y-3">
                {insights.top_services.map((service, i) => (
                  <div key={service.name} className="flex items-center gap-3">
                    <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-md bg-slate-100 text-xs font-semibold text-slate-500">
                      {i + 1}
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium text-slate-900">
                        {service.name}
                      </p>
                      <p className="text-xs text-slate-500">
                        {service.bookings} booking{service.bookings === 1 ? "" : "s"}
                      </p>
                    </div>
                    <span className="shrink-0 text-sm font-semibold text-slate-900">
                      {formatCurrency(service.value)}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-base">Bookings by category</CardTitle>
            <span className="text-xs font-medium text-slate-400">All time</span>
          </CardHeader>
          <CardContent>
            {insightsLoading ? (
              <div className="space-y-3 pt-1">
                {[0, 1, 2, 3].map((i) => (
                  <Skeleton key={i} className="h-10 w-full" />
                ))}
              </div>
            ) : !insights || insights.categories.length === 0 ? (
              <EmptyState
                icon={Tags}
                title="No category data yet"
                description="Booking categories will appear here"
              />
            ) : (
              <div className="space-y-3">
                {insights.categories.map((cat) => (
                  <div key={cat.category}>
                    <div className="mb-1 flex items-center justify-between gap-3">
                      <p className="truncate text-sm font-medium capitalize text-slate-700">
                        {cat.category}
                      </p>
                      <span className="shrink-0 text-xs font-semibold text-slate-500">
                        {cat.bookings}
                      </span>
                    </div>
                    <div className="h-2 w-full overflow-hidden rounded-full bg-slate-100">
                      <div
                        className="h-full rounded-full bg-[#6384DB]"
                        style={{
                          width: `${Math.max(
                            (cat.bookings / maxCategoryBookings) * 100,
                            cat.bookings > 0 ? 4 : 0
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

        <Card>
          <CardHeader className="flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-base">Top taskers</CardTitle>
            <span className="text-xs font-medium text-slate-400">By completions</span>
          </CardHeader>
          <CardContent>
            {insightsLoading ? (
              <div className="space-y-3 pt-1">
                {[0, 1, 2, 3].map((i) => (
                  <Skeleton key={i} className="h-10 w-full" />
                ))}
              </div>
            ) : !insights || insights.top_taskers.length === 0 ? (
              <EmptyState
                icon={Award}
                title="No tasker data yet"
                description="Top performing taskers will appear here"
              />
            ) : (
              <div className="space-y-3">
                {insights.top_taskers.map((tasker) => (
                  <div key={tasker.id} className="flex items-center gap-3">
                    <InitialAvatar name={tasker.name} size="sm" />
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <p className="truncate text-sm font-medium text-slate-900">
                          {tasker.name}
                        </p>
                        {tasker.is_verified && <StatusBadge status="verified" />}
                      </div>
                      <p className="inline-flex items-center gap-1 text-xs text-slate-500">
                        <Star className="h-3 w-3 fill-amber-400 text-amber-400" />
                        {tasker.rating.toFixed(1)}
                      </p>
                    </div>
                    <span className="shrink-0 text-xs text-slate-500">
                      <span className="font-semibold text-slate-900">
                        {tasker.completed_bookings}
                      </span>{" "}
                      completed
                    </span>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Recent Activity */}
      <Card>
        <CardHeader className="flex-row items-center justify-between space-y-0">
          <CardTitle className="text-base">Recent Activity</CardTitle>
          <span className="text-xs font-medium text-slate-400">
            Latest signups and wallet movement
          </span>
        </CardHeader>
        <CardContent>
          {activityLoading ? (
            <div className="space-y-3">
              {[0, 1, 2].map((i) => (
                <div key={i} className="h-14 animate-pulse rounded-lg bg-slate-100" />
              ))}
            </div>
          ) : activity.length === 0 ? (
            <EmptyState
              icon={Activity}
              title="No recent activity"
              description="New signups and transactions will appear here"
            />
          ) : (
            <div className="space-y-3">
              {activity.map((item) => {
                const isUser = item.kind === "user";
                const Icon = isUser ? UserPlus : ArrowLeftRight;
                return (
                  <div
                    key={item.id}
                    className="flex items-center gap-4 rounded-lg border border-slate-100 p-3.5 transition-colors hover:bg-slate-50"
                  >
                    <div
                      className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-lg ${
                        isUser ? "bg-emerald-50" : "bg-blue-50"
                      }`}
                    >
                      <Icon
                        className={`h-4 w-4 ${
                          isUser ? "text-emerald-600" : "text-[#6384DB]"
                        }`}
                      />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium text-slate-800">
                        {item.label}
                      </p>
                      <p className="text-xs text-slate-500">
                        {formatRelativeTime(item.createdAt)}
                      </p>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </AppShell>
  );
}
