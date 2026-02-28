import React from 'react';
import { rankCss, rankReqCss, sortIndicator } from '../../lib/helpers';
import { policySortVal, sortedList } from '../../lib/sorting';

interface PoliciesTabProps {
  policies: any[];
  isExecutive: boolean;
  sortKey: string;
  sortAsc: boolean;
  openPolicyMenu: string;
  onToggleSort: (key: string) => void;
  onSetOpenPolicyMenu: (v: string) => void;
  onOpenAddModal: () => void;
  onOpenEditModal: (p: any) => void;
  onDeletePolicy: (id: string) => void;
}

export const PoliciesTab: React.FC<PoliciesTabProps> = ({
  policies, isExecutive, sortKey, sortAsc, openPolicyMenu,
  onToggleSort, onSetOpenPolicyMenu, onOpenAddModal, onOpenEditModal, onDeletePolicy,
}) => {
  const sorted = sortedList(policies, sortKey, sortAsc, policySortVal);
  const ind = (key: string) => sortIndicator(sortKey, key, sortAsc);

  return (
    <div className="dashboard-content-card">
      <div className="content-header">
        <h2>Policies</h2>
        {isExecutive && (
          <button className="btn-add" onClick={onOpenAddModal} type="button">+ Add Policy</button>
        )}
      </div>

      {policies.length === 0 ? (
        <p className="empty-state">No policies defined yet.</p>
      ) : (
        <table className="data-table">
          <thead>
            <tr>
              <th className="sortable-th" onClick={() => onToggleSort('name')}>Name<span className="sort-arrow">{ind('name')}</span></th>
              <th className="sortable-th" onClick={() => onToggleSort('description')}>Description<span className="sort-arrow">{ind('description')}</span></th>
              <th className="sortable-th" onClick={() => onToggleSort('restriction')}>Restriction<span className="sort-arrow">{ind('restriction')}</span></th>
              <th className="sortable-th" onClick={() => onToggleSort('rank')}>Rank Req.<span className="sort-arrow">{ind('rank')}</span></th>
              <th className="col-actions"></th>
            </tr>
          </thead>
          <tbody>
            {sorted.map((p: any) => (
              <tr key={p.id}>
                <td style={{ fontWeight: 'var(--font-weight-semibold)', color: 'var(--color-text-heading)' }}>{p.name}</td>
                <td style={{ maxWidth: '320px', lineHeight: '1.4' }}>{p.description}</td>
                <td>{p.restriction}</td>
                <td><span className={rankReqCss(p.rank || 'Operator')}>{p.rank || 'Operator'}</span></td>
                <td className="col-actions">
                  <div className="dot-menu-wrap">
                    <button
                      className="dot-menu-btn"
                      type="button"
                      onClick={() => onSetOpenPolicyMenu(openPolicyMenu === p.id ? '' : p.id)}
                    >
                      <img src="/static/assets/menu.svg" alt="menu" style={{ width: '4px', height: '18px', opacity: '0.6' }} />
                    </button>
                    {openPolicyMenu === p.id && (
                      <div className="dot-menu-dropdown">
                        <button onClick={() => onOpenEditModal(p)} disabled={!isExecutive}>Edit</button>
                        <button className="danger" onClick={() => onDeletePolicy(p.id)} disabled={!isExecutive}>Delete</button>
                      </div>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      {!isExecutive && <p className="perm-notice">Only Executive-rank users can add, edit, or delete policies.</p>}
    </div>
  );
};

interface PolicyModalProps {
  mode: 'add' | 'edit';
  polName: string;
  polDesc: string;
  polRestriction: string;
  polRank: string;
  polError: string;
  polSaving: boolean;
  onSetName: (v: string) => void;
  onSetDesc: (v: string) => void;
  onSetRestriction: (v: string) => void;
  onSetRank: (v: string) => void;
  onSubmit: () => void;
  onClose: () => void;
}

export const PolicyModal: React.FC<PolicyModalProps> = ({
  mode, polName, polDesc, polRestriction, polRank, polError, polSaving,
  onSetName, onSetDesc, onSetRestriction, onSetRank, onSubmit, onClose,
}) => (
  <div className="modal-overlay" onClick={onClose}>
    <div className="modal-card" onClick={(e: any) => e.stopPropagation()}>
      <button className="modal-close-btn" type="button" onClick={onClose}>
        <img src="/static/assets/icons/close.svg" alt="close" className="close-icon" />
      </button>
      <h3>{mode === 'add' ? 'Add Policy' : 'Edit Policy'}</h3>
      {polError && <div className="login-error">{polError}</div>}
      <div className="modal-field">
        <label>Name</label>
        <input type="text" value={polName} onChange={(e: any) => onSetName(e.target.value)} />
      </div>
      <div className="modal-field">
        <label>Description</label>
        <input type="text" value={polDesc} onChange={(e: any) => onSetDesc(e.target.value)} />
      </div>
      <div className="modal-field">
        <label>Restriction</label>
        <input type="text" value={polRestriction} onChange={(e: any) => onSetRestriction(e.target.value)} />
      </div>
      <div className="modal-field">
        <label>Rank Requirement</label>
        <select value={polRank} onChange={(e: any) => onSetRank(e.target.value)}>
          <option value="Operator">Operator</option>
          <option value="Administrator">Administrator</option>
          <option value="Executive">Executive</option>
        </select>
      </div>
      <div className="modal-actions">
        <button className="btn-modal-cancel" type="button" onClick={onClose}>Cancel</button>
        <button className="btn-modal-submit" type="button" onClick={onSubmit} disabled={polSaving}>
          {polSaving ? 'Saving...' : (mode === 'add' ? 'Add Policy' : 'Save Changes')}
        </button>
      </div>
    </div>
  </div>
);
