import React from 'react';
import {
  LineChart, Line,
  XAxis, YAxis, Tooltip, ResponsiveContainer,
  CartesianGrid
} from 'recharts';

interface TrendPoint {
  name: string;
  posts: number;
  reach: number;
  risk: number;
}

interface ActorTrendsChartProps {
  data: TrendPoint[];
  height?: number;
}

const formatReach = (v: number) => {
  if (v >= 1_000_000) return `${(v / 1_000_000).toFixed(1)}M`;
  if (v >= 1_000) return `${(v / 1_000).toFixed(0)}K`;
  return String(v);
};

export const ActorTrendsChart: React.FC<ActorTrendsChartProps> = ({ data, height = 200 }) => {
  return (
    <ResponsiveContainer width="100%" height={height}>
      <LineChart data={data} margin={{ top: 8, right: 12, bottom: 0, left: -10 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#F0EEF9" />
        <XAxis
          dataKey="name"
          tick={{ fontSize: 10, fill: '#9090B0' }}
          axisLine={false}
          tickLine={false}
        />
        <YAxis
          yAxisId="left"
          tick={{ fontSize: 10, fill: '#9090B0' }}
          axisLine={false}
          tickLine={false}
          width={40}
        />
        <YAxis
          yAxisId="right"
          orientation="right"
          tick={{ fontSize: 10, fill: '#9090B0' }}
          axisLine={false}
          tickLine={false}
          tickFormatter={formatReach}
          width={48}
        />
        <Tooltip
          contentStyle={{
            background: '#fff',
            border: '1px solid #E6E3F5',
            borderRadius: 8,
            fontSize: 12,
            fontFamily: 'Manrope, sans-serif',
          }}
          formatter={(value: number, name: string) => {
            if (name === 'reach') return [formatReach(value), 'Reach'];
            if (name === 'posts') return [value, 'Posts'];
            return [value, 'Risk'];
          }}
        />
        <Line yAxisId="left" type="monotone" dataKey="posts" stroke="#7C5CBF" strokeWidth={2} dot={false} activeDot={{ r: 4, fill: '#7C5CBF' }} />
        <Line yAxisId="right" type="monotone" dataKey="reach" stroke="#E05C5C" strokeWidth={2} dot={false} activeDot={{ r: 4, fill: '#E05C5C' }} />
      </LineChart>
    </ResponsiveContainer>
  );
};
