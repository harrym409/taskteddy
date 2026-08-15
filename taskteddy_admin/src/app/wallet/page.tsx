"use client";

import { useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { PartyCell } from "@/components/ui/avatar";
import { StatusBadge } from "@/components/ui/status-badge";
import { EmptyState, ErrorBanner, TableSkeleton } from "@/components/ui/feedback";
import { getTransactions, getWithdrawals, approveWithdrawal, rejectWithdrawal } from "@/lib/api";
import { exportCsv } from "@/lib/csv";
import { formatDate, formatCurrency } from "@/lib/utils";
import { Transaction, Withdrawal } from "@/types";
import { ArrowLeftRight, Check, Download, HandCoins, RefreshCw, X } from "lucide-react";

const WITHDRAWAL_STATUSES = ["pending", "approved", "completed", "rejected", "all"] as const;

type PendingAction = { type: "approve" | "reject"; withdrawal: Withdrawal };

export default function WalletPage() {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [withdrawals, setWithdrawals] = useState<Withdrawal[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<"transactions" | "withdrawals">("transactions");
  const [withdrawalStatus, setWithdrawalStatus] = useState<string>("pending");
  const [pendingAction, setPendingAction] = useState<PendingAction | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      if (activeTab === "transactions") {
        const data = await getTransactions(50);
        setTransactions(data);
      } else {
        const data = await getWithdrawals(
          withdrawalStatus === "all" ? undefined : withdrawalStatus
        );
        setWithdrawals(data);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load data");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab, withdrawalStatus]);

  const confirmAction = async () => {
    if (!pendingAction) return;
    setActionLoading(true);
    try {
      if (pendingAction.type === "approve") {
        await approveWithdrawal(pendingAction.withdrawal.id);
      } else {
        await rejectWithdrawal(pendingAction.withdrawal.id);
      }
      setPendingAction(null);
      fetchData();
    } catch (err) {
      setPendingAction(null);
      setError(
        err instanceof Error
          ? err.message
          : `Failed to ${pendingAction.type} withdrawal`
      );
    } finally {
      setActionLoading(false);
    }
  };

  const handleExport = () => {
    if (activeTab === "transactions") {
      exportCsv(
        "transactions",
        ["ID", "User", "Type", "Amount", "Description", "Date"],
        transactions.map((t) => [
          t.id,
          t.user_name || t.user_id,
          t.type,
          t.amount,
          t.description,
          t.created_at,
        ])
      );
    } else {
      exportCsv(
        "withdrawals",
        ["ID", "User", "Amount", "Method", "Details", "Status", "Date"],
        withdrawals.map((w) => [
          w.id,
          w.user_name || w.user_id,
          w.amount,
          w.method,
          Object.entries(w.details || {})
            .map(([k, v]) => `${k}: ${String(v)}`)
            .join("; "),
          w.status,
          w.created_at,
        ])
      );
    }
  };

  const exportDisabled =
    loading ||
    (activeTab === "transactions" ? transactions.length === 0 : withdrawals.length === 0);

  return (
    <AppShell>
      <PageHeader
        title="Wallet"
        subtitle="Monitor transactions and process withdrawal requests"
        action={
          <>
            <Button variant="outline" size="sm" onClick={fetchData}>
              <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
              Refresh
            </Button>
            <Button variant="outline" size="sm" onClick={handleExport} disabled={exportDisabled}>
              <Download className="mr-1.5 h-3.5 w-3.5" />
              Export CSV
            </Button>
          </>
        }
      />

      {error && <ErrorBanner message={error} onRetry={fetchData} />}

      {/* Tabs */}
      <div className="mb-6 inline-flex rounded-lg border border-slate-200 bg-white p-1 shadow-sm">
        {(
          [
            { key: "transactions", label: "Transactions", icon: ArrowLeftRight },
            { key: "withdrawals", label: "Withdrawal Requests", icon: HandCoins },
          ] as const
        ).map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`flex items-center gap-2 rounded-md px-4 py-2 text-sm font-medium transition-colors ${
              activeTab === tab.key
                ? "bg-[#6384DB] text-white shadow-sm"
                : "text-slate-600 hover:bg-slate-50"
            }`}
          >
            <tab.icon className="h-4 w-4" />
            {tab.label}
          </button>
        ))}
      </div>

      {/* Transactions Table */}
      {activeTab === "transactions" && (
        <Card className="overflow-hidden">
          {loading ? (
            <div className="p-6">
              <TableSkeleton rows={6} />
            </div>
          ) : transactions.length === 0 ? (
            <EmptyState
              icon={ArrowLeftRight}
              title="No transactions found"
              description="Wallet activity will appear here"
            />
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Type</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead>Description</TableHead>
                  <TableHead>Date</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {transactions.map((txn) => (
                  <TableRow key={txn.id}>
                    <TableCell>
                      <PartyCell
                        name={txn.user_name || `${txn.user_id.slice(0, 8)}...`}
                        meta={txn.user_name ? `${txn.user_id.slice(0, 8)}...` : undefined}
                        size="sm"
                      />
                    </TableCell>
                    <TableCell className="capitalize">
                      {txn.type.replace(/_/g, " ")}
                    </TableCell>
                    <TableCell
                      className={`font-medium ${
                        txn.amount > 0 ? "text-emerald-600" : "text-red-600"
                      }`}
                    >
                      {txn.amount > 0 ? "+" : ""}
                      {formatCurrency(txn.amount)}
                    </TableCell>
                    <TableCell className="max-w-xs truncate text-slate-500">
                      {txn.description || "-"}
                    </TableCell>
                    <TableCell className="text-slate-500">
                      {formatDate(txn.created_at)}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </Card>
      )}

      {/* Withdrawals Table */}
      {activeTab === "withdrawals" && (
        <>
          {/* Status filter row */}
          <div className="mb-6 flex flex-wrap gap-2">
            {WITHDRAWAL_STATUSES.map((status) => (
              <button
                key={status}
                onClick={() => setWithdrawalStatus(status)}
                className={`rounded-full px-4 py-1.5 text-sm font-medium capitalize transition-colors ${
                  withdrawalStatus === status
                    ? "bg-[#6384DB] text-white shadow-sm"
                    : "border border-slate-300 bg-white text-slate-600 hover:bg-slate-50"
                }`}
              >
                {status === "all" ? "All" : status}
              </button>
            ))}
          </div>

          <Card className="overflow-hidden">
            {loading ? (
              <div className="p-6">
                <TableSkeleton rows={6} />
              </div>
            ) : withdrawals.length === 0 ? (
              <EmptyState
                icon={HandCoins}
                title="No withdrawals found"
                description={
                  withdrawalStatus === "all"
                    ? "Withdrawal requests will appear here"
                    : `No ${withdrawalStatus} withdrawals`
                }
              />
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>User</TableHead>
                    <TableHead>Amount</TableHead>
                    <TableHead>Method</TableHead>
                    <TableHead>Details</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Date</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {withdrawals.map((wd) => (
                    <TableRow key={wd.id}>
                      <TableCell>
                        <PartyCell
                          name={wd.user_name || `${wd.user_id.slice(0, 8)}...`}
                          meta={wd.user_name ? `${wd.user_id.slice(0, 8)}...` : undefined}
                          size="sm"
                        />
                      </TableCell>
                      <TableCell className="font-semibold text-slate-900">
                        {formatCurrency(wd.amount)}
                      </TableCell>
                      <TableCell className="capitalize">{wd.method}</TableCell>
                      <TableCell className="max-w-xs truncate font-mono text-xs text-slate-500">
                        {Object.entries(wd.details || {})
                          .map(([k, v]) => `${k}: ${String(v)}`)
                          .join(", ") || "-"}
                      </TableCell>
                      <TableCell>
                        <StatusBadge status={wd.status} />
                      </TableCell>
                      <TableCell className="text-slate-500">
                        {formatDate(wd.created_at)}
                      </TableCell>
                      <TableCell className="text-right">
                        {wd.status === "pending" ? (
                          <div className="flex justify-end gap-2">
                            <Button
                              size="sm"
                              onClick={() =>
                                setPendingAction({ type: "approve", withdrawal: wd })
                              }
                            >
                              <Check className="mr-1 h-4 w-4" />
                              Approve
                            </Button>
                            <Button
                              variant="destructive"
                              size="sm"
                              onClick={() =>
                                setPendingAction({ type: "reject", withdrawal: wd })
                              }
                            >
                              <X className="mr-1 h-4 w-4" />
                              Reject
                            </Button>
                          </div>
                        ) : (
                          <span className="text-xs text-slate-400">-</span>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </Card>
        </>
      )}

      {/* Approve / reject confirmation */}
      <ConfirmDialog
        open={!!pendingAction}
        title={pendingAction?.type === "approve" ? "Approve withdrawal" : "Reject withdrawal"}
        variant={pendingAction?.type === "approve" ? "primary" : "danger"}
        message={
          pendingAction ? (
            <>
              {pendingAction.type === "approve" ? "Approve" : "Reject"} the withdrawal of{" "}
              <span className="font-semibold text-slate-900">
                {formatCurrency(pendingAction.withdrawal.amount)}
              </span>{" "}
              requested by{" "}
              <span className="font-semibold text-slate-900">
                {pendingAction.withdrawal.user_name ||
                  `${pendingAction.withdrawal.user_id.slice(0, 8)}...`}
              </span>
              {pendingAction.type === "approve"
                ? "? The payout will be processed."
                : "? The amount will be returned to the user's wallet."}
            </>
          ) : (
            ""
          )
        }
        confirmLabel={pendingAction?.type === "approve" ? "Approve" : "Reject"}
        loading={actionLoading}
        onCancel={() => setPendingAction(null)}
        onConfirm={confirmAction}
      />
    </AppShell>
  );
}
