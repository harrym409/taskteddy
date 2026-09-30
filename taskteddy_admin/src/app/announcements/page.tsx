"use client";

import { useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { ErrorBanner, SuccessBanner } from "@/components/ui/feedback";
import { cn } from "@/lib/utils";
import { sendAnnouncement, sendNotification } from "@/lib/api";
import { AnnouncementAudience } from "@/types";
import { Bell, Megaphone, Send, Store, UserRound, UsersRound } from "lucide-react";

const AUDIENCES: {
  value: AnnouncementAudience;
  label: string;
  icon: typeof UsersRound;
}[] = [
  { value: "all", label: "All users", icon: UsersRound },
  { value: "customers", label: "Customers", icon: UserRound },
  { value: "taskers", label: "Taskers", icon: Store },
];

const TITLE_MAX = 120;
const BODY_MAX = 1000;

export default function AnnouncementsPage() {
  const [audience, setAudience] = useState<AnnouncementAudience>("all");
  const [notifType, setNotifType] = useState("announcement");
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [confirming, setConfirming] = useState(false);
  const [sending, setSending] = useState(false);
  const [success, setSuccess] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const valid = title.trim().length >= 2 && body.trim().length >= 2;
  const audienceLabel = AUDIENCES.find((a) => a.value === audience)?.label ?? "";

  const handleSend = async () => {
    setSending(true);
    setError(null);
    try {
      let recipients: number;
      let pushed = 0;
      if (notifType === "announcement") {
        const result = await sendAnnouncement({
          title: title.trim(),
          body: body.trim(),
          audience,
        });
        recipients = result.recipients;
        pushed = result.pushed ?? 0;
      } else {
        // Typed, deep-linking alert (e.g. verify_email opens the verify flow).
        const result = await sendNotification({
          title: title.trim(),
          body: body.trim(),
          type: notifType,
          audience,
        });
        recipients = result.recipients;
      }
      setSuccess(
        `Sent to ${recipients} recipient${recipients === 1 ? "" : "s"}` +
          (pushed > 0 ? ` (${pushed} push notifications delivered)` : "")
      );
      setTitle("");
      setBody("");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to send announcement");
    } finally {
      setSending(false);
      setConfirming(false);
    }
  };

  return (
    <AppShell>
      <PageHeader
        title="Announcements"
        subtitle="Broadcast a message to your users"
      />

      {success && <SuccessBanner message={success} onDismiss={() => setSuccess(null)} />}
      {error && <ErrorBanner message={error} />}

      <div className="mt-4 grid gap-6 lg:grid-cols-5">
        {/* Composer */}
        <Card className="p-6 lg:col-span-3">
          <div className="flex items-center gap-2 text-slate-900">
            <Megaphone className="h-4 w-4 text-[#6384DB]" />
            <h2 className="text-sm font-semibold">Compose announcement</h2>
          </div>

          <div className="mt-5 space-y-5">
            <div>
              <label className="text-xs font-medium uppercase tracking-wide text-slate-500">
                Audience
              </label>
              <div className="mt-2 inline-flex rounded-lg border border-slate-200 bg-slate-50 p-1">
                {AUDIENCES.map((a) => (
                  <button
                    key={a.value}
                    type="button"
                    onClick={() => setAudience(a.value)}
                    className={cn(
                      "flex items-center gap-1.5 rounded-md px-3 py-1.5 text-sm font-medium transition-colors",
                      audience === a.value
                        ? "bg-white text-[#6384DB] shadow-sm ring-1 ring-slate-200"
                        : "text-slate-500 hover:text-slate-700"
                    )}
                  >
                    <a.icon className="h-3.5 w-3.5" />
                    {a.label}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="text-xs font-medium uppercase tracking-wide text-slate-500">
                Alert type (deep-link)
              </label>
              <select
                value={notifType}
                onChange={(e) => setNotifType(e.target.value)}
                className="mt-2 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-800"
              >
                <option value="announcement">Announcement (no redirect)</option>
                <option value="verify_email">
                  Verify email — opens email verification
                </option>
                <option value="bonus">Bonus — opens the bonus screen</option>
              </select>
              <p className="mt-1 text-xs text-slate-400">
                When a user taps the alert, the app opens the matching screen.
              </p>
            </div>

            <div>
              <div className="flex items-center justify-between">
                <label
                  htmlFor="ann-title"
                  className="text-xs font-medium uppercase tracking-wide text-slate-500"
                >
                  Title
                </label>
                <span className="text-xs tabular-nums text-slate-400">
                  {title.length}/{TITLE_MAX}
                </span>
              </div>
              <input
                id="ann-title"
                value={title}
                maxLength={TITLE_MAX}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g. Weekend offer is live"
                className="mt-2 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-[#6384DB] focus:outline-none focus:ring-2 focus:ring-[#6384DB]/20"
              />
            </div>

            <div>
              <div className="flex items-center justify-between">
                <label
                  htmlFor="ann-body"
                  className="text-xs font-medium uppercase tracking-wide text-slate-500"
                >
                  Message
                </label>
                <span className="text-xs tabular-nums text-slate-400">
                  {body.length}/{BODY_MAX}
                </span>
              </div>
              <textarea
                id="ann-body"
                value={body}
                maxLength={BODY_MAX}
                onChange={(e) => setBody(e.target.value)}
                rows={5}
                placeholder="Write the message your users will see…"
                className="mt-2 w-full resize-none rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-[#6384DB] focus:outline-none focus:ring-2 focus:ring-[#6384DB]/20"
              />
            </div>

            <div className="flex items-center justify-between border-t border-slate-100 pt-4">
              <p className="text-xs text-slate-500">
                Suspended accounts are excluded automatically.
              </p>
              <Button disabled={!valid || sending} onClick={() => setConfirming(true)}>
                <Send className="mr-1.5 h-3.5 w-3.5" />
                Send announcement
              </Button>
            </div>
          </div>
        </Card>

        {/* Preview */}
        <Card className="p-6 lg:col-span-2">
          <h2 className="text-sm font-semibold text-slate-900">In-app preview</h2>
          <p className="mt-1 text-xs text-slate-500">
            How it will appear in the {audienceLabel.toLowerCase()} notification feed.
          </p>
          <div className="mt-4 rounded-xl border border-slate-200 bg-slate-50 p-4">
            <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
              <div className="flex items-start gap-3">
                <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#6384DB]/10">
                  <Bell className="h-4 w-4 text-[#6384DB]" />
                </div>
                <div className="min-w-0">
                  <p className="truncate text-sm font-semibold text-slate-900">
                    {title.trim() || "Announcement title"}
                  </p>
                  <p className="mt-0.5 whitespace-pre-wrap break-words text-sm text-slate-600">
                    {body.trim() || "Your message will appear here."}
                  </p>
                  <p className="mt-1.5 text-xs text-slate-400">Just now</p>
                </div>
              </div>
            </div>
          </div>
        </Card>
      </div>

      <ConfirmDialog
        open={confirming}
        variant="primary"
        title="Send announcement?"
        message={
          <>
            This will immediately notify <strong>{audienceLabel.toLowerCase()}</strong>{" "}
            in-app. This action cannot be undone.
          </>
        }
        confirmLabel="Send now"
        loading={sending}
        onCancel={() => setConfirming(false)}
        onConfirm={handleSend}
      />
    </AppShell>
  );
}
