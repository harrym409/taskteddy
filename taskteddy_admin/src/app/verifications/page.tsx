"use client";

import { useCallback, useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Drawer } from "@/components/ui/drawer";
import { Modal } from "@/components/ui/modal";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { StatusBadge } from "@/components/ui/status-badge";
import { InitialAvatar, PartyCell } from "@/components/ui/avatar";
import {
  EmptyState,
  ErrorBanner,
  SuccessBanner,
  TableSkeleton,
} from "@/components/ui/feedback";
import {
  approveKycDocument,
  fileUrl,
  getKycSubmissions,
  rejectKycDocument,
  setKycNumbers,
} from "@/lib/api";
import { formatDate } from "@/lib/utils";
import { KycDocument, KycSubmission } from "@/types";
import {
  BadgeCheck,
  Check,
  Fingerprint,
  RefreshCw,
  ShieldCheck,
  X,
} from "lucide-react";

const STATUS_FILTERS = ["all", "pending", "approved", "rejected"] as const;
type StatusFilter = (typeof STATUS_FILTERS)[number];

const AADHAAR_RE = /^\d{12}$/;
const PAN_RE = /^[A-Z]{5}[0-9]{4}[A-Z]$/;

const DOC_LABELS: Record<string, string> = {
  aadhaar: "Aadhaar",
  pan: "PAN",
  address: "Address",
  selfie: "Selfie",
};

function docLabel(docType: string): string {
  return (
    DOC_LABELS[docType] ?? docType.charAt(0).toUpperCase() + docType.slice(1)
  );
}

function countByStatus(submission: KycSubmission) {
  const counts = { pending: 0, approved: 0, rejected: 0 };
  for (const doc of submission.documents) {
    if (doc.status in counts) counts[doc.status as keyof typeof counts] += 1;
  }
  return counts;
}

function latestUpdate(submission: KycSubmission): string | null {
  if (submission.documents.length === 0) return null;
  return submission.documents.reduce(
    (latest, doc) => (doc.updated_at > latest ? doc.updated_at : latest),
    submission.documents[0].updated_at
  );
}

const SUMMARY_CHIP_STYLES = {
  pending: "border-amber-200 bg-amber-50 text-amber-700",
  approved: "border-emerald-200 bg-emerald-50 text-emerald-700",
  rejected: "border-red-200 bg-red-50 text-red-700",
} as const;

function DocsSummary({ submission }: { submission: KycSubmission }) {
  const counts = countByStatus(submission);
  const entries = (
    Object.keys(SUMMARY_CHIP_STYLES) as (keyof typeof SUMMARY_CHIP_STYLES)[]
  ).filter((status) => counts[status] > 0);

  if (entries.length === 0) return <span className="text-slate-400">-</span>;

  return (
    <div className="flex flex-wrap gap-1.5">
      {entries.map((status) => (
        <span
          key={status}
          className={`inline-flex items-center whitespace-nowrap rounded-full border px-2 py-0.5 text-[11px] font-medium ${SUMMARY_CHIP_STYLES[status]}`}
        >
          {counts[status]} {status}
        </span>
      ))}
    </div>
  );
}

export default function VerificationsPage() {
  const [submissions, setSubmissions] = useState<KycSubmission[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");

  // Drawer
  const [selected, setSelected] = useState<KycSubmission | null>(null);

  // Image preview
  const [previewDoc, setPreviewDoc] = useState<KycDocument | null>(null);

  // Approve flow
  const [approveTarget, setApproveTarget] = useState<KycDocument | null>(null);
  const [approving, setApproving] = useState(false);

  // Reject flow
  const [rejectTarget, setRejectTarget] = useState<KycDocument | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [rejecting, setRejecting] = useState(false);
  const [rejectError, setRejectError] = useState<string | null>(null);

  // Identity number entry (manual Aadhaar/PAN from document images)
  const [aadhaarInput, setAadhaarInput] = useState("");
  const [panInput, setPanInput] = useState("");
  const [savingNumbers, setSavingNumbers] = useState(false);
  const [numbersError, setNumbersError] = useState<string | null>(null);
  const [numbersSuccess, setNumbersSuccess] = useState<{
    aadhaar_masked: string | null;
    pan_masked: string | null;
  } | null>(null);

  // Reset the identity-number inputs whenever a different tasker is opened.
  useEffect(() => {
    setAadhaarInput("");
    setPanInput("");
    setNumbersError(null);
    setNumbersSuccess(null);
    setSavingNumbers(false);
  }, [selected?.user.id]);

  const fetchSubmissions = useCallback(async (): Promise<KycSubmission[]> => {
    setLoading(true);
    setError(null);
    try {
      const data = await getKycSubmissions(
        statusFilter === "all" ? undefined : statusFilter
      );
      setSubmissions(data);
      return data;
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Failed to load KYC submissions"
      );
      return [];
    } finally {
      setLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    fetchSubmissions();
  }, [fetchSubmissions]);

  /**
   * Refetch the list and keep the drawer in sync. If the tasker dropped out
   * of the current filter after the action, fall back to the locally-updated
   * copy so the drawer stays open.
   */
  const refreshAfterAction = async (
    userId: string,
    localUpdate: KycSubmission
  ) => {
    const data = await fetchSubmissions();
    setSelected(data.find((s) => s.user.id === userId) ?? localUpdate);
  };

  /** Apply a document status change to a submission locally. */
  const withDocUpdate = (
    submission: KycSubmission,
    docId: string,
    patch: Partial<KycDocument>
  ): KycSubmission => ({
    ...submission,
    documents: submission.documents.map((d) =>
      d.id === docId ? { ...d, ...patch } : d
    ),
  });

  const confirmApprove = async () => {
    if (!approveTarget || !selected) return;
    setApproving(true);
    try {
      const res = await approveKycDocument(approveTarget.id);
      setNotice(
        res.auto_verified
          ? res.message
          : `${docLabel(approveTarget.doc_type)} document approved`
      );
      setApproveTarget(null);
      const localUpdate = withDocUpdate(selected, approveTarget.id, {
        status: "approved",
        reason: null,
      });
      if (res.auto_verified) {
        localUpdate.user = { ...localUpdate.user, is_verified: true };
      }
      await refreshAfterAction(selected.user.id, localUpdate);
    } catch (err) {
      setApproveTarget(null);
      setError(
        err instanceof Error ? err.message : "Failed to approve document"
      );
    } finally {
      setApproving(false);
    }
  };

  const openReject = (doc: KycDocument) => {
    setRejectTarget(doc);
    setRejectReason("");
    setRejectError(null);
  };

  const confirmReject = async () => {
    if (!rejectTarget || !selected || rejectReason.trim().length < 3) return;
    setRejecting(true);
    setRejectError(null);
    try {
      const reason = rejectReason.trim();
      await rejectKycDocument(rejectTarget.id, reason);
      setNotice(`${docLabel(rejectTarget.doc_type)} document rejected`);
      const localUpdate = withDocUpdate(selected, rejectTarget.id, {
        status: "rejected",
        reason,
      });
      setRejectTarget(null);
      await refreshAfterAction(selected.user.id, localUpdate);
    } catch (err) {
      setRejectError(
        err instanceof Error ? err.message : "Failed to reject document"
      );
    } finally {
      setRejecting(false);
    }
  };

  const reasonValid = rejectReason.trim().length >= 3;

  const aadhaarTrimmed = aadhaarInput.trim();
  const panTrimmed = panInput.trim();
  const aadhaarValid = aadhaarTrimmed === "" || AADHAAR_RE.test(aadhaarTrimmed);
  const panValid = panTrimmed === "" || PAN_RE.test(panTrimmed);
  const hasNumberInput = aadhaarTrimmed !== "" || panTrimmed !== "";

  const saveNumbers = async () => {
    if (!selected || savingNumbers || !hasNumberInput) return;
    setSavingNumbers(true);
    setNumbersError(null);
    setNumbersSuccess(null);
    try {
      const body: { aadhaar_number?: string; pan_number?: string } = {};
      if (aadhaarTrimmed !== "") body.aadhaar_number = aadhaarTrimmed;
      if (panTrimmed !== "") body.pan_number = panTrimmed;
      const res = await setKycNumbers(selected.user.id, body);
      setNumbersSuccess({
        aadhaar_masked: res.aadhaar_masked,
        pan_masked: res.pan_masked,
      });
      setAadhaarInput("");
      setPanInput("");
    } catch (err) {
      setNumbersError(
        err instanceof Error ? err.message : "Failed to save identity numbers"
      );
    } finally {
      setSavingNumbers(false);
    }
  };

  return (
    <AppShell>
      <PageHeader
        title="Verifications"
        subtitle="Review tasker KYC documents"
        action={
          <Button variant="outline" size="sm" onClick={fetchSubmissions}>
            <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
            Refresh
          </Button>
        }
      />

      {error && <ErrorBanner message={error} onRetry={fetchSubmissions} />}
      {notice && (
        <SuccessBanner message={notice} onDismiss={() => setNotice(null)} />
      )}

      {/* Status filter row */}
      <div className="mb-6 flex flex-wrap gap-2">
        {STATUS_FILTERS.map((status) => (
          <button
            key={status}
            onClick={() => setStatusFilter(status)}
            className={`rounded-full px-4 py-1.5 text-sm font-medium capitalize transition-colors ${
              statusFilter === status
                ? "bg-[#6384DB] text-white shadow-sm"
                : "border border-slate-300 bg-white text-slate-600 hover:bg-slate-50"
            }`}
          >
            {status === "all" ? "All" : status}
          </button>
        ))}
      </div>

      {/* Tasker list */}
      <Card className="overflow-hidden">
        {loading ? (
          <div className="p-6">
            <TableSkeleton rows={6} />
          </div>
        ) : submissions.length === 0 ? (
          <EmptyState
            icon={ShieldCheck}
            title="No submissions"
            description={
              statusFilter === "all"
                ? "KYC documents submitted by taskers will appear here"
                : `No ${statusFilter} documents`
            }
          />
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Tasker</TableHead>
                <TableHead>Verified</TableHead>
                <TableHead>Documents</TableHead>
                <TableHead>Last updated</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {submissions.map((submission) => {
                const updated = latestUpdate(submission);
                return (
                  <TableRow
                    key={submission.user.id}
                    className="cursor-pointer"
                    onClick={() => setSelected(submission)}
                  >
                    <TableCell>
                      <PartyCell
                        name={submission.user.name}
                        meta={submission.user.phone}
                        size="sm"
                      />
                    </TableCell>
                    <TableCell>
                      {submission.user.is_verified ? (
                        <span className="inline-flex items-center gap-1 whitespace-nowrap rounded-full border border-emerald-200 bg-emerald-50 px-2.5 py-0.5 text-xs font-medium text-emerald-700">
                          <BadgeCheck className="h-3.5 w-3.5" />
                          Verified
                        </span>
                      ) : (
                        <span className="text-slate-400">-</span>
                      )}
                    </TableCell>
                    <TableCell>
                      <DocsSummary submission={submission} />
                    </TableCell>
                    <TableCell className="whitespace-nowrap text-slate-500">
                      {updated ? formatDate(updated) : "-"}
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        )}
      </Card>

      {/* Tasker verification drawer */}
      <Drawer
        open={!!selected}
        onClose={() => setSelected(null)}
        title="Tasker verification"
      >
        {selected && (
          <div className="space-y-5">
            {/* Tasker header */}
            <div className="flex items-center justify-between rounded-lg border border-slate-200 p-4">
              <div className="flex min-w-0 items-center gap-3">
                <InitialAvatar name={selected.user.name} />
                <div className="min-w-0">
                  <p className="truncate text-sm font-semibold text-slate-900">
                    {selected.user.name}
                  </p>
                  <p className="truncate text-xs text-slate-500">
                    {selected.user.phone || "-"}
                  </p>
                </div>
              </div>
              {selected.user.is_verified && (
                <span className="inline-flex shrink-0 items-center gap-1 rounded-full border border-emerald-200 bg-emerald-50 px-2.5 py-0.5 text-xs font-medium text-emerald-700">
                  <BadgeCheck className="h-3.5 w-3.5" />
                  Verified
                </span>
              )}
            </div>

            {/* Documents */}
            <div className="space-y-4">
              {selected.documents.map((doc) => (
                <div
                  key={doc.id}
                  className="overflow-hidden rounded-lg border border-slate-200"
                >
                  <button
                    type="button"
                    onClick={() => setPreviewDoc(doc)}
                    className="group relative h-40 w-full overflow-hidden bg-slate-100"
                    aria-label={`Preview ${docLabel(doc.doc_type)} document`}
                  >
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={fileUrl(doc.file_url)}
                      alt={`${docLabel(doc.doc_type)} document`}
                      className="h-full w-full object-cover transition-transform group-hover:scale-105"
                    />
                  </button>
                  <div className="space-y-2 p-3">
                    <div className="flex items-center justify-between gap-2">
                      <p className="text-sm font-medium capitalize text-slate-900">
                        {docLabel(doc.doc_type)}
                      </p>
                      <StatusBadge status={doc.status} />
                    </div>
                    {doc.status === "rejected" && doc.reason && (
                      <p className="rounded-md bg-red-50 px-2 py-1.5 text-xs text-red-700">
                        {doc.reason}
                      </p>
                    )}
                    <p className="text-xs text-slate-400">
                      Updated {formatDate(doc.updated_at)}
                    </p>
                    {doc.status === "pending" && (
                      <div className="flex gap-2 pt-1">
                        <Button
                          size="sm"
                          className="flex-1"
                          onClick={() => setApproveTarget(doc)}
                        >
                          <Check className="mr-1 h-3.5 w-3.5" />
                          Approve
                        </Button>
                        <Button
                          size="sm"
                          variant="outline"
                          className="flex-1 border-red-200 text-red-600 hover:bg-red-50"
                          onClick={() => openReject(doc)}
                        >
                          <X className="mr-1 h-3.5 w-3.5" />
                          Reject
                        </Button>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>

            {/* Identity numbers (manual entry from document images) */}
            <div className="space-y-3 rounded-lg border border-slate-200 p-4">
              <div className="flex items-center gap-2">
                <Fingerprint className="h-4 w-4 text-[#6384DB]" />
                <p className="text-sm font-semibold text-slate-900">
                  Identity numbers
                </p>
              </div>
              <p className="text-xs text-slate-500">
                Type the numbers from the uploaded documents. Stored securely;
                the tasker only sees the masked last 4 digits.
              </p>

              {numbersError && <ErrorBanner message={numbersError} />}
              {numbersSuccess && (
                <div className="space-y-2 rounded-lg border border-emerald-200 bg-emerald-50 p-3">
                  <div className="flex items-center gap-2 text-sm font-medium text-emerald-700">
                    <Check className="h-4 w-4 shrink-0" />
                    <span>Identity numbers saved</span>
                  </div>
                  {numbersSuccess.aadhaar_masked && (
                    <p className="text-xs text-emerald-700">
                      Tasker will see:{" "}
                      <span className="font-semibold">
                        {numbersSuccess.aadhaar_masked}
                      </span>{" "}
                      (Aadhaar)
                    </p>
                  )}
                  {numbersSuccess.pan_masked && (
                    <p className="text-xs text-emerald-700">
                      Tasker will see:{" "}
                      <span className="font-semibold">
                        {numbersSuccess.pan_masked}
                      </span>{" "}
                      (PAN)
                    </p>
                  )}
                  <p className="text-[11px] text-emerald-600">
                    Only the last 4 digits are shown to the tasker.
                  </p>
                </div>
              )}

              <div className="space-y-1">
                <label
                  htmlFor="kyc-aadhaar"
                  className="text-xs font-medium uppercase tracking-wide text-slate-500"
                >
                  Aadhaar number
                </label>
                <Input
                  id="kyc-aadhaar"
                  inputMode="numeric"
                  autoComplete="off"
                  placeholder="12-digit number"
                  value={aadhaarInput}
                  maxLength={12}
                  onChange={(e) =>
                    setAadhaarInput(e.target.value.replace(/\D/g, "").slice(0, 12))
                  }
                />
                {!aadhaarValid && (
                  <p className="text-xs text-amber-600">
                    Aadhaar should be 12 digits.
                  </p>
                )}
              </div>

              <div className="space-y-1">
                <label
                  htmlFor="kyc-pan"
                  className="text-xs font-medium uppercase tracking-wide text-slate-500"
                >
                  PAN number
                </label>
                <Input
                  id="kyc-pan"
                  autoComplete="off"
                  placeholder="ABCDE1234F"
                  value={panInput}
                  maxLength={10}
                  onChange={(e) =>
                    setPanInput(
                      e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 10)
                    )
                  }
                />
                {!panValid && (
                  <p className="text-xs text-amber-600">
                    PAN should look like ABCDE1234F.
                  </p>
                )}
              </div>

              <Button
                type="button"
                className="w-full"
                onClick={saveNumbers}
                disabled={savingNumbers || !hasNumberInput}
              >
                {savingNumbers ? "Saving..." : "Save identity numbers"}
              </Button>
            </div>
          </div>
        )}
      </Drawer>

      {/* Full-size image preview */}
      <Modal
        open={!!previewDoc}
        onClose={() => setPreviewDoc(null)}
        title={
          previewDoc ? (
            <span className="flex items-center gap-2">
              {docLabel(previewDoc.doc_type)} document
              <StatusBadge status={previewDoc.status} />
            </span>
          ) : (
            "Document"
          )
        }
        widthClassName="max-w-3xl"
      >
        {previewDoc && (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={fileUrl(previewDoc.file_url)}
            alt={`${docLabel(previewDoc.doc_type)} document`}
            className="w-full rounded-lg object-contain"
          />
        )}
      </Modal>

      {/* Approve confirmation */}
      <ConfirmDialog
        open={!!approveTarget}
        title="Approve document"
        variant="primary"
        message={
          <>
            Approve this{" "}
            <span className="font-semibold text-slate-900">
              {approveTarget
                ? docLabel(approveTarget.doc_type).toLowerCase()
                : ""}
            </span>{" "}
            document? The tasker will be notified in-app.
          </>
        }
        confirmLabel="Approve"
        loading={approving}
        onCancel={() => setApproveTarget(null)}
        onConfirm={confirmApprove}
      />

      {/* Reject with reason */}
      <Modal
        open={!!rejectTarget}
        onClose={() => setRejectTarget(null)}
        title="Reject document"
        widthClassName="max-w-md"
      >
        {rejectTarget && (
          <div className="space-y-4">
            {rejectError && <ErrorBanner message={rejectError} />}
            <p className="text-sm leading-relaxed text-slate-600">
              Reject this{" "}
              <span className="font-semibold text-slate-900">
                {docLabel(rejectTarget.doc_type).toLowerCase()}
              </span>{" "}
              document? The tasker will see the reason you provide below.
            </p>
            <div>
              <label
                htmlFor="reject-reason"
                className="text-xs font-medium uppercase tracking-wide text-slate-500"
              >
                Reason
              </label>
              <textarea
                id="reject-reason"
                value={rejectReason}
                onChange={(e) => setRejectReason(e.target.value)}
                rows={3}
                maxLength={500}
                placeholder="e.g. Image is blurry, please re-upload"
                className="mt-2 w-full resize-none rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-[#6384DB] focus:outline-none focus:ring-2 focus:ring-[#6384DB]/20"
              />
              {!reasonValid && rejectReason.length > 0 && (
                <p className="mt-1 text-xs text-red-600">
                  Reason must be at least 3 characters.
                </p>
              )}
            </div>
            <div className="flex justify-end gap-2 border-t border-slate-100 pt-4">
              <Button
                type="button"
                variant="outline"
                onClick={() => setRejectTarget(null)}
                disabled={rejecting}
              >
                Cancel
              </Button>
              <Button
                type="button"
                variant="destructive"
                onClick={confirmReject}
                disabled={!reasonValid || rejecting}
              >
                {rejecting ? "Working..." : "Reject document"}
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </AppShell>
  );
}
