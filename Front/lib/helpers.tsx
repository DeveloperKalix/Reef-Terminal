export const RANK_ORDER: Record<string, number> = {
  Executive: 3,
  Administrator: 2,
  Operator: 1,
};

export function scoreColor(score: number): string {
  if (score >= 50) return 'red';
  if (score >= 20) return 'amber';
  return 'green';
}

export function rankCss(rank: string): string {
  const low = rank.toLowerCase();
  if (low === 'administrator') return 'rank-tag rank-tag--administrator';
  if (low === 'executive') return 'rank-tag rank-tag--executive';
  return 'rank-tag rank-tag--operator';
}

export function rankReqCss(rank: string): string {
  return rankCss(rank);
}

export function outcomeCss(outcome: string): string {
  const low = outcome.toLowerCase();
  if (low === 'confirmed') return 'outcome-tag outcome-tag--confirmed';
  if (low === 'escalated') return 'outcome-tag outcome-tag--escalated';
  if (low === 'dismissed') return 'outcome-tag outcome-tag--dismissed';
  if (low === 'open') return 'outcome-tag outcome-tag--open';
  if (low === 'needs review') return 'outcome-tag outcome-tag--needs-review';
  if (outcome.startsWith('Policy:')) return 'outcome-tag outcome-tag--policy';
  return 'outcome-tag outcome-tag--review';
}

export function metricBarColor(val: number): string {
  if (val <= 20) return '#3DA04D';
  if (val <= 35) return '#6DC87A';
  if (val <= 50) return '#E8C840';
  if (val <= 70) return '#E0A83A';
  return '#E05C5C';
}

export function sortIndicator(activeKey: string, currentKey: string, isAsc: boolean): string {
  if (activeKey !== currentKey) return '';
  return isAsc ? ' \u2191' : ' \u2193';
}

export function threatLevelCss(level: string): string {
  const low = level.toLowerCase();
  if (low === 'high') return 'threat-badge threat-badge--high';
  if (low === 'mid') return 'threat-badge threat-badge--mid';
  return 'threat-badge threat-badge--low';
}

export function insightSeverityCss(severity: string): string {
  if (severity === 'critical') return 'insight-severity insight-severity--critical';
  if (severity === 'warning') return 'insight-severity insight-severity--warning';
  return 'insight-severity insight-severity--info';
}
