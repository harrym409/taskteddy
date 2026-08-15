"use client";

import * as React from "react";

const BRAND = "#6384DB";
const GRID = "#e2e8f0";
const TICK = "#64748b";

const W = 600;
const H = 220;
const PAD_LEFT = 44;
const PAD_RIGHT = 8;
const PAD_TOP = 12;
const PAD_BOTTOM = 26;

function niceMax(max: number): number {
  if (max <= 0) return 1;
  const exp = Math.floor(Math.log10(max));
  const base = Math.pow(10, exp);
  const n = max / base;
  let nice: number;
  if (n <= 1) nice = 1;
  else if (n <= 2) nice = 2;
  else if (n <= 2.5) nice = 2.5;
  else if (n <= 5) nice = 5;
  else nice = 10;
  return nice * base;
}

function shortDate(iso: string): string {
  const d = new Date(iso + "T00:00:00");
  if (isNaN(d.getTime())) return iso;
  return `${d.getDate()} ${d.toLocaleString("en-IN", { month: "short" })}`;
}

function compactINR(v: number): string {
  if (v >= 10000000) return `₹${(v / 10000000).toFixed(1)}Cr`;
  if (v >= 100000) return `₹${(v / 100000).toFixed(1)}L`;
  if (v >= 1000) return `₹${(v / 1000).toFixed(v >= 10000 ? 0 : 1)}k`;
  return `₹${Math.round(v)}`;
}

function xLabelIndices(n: number): number[] {
  if (n <= 4) return Array.from({ length: n }, (_, i) => i);
  const step = (n - 1) / 3;
  return [0, Math.round(step), Math.round(step * 2), n - 1];
}

interface ChartPoint {
  date: string;
  value: number;
}

function EmptyChart() {
  return (
    <div className="flex h-[220px] items-center justify-center text-sm text-gray-500">
      No data yet
    </div>
  );
}

export function BarChart({ data }: { data: ChartPoint[] }) {
  if (!data || data.length === 0) return <EmptyChart />;

  const plotW = W - PAD_LEFT - PAD_RIGHT;
  const plotH = H - PAD_TOP - PAD_BOTTOM;
  const max = niceMax(Math.max(...data.map((d) => d.value)));
  const ticks = [0, max / 3, (2 * max) / 3, max];
  const slot = plotW / data.length;
  const barW = slot * 0.6; // 40% gap
  const labelIdx = new Set(xLabelIndices(data.length));

  return (
    <svg viewBox={`0 0 ${W} ${H}`} className="h-auto w-full" role="img">
      {/* Horizontal gridlines */}
      {ticks.map((t, i) => {
        const y = PAD_TOP + plotH - (t / max) * plotH;
        return (
          <g key={i}>
            <line x1={PAD_LEFT} x2={W - PAD_RIGHT} y1={y} y2={y} stroke={GRID} strokeWidth={1} />
            <text
              x={PAD_LEFT - 6}
              y={y + 3.5}
              textAnchor="end"
              fontSize={11}
              fill={TICK}
            >
              {t >= 1000 ? `${(t / 1000).toFixed(t % 1000 === 0 ? 0 : 1)}k` : Math.round(t)}
            </text>
          </g>
        );
      })}
      {/* Bars */}
      {data.map((d, i) => {
        const h = max > 0 ? (d.value / max) * plotH : 0;
        const x = PAD_LEFT + i * slot + (slot - barW) / 2;
        const y = PAD_TOP + plotH - h;
        return (
          <rect
            key={d.date}
            x={x}
            y={y}
            width={barW}
            height={Math.max(h, d.value > 0 ? 2 : 0)}
            rx={2}
            fill={BRAND}
          >
            <title>{`${shortDate(d.date)}: ${d.value}`}</title>
          </rect>
        );
      })}
      {/* X-axis labels */}
      {data.map((d, i) =>
        labelIdx.has(i) ? (
          <text
            key={`x-${d.date}`}
            x={PAD_LEFT + i * slot + slot / 2}
            y={H - 8}
            textAnchor="middle"
            fontSize={11}
            fill={TICK}
          >
            {shortDate(d.date)}
          </text>
        ) : null
      )}
    </svg>
  );
}

interface LineSeries {
  name: string;
  color: string;
  data: ChartPoint[];
}

/**
 * Multi-series line chart on a shared y-axis. Intended for same-unit series
 * (e.g. new customers vs new taskers). Renders a compact legend above the plot.
 */
export function MultiLineChart({ series }: { series: LineSeries[] }) {
  const nonEmpty = series.filter((s) => s.data && s.data.length > 0);
  if (nonEmpty.length === 0) return <EmptyChart />;

  const length = Math.max(...nonEmpty.map((s) => s.data.length));
  const plotW = W - PAD_LEFT - PAD_RIGHT;
  const plotH = H - PAD_TOP - PAD_BOTTOM;
  const rawMax = Math.max(1, ...nonEmpty.flatMap((s) => s.data.map((d) => d.value)));
  const max = niceMax(rawMax);
  const ticks = [0, max / 3, (2 * max) / 3, max];
  const labelIdx = new Set(xLabelIndices(length));
  const axisDates = (nonEmpty.find((s) => s.data.length === length) ?? nonEmpty[0]).data;

  const px = (i: number) =>
    length === 1 ? PAD_LEFT + plotW / 2 : PAD_LEFT + (i / (length - 1)) * plotW;
  const py = (v: number) => PAD_TOP + plotH - (max > 0 ? (v / max) * plotH : 0);

  return (
    <div>
      <div className="mb-2 flex flex-wrap items-center gap-x-4 gap-y-1">
        {series.map((s) => (
          <span key={s.name} className="inline-flex items-center gap-1.5 text-xs text-slate-600">
            <span className="h-2 w-2 rounded-full" style={{ backgroundColor: s.color }} />
            {s.name}
          </span>
        ))}
      </div>
      <svg viewBox={`0 0 ${W} ${H}`} className="h-auto w-full" role="img">
        {ticks.map((t, i) => {
          const y = PAD_TOP + plotH - (t / max) * plotH;
          return (
            <g key={i}>
              <line x1={PAD_LEFT} x2={W - PAD_RIGHT} y1={y} y2={y} stroke={GRID} strokeWidth={1} />
              <text x={PAD_LEFT - 6} y={y + 3.5} textAnchor="end" fontSize={11} fill={TICK}>
                {t >= 1000 ? `${(t / 1000).toFixed(t % 1000 === 0 ? 0 : 1)}k` : Math.round(t)}
              </text>
            </g>
          );
        })}
        {series.map((s) => {
          if (!s.data || s.data.length === 0) return null;
          const linePath = s.data
            .map((d, i) => `${i === 0 ? "M" : "L"}${px(i).toFixed(2)},${py(d.value).toFixed(2)}`)
            .join(" ");
          return (
            <g key={s.name}>
              <path
                d={linePath}
                fill="none"
                stroke={s.color}
                strokeWidth={2}
                strokeLinejoin="round"
                strokeLinecap="round"
              />
              {s.data.map((d, i) => (
                <circle key={d.date} cx={px(i)} cy={py(d.value)} r={2.2} fill={s.color}>
                  <title>{`${s.name} — ${shortDate(d.date)}: ${d.value}`}</title>
                </circle>
              ))}
            </g>
          );
        })}
        {axisDates.map((d, i) =>
          labelIdx.has(i) ? (
            <text
              key={`x-${d.date}`}
              x={px(i)}
              y={H - 8}
              textAnchor="middle"
              fontSize={11}
              fill={TICK}
            >
              {shortDate(d.date)}
            </text>
          ) : null
        )}
      </svg>
    </div>
  );
}

export function AreaChart({ data }: { data: ChartPoint[] }) {
  if (!data || data.length === 0) return <EmptyChart />;

  const plotW = W - PAD_LEFT - PAD_RIGHT;
  const plotH = H - PAD_TOP - PAD_BOTTOM;
  const max = niceMax(Math.max(...data.map((d) => d.value)));
  const ticks = [0, max / 3, (2 * max) / 3, max];
  const labelIdx = new Set(xLabelIndices(data.length));

  const px = (i: number) =>
    data.length === 1
      ? PAD_LEFT + plotW / 2
      : PAD_LEFT + (i / (data.length - 1)) * plotW;
  const py = (v: number) => PAD_TOP + plotH - (max > 0 ? (v / max) * plotH : 0);

  const linePath = data
    .map((d, i) => `${i === 0 ? "M" : "L"}${px(i).toFixed(2)},${py(d.value).toFixed(2)}`)
    .join(" ");
  const areaPath = `${linePath} L${px(data.length - 1).toFixed(2)},${(
    PAD_TOP + plotH
  ).toFixed(2)} L${px(0).toFixed(2)},${(PAD_TOP + plotH).toFixed(2)} Z`;

  return (
    <svg viewBox={`0 0 ${W} ${H}`} className="h-auto w-full" role="img">
      {/* Horizontal gridlines */}
      {ticks.map((t, i) => {
        const y = PAD_TOP + plotH - (t / max) * plotH;
        return (
          <g key={i}>
            <line x1={PAD_LEFT} x2={W - PAD_RIGHT} y1={y} y2={y} stroke={GRID} strokeWidth={1} />
            <text
              x={PAD_LEFT - 6}
              y={y + 3.5}
              textAnchor="end"
              fontSize={11}
              fill={TICK}
            >
              {compactINR(t)}
            </text>
          </g>
        );
      })}
      {/* Flat area fill at 12% opacity */}
      <path d={areaPath} fill={BRAND} fillOpacity={0.12} />
      {/* Line */}
      <path d={linePath} fill="none" stroke={BRAND} strokeWidth={2} strokeLinejoin="round" strokeLinecap="round" />
      {/* Points */}
      {data.map((d, i) => (
        <circle key={d.date} cx={px(i)} cy={py(d.value)} r={2.5} fill={BRAND}>
          <title>{`${shortDate(d.date)}: ${compactINR(d.value)}`}</title>
        </circle>
      ))}
      {/* X-axis labels */}
      {data.map((d, i) =>
        labelIdx.has(i) ? (
          <text
            key={`x-${d.date}`}
            x={px(i)}
            y={H - 8}
            textAnchor="middle"
            fontSize={11}
            fill={TICK}
          >
            {shortDate(d.date)}
          </text>
        ) : null
      )}
    </svg>
  );
}
