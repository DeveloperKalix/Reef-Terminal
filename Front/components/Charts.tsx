import React, { useState, useCallback, useRef } from 'react';
import {
  LineChart, Line, AreaChart, Area,
  XAxis, YAxis, Tooltip, ResponsiveContainer,
  CartesianGrid, PieChart, Pie, Cell, Sector
} from 'recharts';

interface ChartProps {
  data: { name: string; value: number }[];
  color?: string;
  type?: 'line' | 'area';
  height?: number;
}

export const MiniChart: React.FC<ChartProps> = ({
  data, color = '#7C5CBF', type = 'line', height = 160
}) => {
  return (
    <ResponsiveContainer width="100%" height={height}>
      {type === 'area' ? (
        <AreaChart data={data} margin={{ top: 8, right: 8, bottom: 0, left: -20 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#F0EEF9" />
          <XAxis dataKey="name" tick={{ fontSize: 10, fill: '#9090B0' }} axisLine={false} tickLine={false} />
          <YAxis hide />
          <Tooltip contentStyle={{ background: '#fff', border: '1px solid #E6E3F5', borderRadius: 8, fontSize: 12, fontFamily: 'Manrope, sans-serif' }} />
          <Area type="monotone" dataKey="value" stroke={color} fill={color} fillOpacity={0.12} strokeWidth={2} dot={false} activeDot={{ r: 4, fill: color }} />
        </AreaChart>
      ) : (
        <LineChart data={data} margin={{ top: 8, right: 8, bottom: 0, left: -20 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#F0EEF9" />
          <XAxis dataKey="name" tick={{ fontSize: 10, fill: '#9090B0' }} axisLine={false} tickLine={false} />
          <YAxis hide />
          <Tooltip contentStyle={{ background: '#fff', border: '1px solid #E6E3F5', borderRadius: 8, fontSize: 12, fontFamily: 'Manrope, sans-serif' }} />
          <Line type="monotone" dataKey="value" stroke={color} strokeWidth={2} dot={false} activeDot={{ r: 4, fill: color }} />
        </LineChart>
      )}
    </ResponsiveContainer>
  );
};

interface FullChartProps extends ChartProps {
  title: string;
}

export const FullScreenChart: React.FC<FullChartProps> = ({
  data, color = '#7C5CBF', type = 'line', title
}) => {
  return (
    <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column' }}>
      <h3 style={{
        fontWeight: 800, fontSize: '1.25rem', color: '#1E1E2E',
        margin: '0 0 1rem 0', fontFamily: 'Manrope, sans-serif'
      }}>{title}</h3>
      <div style={{ flex: 1, minHeight: 0 }}>
        <ResponsiveContainer width="100%" height="100%">
          {type === 'area' ? (
            <AreaChart data={data} margin={{ top: 8, right: 16, bottom: 8, left: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#F0EEF9" />
              <XAxis dataKey="name" tick={{ fontSize: 11, fill: '#9090B0' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#9090B0' }} axisLine={false} tickLine={false} />
              <Tooltip contentStyle={{ background: '#fff', border: '1px solid #E6E3F5', borderRadius: 8, fontSize: 12, fontFamily: 'Manrope, sans-serif' }} />
              <Area type="monotone" dataKey="value" stroke={color} fill={color} fillOpacity={0.15} strokeWidth={2} dot={{ r: 3, fill: color }} activeDot={{ r: 5, fill: color }} />
            </AreaChart>
          ) : (
            <LineChart data={data} margin={{ top: 8, right: 16, bottom: 8, left: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#F0EEF9" />
              <XAxis dataKey="name" tick={{ fontSize: 11, fill: '#9090B0' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: '#9090B0' }} axisLine={false} tickLine={false} />
              <Tooltip contentStyle={{ background: '#fff', border: '1px solid #E6E3F5', borderRadius: 8, fontSize: 12, fontFamily: 'Manrope, sans-serif' }} />
              <Line type="monotone" dataKey="value" stroke={color} strokeWidth={2} dot={{ r: 3, fill: color }} activeDot={{ r: 5, fill: color }} />
            </LineChart>
          )}
        </ResponsiveContainer>
      </div>
    </div>
  );
};

/* ── Pie chart for misinformation themes ───────────── */

interface ThemeSlice {
  name: string;
  value: number;
  color: string;
  insight: string;
  trend: string;        // e.g. "+12% MoM"
  trendUp: boolean;
}

interface ThemePieProps {
  data: ThemeSlice[];
  activeLabel: string;
  onHoverSlice: (label: string) => void;
}

const renderActiveShape = (props: any) => {
  const {
    cx, cy, innerRadius, outerRadius, startAngle, endAngle,
    fill, payload, percent
  } = props;
  return (
    <g>
      <text x={cx} y={cy - 10} textAnchor="middle" fill="#1E1E2E"
        style={{ fontFamily: 'Manrope, sans-serif', fontWeight: 800, fontSize: '0.8rem' }}>
        {payload.name}
      </text>
      <text x={cx} y={cy + 14} textAnchor="middle" fill="#9090B0"
        style={{ fontFamily: 'Manrope, sans-serif', fontWeight: 600, fontSize: '0.72rem' }}>
        Themes
      </text>
      <Sector cx={cx} cy={cy} innerRadius={innerRadius} outerRadius={outerRadius + 8}
        startAngle={startAngle} endAngle={endAngle} fill={fill} />
      <Sector cx={cx} cy={cy} innerRadius={outerRadius + 12} outerRadius={outerRadius + 16}
        startAngle={startAngle} endAngle={endAngle} fill={fill} />
    </g>
  );
};

export const ThemePieChart: React.FC<ThemePieProps> = ({ data, activeLabel, onHoverSlice }) => {
  const activeIndex = data.findIndex(d => d.name === activeLabel);
  const idx = activeIndex >= 0 ? activeIndex : undefined;

  return (
    <ResponsiveContainer width="100%" height="100%">
      <PieChart>
        <Pie
          activeIndex={idx !== undefined ? idx : undefined}
          activeShape={renderActiveShape}
          data={data}
          cx="50%"
          cy="50%"
          innerRadius="48%"
          outerRadius="72%"
          dataKey="value"
          paddingAngle={2}
          onMouseEnter={(_: any, index: number) => onHoverSlice(data[index].name)}
          onMouseLeave={() => onHoverSlice('')}
          stroke="none"
        >
          {data.map((entry, i) => (
            <Cell key={entry.name} fill={entry.color} />
          ))}
        </Pie>
      </PieChart>
    </ResponsiveContainer>
  );
};
