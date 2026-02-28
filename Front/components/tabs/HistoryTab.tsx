import React from 'react';
import { outcomeCss, metricBarColor } from '../../lib/helpers';

interface HistoryTabProps {
  historyRecords: any[];
  openHistoryMenu: string;
  isExecutive: boolean;
  onSetOpenHistoryMenu: (v: string) => void;
  onSelectCase: (c: any) => void;
}

export const HistoryTab: React.FC<HistoryTabProps> = ({
  historyRecords, openHistoryMenu, isExecutive,
  onSetOpenHistoryMenu, onSelectCase,
}) => (
  <div className="dashboard-content-card">
    <div className="content-header"><h2>Case History</h2></div>
    <div className="history-table-wrap">
      <table className="data-table history-table">
        <thead>
          <tr>
            <th>Case ID</th>
            <th>Media Title</th>
            <th>Actor</th>
            <th>Personnel</th>
            <th>Outcome</th>
            <th className="col-actions"></th>
          </tr>
        </thead>
        <tbody>
          {historyRecords.map((rec: any) => (
            <tr key={rec.id} className="history-row" onClick={() => onSelectCase(rec)}>
              <td className="history-cell--id">{rec.id}</td>
              <td className="history-cell--title">{rec.title}</td>
              <td className="history-cell--actor">{rec.actor}</td>
              <td className="history-cell--personnel">
                <div className="personnel-avatars">
                  {(rec.personnel || []).map((p: any, pi: number) => (
                    <span className="personnel-badge" key={p.initials + pi} title={p.initials}>
                      {p.initials}
                    </span>
                  ))}
                </div>
              </td>
              <td><span className={outcomeCss(rec.outcome)}>{rec.outcome}</span></td>
              <td className="col-actions" onClick={(e: any) => e.stopPropagation()}>
                <div className="dot-menu-wrap">
                  <button
                    className="dot-menu-btn"
                    type="button"
                    onClick={() => onSetOpenHistoryMenu(openHistoryMenu === rec.id ? '' : rec.id)}
                  >
                    <img src="/static/assets/menu.svg" alt="menu" style={{ width: '4px', height: '18px', opacity: '0.6' }} />
                  </button>
                  {openHistoryMenu === rec.id && (
                    <div className="dot-menu-dropdown">
                      <button onClick={() => { onSelectCase(rec); onSetOpenHistoryMenu(''); }}>Examine</button>
                      <button disabled={!isExecutive} onClick={() => onSetOpenHistoryMenu('')}>Re-evaluate</button>
                    </div>
                  )}
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  </div>
);

interface ReportModalProps {
  record: any;
  fakeActors: any[];
  policies: any[];
  reportOpenMetrics: string[];
  reportAction: string;
  reportSaving: boolean;
  triageLoading: boolean;
  triageResult: any;
  myRank: string;
  rankOrder: Record<string, number>;
  onClose: () => void;
  onToggleMetric: (name: string) => void;
  onSetReportAction: (v: string) => void;
  onApplyAction: () => void;
  onRunTriage: (caseId: string) => void;
}

export const ReportModal: React.FC<ReportModalProps> = ({
  record, fakeActors, policies, reportOpenMetrics, reportAction, reportSaving,
  triageLoading, triageResult, myRank, rankOrder,
  onClose, onToggleMetric, onSetReportAction, onApplyAction, onRunTriage,
}) => {
  if (!record || !record.id) return null;

  const m = record.metrics;
  const md = record.metric_details;
  const metricNames = ['factuality', 'rhetoric', 'logic', 'argumentation', 'overall'];
  const metricLabels: Record<string, string> = {
    factuality: 'Factuality', rhetoric: 'Rhetoric', logic: 'Logic',
    argumentation: 'Argumentation', overall: 'Overall',
  };

  const actorObj = fakeActors.find((a: any) => a.handle === record.actor);

  const myLevel = rankOrder[myRank] || 0;
  const applicablePolicies = policies.filter((p: any) => {
    const polLevel = rankOrder[p.rank || 'Operator'] || 0;
    return myLevel >= polLevel;
  });

  const needsAction = record.outcome === 'Needs Review' || record.outcome === 'Open' || record.outcome === 'Under Review';

  return (
    <div className="report-overlay" onClick={onClose}>
      <div className="report-card" onClick={(e: any) => e.stopPropagation()}>
        <button className="report-close" type="button" onClick={onClose}>
          <img src="/static/assets/icons/close.svg" alt="close" className="close-icon" />
        </button>

        <div className="report-header">
          <span className="report-header__id">{record.id}</span>
          <h2 className="report-header__title">{record.title}</h2>
          <span className={outcomeCss(record.outcome)}>{record.outcome}</span>
        </div>

        <div className="report-bento">
          <div className="report-bento__card">
            <h4>Media Metadata</h4>
            <div className="report-meta-grid">
              <span className="report-meta__label">Type</span>
              <span className="report-meta__value">{record.media_type}</span>
              <span className="report-meta__label">Length</span>
              <span className="report-meta__value">{record.length}</span>
              <span className="report-meta__label">URI</span>
              <a className="report-meta__value report-meta__link" href={record.uri} target="_blank" rel="noreferrer">{record.uri}</a>
              <span className="report-meta__label">Date</span>
              <span className="report-meta__value">{record.date}</span>
            </div>
          </div>
          <div className="report-bento__card">
            <h4>Creator Profile</h4>
            <div className="report-meta-grid">
              <span className="report-meta__label">Handle</span>
              <span className="report-meta__value">{record.actor}</span>
              <span className="report-meta__label">Category</span>
              <span className="report-meta__value">{actorObj ? actorObj.type : 'Unknown'}</span>
              <span className="report-meta__label">Total Posts</span>
              <span className="report-meta__value">{actorObj ? String(actorObj.posts) : 'N/A'}</span>
              <span className="report-meta__label">Risk Score</span>
              <span className="report-meta__value">{actorObj ? actorObj.risk + '%' : 'N/A'}</span>
            </div>
          </div>
        </div>

        <div className="report-stats-row">
          {[
            { value: record.ratings,  label: 'Ratings' },
            { value: record.comments, label: 'Comments' },
            { value: record.shares,   label: 'Shares' },
            { value: record.views,    label: 'Views' },
          ].map(s => (
            <div key={s.label} className="report-stat">
              <span className="report-stat__value">{String(s.value)}</span>
              <span className="report-stat__label">{s.label}</span>
            </div>
          ))}
        </div>

        <div className="report-section-title">Analysis Metrics</div>

        <div className="report-metrics">
          {metricNames.map((mn: string) => {
            const score = m[mn];
            const isOpen = reportOpenMetrics.indexOf(mn) >= 0;
            const barColor = metricBarColor(score);
            const detailData = md[mn];
            return (
              <div className={'report-metric' + (isOpen ? ' report-metric--open' : '')} key={mn}>
                <button className="report-metric__row" type="button" onClick={() => onToggleMetric(mn)}>
                  <span className="report-metric__label">{metricLabels[mn]}</span>
                  <div className="report-metric__bar-track">
                    <div className="report-metric__bar-fill" style={{ width: score + '%', background: barColor }} />
                  </div>
                  <span className="report-metric__score">{score}%</span>
                  <img
                    src="/static/assets/icons/chevron.svg" alt="toggle"
                    className={'report-metric__chevron' + (isOpen ? ' report-metric__chevron--open' : '')}
                  />
                </button>
                {isOpen && (
                  <div className="report-metric__detail">
                    <p className="report-metric__analysis">{detailData.detail}</p>
                    <div className="report-metric__footnotes">
                      <span className="report-metric__fn-title">Sources</span>
                      {(detailData.sources || []).map((src: string, si: number) => (
                        <span className="report-metric__fn" key={si}>[{si + 1}] {src}</span>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>

        <div className="report-personnel-section">
          <span className="report-section-title">Assigned Personnel</span>
          <div className="personnel-avatars personnel-avatars--lg">
            {(record.personnel || []).map((p: any, pi: number) => (
              <span className="personnel-badge personnel-badge--lg" key={p.initials + pi} title={p.initials}>
                {p.initials}
              </span>
            ))}
          </div>
        </div>

        {needsAction && (
          <div className="report-action-section">
            <div className="ai-triage-section">
              <div className="ai-triage-header">
                <span className="ai-triage-label">AI Case Triage</span>
                <button
                  className="ai-triage-btn"
                  type="button"
                  disabled={triageLoading}
                  onClick={() => onRunTriage(record.id)}
                >{triageLoading ? 'Analysing...' : 'Run AI Triage'}</button>
              </div>

              {triageLoading && (
                <div className="ai-triage-card ai-triage-card--loading">
                  <div className="ai-triage-spinner" />
                  <span>Gemini is analysing this case...</span>
                </div>
              )}

              {!triageLoading && triageResult && triageResult.action && (
                <div className="ai-triage-card">
                  <div className="ai-triage-card__top">
                    <div className="ai-triage-card__action-wrap">
                      <span className="ai-triage-card__rec-label">Recommended:</span>
                      <span className={outcomeCss(triageResult.action)}>{triageResult.action}</span>
                    </div>
                    <span className={'ai-triage-confidence ai-triage-confidence--' + (triageResult.confidence >= 70 ? 'high' : (triageResult.confidence >= 40 ? 'mid' : 'low'))}>
                      {triageResult.confidence}% confidence
                    </span>
                  </div>
                  <p className="ai-triage-card__rationale">{triageResult.rationale}</p>
                  <button
                    className="ai-triage-apply-btn"
                    type="button"
                    onClick={() => onSetReportAction(triageResult.action)}
                  >Apply Recommendation</button>
                </div>
              )}
            </div>

            <div className="report-section-title">Investigation Action</div>
            <div className="report-action-row">
              <select
                className="report-action-select"
                value={reportAction}
                onChange={(e: any) => onSetReportAction(e.target.value)}
              >
                <option value="">Select action...</option>
                <option value="Confirmed">Confirm - Misinformation Verified</option>
                <option value="Escalated">Escalate - Requires Senior Review</option>
                <option value="Dismissed">Dismiss - No Policy Violation</option>
                <option value="Under Review">Keep Under Review</option>
                {applicablePolicies.map((pol: any) => (
                  <option key={pol.id} value={'Policy: ' + pol.name}>
                    {'Apply Policy \u2014 ' + pol.name}
                  </option>
                ))}
              </select>
              <button
                className="btn-modal-submit report-action-save"
                type="button"
                disabled={!reportAction || reportSaving}
                onClick={onApplyAction}
              >{reportSaving ? 'Saving...' : 'Save Decision'}</button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
