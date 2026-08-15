import * as React from "react";
import { cn } from "@/lib/utils";

type Tone = "green" | "amber" | "red" | "blue" | "violet" | "teal" | "slate";

const CHIP_STYLES: Record<Tone, string> = {
  green: "border-emerald-200 bg-emerald-50 text-emerald-700",
  amber: "border-amber-200 bg-amber-50 text-amber-700",
  red: "border-red-200 bg-red-50 text-red-700",
  blue: "border-blue-200 bg-blue-50 text-blue-700",
  violet: "border-violet-200 bg-violet-50 text-violet-700",
  teal: "border-teal-200 bg-teal-50 text-teal-700",
  slate: "border-slate-200 bg-slate-100 text-slate-600",
};

const DOT_STYLES: Record<Tone, string> = {
  green: "bg-emerald-500",
  amber: "bg-amber-500",
  red: "bg-red-500",
  blue: "bg-blue-500",
  violet: "bg-violet-500",
  teal: "bg-teal-500",
  slate: "bg-slate-400",
};

const STATUS_TONES: Record<string, Tone> = {
  // Success-like
  confirmed: "green",
  completed: "green",
  approved: "green",
  active: "green",
  verified: "green",
  connected: "green",
  // Waiting
  pending: "amber",
  unassigned: "amber",
  // Failure-like
  cancelled: "red",
  rejected: "red",
  failed: "red",
  suspended: "red",
  error: "red",
  // In-flight
  open: "blue",
  assigned: "blue",
  in_progress: "blue",
  inprogress: "blue",
  // User types
  customer: "violet",
  tasker: "teal",
  // Neutral
  inactive: "slate",
  disabled: "slate",
};

function toneFor(status: string): Tone {
  const key = status.toLowerCase().replace(/[\s_-]/g, "");
  return STATUS_TONES[key] ?? STATUS_TONES[status.toLowerCase()] ?? "slate";
}

function labelFor(status: string): string {
  const words = status
    .replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/[_-]+/g, " ")
    .trim()
    .toLowerCase();
  return words.charAt(0).toUpperCase() + words.slice(1);
}

interface StatusBadgeProps {
  status: string;
  className?: string;
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const tone = toneFor(status);
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 whitespace-nowrap rounded-full border px-2.5 py-0.5 text-xs font-medium",
        CHIP_STYLES[tone],
        className
      )}
    >
      <span className={cn("h-1.5 w-1.5 shrink-0 rounded-full", DOT_STYLES[tone])} />
      {labelFor(status)}
    </span>
  );
}
