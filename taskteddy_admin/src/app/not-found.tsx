import Link from "next/link";
import { ArrowLeft, SearchX } from "lucide-react";

export default function NotFound() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 p-6">
      <div className="w-full max-w-md rounded-xl border border-slate-200 bg-white p-10 text-center shadow-sm">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/logo-blue.png" alt="TaskTeddy" className="mx-auto h-8 w-auto" />
        <div className="mx-auto mt-8 flex h-14 w-14 items-center justify-center rounded-full bg-slate-100">
          <SearchX className="h-7 w-7 text-slate-400" />
        </div>
        <h1 className="mt-5 text-xl font-bold text-slate-900">Page not found</h1>
        <p className="mt-2 text-sm text-slate-500">
          The page you are looking for does not exist or may have been moved.
        </p>
        <Link
          href="/"
          className="mt-6 inline-flex items-center gap-2 rounded-lg bg-[#6384DB] px-4 py-2 text-sm font-medium text-white shadow-sm transition-colors hover:bg-[#5273c9]"
        >
          <ArrowLeft className="h-4 w-4" />
          Back to dashboard
        </Link>
      </div>
    </div>
  );
}
