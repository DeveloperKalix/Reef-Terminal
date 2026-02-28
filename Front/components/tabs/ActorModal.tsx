import React from 'react';
import { scoreColor, outcomeCss, metricBarColor, threatLevelCss } from '../../lib/helpers';

interface ActorModalProps {
  actor: any;
  allCases: any[];
  policies: any[];
  actorTrendsData: any;
  actorTrendsLoading: boolean;
  actorAssessment: any;
  actorAssessmentLoading: boolean;
  actorAction: string;
  actorActionSaving: boolean;
  myRank: string;
  rankOrder: Record<string, number>;
  onClose: () => void;
  onSetActorAction: (v: string) => void;
  onApplyActorAction: () => void;
  onRunActorAssessment: (actorId: string) => void;
  onLoadActorTrends: (actorId: string) => void;
}

export const ActorModal: React.FC<ActorModalProps> = ({
  actor, allCases, policies, actorTrendsData, actorTrendsLoading,
  actorAssessment, actorAssessmentLoading,
  actorAction, actorActionSaving,
  myRank, rankOrder,
  onClose, onSetActorAction, onApplyActorAction,
  onRunActorAssessment, onLoadActorTrends,
}) => {
  if (!actor || !actor.id) return null;

  const sc = scoreColor(actor.risk);
  const actorCases = allCases.filter((c: any) => c.actor === actor.handle);
  const confirmedCount = actorCases.filter((c: any) => c.outcome === 'Confirmed' || (c.outcome || '').startsWith('Policy:')).length;
  const escalatedCount = actorCases.filter((c: any) => c.outcome === 'Escalated').length;
  const openCount = actorCases.filter((c: any) => c.outcome === 'Open' || c.outcome === 'Needs Review').length;

  const myLevel = rankOrder[myRank] || 0;
  const applicablePolicies = policies.filter((p: any) => {
    const polLevel = rankOrder[p.rank || 'Operator'] || 0;
    return myLevel >= polLevel;
  });

  const trends = actorTrendsData || {};
  const hasTrends = !!(trends.threat_level || trends.summary);

  React.useEffect(() => {
    if (actor.id && !hasTrends && !actorTrendsLoading) {
      onLoadActorTrends(actor.id);
    }
  }, [actor.id]);

  return (
    <div className="report-overlay" onClick={onClose}>
      <div className="report-card report-card--actor" onClick={(e: any) => e.stopPropagation()}>
        <button className="report-close" type="button" onClick={onClose}>
          <img src="/static/assets/icons/close.svg" alt="close" className="close-icon" />
        </button>

        <div className="report-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <img
              className="case-card__thumb case-card__thumb--avatar"
              src={actor.avatar}
              alt={actor.handle}
              style={{ width: '56px', height: '56px', borderRadius: '50%', objectFit: 'cover' }}
            />
            <div>
              <h2 className="report-header__title" style={{ margin: 0 }}>{actor.handle}</h2>
              <span className="report-header__id">{actor.type}</span>
            </div>
          </div>
          <span className={'case-card__score score-' + sc} style={{ fontSize: '1.5rem' }}>{actor.risk}%</span>
        </div>

        <div className="report-bento">
          <div className="report-bento__card">
            <h4>Actor Profile</h4>
            <div className="report-meta-grid">
              <span className="report-meta__label">Handle</span>
              <span className="report-meta__value">{actor.handle}</span>
              <span className="report-meta__label">Classification</span>
              <span className="report-meta__value">{actor.type}</span>
              <span className="report-meta__label">Risk Score</span>
              <span className="report-meta__value">{actor.risk}%</span>
              <span className="report-meta__label">Total Posts</span>
              <span className="report-meta__value">{actor.posts?.toLocaleString()}</span>
            </div>
          </div>
          <div className="report-bento__card">
            <h4>Case Summary</h4>
            <div className="report-meta-grid">
              <span className="report-meta__label">Total Cases</span>
              <span className="report-meta__value">{actorCases.length}</span>
              <span className="report-meta__label">Confirmed / Policy</span>
              <span className="report-meta__value" style={{ color: confirmedCount > 0 ? '#E05C5C' : undefined }}>{confirmedCount}</span>
              <span className="report-meta__label">Escalated</span>
              <span className="report-meta__value">{escalatedCount}</span>
              <span className="report-meta__label">Open / Review</span>
              <span className="report-meta__value">{openCount}</span>
            </div>
          </div>
        </div>

        {hasTrends && (
          <div className="report-bento" style={{ marginTop: '0.5rem' }}>
            <div className="report-bento__card" style={{ gridColumn: '1 / -1' }}>
              <h4>Threat Assessment</h4>
              <div style={{ display: 'flex', gap: '1.5rem', flexWrap: 'wrap', marginTop: '0.5rem' }}>
                {trends.threat_level && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span className="report-meta__label" style={{ margin: 0 }}>Threat Level</span>
                    <span className={threatLevelCss(trends.threat_level)}>{trends.threat_level}</span>
                  </div>
                )}
                {trends.audience_growth && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <span className="report-meta__label" style={{ margin: 0 }}>Audience Growth</span>
                    <span className="report-meta__value">{trends.audience_growth}</span>
                  </div>
                )}
              </div>
              {trends.summary && (
                <p className="report-meta__value" style={{ marginTop: '0.75rem', lineHeight: '1.5' }}>{trends.summary}</p>
              )}
            </div>
          </div>
        )}

        <div className="report-stats-row">
          {[
            { value: actorCases.reduce((acc: number, c: any) => acc + (c.views || 0), 0).toLocaleString(), label: 'Total Reach' },
            { value: actorCases.reduce((acc: number, c: any) => acc + (c.shares || 0), 0).toLocaleString(), label: 'Total Shares' },
            { value: actorCases.reduce((acc: number, c: any) => acc + (c.comments || 0), 0).toLocaleString(), label: 'Total Comments' },
            { value: actor.posts?.toLocaleString() || '0', label: 'Total Posts' },
          ].map(s => (
            <div key={s.label} className="report-stat">
              <span className="report-stat__value">{s.value}</span>
              <span className="report-stat__label">{s.label}</span>
            </div>
          ))}
        </div>

        {actorCases.length > 0 && (
          <>
            <div className="report-section-title">Associated Cases</div>
            <div className="actor-cases-list">
              {actorCases.slice(0, 8).map((c: any) => (
                <div className="actor-case-row" key={c.id}>
                  <span className="actor-case-row__id">{c.id}</span>
                  <span className="actor-case-row__title">{c.title}</span>
                  <span className={'actor-case-row__score score-' + scoreColor(c.score)}>{c.score}%</span>
                  <span className={outcomeCss(c.outcome)}>{c.outcome}</span>
                </div>
              ))}
              {actorCases.length > 8 && (
                <p className="actor-cases-more">+ {actorCases.length - 8} more cases</p>
              )}
            </div>
          </>
        )}

        <div className="report-action-section">
          <div className="ai-triage-section">
            <div className="ai-triage-header">
              <span className="ai-triage-label">AI Actor Assessment</span>
              <button
                className="ai-triage-btn"
                type="button"
                disabled={actorAssessmentLoading}
                onClick={() => onRunActorAssessment(actor.id)}
              >{actorAssessmentLoading ? 'Analysing...' : 'Run AI Assessment'}</button>
            </div>

            {actorAssessmentLoading && (
              <div className="ai-triage-card ai-triage-card--loading">
                <div className="ai-triage-spinner" />
                <span>Gemini is assessing this actor&apos;s threat profile...</span>
              </div>
            )}

            {!actorAssessmentLoading && actorAssessment && actorAssessment.recommended_action && (
              <div className="ai-triage-card">
                <div className="ai-triage-card__top">
                  <div className="ai-triage-card__action-wrap">
                    <span className="ai-triage-card__rec-label">Recommended:</span>
                    <span className={outcomeCss(actorAssessment.recommended_action)}>{actorAssessment.recommended_action}</span>
                  </div>
                  <span className={'ai-triage-confidence ai-triage-confidence--' + (actorAssessment.confidence >= 70 ? 'high' : (actorAssessment.confidence >= 40 ? 'mid' : 'low'))}>
                    {actorAssessment.confidence}% confidence
                  </span>
                </div>
                <p className="ai-triage-card__rationale">{actorAssessment.rationale}</p>

                {actorAssessment.escalation_path && actorAssessment.escalation_path.length > 0 && (
                  <div className="actor-escalation-path">
                    <span className="actor-escalation-path__title">Recommended Escalation Path</span>
                    <div className="actor-escalation-steps">
                      {actorAssessment.escalation_path.map((step: string, i: number) => (
                        <div className="actor-escalation-step" key={i}>
                          <span className="actor-escalation-step__num">{i + 1}</span>
                          <span className="actor-escalation-step__text">{step}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                <button
                  className="ai-triage-apply-btn"
                  type="button"
                  onClick={() => onSetActorAction(actorAssessment.recommended_action)}
                >Apply Recommendation</button>
              </div>
            )}
          </div>

          <div className="report-section-title">Enforcement Action</div>
          <div className="report-action-row">
            <select
              className="report-action-select"
              value={actorAction}
              onChange={(e: any) => onSetActorAction(e.target.value)}
            >
              <option value="">Select action...</option>
              <optgroup label="Informational">
                <option value="Warning: Content Advisory">{'Warning \u2014 Content Advisory Notice'}</option>
                <option value="Warning: Fact-Check Notice">{'Warning \u2014 Attach Fact-Check Notices'}</option>
                <option value="Warning: Community Guidelines">{'Warning \u2014 Community Guidelines Reminder'}</option>
              </optgroup>
              <optgroup label="Restrictions">
                <option value="Restrict: Reduce Reach">{'Restrict \u2014 Reduce Algorithmic Reach'}</option>
                <option value="Restrict: Disable Monetisation">{'Restrict \u2014 Disable Monetisation'}</option>
                <option value="Restrict: Disable Sharing">{'Restrict \u2014 Disable Sharing on Content'}</option>
              </optgroup>
              <optgroup label="Suspensions">
                <option value="Suspend: 7-Day Temp Ban">{'Suspend \u2014 7-Day Temporary Ban'}</option>
                <option value="Suspend: 30-Day Temp Ban">{'Suspend \u2014 30-Day Temporary Ban'}</option>
                <option value="Suspend: Indefinite">{'Suspend \u2014 Indefinite Suspension'}</option>
              </optgroup>
              <optgroup label="Severe">
                <option value="Permanent Ban: ToS Violation">{'Permanent Ban \u2014 Terms of Service Violation'}</option>
                <option value="Permanent Ban: Coordinated Psy-Op">{'Permanent Ban \u2014 Coordinated Influence Operation'}</option>
              </optgroup>
              {applicablePolicies.map((pol: any) => (
                <option key={pol.id} value={'Policy: ' + pol.name}>
                  {'Apply Policy \u2014 ' + pol.name}
                </option>
              ))}
            </select>
            <button
              className="btn-modal-submit report-action-save"
              type="button"
              disabled={!actorAction || actorActionSaving}
              onClick={onApplyActorAction}
            >{actorActionSaving ? 'Saving...' : 'Apply Action'}</button>
          </div>
        </div>
      </div>
    </div>
  );
};
