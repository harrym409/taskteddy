"use client";

import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { isAuthenticated } from "@/lib/api";

// Routes that must NOT require authentication.
const PUBLIC_PATHS = ["/login"];

/**
 * Client-side auth gate. Renders children only when the admin is authenticated;
 * otherwise redirects to /login. Public paths (the login page) render freely.
 *
 * This deliberately uses plain React + next/navigation (no edge middleware) so
 * it is robust across Next.js versions.
 */
export function AuthGuard({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [checked, setChecked] = useState(false);

  const isPublic = PUBLIC_PATHS.includes(pathname);

  useEffect(() => {
    if (isPublic) {
      setChecked(true);
      return;
    }
    if (!isAuthenticated()) {
      router.replace("/login");
      return;
    }
    setChecked(true);
  }, [isPublic, pathname, router]);

  // Public pages render immediately.
  if (isPublic) return <>{children}</>;

  // Protected pages: render nothing until the token check passes, so the UI and
  // its action buttons never flash for an unauthenticated visitor.
  if (!checked) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50">
        <span className="text-gray-400">Loading…</span>
      </div>
    );
  }

  return <>{children}</>;
}
