import { RANK_ORDER } from './helpers';

export function userSortVal(u: Record<string, any>, k: string): string {
  if (k === 'name') {
    return ((u.first_name || '') + ' ' + (u.last_name || '')).toLowerCase();
  }
  if (k === 'rank') {
    return String(RANK_ORDER[u.rank || 'Operator'] || 0);
  }
  return (u[k] || '').toLowerCase();
}

export function policySortVal(p: Record<string, any>, k: string): string {
  if (k === 'rank') {
    return String(RANK_ORDER[p.rank || 'Operator'] || 0);
  }
  return (p[k] || '').toLowerCase();
}

export function sortedList<T extends Record<string, any>>(
  items: T[],
  sortKey: string,
  isAsc: boolean,
  valFn: (item: T, key: string) => string,
): T[] {
  if (!sortKey) return items;
  const copy = items.slice();
  const isNumeric = sortKey === 'rank';
  copy.sort((a, b) => {
    const va = valFn(a, sortKey);
    const vb = valFn(b, sortKey);
    if (isNumeric) {
      const na = Number(va);
      const nb = Number(vb);
      return isAsc ? na - nb : nb - na;
    }
    if (va < vb) return isAsc ? -1 : 1;
    if (va > vb) return isAsc ? 1 : -1;
    return 0;
  });
  return copy;
}
