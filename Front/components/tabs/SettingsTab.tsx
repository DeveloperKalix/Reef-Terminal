import React from 'react';
import { rankCss } from '../../lib/helpers';

const ALL_PERMISSIONS = [
  'View Dashboard', 'View Cases', 'View Analytics', 'View History',
  'Investigate Cases', 'Apply Case Actions', 'View Personnel',
  'Add Personnel', 'Edit Personnel', 'Delete Personnel',
  'View Policies', 'Add Policies', 'Edit Policies', 'Delete Policies',
  'Manage Roles', 'Export Data', 'System Configuration',
];

const OPERATOR_PERMS = [
  'View Dashboard', 'View Cases', 'View Analytics', 'View History',
  'Investigate Cases', 'Apply Case Actions', 'View Personnel', 'View Policies',
];

const ADMIN_PERMS = [
  'View Dashboard', 'View Cases', 'View Analytics', 'View History',
  'Investigate Cases', 'Apply Case Actions', 'View Personnel',
  'Add Personnel', 'Edit Personnel', 'View Policies',
  'Add Policies', 'Edit Policies', 'Export Data',
];

const ROLE_CONFIGS = [
  { name: 'Operator',      perms: OPERATOR_PERMS,  isExec: false },
  { name: 'Administrator', perms: ADMIN_PERMS,     isExec: false },
  { name: 'Executive',     perms: ALL_PERMISSIONS, isExec: true },
];

export const SettingsTab: React.FC = () => (
  <div className="dashboard-content-card">
    <div className="content-header"><h2>Settings</h2></div>
    <div className="settings-roles-grid">
      {ROLE_CONFIGS.map(rc => (
        <div key={rc.name} className="settings-role-card">
          <h3 className={`settings-role-card__title ${rankCss(rc.name)}`}>{rc.name}</h3>
          {rc.isExec && (
            <div className="settings-exec-blurb">
              <p>The Executive role has unrestricted access to all current and future platform capabilities. This includes full administrative control, policy enforcement, personnel management, and system configuration.</p>
            </div>
          )}
          <div className="settings-perms-list">
            {ALL_PERMISSIONS.map(perm => {
              const has = rc.perms.includes(perm);
              return (
                <div key={perm} className={`settings-perm-row ${has ? 'settings-perm-row--granted' : 'settings-perm-row--denied'}`}>
                  <span className="settings-perm-row__icon">
                    {has
                      ? <img src="/static/assets/icons/green_check.svg" alt="Granted" className="settings-perm-icon" />
                      : <img src="/static/assets/icons/red_close.svg" alt="Denied" className="settings-perm-icon" />
                    }
                  </span>
                  <span className="settings-perm-row__label">{perm}</span>
                </div>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  </div>
);
