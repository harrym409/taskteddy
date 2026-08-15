type CsvValue = string | number | boolean | null | undefined;

function escapeCell(value: CsvValue): string {
  let s = value === null || value === undefined ? "" : String(value);
  // Prevent spreadsheet formula injection (=, +, -, @ at cell start).
  if (/^[=+\-@]/.test(s)) s = "'" + s;
  return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

function dateStamp(): string {
  const d = new Date();
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}`;
}

/**
 * Client-side CSV download of the currently loaded rows.
 * Produces a file named `taskteddy-<baseName>-YYYYMMDD.csv`.
 */
export function exportCsv(baseName: string, headers: string[], rows: CsvValue[][]): void {
  if (typeof window === "undefined") return;
  const lines = [headers, ...rows].map((row) => row.map(escapeCell).join(","));
  // BOM so Excel opens UTF-8 (₹, names) correctly.
  const blob = new Blob(["\uFEFF" + lines.join("\r\n")], {
    type: "text/csv;charset=utf-8;",
  });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `taskteddy-${baseName}-${dateStamp()}.csv`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
