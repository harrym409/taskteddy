"use client";

import { useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { getSettings, updateSettings } from "@/lib/api";
import { AlertCircle, CheckCircle2, Loader2, ShieldCheck, SlidersHorizontal } from "lucide-react";

export default function SettingsPage() {
  const [platformName, setPlatformName] = useState("");
  const [supportEmail, setSupportEmail] = useState("");
  const [commission, setCommission] = useState("");
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [status, setStatus] = useState<
    { type: "success" | "error"; message: string } | null
  >(null);

  useEffect(() => {
    getSettings()
      .then((data) => {
        setPlatformName(data.platform_name ?? "");
        setSupportEmail(data.support_email ?? "");
        setCommission(data.platform_commission_percent ?? "");
      })
      .catch((err) =>
        setStatus({ type: "error", message: err?.message || "Failed to load settings" })
      )
      .finally(() => setLoading(false));
  }, []);

  const handleSave = async () => {
    setSaving(true);
    setStatus(null);
    try {
      const updated = await updateSettings({
        platform_name: platformName,
        support_email: supportEmail,
        platform_commission_percent: commission,
      });
      setPlatformName(updated.platform_name ?? "");
      setSupportEmail(updated.support_email ?? "");
      setCommission(updated.platform_commission_percent ?? "");
      setStatus({ type: "success", message: "Settings saved successfully" });
    } catch (err) {
      setStatus({
        type: "error",
        message: err instanceof Error ? err.message : "Failed to save settings",
      });
    } finally {
      setSaving(false);
    }
  };

  return (
    <AppShell>
      <PageHeader
        title="Settings"
        subtitle="Platform configuration and admin account"
      />

      <div className="max-w-3xl space-y-6">
        {/* Platform Settings */}
        <Card>
          <CardHeader className="flex-row items-start gap-3 space-y-0">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-blue-50">
              <SlidersHorizontal className="h-5 w-5 text-[#6384DB]" />
            </div>
            <div>
              <CardTitle className="text-base">Platform Settings</CardTitle>
              <CardDescription className="mt-1">
                Configure platform-wide settings
              </CardDescription>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-1.5">
              <label htmlFor="platformName" className="text-sm font-medium text-slate-700">
                Platform Name
              </label>
              <Input
                id="platformName"
                value={platformName}
                onChange={(e) => setPlatformName(e.target.value)}
                disabled={loading}
              />
            </div>
            <div className="space-y-1.5">
              <label htmlFor="supportEmail" className="text-sm font-medium text-slate-700">
                Support Email
              </label>
              <Input
                id="supportEmail"
                type="email"
                value={supportEmail}
                onChange={(e) => setSupportEmail(e.target.value)}
                disabled={loading}
              />
            </div>
            <div className="space-y-1.5">
              <label htmlFor="commission" className="text-sm font-medium text-slate-700">
                Commission Rate (%)
              </label>
              <Input
                id="commission"
                type="number"
                value={commission}
                onChange={(e) => setCommission(e.target.value)}
                disabled={loading}
              />
              <p className="text-xs text-slate-400">
                Percentage the platform keeps from each completed booking.
              </p>
            </div>

            {status && (
              <div
                className={`flex items-center gap-2 rounded-lg border px-3 py-2.5 text-sm ${
                  status.type === "success"
                    ? "border-emerald-200 bg-emerald-50 text-emerald-700"
                    : "border-red-200 bg-red-50 text-red-700"
                }`}
              >
                {status.type === "success" ? (
                  <CheckCircle2 className="h-4 w-4 shrink-0" />
                ) : (
                  <AlertCircle className="h-4 w-4 shrink-0" />
                )}
                {status.message}
              </div>
            )}

            <Button onClick={handleSave} disabled={loading || saving}>
              {saving && <Loader2 className="mr-1.5 h-4 w-4 animate-spin" />}
              {saving ? "Saving..." : "Save Settings"}
            </Button>
          </CardContent>
        </Card>

        {/* Admin Account */}
        <Card>
          <CardHeader className="flex-row items-start gap-3 space-y-0">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-blue-50">
              <ShieldCheck className="h-5 w-5 text-[#6384DB]" />
            </div>
            <div>
              <CardTitle className="text-base">Admin Account</CardTitle>
              <CardDescription className="mt-1">
                Admin credentials are managed via server environment variables
              </CardDescription>
            </div>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-slate-500">
              The admin email and password are configured through the{" "}
              <code className="rounded bg-slate-100 px-1 py-0.5 text-xs">ADMIN_EMAIL</code>{" "}
              and{" "}
              <code className="rounded bg-slate-100 px-1 py-0.5 text-xs">
                ADMIN_PASSWORD_HASH
              </code>{" "}
              environment variables and cannot be changed from this panel.
            </p>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  );
}
