import React from 'react';
import { rankCss, sortIndicator } from '../../lib/helpers';
import { userSortVal, sortedList } from '../../lib/sorting';

interface PersonnelTabProps {
  users: any[];
  usersLoaded: boolean;
  isExecutive: boolean;
  sortKey: string;
  sortAsc: boolean;
  openMenu: string;
  onToggleSort: (key: string) => void;
  onSetOpenMenu: (v: string) => void;
  onOpenAddModal: () => void;
  onOpenEditModal: (u: any) => void;
  onDeleteUser: (id: string) => void;
}

export const PersonnelTab: React.FC<PersonnelTabProps> = ({
  users, usersLoaded, isExecutive, sortKey, sortAsc, openMenu,
  onToggleSort, onSetOpenMenu, onOpenAddModal, onOpenEditModal, onDeleteUser,
}) => {
  const sorted = sortedList(users, sortKey, sortAsc, userSortVal);
  const ind = (key: string) => sortIndicator(sortKey, key, sortAsc);

  return (
    <div className="dashboard-content-card">
      <div className="content-header">
        <h2>Personnel</h2>
        {isExecutive && (
          <button className="btn-add" onClick={onOpenAddModal} type="button">+ Add User</button>
        )}
      </div>

      {!usersLoaded ? (
        <p className="empty-state">Loading personnel...</p>
      ) : users.length === 0 ? (
        <p className="empty-state">No personnel found. Add your first team member.</p>
      ) : (
        <table className="data-table">
          <thead>
            <tr>
              <th className="sortable-th" onClick={() => onToggleSort('name')}>
                <img src="/static/assets/icons/star.svg" alt="" className="th-icon" />
                Name<span className="sort-arrow">{ind('name')}</span>
              </th>
              <th className="sortable-th" onClick={() => onToggleSort('email')}>
                <img src="/static/assets/icons/mail.svg" alt="" className="th-icon" />
                Email<span className="sort-arrow">{ind('email')}</span>
              </th>
              <th className="sortable-th" onClick={() => onToggleSort('rank')}>
                <img src="/static/assets/icons/tag.svg" alt="" className="th-icon" />
                Rank<span className="sort-arrow">{ind('rank')}</span>
              </th>
              <th className="col-actions"></th>
            </tr>
          </thead>
          <tbody>
            {sorted.map((u: any) => (
              <tr key={u.id}>
                <td>{(u.first_name || '') + ' ' + (u.last_name || '')}</td>
                <td>{u.email || ''}</td>
                <td><span className={rankCss(u.rank || 'Operator')}>{u.rank || 'Operator'}</span></td>
                <td className="col-actions">
                  <div className="dot-menu-wrap">
                    <button
                      className="dot-menu-btn"
                      type="button"
                      onClick={() => onSetOpenMenu(openMenu === u.id ? '' : u.id)}
                    >
                      <img src="/static/assets/menu.svg" alt="menu" style={{ width: '4px', height: '18px', opacity: '0.6' }} />
                    </button>
                    {openMenu === u.id && (
                      <div className="dot-menu-dropdown">
                        <button onClick={() => onOpenEditModal(u)} disabled={!isExecutive}>Edit</button>
                        <button className="danger" onClick={() => onDeleteUser(u.id)} disabled={!isExecutive}>Delete</button>
                      </div>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      {!isExecutive && <p className="perm-notice">Only Executive-rank users can add, edit, or delete personnel.</p>}
    </div>
  );
};

interface UserModalProps {
  mode: 'add' | 'edit';
  formFirst: string;
  formLast: string;
  formEmail: string;
  formUsername: string;
  formRank: string;
  formError: string;
  formSaving: boolean;
  onSetFirst: (v: string) => void;
  onSetLast: (v: string) => void;
  onSetEmail: (v: string) => void;
  onSetUsername: (v: string) => void;
  onSetRank: (v: string) => void;
  onSubmit: () => void;
  onClose: () => void;
}

export const UserModal: React.FC<UserModalProps> = ({
  mode, formFirst, formLast, formEmail, formUsername, formRank,
  formError, formSaving,
  onSetFirst, onSetLast, onSetEmail, onSetUsername, onSetRank,
  onSubmit, onClose,
}) => (
  <div className="modal-overlay" onClick={onClose}>
    <div className="modal-card" onClick={(e: any) => e.stopPropagation()}>
      <button className="modal-close-btn" type="button" onClick={onClose}>
        <img src="/static/assets/icons/close.svg" alt="close" className="close-icon" />
      </button>
      <h3>{mode === 'add' ? 'Add Team Member' : 'Edit Team Member'}</h3>
      {formError && <div className="login-error">{formError}</div>}
      <div className="modal-field">
        <label>First Name</label>
        <input type="text" value={formFirst} onChange={(e: any) => onSetFirst(e.target.value)} />
      </div>
      <div className="modal-field">
        <label>Last Name</label>
        <input type="text" value={formLast} onChange={(e: any) => onSetLast(e.target.value)} />
      </div>
      <div className="modal-field">
        <label>Email</label>
        <input type="email" value={formEmail} onChange={(e: any) => onSetEmail(e.target.value)} />
      </div>
      <div className="modal-field">
        <label>Username</label>
        <input type="text" value={formUsername} onChange={(e: any) => onSetUsername(e.target.value)} />
      </div>
      <div className="modal-field">
        <label>Rank</label>
        <select value={formRank} onChange={(e: any) => onSetRank(e.target.value)}>
          <option value="Operator">Operator</option>
          <option value="Administrator">Administrator</option>
          <option value="Executive">Executive</option>
        </select>
      </div>
      <div className="modal-actions">
        <button className="btn-modal-cancel" type="button" onClick={onClose}>Cancel</button>
        <button className="btn-modal-submit" type="button" onClick={onSubmit} disabled={formSaving}>
          {formSaving ? 'Saving...' : (mode === 'add' ? 'Add Member' : 'Save Changes')}
        </button>
      </div>
    </div>
  </div>
);
