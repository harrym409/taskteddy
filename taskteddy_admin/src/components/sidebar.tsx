"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { cn } from "@/lib/utils";
import { adminLogout, getQueueCounts, getAdminRole } from "@/lib/api";
import { QueueCounts, AdminRole } from "@/types";
import {
  LayoutDashboard,
  LineChart,
  Megaphone,
  Users,
  ListTodo,
  Wrench,
  CalendarCheck,
  Wallet,
  FileText,
  Gavel,
  ClipboardCheck,
  Star,
  Settings,
  ScrollText,
  Activity,
  ShieldCheck,
  ShieldAlert,
  LifeBuoy,
  UserCog,
  LogOut,
  PanelLeftClose,
  PanelLeftOpen,
} from "lucide-react";

type BadgeTone = "amber" | "slate";

interface SidebarItem {
  href: string;
  label: string;
  icon: typeof LayoutDashboard;
  badge?: { key: keyof QueueCounts; tone: BadgeTone };
  // Which roles may see this item. Omitted = visible to every role.
  roles?: AdminRole[];
}

interface SidebarSection {
  label: string;
  items: SidebarItem[];
}

const MANAGER: AdminRole[] = ["superadmin", "admin"];

const sidebarSections: SidebarSection[] = [
  {
    label: "Overview",
    items: [
      { href: "/", label: "Dashboard", icon: LayoutDashboard },
      { href: "/analytics", label: "Analytics", icon: LineChart, roles: MANAGER },
    ],
  },
  {
    label: "Management",
    items: [
      { href: "/users", label: "Users", icon: Users },
      { href: "/verifications", label: "Verifications", icon: ShieldCheck, roles: MANAGER },
      { href: "/tasks", label: "Tasks", icon: ListTodo },
      {
        href: "/review-queue",
        label: "Review queue",
        icon: ClipboardCheck,
        badge: { key: "review_queue", tone: "amber" },
      },
      { href: "/services", label: "Services", icon: Wrench, roles: MANAGER },
      { href: "/bookings", label: "Bookings", icon: CalendarCheck, roles: MANAGER },
      { href: "/disputes", label: "Disputes", icon: Gavel },
      {
        href: "/reports-safety",
        label: "Safety reports",
        icon: ShieldAlert,
        badge: { key: "safety_reports", tone: "amber" },
      },
    ],
  },
  {
    label: "Finance",
    items: [
      {
        href: "/wallet",
        label: "Wallet",
        icon: Wallet,
        badge: { key: "pending_withdrawals", tone: "slate" },
        roles: MANAGER,
      },
      { href: "/reports", label: "Financial report", icon: FileText, roles: MANAGER },
    ],
  },
  {
    label: "Platform",
    items: [
      { href: "/announcements", label: "Announcements", icon: Megaphone, roles: MANAGER },
      {
        href: "/support",
        label: "Support",
        icon: LifeBuoy,
        badge: { key: "open_tickets", tone: "slate" },
      },
      { href: "/audit", label: "Audit log", icon: ScrollText, roles: MANAGER },
      { href: "/reviews", label: "Reviews", icon: Star },
      { href: "/team", label: "Team", icon: UserCog, roles: ["superadmin"] },
      { href: "/settings", label: "Settings", icon: Settings, roles: MANAGER },
      { href: "/system", label: "System", icon: Activity, roles: MANAGER },
    ],
  },
];

const BADGE_TONES: Record<BadgeTone, string> = {
  amber: "bg-amber-500 text-white",
  slate: "bg-slate-600 text-white",
};

// A pill for the expanded rail: sits after the label, pushed to the right.
function CountBadge({ tone, count }: { tone: BadgeTone; count: number }) {
  return (
    <span
      className={cn(
        "ml-auto inline-flex min-w-[1.25rem] items-center justify-center rounded-full px-1.5 py-0.5 text-[11px] font-semibold leading-none tabular-nums",
        BADGE_TONES[tone]
      )}
    >
      {count > 99 ? "99+" : count}
    </span>
  );
}

// A tiny count nub overlaid on the icon in the collapsed rail.
function CountDot({ tone, count }: { tone: BadgeTone; count: number }) {
  return (
    <span
      className={cn(
        "absolute right-1 top-0.5 inline-flex h-4 min-w-[1rem] items-center justify-center rounded-full px-1 text-[9px] font-semibold leading-none tabular-nums ring-2 ring-slate-900",
        BADGE_TONES[tone]
      )}
    >
      {count > 9 ? "9+" : count}
    </span>
  );
}

export function Sidebar({
  collapsed = false,
  onToggle,
}: {
  collapsed?: boolean;
  onToggle?: () => void;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const [counts, setCounts] = useState<QueueCounts | null>(null);
  const [role, setRole] = useState<AdminRole | null>(null);

  // Read the signed-in role once mounted (localStorage is client-only).
  useEffect(() => setRole(getAdminRole()), []);

  // Hide items the current role isn't allowed to see; drop empty sections.
  const visibleSections = sidebarSections
    .map((section) => ({
      ...section,
      items: section.items.filter(
        (item) => !item.roles || (role != null && item.roles.includes(role))
      ),
    }))
    .filter((section) => section.items.length > 0);

  // Live queue counts: fetch on mount, then poll every 30s. Failures are
  // swallowed so a transient/network error never breaks the shell chrome.
  useEffect(() => {
    let active = true;
    const load = async () => {
      try {
        const data = await getQueueCounts();
        if (active) setCounts(data);
      } catch {
        /* silent: keep the last known counts, don't disrupt navigation */
      }
    };
    load();
    const id = setInterval(load, 30000);
    return () => {
      active = false;
      clearInterval(id);
    };
  }, []);

  const handleLogout = async () => {
    await adminLogout();
    router.replace("/login");
  };

  return (
    <aside
      className={cn(
        "fixed left-0 top-0 z-40 flex h-screen flex-col bg-slate-900 transition-[width] duration-200",
        collapsed ? "w-16" : "w-64"
      )}
    >
      {/* Logo + collapse toggle */}
      <div
        className={cn(
          "flex h-16 shrink-0 items-center border-b border-slate-800",
          collapsed ? "justify-center px-0" : "justify-between px-5"
        )}
      >
        {collapsed ? (
          <button
            type="button"
            onClick={onToggle}
            title="Expand menu"
            aria-label="Expand menu"
            className="flex h-10 w-10 items-center justify-center rounded-lg transition-colors hover:bg-slate-800"
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/favicon.png" alt="TaskTeddy" className="h-7 w-7" />
          </button>
        ) : (
          <>
            <Link href="/" className="flex items-center">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/logo-white.png" alt="TaskTeddy" className="h-7 w-auto" />
            </Link>
            <button
              type="button"
              onClick={onToggle}
              title="Collapse menu"
              aria-label="Collapse menu"
              className="flex h-8 w-8 items-center justify-center rounded-lg text-slate-400 transition-colors hover:bg-slate-800 hover:text-white"
            >
              <PanelLeftClose className="h-[18px] w-[18px]" />
            </button>
          </>
        )}
      </div>

      {/* Navigation */}
      <nav
        className={cn(
          "flex-1 overflow-y-auto py-5",
          collapsed ? "space-y-2 px-2" : "space-y-6 px-3"
        )}
      >
        {visibleSections.map((section) => (
          <div key={section.label}>
            {!collapsed && (
              <p className="mb-1.5 px-3 text-[10px] font-semibold uppercase tracking-widest text-slate-500">
                {section.label}
              </p>
            )}
            {collapsed && <div className="mx-2 mb-2 border-t border-slate-800" />}
            <div className="space-y-1">
              {section.items.map((item) => {
                const isActive =
                  pathname === item.href ||
                  (item.href !== "/" && pathname.startsWith(item.href));

                const count = item.badge ? counts?.[item.badge.key] ?? 0 : 0;
                const showBadge = !!item.badge && count > 0;

                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    title={collapsed ? item.label : undefined}
                    className={cn(
                      "relative flex items-center rounded-lg text-sm font-medium transition-colors",
                      collapsed
                        ? "justify-center px-0 py-2.5"
                        : "gap-3 px-3 py-2",
                      isActive
                        ? "bg-[#6384DB] text-white shadow-sm"
                        : "text-slate-300 hover:bg-slate-800 hover:text-white"
                    )}
                  >
                    <item.icon
                      className={cn(
                        "h-[18px] w-[18px] shrink-0",
                        isActive ? "text-white" : "text-slate-400"
                      )}
                    />
                    {!collapsed && <span className="truncate">{item.label}</span>}
                    {!collapsed && showBadge && item.badge && (
                      <CountBadge tone={item.badge.tone} count={count} />
                    )}
                    {collapsed && showBadge && item.badge && (
                      <CountDot tone={item.badge.tone} count={count} />
                    )}
                  </Link>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      {/* Expand button (collapsed) + Logout */}
      <div className="shrink-0 border-t border-slate-800 p-3">
        {collapsed && (
          <button
            type="button"
            onClick={onToggle}
            title="Expand menu"
            aria-label="Expand menu"
            className="mb-1 flex w-full items-center justify-center rounded-lg py-2.5 text-slate-400 transition-colors hover:bg-slate-800 hover:text-white"
          >
            <PanelLeftOpen className="h-[18px] w-[18px]" />
          </button>
        )}
        <button
          onClick={handleLogout}
          title={collapsed ? "Logout" : undefined}
          className={cn(
            "flex w-full items-center rounded-lg text-sm font-medium text-red-300 transition-colors hover:bg-red-500/10 hover:text-red-200",
            collapsed ? "justify-center px-0 py-2.5" : "gap-3 px-3 py-2"
          )}
        >
          <LogOut className="h-[18px] w-[18px] shrink-0" />
          {!collapsed && "Logout"}
        </button>
        {!collapsed && (
          <p className="mt-2 px-3 text-[10px] text-slate-600">
            TaskTeddy Admin v1.0
          </p>
        )}
      </div>
    </aside>
  );
}
