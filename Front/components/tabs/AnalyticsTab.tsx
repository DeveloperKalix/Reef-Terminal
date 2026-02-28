import React from 'react';
import { FullScreenChart, ThemePieChart } from '../Charts';
import { ActorTrendsChart } from '../ActorTrendsChart';
import {
  outcomeCss, metricBarColor, threatLevelCss, insightSeverityCss,
} from '../../lib/helpers';

interface AnalyticsTabProps {
  analyticsPage: number;
  analyticsTimescale: string;
  analyticsPill: string;
  pieHoverLabel: string;
  actorsCollapsed: boolean;
  actorProfileOpen: any;
  actorProfilePill: string;
  actorTrendsData: any;
  actorTrendsLoading: boolean;
  actorBrief: any;
  actorBriefLoading: boolean;
  fakeActors: any[];
  allCases: any[];
  themeSlices: any[];
  analyticsVizList: any[];
  onSetAnalyticsPage: (v: number) => void;
  onSetAnalyticsTimescale: (v: string) => void;
  onSetAnalyticsPill: (v: string) => void;
  onSetPieHoverLabel: (v: string) => void;
  onSetActorsCollapsed: (v: boolean) => void;
  onSetActorProfileOpen: (v: any) => void;
  onSetActorProfilePill: (v: string) => void;
  onLoadActorTrends: (id: string) => void;
  onRunActorBrief: (id: string) => void;
}

export const AnalyticsTab: React.FC<AnalyticsTabProps> = ({
  analyticsPage, analyticsTimescale, analyticsPill, pieHoverLabel,
  actorsCollapsed, actorProfileOpen, actorProfilePill,
  actorTrendsData, actorTrendsLoading, actorBrief, actorBriefLoading,
  fakeActors, allCases, themeSlices, analyticsVizList,
  onSetAnalyticsPage, onSetAnalyticsTimescale, onSetAnalyticsPill,
  onSetPieHoverLabel, onSetActorsCollapsed, onSetActorProfileOpen,
  onSetActorProfilePill, onLoadActorTrends, onRunActorBrief,
}) => {
  const aTotal = analyticsVizList.length;
  const current = analyticsVizList[analyticsPage] || analyticsVizList[0];

  let hoveredTheme: any = null;
  if (pieHoverLabel) {
    hoveredTheme = themeSlices.find((ts: any) => ts.name === pieHoverLabel) || null;
  }

  const getActorCases = () => {
    if (actorProfileOpen && actorProfileOpen.handle) {
      return allCases.filter((c: any) => c.actor === actorProfileOpen.handle);
    }
    return [];
  };

  const renderTrustMetrics = () => {
    const risk = actorProfileOpen.risk;
    const metrics = [
      { label: 'Factuality',    val: 10 + (risk * 37) % 80 },
      { label: 'Rhetoric',      val: 5  + (risk * 53) % 70 },
      { label: 'Logic',         val: 10 + (risk * 71) % 85 },
      { label: 'Argumentation', val: 8  + (risk * 43) % 75 },
      { label: 'Overall',       val: risk },
    ];
    return (
      <div className="actor-profile-metrics">
        {metrics.map((m: any) => (
          <div key={m.label} className="actor-metric-row">
            <span className="actor-metric-row__label">{m.label}</span>
            <div className="actor-metric-row__track">
              <div className="actor-metric-row__fill" style={{ width: m.val + '%', background: metricBarColor(m.val) }} />
            </div>
            <span className="actor-metric-row__score">{m.val}%</span>
          </div>
        ))}
      </div>
    );
  };

  const renderHistoryList = () => {
    const cases = getActorCases();
    if (cases.length === 0) return <p className="actor-profile-empty">No case history.</p>;
    return (
      <div className="actor-profile-history">
        <div className="actor-profile-history__list">
          {cases.map((c: any) => (
            <div key={c.id} className="actor-history-item">
              <span className="actor-history-item__id">{c.id}</span>
              <span className="actor-history-item__title">{c.title}</span>
              <span className={outcomeCss(c.outcome)}>{c.outcome}</span>
            </div>
          ))}
        </div>
      </div>
    );
  };

  return (
    <div className={'analytics-layout' + (actorsCollapsed ? ' analytics-layout--expanded' : '')}>
      <div className="analytics-main">
        <div className="analytics-main__header">
          <h2 className="analytics-main__title">Misinformation Dashboard</h2>
          <div className="analytics-pill-toggle">
            {['themes', 'trends', 'impact'].map(pill => (
              <button
                key={pill}
                className={'analytics-pill-btn' + (analyticsPill === pill ? ' analytics-pill-btn--active' : '')}
                type="button"
                onClick={() => onSetAnalyticsPill(pill)}
              >{pill.charAt(0).toUpperCase() + pill.slice(1)}</button>
            ))}
          </div>
        </div>

        {analyticsPill === 'themes' && (
          <div className="analytics-themes-wrap">
            <div className="analytics-pie-container">
              <ThemePieChart
                data={themeSlices}
                activeLabel={pieHoverLabel}
                onHoverSlice={(label: string) => onSetPieHoverLabel(label)}
              />
              {hoveredTheme && hoveredTheme.name && (
                <div className="pie-tooltip-modal">
                  <div className="pie-tooltip-modal__header">
                    <span className="pie-tooltip-modal__dot" style={{ background: hoveredTheme.color }} />
                    <span className="pie-tooltip-modal__name">{hoveredTheme.name}</span>
                    <span className={'pie-tooltip-modal__trend' + (hoveredTheme.trendUp ? ' pie-tooltip-modal__trend--up' : ' pie-tooltip-modal__trend--down')}>
                      {hoveredTheme.trend}
                    </span>
                  </div>
                  <p className="pie-tooltip-modal__text">{hoveredTheme.insight}</p>
                  <div className="pie-tooltip-modal__stat">
                    <span>{hoveredTheme.value}% of total cases</span>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {analyticsPill === 'trends' && (
          <div className="analytics-trends-wrap">
            <div className="analytics-trends-controls">
              <select
                className="viz-timescale-select"
                value={analyticsTimescale}
                onChange={(e: any) => { onSetAnalyticsTimescale(e.target.value); onSetAnalyticsPage(0); }}
              >
                <option value="monthly">Monthly</option>
                <option value="weekly">Weekly</option>
                <option value="daily">Daily</option>
              </select>
            </div>
            <div className="analytics-full__carousel">
              <button
                className="analytics-full__arrow analytics-full__arrow--left"
                type="button"
                disabled={analyticsPage === 0}
                onClick={() => onSetAnalyticsPage(analyticsPage - 1)}
              >
                <img src="/static/assets/icons/chevron.svg" alt="prev" style={{ width: '14px', height: '10px', transform: 'rotate(90deg)' }} />
              </button>
              <div className="analytics-full__chart" key={(current?.title || '') + analyticsTimescale}>
                <FullScreenChart
                  data={current?.data}
                  color={current?.color}
                  type={current?.type}
                  title={current?.title}
                  xLabel={current?.xLabel}
                  yLabel={current?.yLabel}
                />
              </div>
              <button
                className="analytics-full__arrow analytics-full__arrow--right"
                type="button"
                disabled={analyticsPage >= aTotal - 1}
                onClick={() => onSetAnalyticsPage(analyticsPage + 1)}
              >
                <img src="/static/assets/icons/chevron.svg" alt="next" style={{ width: '14px', height: '10px', transform: 'rotate(-90deg)' }} />
              </button>
            </div>
            <div className="analytics-full__dots">
              {analyticsVizList.map((v: any, i: number) => (
                <button
                  key={v.title}
                  className={'analytics-full__dot' + (i === analyticsPage ? ' analytics-full__dot--active' : '')}
                  type="button"
                  onClick={() => onSetAnalyticsPage(i)}
                />
              ))}
            </div>
          </div>
        )}

        {analyticsPill === 'impact' && (
          <div className="analytics-impact-wrap">
            <div className="analytics-impact-grid">
              {[
                { value: '2.4M', label: 'Total Reach' },
                { value: '487K', label: 'Engagements' },
                { value: '55',   label: 'Active Cases' },
                { value: '78%',  label: 'Resolution Rate' },
              ].map(card => (
                <div key={card.label} className="analytics-impact-card">
                  <span className="analytics-impact-card__value">{card.value}</span>
                  <span className="analytics-impact-card__label">{card.label}</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      <div className={'analytics-actors-sidebar' + (actorsCollapsed ? ' analytics-actors-sidebar--collapsed' : '')}>
        <button
          className="analytics-actors-toggle"
          type="button"
          onClick={() => onSetActorsCollapsed(!actorsCollapsed)}
        >
          <img
            src="/static/assets/icons/chevron.svg" alt="toggle"
            className={'analytics-actors-toggle__icon' + (actorsCollapsed ? ' analytics-actors-toggle__icon--collapsed' : '')}
          />
        </button>
        {!actorsCollapsed && (
          <div className="analytics-actors-content">
            <h3 className="analytics-actors-title">Negative Actors</h3>
            <div className="analytics-actors-list">
              {fakeActors.map((a: any) => {
                const riskCls = a.risk >= 70 ? 'actor-risk--high' : (a.risk >= 40 ? 'actor-risk--mid' : 'actor-risk--low');
                return (
                  <button
                    key={a.id}
                    className="analytics-actor-card"
                    type="button"
                    onClick={() => { onSetActorProfileOpen(a); onSetActorProfilePill('trust'); }}
                  >
                    <img src={a.avatar} alt="" className="analytics-actor-card__avatar" />
                    <span className="analytics-actor-card__handle">{a.handle}</span>
                    <span className={'analytics-actor-card__risk ' + riskCls}>
                      {a.risk >= 70 ? 'HIGH' : (a.risk >= 40 ? 'MID' : 'LOW')}
                    </span>
                    <img src="/static/assets/icons/chevron.svg" alt="" className="analytics-actor-card__chevron" />
                  </button>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {actorProfileOpen && actorProfileOpen.id && (
        <div className="actor-profile-overlay" onClick={() => onSetActorProfileOpen({})}>
          <div className="actor-profile-card" onClick={(e: any) => e.stopPropagation()}>
            <button className="actor-profile-close" type="button" onClick={() => onSetActorProfileOpen({})}>
              <img src="/static/assets/icons/close.svg" alt="close" className="close-icon" />
            </button>
            <h2 className="actor-profile__heading">Negative Actor</h2>
            <img src={actorProfileOpen.avatar} alt="" className="actor-profile__avatar" />
            <h3 className="actor-profile__handle">{actorProfileOpen.handle}</h3>
            <p className="actor-profile__type">{actorProfileOpen.type}</p>

            <div className="actor-profile-pills">
              <button className={'actor-profile-pill' + (actorProfilePill === 'trust' ? ' actor-profile-pill--active' : '')} type="button" onClick={() => onSetActorProfilePill('trust')}>Trust Factor</button>
              <button className={'actor-profile-pill' + (actorProfilePill === 'history' ? ' actor-profile-pill--active' : '')} type="button" onClick={() => onSetActorProfilePill('history')}>History</button>
              <button className={'actor-profile-pill' + (actorProfilePill === 'trends' ? ' actor-profile-pill--active' : '')} type="button" onClick={() => { onSetActorProfilePill('trends'); onLoadActorTrends(actorProfileOpen.id); }}>Trends</button>
              <button className={'actor-profile-pill' + (actorProfilePill === 'reports' ? ' actor-profile-pill--active' : '')} type="button" onClick={() => onSetActorProfilePill('reports')}>Reports</button>
            </div>

            {actorProfilePill === 'trust' && renderTrustMetrics()}
            {actorProfilePill === 'history' && renderHistoryList()}

            {actorProfilePill === 'trends' && (
              <div className="actor-profile-trends">
                {actorTrendsLoading && <p className="actor-profile-empty">Loading trends...</p>}
                {!actorTrendsLoading && actorTrendsData && actorTrendsData.threat_level && (
                  <div className="actor-trends-content">
                    <div className="actor-trends-header">
                      <span className={threatLevelCss(actorTrendsData.threat_level)}>{actorTrendsData.threat_level}</span>
                      <span className="actor-trends-growth">{actorTrendsData.audience_growth}</span>
                    </div>
                    <p className="actor-trends-summary">{actorTrendsData.summary}</p>
                    <div className="actor-trends-chart-wrap">
                      <h4 className="actor-trends-section-title">Activity &amp; Reach</h4>
                      <ActorTrendsChart data={actorTrendsData.trend_data} height={180} />
                      <div className="actor-trends-legend">
                        <span className="actor-trends-legend__item"><span className="actor-trends-legend__dot" style={{ background: '#7C5CBF' }} />Posts</span>
                        <span className="actor-trends-legend__item"><span className="actor-trends-legend__dot" style={{ background: '#E05C5C' }} />Reach</span>
                      </div>
                    </div>
                    <h4 className="actor-trends-section-title">Intelligence Insights</h4>
                    <div className="actor-trends-insights">
                      {(actorTrendsData.insights || []).map((ins: any, idx: number) => (
                        <div key={idx} className="actor-insight-card">
                          <div className="actor-insight-card__header">
                            <span className={insightSeverityCss(ins.severity)}>{ins.severity}</span>
                            <span className="actor-insight-card__title">{ins.title}</span>
                          </div>
                          <p className="actor-insight-card__detail">{ins.detail}</p>
                        </div>
                      ))}
                    </div>

                    <div className="ai-brief-section">
                      <div className="ai-brief-header">
                        <h4 className="actor-trends-section-title">AI Intelligence Brief</h4>
                        <button
                          className="ai-triage-btn"
                          type="button"
                          disabled={actorBriefLoading}
                          onClick={() => onRunActorBrief(actorProfileOpen.id)}
                        >{actorBriefLoading ? 'Generating...' : 'Generate Brief'}</button>
                      </div>

                      {actorBriefLoading && (
                        <div className="ai-triage-card ai-triage-card--loading">
                          <div className="ai-triage-spinner" />
                          <span>Gemini is generating an intelligence brief...</span>
                        </div>
                      )}

                      {!actorBriefLoading && actorBrief && actorBrief.brief && (
                        <div className="ai-brief-card">
                          <p className="ai-brief-card__text">{actorBrief.brief}</p>
                          {actorBrief.key_findings && actorBrief.key_findings.length > 0 && (
                            <div className="ai-brief-findings">
                              <span className="ai-brief-findings__title">Key Findings</span>
                              {actorBrief.key_findings.map((f: string, fi: number) => (
                                <div key={fi} className="ai-brief-finding">
                                  <span className="ai-brief-finding__bullet">{fi + 1}</span>
                                  <span className="ai-brief-finding__text">{f}</span>
                                </div>
                              ))}
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                )}
                {!actorTrendsLoading && (!actorTrendsData || !actorTrendsData.threat_level) && (
                  <p className="actor-profile-empty">No trend data available.</p>
                )}
              </div>
            )}

            {actorProfilePill === 'reports' && (
              <div className="actor-profile-reports">
                <p className="actor-profile-empty">Detailed reports coming soon.</p>
              </div>
            )}
          </div>

          <div className="actor-content-sidebar" onClick={(e: any) => e.stopPropagation()}>
            <h3 className="actor-content-sidebar__title">Unsubstantiated Content</h3>
            <div className="actor-content-sidebar__list">
              {getActorCases().map((c: any) => (
                <div key={c.id} className="actor-content-item">
                  <img src={c.thumb} alt="" className="actor-content-item__thumb" />
                  <div className="actor-content-item__info">
                    <span className="actor-content-item__title">{c.title}</span>
                  </div>
                  <button className="case-card__menu-btn" type="button">
                    <img src="/static/assets/menu.svg" alt="menu" />
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
