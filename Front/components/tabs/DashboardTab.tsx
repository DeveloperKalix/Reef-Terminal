import React from 'react';
import { MiniChart, FullScreenChart } from '../Charts';
import { scoreColor, outcomeCss } from '../../lib/helpers';

interface DashboardTabProps {
  dashPill: string;
  dashSearch: string;
  dashPage: number;
  vizPage: number;
  vizFullscreen: number;
  vizTimescale: string;
  openCardMenu: string;
  fakeCases: any[];
  fakeActors: any[];
  vizList: any[];
  onSetDashPill: (v: string) => void;
  onSetDashSearch: (v: string) => void;
  onSetDashPage: (v: number) => void;
  onSetVizPage: (v: number) => void;
  onSetVizFullscreen: (v: number) => void;
  onSetVizTimescale: (v: string) => void;
  onSetOpenCardMenu: (v: string) => void;
  onInvestigateCase: (c: any) => void;
  onInvestigateActor: (a: any) => void;
}

const PAGE_SIZE = 5;

export const DashboardTab: React.FC<DashboardTabProps> = ({
  dashPill, dashSearch, dashPage, vizPage, vizFullscreen, vizTimescale,
  openCardMenu, fakeCases, fakeActors, vizList,
  onSetDashPill, onSetDashSearch, onSetDashPage, onSetVizPage,
  onSetVizFullscreen, onSetVizTimescale, onSetOpenCardMenu, onInvestigateCase,
  onInvestigateActor,
}) => {
  const items = dashPill === 'cases' ? fakeCases : fakeActors;
  let filtered = items;
  if (dashSearch.trim()) {
    const q = dashSearch.trim().toLowerCase();
    if (dashPill === 'cases') {
      filtered = fakeCases.filter((c: any) => c.title.toLowerCase().indexOf(q) >= 0);
    } else {
      filtered = fakeActors.filter((a: any) => a.handle.toLowerCase().indexOf(q) >= 0);
    }
  }
  const totalPages = Math.ceil(filtered.length / PAGE_SIZE);
  const safePage = dashPage >= totalPages ? 0 : dashPage;
  const pageStart = safePage * PAGE_SIZE;
  const paged = filtered.slice(pageStart, pageStart + PAGE_SIZE);

  const vizStart = vizPage * 2;
  const visibleViz = vizList.slice(vizStart, vizStart + 2);
  const hasMoreViz = (vizStart + 2) < vizList.length;

  return (
    <div className="dashboard-content-card" style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-5)', padding: 'var(--space-6)' }}>
      <div className="dash-header">
        <h2>Trust &amp; Safety Dashboard</h2>
        <div className="dash-controls">
          <div className="dash-search">
            <img src="/static/assets/icons/search.svg" alt="" className="dash-search__icon" />
            <input
              type="text"
              placeholder="Search"
              value={dashSearch}
              onChange={(e: any) => { onSetDashSearch(e.target.value); onSetDashPage(0); }}
            />
          </div>
        </div>
      </div>

      <div className={vizFullscreen >= 0 ? 'dash-grid dash-grid--fullscreen' : 'dash-grid'}>
        <div className="cases-list">
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <div className="pill-toggle">
              <button
                className={'pill-toggle__btn' + (dashPill === 'cases' ? ' pill-toggle__btn--active' : '')}
                onClick={() => { onSetDashPill('cases'); onSetDashPage(0); }}
                type="button"
              >Cases</button>
              <button
                className={'pill-toggle__btn' + (dashPill === 'actors' ? ' pill-toggle__btn--active' : '')}
                onClick={() => { onSetDashPill('actors'); onSetDashPage(0); }}
                type="button"
              >Bad Actors</button>
            </div>
          </div>

          {dashPill === 'cases' && paged.map((c: any) => {
            const sc = scoreColor(c.score);
            return (
              <div className="case-card" key={c.id}>
                <img className="case-card__thumb" src={c.thumb} alt={c.title} />
                <div className="case-card__info">
                  <p className="case-card__title">{c.title}</p>
                  <p className="case-card__meta">
                    {c.media_type} | {c.analyses} analyses
                    <span className={outcomeCss(c.outcome)} style={{ marginLeft: 'var(--space-2)' }}>{c.outcome}</span>
                  </p>
                  <div className="case-card__bar">
                    <div className={'case-card__bar-fill bar-' + sc} style={{ width: c.score + '%' }} />
                  </div>
                </div>
                <span className={'case-card__score score-' + sc}>{c.score}%</span>
                <div className="dot-menu-wrap">
                  <button
                    className="case-card__menu-btn"
                    type="button"
                    onClick={() => onSetOpenCardMenu(openCardMenu === c.id ? '' : c.id)}
                  >
                    <img src="/static/assets/menu.svg" alt="menu" />
                  </button>
                  {openCardMenu === c.id && (
                    <div className="dot-menu-dropdown">
                      <button onClick={() => { onInvestigateCase(c); onSetOpenCardMenu(''); }}>Investigate</button>
                      <button onClick={() => onSetOpenCardMenu('')}>Edit</button>
                      <button className="danger" onClick={() => onSetOpenCardMenu('')}>Close Case</button>
                    </div>
                  )}
                </div>
              </div>
            );
          })}

          {dashPill === 'actors' && paged.map((a: any) => {
            const sc = scoreColor(a.risk);
            return (
              <div className="case-card" key={a.id}>
                <img className="case-card__thumb case-card__thumb--avatar" src={a.avatar} alt={a.handle} />
                <div className="case-card__info">
                  <p className="case-card__title">{a.handle}</p>
                  <p className="case-card__meta">{a.type} | {a.posts} posts</p>
                  <div className="case-card__bar">
                    <div className={'case-card__bar-fill bar-' + sc} style={{ width: a.risk + '%' }} />
                  </div>
                </div>
                <span className={'case-card__score score-' + sc}>{a.risk}%</span>
                <div className="dot-menu-wrap">
                  <button
                    className="case-card__menu-btn"
                    type="button"
                    onClick={() => onSetOpenCardMenu(openCardMenu === a.id ? '' : a.id)}
                  >
                    <img src="/static/assets/menu.svg" alt="menu" />
                  </button>
                  {openCardMenu === a.id && (
                    <div className="dot-menu-dropdown">
                      <button onClick={() => { onInvestigateActor(a); onSetOpenCardMenu(''); }}>Investigate</button>
                      <button onClick={() => onSetOpenCardMenu('')}>Edit</button>
                      <button className="danger" onClick={() => onSetOpenCardMenu('')}>Suspend Actor</button>
                    </div>
                  )}
                </div>
              </div>
            );
          })}

          {totalPages > 1 && (
            <div className="dash-pagination">
              <button
                className="dash-pagination__btn"
                type="button"
                disabled={safePage === 0}
                onClick={() => onSetDashPage(safePage - 1)}
              >{'< Prev'}</button>
              <span className="dash-pagination__info">{String(safePage + 1) + ' / ' + String(totalPages)}</span>
              <button
                className="dash-pagination__btn"
                type="button"
                disabled={safePage >= totalPages - 1}
                onClick={() => onSetDashPage(safePage + 1)}
              >{'Next >'}</button>
            </div>
          )}
        </div>

        {vizFullscreen < 0 && (
          <div className="viz-sidebar">
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 'var(--space-2)' }}>
              <h3 className="analytics-header" style={{ margin: '0', textAlign: 'left' }}>Analytics</h3>
              <select
                className="viz-timescale-select"
                value={vizTimescale}
                onChange={(e: any) => { onSetVizTimescale(e.target.value); onSetVizPage(0); }}
              >
                <option value="monthly">Monthly</option>
                <option value="weekly">Weekly</option>
                <option value="daily">Daily</option>
              </select>
            </div>
            {visibleViz.map((v: any, i: number) => {
              const idx = vizStart + i;
              return (
                <div className="viz-card" key={v.title + vizTimescale}>
                  <MiniChart data={v.data} color={v.color} type={v.type} height={140} xLabel={v.xLabel} yLabel={v.yLabel} />
                  <div className="viz-card__header">
                    <span className="viz-card__title">{v.title}</span>
                    <button
                      className="viz-card__expand viz-card__open-btn"
                      type="button"
                      onClick={() => onSetVizFullscreen(idx)}
                    >open <img src="/static/assets/icons/arrow_icon.svg" alt="" style={{ width: '10px', height: '10px', marginLeft: '4px', verticalAlign: 'middle' }} /></button>
                  </div>
                </div>
              );
            })}
            {hasMoreViz && (
              <div className="viz-carousel-nav">
                <button className="viz-carousel-btn" type="button" onClick={() => onSetVizPage(vizPage + 1)}>
                  <img src="/static/assets/icons/chevron.svg" alt="next" style={{ width: '11px', height: '7px' }} />
                </button>
              </div>
            )}
            {vizPage > 0 && (
              <div className="viz-carousel-nav">
                <button className="viz-carousel-btn" type="button" onClick={() => onSetVizPage(vizPage - 1)}>
                  <img src="/static/assets/icons/chevron.svg" alt="prev" style={{ width: '11px', height: '7px', transform: 'rotate(180deg)' }} />
                </button>
              </div>
            )}
          </div>
        )}
      </div>

      {vizFullscreen >= 0 && (
        <div className="viz-fullscreen" onClick={() => onSetVizFullscreen(-1)}>
          <div className="viz-fullscreen__card" onClick={(e: any) => e.stopPropagation()}>
            <button className="viz-fullscreen__close" type="button" onClick={() => onSetVizFullscreen(-1)}>
              <img src="/static/assets/icons/close.svg" alt="close" className="close-icon" />
            </button>
            <FullScreenChart
              data={vizList[vizFullscreen]?.data}
              color={vizList[vizFullscreen]?.color}
              type={vizList[vizFullscreen]?.type}
              title={vizList[vizFullscreen]?.title}
              xLabel={vizList[vizFullscreen]?.xLabel}
              yLabel={vizList[vizFullscreen]?.yLabel}
            />
          </div>
        </div>
      )}
    </div>
  );
};
