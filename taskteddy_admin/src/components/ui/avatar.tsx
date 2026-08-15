"use client";

import * as React from "react";
import { cn } from "@/lib/utils";
import { fileUrl } from "@/lib/api";

export function initialOf(name?: string | null): string {
  return (name || "?").trim().charAt(0).toUpperCase() || "?";
}

const SIZES = {
  sm: "h-7 w-7 text-xs",
  md: "h-9 w-9 text-sm",
  lg: "h-14 w-14 text-xl",
};

interface InitialAvatarProps {
  name?: string | null;
  /** Server-relative or absolute profile-picture URL; falls back to initials. */
  avatarUrl?: string | null;
  size?: "sm" | "md" | "lg";
  className?: string;
}

export function InitialAvatar({
  name,
  avatarUrl,
  size = "md",
  className,
}: InitialAvatarProps) {
  const [broken, setBroken] = React.useState(false);
  const url = avatarUrl && avatarUrl.trim() ? fileUrl(avatarUrl) : "";

  if (url && !broken) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img
        src={url}
        alt={name || "avatar"}
        onError={() => setBroken(true)}
        className={cn(
          "shrink-0 rounded-full bg-slate-100 object-cover",
          SIZES[size],
          className
        )}
      />
    );
  }

  return (
    <span
      className={cn(
        "flex shrink-0 items-center justify-center rounded-full bg-[#6384DB]/10 font-semibold text-[#6384DB]",
        SIZES[size],
        className
      )}
    >
      {initialOf(name)}
    </span>
  );
}

interface PartyCellProps {
  name?: string | null;
  meta?: string | null;
  avatarUrl?: string | null;
  size?: "sm" | "md";
}

/** Avatar (photo or initial) + name stacked over a muted id/email line. */
export function PartyCell({ name, meta, avatarUrl, size = "md" }: PartyCellProps) {
  if (!name && !meta) return <span className="text-slate-400">-</span>;
  return (
    <div className="flex min-w-0 items-center gap-2.5">
      <InitialAvatar
        name={name}
        avatarUrl={avatarUrl}
        size={size === "sm" ? "sm" : "md"}
      />
      <div className="min-w-0">
        <p className="truncate text-sm font-medium text-slate-900">{name || "-"}</p>
        {meta && <p className="truncate text-xs text-slate-500">{meta}</p>}
      </div>
    </div>
  );
}
