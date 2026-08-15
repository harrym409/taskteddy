"use client";

import { useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { InitialAvatar } from "@/components/ui/avatar";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import {
  EmptyState,
  ErrorBanner,
  SuccessBanner,
  TableSkeleton,
} from "@/components/ui/feedback";
import { formatDate } from "@/lib/utils";
import { getReviews, deleteReview } from "@/lib/api";
import { Review } from "@/types";
import { ArrowRight, RefreshCw, Star, Trash2 } from "lucide-react";

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [deletingReview, setDeletingReview] = useState<Review | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [reloadKey, setReloadKey] = useState(0);

  const handleDelete = async () => {
    if (!deletingReview) return;
    setDeleting(true);
    try {
      await deleteReview(deletingReview.id);
      setSuccess("Review deleted and user rating recalculated");
      setDeletingReview(null);
      setReloadKey((k) => k + 1);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to delete review");
      setDeletingReview(null);
    } finally {
      setDeleting(false);
    }
  };

  useEffect(() => {
    setLoading(true);
    getReviews()
      .then((data) => {
        setReviews(data);
        setError(null);
      })
      .catch((err) => setError(err?.message || "Failed to load reviews"))
      .finally(() => setLoading(false));
  }, [reloadKey]);

  return (
    <AppShell>
      <PageHeader
        title="Reviews"
        subtitle="Ratings and feedback exchanged between users"
        action={
          <Button variant="outline" size="sm" onClick={() => setReloadKey((k) => k + 1)}>
            <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
            Refresh
          </Button>
        }
      />

      {error && (
        <ErrorBanner message={error} onRetry={() => setReloadKey((k) => k + 1)} />
      )}
      {success && (
        <SuccessBanner message={success} onDismiss={() => setSuccess(null)} />
      )}

      <Card className="overflow-hidden">
        {loading ? (
          <div className="p-6">
            <TableSkeleton rows={6} />
          </div>
        ) : reviews.length === 0 ? (
          <EmptyState
            icon={Star}
            title="No reviews found"
            description="Reviews will appear here as users rate each other"
          />
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Review</TableHead>
                <TableHead>Reviewer</TableHead>
                <TableHead>Rating</TableHead>
                <TableHead>Date</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {reviews.map((review) => {
                const reviewerName =
                  review.reviewer_name || review.reviewer_id.slice(0, 8);
                const reviewedName =
                  review.reviewed_user_name || review.reviewed_user_id.slice(0, 8);
                return (
                  <TableRow key={review.id}>
                    <TableCell className="max-w-xs truncate">
                      {review.comment || <span className="text-slate-400">-</span>}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-2 text-sm">
                        <InitialAvatar name={reviewerName} size="sm" />
                        <span className="font-medium text-slate-900">{reviewerName}</span>
                        <ArrowRight className="h-3.5 w-3.5 shrink-0 text-slate-400" />
                        <span className="font-medium text-slate-900">{reviewedName}</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <span className="inline-flex items-center gap-1">
                        <Star className="h-4 w-4 fill-amber-400 text-amber-400" />
                        <span className="font-medium text-slate-900">{review.rating}</span>
                        <span className="text-xs text-slate-400">/ 5</span>
                      </span>
                    </TableCell>
                    <TableCell className="text-slate-500">
                      {formatDate(review.created_at)}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        variant="outline"
                        size="sm"
                        className="border-red-200 text-red-600 hover:bg-red-50 hover:text-red-700"
                        onClick={() => setDeletingReview(review)}
                      >
                        <Trash2 className="mr-1 h-3.5 w-3.5" />
                        Delete
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        )}
      </Card>

      {/* Delete confirmation */}
      <ConfirmDialog
        open={!!deletingReview}
        title="Delete review"
        message="This review will be permanently removed and the user's rating recalculated. This action cannot be undone."
        confirmLabel="Delete review"
        variant="danger"
        loading={deleting}
        onCancel={() => setDeletingReview(null)}
        onConfirm={handleDelete}
      />
    </AppShell>
  );
}
