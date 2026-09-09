"use client";

import { useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import {
  getAdminRole,
  getTeam,
  createTeamMember,
  updateTeamMember,
  resetTeamPassword,
  deleteTeamMember,
} from "@/lib/api";
import { TeamMember } from "@/types";
import { AlertCircle, Loader2, ShieldAlert, UserCog, UserPlus } from "lucide-react";

const ROLE_LABEL: Record<string, string> = {
  superadmin: "Super Admin",
  admin: "Admin",
  support: "Support Executive",
};

const ROLE_STYLE: Record<string, string> = {
  superadmin: "bg-violet-100 text-violet-700",
  admin: "bg-blue-100 text-blue-700",
  support: "bg-emerald-100 text-emerald-700",
};

export default function TeamPage() {
  const [role, setRole] = useState<string | null>(null);
  const [members, setMembers] = useState<TeamMember[]>([]);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState<
    { type: "success" | "error"; message: string } | null
  >(null);

  // Create form
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [newRole, setNewRole] = useState<"admin" | "support">("support");
  const [creating, setCreating] = useState(false);

  useEffect(() => setRole(getAdminRole()), []);

  const load = () => {
    setLoading(true);
    getTeam()
      .then(setMembers)
      .catch((e) => setStatus({ type: "error", message: e?.message || "Failed to load team" }))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    if (role === "superadmin") load();
    else if (role) setLoading(false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [role]);

  if (role && role !== "superadmin") {
    return (
      <AppShell>
        <PageHeader title="Team" subtitle="Manage portal staff accounts" />
        <Card>
          <CardContent className="flex flex-col items-center gap-3 py-16 text-center">
            <ShieldAlert className="h-10 w-10 text-slate-400" />
            <p className="text-lg font-semibold text-slate-800">
              Super admin access required
            </p>
            <p className="max-w-md text-sm text-slate-500">
              Only a Super Admin can create and manage admin and support accounts.
            </p>
          </CardContent>
        </Card>
      </AppShell>
    );
  }

  const handleCreate = async () => {
    setStatus(null);
    if (!name.trim() || !email.trim() || password.length < 6) {
      setStatus({ type: "error", message: "Name, a valid email, and a 6+ char password are required." });
      return;
    }
    setCreating(true);
    try {
      await createTeamMember({ name: name.trim(), email: email.trim(), password, role: newRole });
      setName("");
      setEmail("");
      setPassword("");
      setNewRole("support");
      setStatus({ type: "success", message: "Account created." });
      load();
    } catch (e) {
      setStatus({ type: "error", message: (e as Error)?.message || "Could not create account" });
    } finally {
      setCreating(false);
    }
  };

  const toggleActive = async (m: TeamMember) => {
    try {
      await updateTeamMember(m.id, { is_active: !m.is_active });
      load();
    } catch (e) {
      setStatus({ type: "error", message: (e as Error)?.message || "Update failed" });
    }
  };

  const changeRole = async (m: TeamMember, r: "admin" | "support") => {
    try {
      await updateTeamMember(m.id, { role: r });
      load();
    } catch (e) {
      setStatus({ type: "error", message: (e as Error)?.message || "Update failed" });
    }
  };

  const doResetPassword = async (m: TeamMember) => {
    const pw = window.prompt(`New password for ${m.email} (min 6 characters):`);
    if (!pw) return;
    if (pw.length < 6) {
      setStatus({ type: "error", message: "Password must be at least 6 characters." });
      return;
    }
    try {
      await resetTeamPassword(m.id, pw);
      setStatus({ type: "success", message: `Password updated for ${m.email}.` });
    } catch (e) {
      setStatus({ type: "error", message: (e as Error)?.message || "Reset failed" });
    }
  };

  const doDelete = async (m: TeamMember) => {
    if (!window.confirm(`Remove ${m.email}? They will no longer be able to log in.`)) return;
    try {
      await deleteTeamMember(m.id);
      load();
    } catch (e) {
      setStatus({ type: "error", message: (e as Error)?.message || "Delete failed" });
    }
  };

  return (
    <AppShell>
      <PageHeader
        title="Team & access"
        subtitle="Create and manage Admin and Support Executive logins"
      />

      {status && (
        <div
          className={`mb-4 flex items-center gap-2 rounded-lg border px-4 py-2.5 text-sm ${
            status.type === "success"
              ? "border-emerald-200 bg-emerald-50 text-emerald-700"
              : "border-red-200 bg-red-50 text-red-700"
          }`}
        >
          <AlertCircle className="h-4 w-4 shrink-0" />
          {status.message}
        </div>
      )}

      {/* Create form */}
      <Card className="mb-6">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <UserPlus className="h-5 w-5 text-slate-500" />
            Create a login
          </CardTitle>
          <CardDescription>
            Super Admin only. New accounts can be an Admin or a Support Executive.
          </CardDescription>
        </CardHeader>
        <CardContent className="grid grid-cols-1 gap-3 md:grid-cols-5">
          <Input placeholder="Full name" value={name} onChange={(e) => setName(e.target.value)} />
          <Input placeholder="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
          <Input placeholder="Temp password" type="text" value={password} onChange={(e) => setPassword(e.target.value)} />
          <select
            value={newRole}
            onChange={(e) => setNewRole(e.target.value as "admin" | "support")}
            className="h-10 rounded-lg border border-slate-200 bg-white px-3 text-sm text-slate-800 outline-none focus:border-slate-400"
          >
            <option value="support">Support Executive</option>
            <option value="admin">Admin</option>
          </select>
          <Button onClick={handleCreate} disabled={creating}>
            {creating ? <Loader2 className="h-4 w-4 animate-spin" /> : "Create account"}
          </Button>
        </CardContent>
      </Card>

      {/* Member list */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <UserCog className="h-5 w-5 text-slate-500" />
            Portal accounts
          </CardTitle>
          <CardDescription>{members.length} account(s) besides the bootstrap super admin</CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center py-10">
              <Loader2 className="h-6 w-6 animate-spin text-slate-400" />
            </div>
          ) : members.length === 0 ? (
            <p className="py-8 text-center text-sm text-slate-500">
              No team accounts yet. Create one above.
            </p>
          ) : (
            <div className="divide-y divide-slate-100">
              {members.map((m) => (
                <div key={m.id} className="flex flex-wrap items-center gap-3 py-3">
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-semibold text-slate-800">{m.name || "—"}</p>
                    <p className="truncate text-sm text-slate-500">{m.email}</p>
                  </div>
                  <span
                    className={`rounded-full px-2.5 py-1 text-xs font-semibold ${
                      ROLE_STYLE[m.role] ?? "bg-slate-100 text-slate-600"
                    }`}
                  >
                    {ROLE_LABEL[m.role] ?? m.role}
                  </span>
                  <span
                    className={`rounded-full px-2.5 py-1 text-xs font-semibold ${
                      m.is_active ? "bg-emerald-100 text-emerald-700" : "bg-slate-200 text-slate-600"
                    }`}
                  >
                    {m.is_active ? "Active" : "Disabled"}
                  </span>
                  {m.role !== "superadmin" && (
                    <div className="flex items-center gap-2">
                      <select
                        value={m.role}
                        onChange={(e) => changeRole(m, e.target.value as "admin" | "support")}
                        className="h-8 rounded-md border border-slate-200 bg-white px-2 text-xs text-slate-700 outline-none"
                      >
                        <option value="support">Support</option>
                        <option value="admin">Admin</option>
                      </select>
                      <Button variant="outline" size="sm" onClick={() => toggleActive(m)}>
                        {m.is_active ? "Disable" : "Enable"}
                      </Button>
                      <Button variant="outline" size="sm" onClick={() => doResetPassword(m)}>
                        Reset password
                      </Button>
                      <Button variant="outline" size="sm" onClick={() => doDelete(m)}>
                        Remove
                      </Button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </AppShell>
  );
}
