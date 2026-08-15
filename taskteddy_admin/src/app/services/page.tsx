"use client";

import { useEffect, useState } from "react";
import { AppShell } from "@/components/app-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Modal } from "@/components/ui/modal";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { StatusBadge } from "@/components/ui/status-badge";
import { EmptyState, ErrorBanner, TableSkeleton } from "@/components/ui/feedback";
import { getServices, updateService, createService, deleteService } from "@/lib/api";
import { formatCurrency } from "@/lib/utils";
import { Service, ServicePayload } from "@/types";
import { Search, Star, Plus, Pencil, Trash2, Wrench, RefreshCw } from "lucide-react";

interface ServiceFormState {
  name: string;
  emoji: string;
  category: string;
  description: string;
  price: string;
  original_price: string;
  includes: string;
  is_hot: boolean;
  is_new: boolean;
}

const emptyForm: ServiceFormState = {
  name: "",
  emoji: "",
  category: "cleaning",
  description: "",
  price: "",
  original_price: "",
  includes: "",
  is_hot: false,
  is_new: false,
};

export default function ServicesPage() {
  const [services, setServices] = useState<Service[]>([]);
  const [togglingId, setTogglingId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<string>("all");

  // Modal state
  const [modalOpen, setModalOpen] = useState(false);
  const [editingService, setEditingService] = useState<Service | null>(null);
  const [form, setForm] = useState<ServiceFormState>(emptyForm);
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  // Delete confirmation state
  const [deleteTarget, setDeleteTarget] = useState<Service | null>(null);
  const [deleting, setDeleting] = useState(false);

  const fetchServices = async () => {
    setLoading(true);
    setError(null);
    try {
      const category = categoryFilter === "all" ? undefined : categoryFilter;
      const data = await getServices(category);
      setServices(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load services");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchServices();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [categoryFilter]);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    fetchServices();
  };

  const handleToggleActive = async (service: Service) => {
    if (togglingId) return;
    setTogglingId(service.id);
    try {
      await updateService(service.id, { is_active: !service.is_active });
      fetchServices();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to update service");
    }
    setTogglingId(null);
  };

  const confirmDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await deleteService(deleteTarget.id);
      setDeleteTarget(null);
      fetchServices();
    } catch (err) {
      setDeleteTarget(null);
      setError(err instanceof Error ? err.message : "Failed to delete service");
    } finally {
      setDeleting(false);
    }
  };

  const openAddModal = () => {
    setEditingService(null);
    setForm(emptyForm);
    setFormError(null);
    setModalOpen(true);
  };

  const openEditModal = (service: Service) => {
    setEditingService(service);
    setForm({
      name: service.name,
      emoji: service.emoji || "",
      category: service.category,
      description: service.description,
      price: String(service.price),
      original_price: service.original_price ? String(service.original_price) : "",
      includes: (service.includes || []).join(", "),
      is_hot: service.is_hot,
      is_new: service.is_new,
    });
    setFormError(null);
    setModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    const price = parseFloat(form.price);
    if (!form.name.trim() || isNaN(price) || price <= 0) {
      setFormError("Name and a valid price are required.");
      return;
    }
    const originalPrice = form.original_price ? parseFloat(form.original_price) : undefined;
    if (form.original_price && (originalPrice === undefined || isNaN(originalPrice))) {
      setFormError("Original price must be a number.");
      return;
    }

    const payload: ServicePayload = {
      name: form.name.trim(),
      emoji: form.emoji.trim(),
      category: form.category,
      description: form.description.trim(),
      price,
      ...(originalPrice !== undefined && !isNaN(originalPrice)
        ? { original_price: originalPrice }
        : {}),
      includes: form.includes
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean),
      is_hot: form.is_hot,
      is_new: form.is_new,
    };

    setSaving(true);
    try {
      if (editingService) {
        await updateService(editingService.id, payload as Partial<Service>);
      } else {
        await createService(payload);
      }
      setModalOpen(false);
      fetchServices();
    } catch (err) {
      setFormError(err instanceof Error ? err.message : "Failed to save service");
    } finally {
      setSaving(false);
    }
  };

  const filteredServices = search.trim()
    ? services.filter((s) => s.name.toLowerCase().includes(search.trim().toLowerCase()))
    : services;

  return (
    <AppShell>
      <PageHeader
        title="Services"
        subtitle="Manage the service catalog offered to customers"
        action={
          <>
            <Button variant="outline" size="sm" onClick={fetchServices}>
              <RefreshCw className="mr-1.5 h-3.5 w-3.5" />
              Refresh
            </Button>
            <Button onClick={openAddModal}>
              <Plus className="mr-1 h-4 w-4" />
              Add Service
            </Button>
          </>
        }
      />

      {error && <ErrorBanner message={error} onRetry={fetchServices} />}

      {/* Filters */}
      <Card className="mb-6">
        <CardContent className="p-4">
          <form onSubmit={handleSearch} className="flex flex-wrap gap-3">
            <div className="relative min-w-56 flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
              <Input
                placeholder="Search services..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-10"
              />
            </div>
            <select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              className="rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-700 focus:border-[#6384DB] focus:outline-none focus:ring-2 focus:ring-[#6384DB]/25"
            >
              <option value="all">All Categories</option>
              <option value="cleaning">Cleaning</option>
              <option value="laundry">Laundry</option>
              <option value="kitchen">Kitchen</option>
              <option value="organising">Organising</option>
            </select>
          </form>
        </CardContent>
      </Card>

      {/* Services Table */}
      <Card className="overflow-hidden">
        {loading ? (
          <div className="p-6">
            <TableSkeleton rows={6} />
          </div>
        ) : filteredServices.length === 0 ? (
          <EmptyState
            icon={Wrench}
            title="No services found"
            description="Add a service to get started"
            action={
              <Button size="sm" onClick={openAddModal}>
                <Plus className="mr-1 h-4 w-4" />
                Add Service
              </Button>
            }
          />
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Service</TableHead>
                <TableHead>Category</TableHead>
                <TableHead>Price</TableHead>
                <TableHead>Original</TableHead>
                <TableHead>Rating</TableHead>
                <TableHead>Flags</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredServices.map((service) => (
                <TableRow key={service.id}>
                  <TableCell>
                    <div className="flex items-center gap-2.5">
                      {/* service.emoji is catalog data, not UI chrome */}
                      {service.emoji && (
                        <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-slate-100 text-base">
                          {service.emoji}
                        </span>
                      )}
                      <span className="block max-w-xs truncate font-medium text-slate-900" title={service.name}>{service.name}</span>
                    </div>
                  </TableCell>
                  <TableCell className="capitalize">{service.category}</TableCell>
                  <TableCell className="font-medium text-slate-900">
                    {formatCurrency(service.price)}
                  </TableCell>
                  <TableCell>
                    {service.original_price > service.price ? (
                      <span className="text-slate-400 line-through">
                        {formatCurrency(service.original_price)}
                      </span>
                    ) : (
                      <span className="text-slate-400">-</span>
                    )}
                  </TableCell>
                  <TableCell>
                    <span className="inline-flex items-center gap-1">
                      <Star className="h-3.5 w-3.5 fill-amber-400 text-amber-400" />
                      {service.rating.toFixed(1)}
                      <span className="text-xs text-slate-400">({service.review_count})</span>
                    </span>
                  </TableCell>
                  <TableCell>
                    <div className="flex gap-1">
                      {service.is_hot && (
                        <span className="rounded-full bg-red-50 px-2 py-0.5 text-[10px] font-semibold text-red-700">
                          HOT
                        </span>
                      )}
                      {service.is_new && (
                        <span className="rounded-full bg-[#6384DB]/10 px-2 py-0.5 text-[10px] font-semibold text-[#6384DB]">
                          NEW
                        </span>
                      )}
                    </div>
                  </TableCell>
                  <TableCell>
                    <StatusBadge status={service.is_active ? "active" : "inactive"} />
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-1">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleToggleActive(service)}
                      >
                        {service.is_active ? "Deactivate" : "Activate"}
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8"
                        onClick={() => openEditModal(service)}
                        title="Edit"
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8"
                        onClick={() => setDeleteTarget(service)}
                        title="Delete"
                      >
                        <Trash2 className="h-4 w-4 text-red-500" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Card>

      {/* Delete confirmation */}
      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete service"
        message={
          <>
            Delete{" "}
            <span className="font-semibold text-slate-900">
              &ldquo;{deleteTarget?.name}&rdquo;
            </span>
            ? It will be deactivated and removed from the catalog.
          </>
        }
        confirmLabel="Delete service"
        loading={deleting}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={confirmDelete}
      />

      {/* Add / Edit Modal */}
      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editingService ? "Edit Service" : "Add Service"}
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          {formError && (
            <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
              {formError}
            </div>
          )}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <div className="space-y-1 sm:col-span-2">
              <label className="text-sm font-medium text-slate-700">Name</label>
              <Input
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                placeholder="Deep Home Cleaning"
                required
              />
            </div>
            <div className="space-y-1">
              <label className="text-sm font-medium text-slate-700">Emoji</label>
              <Input
                value={form.emoji}
                onChange={(e) => setForm({ ...form, emoji: e.target.value })}
                placeholder="Paste an emoji"
              />
            </div>
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Category</label>
            <select
              value={form.category}
              onChange={(e) => setForm({ ...form, category: e.target.value })}
              className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-700 focus:border-[#6384DB] focus:outline-none focus:ring-2 focus:ring-[#6384DB]/25"
            >
              <option value="cleaning">Cleaning</option>
              <option value="laundry">Laundry</option>
              <option value="kitchen">Kitchen</option>
              <option value="organising">Organising</option>
            </select>
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">Description</label>
            <textarea
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              rows={3}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-[#6384DB] focus:outline-none focus:ring-2 focus:ring-[#6384DB]/25"
              placeholder="What's included in this service..."
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1">
              <label className="text-sm font-medium text-slate-700">Price (₹)</label>
              <Input
                type="number"
                min="0"
                step="0.01"
                value={form.price}
                onChange={(e) => setForm({ ...form, price: e.target.value })}
                required
              />
            </div>
            <div className="space-y-1">
              <label className="text-sm font-medium text-slate-700">
                Original price (₹)
              </label>
              <Input
                type="number"
                min="0"
                step="0.01"
                value={form.original_price}
                onChange={(e) => setForm({ ...form, original_price: e.target.value })}
                placeholder="Optional"
              />
            </div>
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-700">
              Includes (comma-separated)
            </label>
            <Input
              value={form.includes}
              onChange={(e) => setForm({ ...form, includes: e.target.value })}
              placeholder="Dusting, Mopping, Bathroom cleaning"
            />
          </div>
          <div className="flex gap-6">
            <label className="flex items-center gap-2 text-sm text-slate-700">
              <input
                type="checkbox"
                checked={form.is_hot}
                onChange={(e) => setForm({ ...form, is_hot: e.target.checked })}
                className="h-4 w-4 rounded border-slate-300 accent-[#6384DB]"
              />
              Mark as Hot
            </label>
            <label className="flex items-center gap-2 text-sm text-slate-700">
              <input
                type="checkbox"
                checked={form.is_new}
                onChange={(e) => setForm({ ...form, is_new: e.target.checked })}
                className="h-4 w-4 rounded border-slate-300 accent-[#6384DB]"
              />
              Mark as New
            </label>
          </div>
          <div className="flex justify-end gap-2 border-t border-slate-100 pt-4">
            <Button type="button" variant="outline" onClick={() => setModalOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" disabled={saving}>
              {saving ? "Saving..." : editingService ? "Save Changes" : "Create Service"}
            </Button>
          </div>
        </form>
      </Modal>
    </AppShell>
  );
}
