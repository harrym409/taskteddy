"use client";

import * as React from "react";
import { TriangleAlert, HelpCircle } from "lucide-react";
import { Modal } from "./modal";
import { Button } from "./button";
import { cn } from "@/lib/utils";

interface ConfirmDialogProps {
  open: boolean;
  title: string;
  message: React.ReactNode;
  confirmLabel?: string;
  cancelLabel?: string;
  /** "danger" renders a red confirm button; "primary" a brand-blue one. */
  variant?: "danger" | "primary";
  loading?: boolean;
  onCancel: () => void;
  onConfirm: () => void;
}

export function ConfirmDialog({
  open,
  title,
  message,
  confirmLabel = "Confirm",
  cancelLabel = "Cancel",
  variant = "danger",
  loading = false,
  onCancel,
  onConfirm,
}: ConfirmDialogProps) {
  const danger = variant === "danger";
  const Icon = danger ? TriangleAlert : HelpCircle;

  return (
    <Modal open={open} onClose={onCancel} title={title} widthClassName="max-w-md">
      <div className="flex items-start gap-4">
        <div
          className={cn(
            "flex h-10 w-10 shrink-0 items-center justify-center rounded-full",
            danger ? "bg-red-50" : "bg-[#6384DB]/10"
          )}
        >
          <Icon className={cn("h-5 w-5", danger ? "text-red-600" : "text-[#6384DB]")} />
        </div>
        <p className="pt-1.5 text-sm leading-relaxed text-slate-600">{message}</p>
      </div>
      <div className="mt-6 flex justify-end gap-2 border-t border-slate-100 pt-4">
        <Button type="button" variant="outline" onClick={onCancel} disabled={loading}>
          {cancelLabel}
        </Button>
        <Button
          type="button"
          variant={danger ? "destructive" : "default"}
          onClick={onConfirm}
          disabled={loading}
        >
          {loading ? "Working..." : confirmLabel}
        </Button>
      </div>
    </Modal>
  );
}
