"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  AlertCircle,
  CalendarCheck,
  Loader2,
  Lock,
  Mail,
  ShieldCheck,
  Wallet,
} from "lucide-react";
import { adminLogin } from "@/lib/api";

const FEATURES = [
  {
    icon: ShieldCheck,
    title: "Full platform control",
    description: "Manage users, taskers, and the service catalog from one place.",
  },
  {
    icon: CalendarCheck,
    title: "Live operations",
    description: "Track bookings and tasks as they move through the pipeline.",
  },
  {
    icon: Wallet,
    title: "Payouts and finance",
    description: "Review wallet activity and approve withdrawal requests.",
  },
];

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      await adminLogin(email, password);
      router.push("/");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen">
      {/* Brand panel */}
      <div className="relative hidden w-1/2 flex-col justify-between overflow-hidden bg-gradient-to-br from-slate-950 via-slate-900 to-[#33487e] p-12 lg:flex">
        <div
          className="pointer-events-none absolute -right-40 -top-40 h-96 w-96 rounded-full bg-[#6384DB]/20 blur-3xl"
          aria-hidden="true"
        />
        <div
          className="pointer-events-none absolute -bottom-32 -left-24 h-80 w-80 rounded-full bg-[#6384DB]/10 blur-3xl"
          aria-hidden="true"
        />

        <div className="relative">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/logo-white.png" alt="TaskTeddy" className="h-12 w-auto" />
        </div>

        <div className="relative">
          <h1 className="max-w-md text-3xl font-bold leading-snug text-white">
            Operations console for the TaskTeddy marketplace
          </h1>
          <div className="mt-10 space-y-6">
            {FEATURES.map((feature) => (
              <div key={feature.title} className="flex items-start gap-4">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-white/10">
                  <feature.icon className="h-5 w-5 text-[#9db4ec]" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-white">{feature.title}</p>
                  <p className="mt-0.5 text-sm text-slate-400">{feature.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <p className="relative text-xs text-slate-500">
          TaskTeddy Admin v1.0 &middot; Authorized personnel only
        </p>
      </div>

      {/* Sign-in panel */}
      <div className="flex w-full items-center justify-center bg-slate-50 p-6 lg:w-1/2">
        <div className="w-full max-w-md rounded-xl border border-slate-200 bg-white p-8 shadow-sm">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/logo-blue.png" alt="TaskTeddy" className="h-8 w-auto" />
          <h2 className="mt-6 text-xl font-bold text-slate-900">Sign in to Admin</h2>
          <p className="mt-1 text-sm text-slate-500">
            Enter your credentials to access the console
          </p>

          <form onSubmit={handleSubmit} className="mt-6 space-y-4">
            {error && (
              <div className="flex items-center gap-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2.5 text-sm text-red-700">
                <AlertCircle className="h-4 w-4 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <div className="space-y-1.5">
              <label htmlFor="email" className="text-sm font-medium text-slate-700">
                Email
              </label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input
                  id="email"
                  type="email"
                  autoComplete="email"
                  placeholder="admin@taskteddy.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  className="h-10 w-full rounded-lg border border-slate-300 bg-white pl-9 pr-3 text-sm text-slate-900 placeholder:text-slate-400 focus:border-[#6384DB] focus:outline-none focus:ring-2 focus:ring-[#6384DB]/25"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label htmlFor="password" className="text-sm font-medium text-slate-700">
                Password
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
                <input
                  id="password"
                  type="password"
                  autoComplete="current-password"
                  placeholder="Enter your password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="h-10 w-full rounded-lg border border-slate-300 bg-white pl-9 pr-3 text-sm text-slate-900 placeholder:text-slate-400 focus:border-[#6384DB] focus:outline-none focus:ring-2 focus:ring-[#6384DB]/25"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="flex h-10 w-full items-center justify-center gap-2 rounded-lg bg-[#6384DB] text-sm font-medium text-white shadow-sm transition-colors hover:bg-[#5273c9] disabled:pointer-events-none disabled:opacity-60"
            >
              {loading && <Loader2 className="h-4 w-4 animate-spin" />}
              {loading ? "Signing in..." : "Sign in"}
            </button>
          </form>

          <p className="mt-6 text-center text-xs text-slate-400">
            Access is restricted to TaskTeddy administrators.
          </p>
        </div>
      </div>
    </div>
  );
}
