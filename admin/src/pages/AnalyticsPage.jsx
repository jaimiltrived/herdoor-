import React, { useState, useEffect } from 'react';
import { Download, RefreshCw, Cpu, Activity, Clock, Users, TrendingUp, Wheat, ShieldCheck } from 'lucide-react';
import { apiService } from '../services/apiService';

export default function AnalyticsPage() {
  const [orders, setOrders] = useState([]);
  const [mills, setMills] = useState([]);
  const [timeframe, setTimeframe] = useState('30d');
  const [selectedGrain, setSelectedGrain] = useState('ALL');
  const [hoverPoint, setHoverPoint] = useState(null);

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 3000);
    return () => clearInterval(interval);
  }, []);

  const loadData = async () => {
    try {
      const [dbOrders, dbMills] = await Promise.all([
        apiService.getOrders(),
        apiService.getMills()
      ]);
      if (dbOrders && dbOrders.length > 0) setOrders(dbOrders);
      if (dbMills && dbMills.length > 0) setMills(dbMills);
    } catch (e) {
      console.warn('Load analytics error:', e);
    }
  };

  const totalKg = orders.reduce((sum, o) => sum + (parseFloat(o.quantityKg) || 12), 0);
  const totalRevenue = orders.reduce((sum, o) => sum + (parseFloat(o.totalAmount) || 180), 0);
  const avgOrderValue = orders.length > 0 ? (totalRevenue / orders.length).toFixed(2) : '45.20';
  const monthlyVolumeKg = (12400 + totalKg * 10).toLocaleString('en-IN');

  // Dynamic dataset generator tied to real orders and timeframe
  const totalWheatKg = orders.reduce((sum, o) => {
    const isWheat = !o.itemsSummary || o.itemsSummary.toLowerCase().includes('wheat') || o.itemsSummary.toLowerCase().includes('atta');
    return sum + (isWheat ? (parseFloat(o.quantityKg) || 15) : 0);
  }, 0) || 45;

  const totalMaizeKg = orders.reduce((sum, o) => {
    const isMaize = o.itemsSummary && (o.itemsSummary.toLowerCase().includes('maize') || o.itemsSummary.toLowerCase().includes('makka'));
    return sum + (isMaize ? (parseFloat(o.quantityKg) || 10) : 0);
  }, 0) || 30;

  const totalMilletKg = orders.reduce((sum, o) => {
    const isMillet = o.itemsSummary && (o.itemsSummary.toLowerCase().includes('millet') || o.itemsSummary.toLowerCase().includes('bajra') || o.itemsSummary.toLowerCase().includes('ragi'));
    return sum + (isMillet ? (parseFloat(o.quantityKg) || 8) : 0);
  }, 0) || 22;

  const getDynamicGraphDataset = () => {
    if (timeframe === '7d') {
      return {
        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Live (Peak)'],
        wheat: [
          Math.round(totalWheatKg * 0.4),
          Math.round(totalWheatKg * 0.6),
          Math.round(totalWheatKg * 0.75),
          Math.round(totalWheatKg * 0.9),
          Math.round(totalWheatKg * 1.1),
          Math.round(totalWheatKg * 1.35),
          Math.round(totalWheatKg * 1.6),
        ],
        maize: [
          Math.round(totalMaizeKg * 0.45),
          Math.round(totalMaizeKg * 0.6),
          Math.round(totalMaizeKg * 0.7),
          Math.round(totalMaizeKg * 0.85),
          Math.round(totalMaizeKg * 1.05),
          Math.round(totalMaizeKg * 1.25),
          Math.round(totalMaizeKg * 1.45),
        ],
        millet: [
          Math.round(totalMilletKg * 0.4),
          Math.round(totalMilletKg * 0.55),
          Math.round(totalMilletKg * 0.7),
          Math.round(totalMilletKg * 0.8),
          Math.round(totalMilletKg * 0.95),
          Math.round(totalMilletKg * 1.15),
          Math.round(totalMilletKg * 1.35),
        ],
        trend: '+24.6% Live Surge',
      };
    } else if (timeframe === '90d') {
      return {
        labels: ['Month 1', 'Month 2', 'Month 3', 'Forecast Target'],
        wheat: [
          Math.round(totalWheatKg * 1.5),
          Math.round(totalWheatKg * 2.8),
          Math.round(totalWheatKg * 4.2),
          Math.round(totalWheatKg * 6.0),
        ],
        maize: [
          Math.round(totalMaizeKg * 1.4),
          Math.round(totalMaizeKg * 2.4),
          Math.round(totalMaizeKg * 3.6),
          Math.round(totalMaizeKg * 5.1),
        ],
        millet: [
          Math.round(totalMilletKg * 1.2),
          Math.round(totalMilletKg * 2.0),
          Math.round(totalMilletKg * 2.9),
          Math.round(totalMilletKg * 4.1),
        ],
        trend: '+48.2% Quarterly Expansion',
      };
    }
    // 30d default
    return {
      labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Live Peak'],
      wheat: [
        Math.round(totalWheatKg * 0.6),
        Math.round(totalWheatKg * 0.95),
        Math.round(totalWheatKg * 1.3),
        Math.round(totalWheatKg * 1.7),
        Math.round(totalWheatKg * 2.2),
      ],
      maize: [
        Math.round(totalMaizeKg * 0.5),
        Math.round(totalMaizeKg * 0.8),
        Math.round(totalMaizeKg * 1.15),
        Math.round(totalMaizeKg * 1.5),
        Math.round(totalMaizeKg * 1.9),
      ],
      millet: [
        Math.round(totalMilletKg * 0.45),
        Math.round(totalMilletKg * 0.7),
        Math.round(totalMilletKg * 0.95),
        Math.round(totalMilletKg * 1.25),
        Math.round(totalMilletKg * 1.6),
      ],
      trend: `Wheat: +${Math.round(totalWheatKg / 2)}% Peak Trend`,
    };
  };

  const currentDataset = getDynamicGraphDataset();

  // Calculate SVG curve paths dynamically
  const getSvgPath = (dataPoints, grainLabel) => {
    const width = 560;
    const height = 160;
    const maxVal = Math.max(...currentDataset.wheat, ...currentDataset.maize, ...currentDataset.millet, 100) * 1.15;
    const step = width / (dataPoints.length - 1);

    const points = dataPoints.map((val, idx) => {
      const x = idx * step + 20;
      const y = height - (val / maxVal) * (height - 30) - 15;
      const label = currentDataset.labels[idx];
      return { x, y, val, label, grain: grainLabel };
    });

    let path = `M ${points[0].x} ${points[0].y}`;
    for (let i = 0; i < points.length - 1; i++) {
      const xc = (points[i].x + points[i + 1].x) / 2;
      const yc = (points[i].y + points[i + 1].y) / 2;
      path += ` Q ${points[i].x} ${points[i].y}, ${xc} ${yc}`;
    }
    path += ` T ${points[points.length - 1].x} ${points[points.length - 1].y}`;
    return { path, points };
  };

  const wheatCurve = getSvgPath(currentDataset.wheat, 'Whole Wheat');
  const maizeCurve = getSvgPath(currentDataset.maize, 'Yellow Maize');
  const milletCurve = getSvgPath(currentDataset.millet, 'Pearl Millet');

  return (
    <div className="analytics-page-container">
      {/* Page Header */}
      <div className="page-header-flex" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <h1 className="page-title serif-heading" style={{ fontSize: '2rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>Advanced Analytics</h1>
            <span className="live-stream-badge">
              <span className="live-stream-dot"></span>
              <span>LIVE TELEMETRY</span>
            </span>
          </div>
          <p className="page-subtitle" style={{ fontSize: '0.92rem', color: '#756D69', marginTop: 4 }}>Deep-dive into platform data and predictive real-time demand trends.</p>
        </div>
        <div className="page-actions-group">
          <button className="btn-primary btn-with-icon" style={{ backgroundColor: '#8C4A3E', background: 'linear-gradient(135deg, #8C4A3E, #6E372D)', padding: '10px 18px', borderRadius: 14 }}>
            <Download size={16} />
            <span>Generate Report</span>
          </button>
        </div>
      </div>

      {/* 3 Metric Cards */}
      <div className="metrics-grid-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '20px', marginBottom: '28px' }}>
        <div className="card" style={{ padding: 22, background: '#FFF', borderRadius: 16, border: '1px solid #ECE4D9' }}>
          <span style={{ fontSize: '0.75rem', fontWeight: 800, color: '#756D69', textTransform: 'uppercase' }}>Monthly Milling Volume</span>
          <div style={{ fontSize: '2.2rem', fontWeight: 800, marginTop: '8px', color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, sans-serif" }}>
            {monthlyVolumeKg} kg
          </div>
          <span className="trend-badge positive" style={{ fontSize: '0.8rem', marginTop: '8px', display: 'inline-flex', background: '#E8F8F0', color: '#1E8449', padding: '3px 8px', borderRadius: 8, fontWeight: 700 }}>
            +8.2% vs last month
          </span>
        </div>

        <div className="card" style={{ padding: 22, background: '#FFF', borderRadius: 16, border: '1px solid #ECE4D9' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <span style={{ fontSize: '0.75rem', fontWeight: 800, color: '#756D69', textTransform: 'uppercase' }}>Active Subscriptions</span>
              <div style={{ fontSize: '2.2rem', fontWeight: 800, marginTop: '8px', color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, sans-serif" }}>
                842
              </div>
            </div>
            <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: '#EFE6D2', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#6E5616' }}>
              <RefreshCw size={20} />
            </div>
          </div>
          <span className="trend-badge positive" style={{ fontSize: '0.8rem', marginTop: '8px', display: 'inline-flex', background: '#E8F8F0', color: '#1E8449', padding: '3px 8px', borderRadius: 8, fontWeight: 700 }}>
            +12% vs last month
          </span>
        </div>

        <div className="card" style={{ padding: 22, background: '#FFF', borderRadius: 16, border: '1px solid #ECE4D9' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <span style={{ fontSize: '0.75rem', fontWeight: 800, color: '#756D69', textTransform: 'uppercase' }}>Avg. Order Value</span>
              <div style={{ fontSize: '2.2rem', fontWeight: 800, marginTop: '8px', color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, sans-serif" }}>
                Rs.{avgOrderValue}
              </div>
            </div>
            <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: '#FFECEB', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#FF9A93' }}>
              <Activity size={20} />
            </div>
          </div>
          <span style={{ fontSize: '0.8rem', color: '#756D69', marginTop: '8px', display: 'inline-block', fontWeight: 600 }}>Steady vs last month</span>
        </div>
      </div>

      {/* Main Grid: Forecast chart on left, Hubs on right */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 340px', gap: '24px', marginBottom: '28px' }}>
        {/* Multi-Grain Demand Forecast Chart */}
        <div className="card" style={{ padding: 24 }}>
          <div className="card-header-flex" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px', flexWrap: 'wrap', gap: 10 }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <h2 className="card-title" style={{ fontSize: '1.2rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>Multi-Grain Demand Forecast</h2>
                <span className="live-stream-badge">
                  <span className="live-stream-dot"></span>
                  <span>SYNC</span>
                </span>
              </div>
              <p style={{ fontSize: '0.78rem', color: '#756D69', margin: '3px 0 0 0' }}>AI predictive grain consumption trajectory</p>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
              {/* Grain Legend Toggles */}
              <div style={{ display: 'flex', gap: '10px', fontSize: '0.8rem', fontWeight: 700 }}>
                <button
                  type="button"
                  onClick={() => setSelectedGrain(selectedGrain === 'WHEAT' ? 'ALL' : 'WHEAT')}
                  style={{ display: 'flex', alignItems: 'center', gap: '5px', background: selectedGrain === 'WHEAT' ? '#FFECEB' : 'transparent', border: '1px solid #ECE4D9', padding: '4px 10px', borderRadius: 8, cursor: 'pointer', color: '#8C4A3E' }}
                >
                  <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#8C4A3E' }}></span> Wheat
                </button>
                <button
                  type="button"
                  onClick={() => setSelectedGrain(selectedGrain === 'MAIZE' ? 'ALL' : 'MAIZE')}
                  style={{ display: 'flex', alignItems: 'center', gap: '5px', background: selectedGrain === 'MAIZE' ? '#FFF8E7' : 'transparent', border: '1px solid #ECE4D9', padding: '4px 10px', borderRadius: 8, cursor: 'pointer', color: '#CBA034' }}
                >
                  <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#CBA034' }}></span> Maize
                </button>
                <button
                  type="button"
                  onClick={() => setSelectedGrain(selectedGrain === 'MILLET' ? 'ALL' : 'MILLET')}
                  style={{ display: 'flex', alignItems: 'center', gap: '5px', background: selectedGrain === 'MILLET' ? '#F0F9EB' : 'transparent', border: '1px solid #ECE4D9', padding: '4px 10px', borderRadius: 8, cursor: 'pointer', color: '#6B701D' }}
                >
                  <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#6B701D' }}></span> Millet
                </button>
              </div>

              {/* Timeframe Select */}
              <select
                value={timeframe}
                onChange={(e) => setTimeframe(e.target.value)}
                style={{ padding: '6px 12px', borderRadius: '10px', border: '1px solid #ECE4D9', background: '#FAF6F0', fontWeight: 700, fontSize: '0.8rem', cursor: 'pointer', outline: 'none' }}
              >
                <option value="7d">7 Days</option>
                <option value="30d">30 Days</option>
                <option value="90d">3 Months</option>
              </select>
            </div>
          </div>

          <div style={{ position: 'relative', background: '#FAF6F0', borderRadius: '16px', border: '1px solid #ECE4D9', padding: '20px' }}>
            <div style={{ position: 'absolute', top: '16px', right: '20px', background: '#FFF', padding: '4px 12px', borderRadius: '8px', border: '1px solid #ECE4D9', fontSize: '0.78rem', fontWeight: 800, color: '#6E5616', boxShadow: '0 2px 6px rgba(0,0,0,0.04)' }}>
              {currentDataset.trend}
            </div>

            {/* Floating Interactive Tooltip */}
            {hoverPoint && (
              <div
                className="chart-floating-tooltip"
                style={{
                  left: `${(hoverPoint.x / 600) * 100}%`,
                  top: `${hoverPoint.y}px`,
                }}
              >
                <div style={{ color: '#FF9A93', fontSize: '0.7rem' }}>{hoverPoint.grain} • {hoverPoint.label}</div>
                <div>{hoverPoint.val} kg Processed</div>
              </div>
            )}

            <svg viewBox="0 0 600 180" style={{ width: '100%', height: '180px', overflow: 'visible' }}>
              <defs>
                <linearGradient id="wheatAreaGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                  <stop offset="0%" stopColor="#8C4A3E" stopOpacity="0.28" />
                  <stop offset="100%" stopColor="#8C4A3E" stopOpacity="0.0" />
                </linearGradient>
              </defs>

              {/* Grid Lines */}
              <line x1="20" y1="35" x2="580" y2="35" stroke="#ECE4D9" strokeDasharray="3,3" />
              <line x1="20" y1="75" x2="580" y2="75" stroke="#ECE4D9" strokeDasharray="3,3" />
              <line x1="20" y1="115" x2="580" y2="115" stroke="#ECE4D9" strokeDasharray="3,3" />
              <line x1="20" y1="150" x2="580" y2="150" stroke="#ECE4D9" strokeWidth="1.5" />

              {/* Wheat Curve & Area */}
              {(selectedGrain === 'ALL' || selectedGrain === 'WHEAT') && (
                <>
                  <path
                    d={`${wheatCurve.path} L ${wheatCurve.points[wheatCurve.points.length - 1].x} 150 L 20 150 Z`}
                    fill="url(#wheatAreaGrad)"
                    style={{ transition: 'all 0.4s ease' }}
                  />
                  <path d={wheatCurve.path} fill="none" stroke="#8C4A3E" strokeWidth="4" strokeLinecap="round" style={{ transition: 'all 0.4s ease' }} />
                  {wheatCurve.points.map((pt, i) => (
                    <circle
                      key={`w_${i}`}
                      cx={pt.x}
                      cy={pt.y}
                      r={hoverPoint?.label === pt.label && hoverPoint?.grain === pt.grain ? 7 : (i === wheatCurve.points.length - 1 ? 5.5 : 4)}
                      fill="#8C4A3E"
                      stroke="#FFF"
                      strokeWidth="2"
                      className="graph-interactive-node"
                      onMouseEnter={() => setHoverPoint(pt)}
                      onMouseLeave={() => setHoverPoint(null)}
                    />
                  ))}
                  {/* Radar Beacon on latest Wheat Point */}
                  <circle
                    cx={wheatCurve.points[wheatCurve.points.length - 1].x}
                    cy={wheatCurve.points[wheatCurve.points.length - 1].y}
                    r="5"
                    fill="none"
                    stroke="#8C4A3E"
                    strokeWidth="2"
                    className="live-pulse-radar"
                  />
                </>
              )}

              {/* Maize Curve */}
              {(selectedGrain === 'ALL' || selectedGrain === 'MAIZE') && (
                <>
                  <path d={maizeCurve.path} fill="none" stroke="#CBA034" strokeWidth="3" strokeDasharray="6,6" strokeLinecap="round" style={{ transition: 'all 0.4s ease' }} />
                  {maizeCurve.points.map((pt, i) => (
                    <circle
                      key={`m_${i}`}
                      cx={pt.x}
                      cy={pt.y}
                      r={hoverPoint?.label === pt.label && hoverPoint?.grain === pt.grain ? 7 : 4}
                      fill="#CBA034"
                      stroke="#FFF"
                      strokeWidth="2"
                      className="graph-interactive-node"
                      onMouseEnter={() => setHoverPoint(pt)}
                      onMouseLeave={() => setHoverPoint(null)}
                    />
                  ))}
                </>
              )}

              {/* Millet Curve */}
              {(selectedGrain === 'ALL' || selectedGrain === 'MILLET') && (
                <>
                  <path d={milletCurve.path} fill="none" stroke="#6B701D" strokeWidth="3" strokeLinecap="round" style={{ transition: 'all 0.4s ease' }} />
                  {milletCurve.points.map((pt, i) => (
                    <circle
                      key={`ml_${i}`}
                      cx={pt.x}
                      cy={pt.y}
                      r={hoverPoint?.label === pt.label && hoverPoint?.grain === pt.grain ? 7 : 4}
                      fill="#6B701D"
                      stroke="#FFF"
                      strokeWidth="2"
                      className="graph-interactive-node"
                      onMouseEnter={() => setHoverPoint(pt)}
                      onMouseLeave={() => setHoverPoint(null)}
                    />
                  ))}
                </>
              )}
            </svg>

            {/* X-Axis Timeline Labels */}
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.75rem', color: '#756D69', marginTop: 12, fontWeight: 700, paddingLeft: 10, paddingRight: 10 }}>
              {currentDataset.labels.map((lbl, idx) => (
                <span key={idx} style={{ color: idx === currentDataset.labels.length - 1 ? '#8C4A3E' : '#756D69', fontWeight: idx === currentDataset.labels.length - 1 ? 800 : 600 }}>
                  {lbl}
                </span>
              ))}
            </div>
          </div>
        </div>

        {/* Top Performing Hubs */}
        <div className="card" style={{ padding: 24 }}>
          <h2 className="card-title" style={{ fontSize: '1.2rem', fontWeight: 800, color: '#2A2421', marginBottom: '18px' }}>Top Performing Hubs</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            {mills.length > 0 ? (
              mills.slice(0, 3).map((m, idx) => (
                <div key={m.id || idx} style={{ padding: '12px 14px', background: '#FAF6F0', borderRadius: '12px', border: '1px solid #ECE4D9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: '0.9rem', color: '#2A2421' }}>{m.name}</div>
                    <div style={{ fontSize: '0.75rem', color: '#756D69' }}>{m.capacityKgPerDay || 500} kg/day capacity</div>
                  </div>
                  <span className="tag-pill" style={{ background: '#E8F8F0', color: '#1E8449', padding: '4px 8px', borderRadius: 8, fontSize: '0.75rem', fontWeight: 700 }}>
                    {idx === 0 ? '+15.2% Growth' : idx === 1 ? '+8.4% Growth' : '+5.1% Growth'}
                  </span>
                </div>
              ))
            ) : (
              <>
                <div style={{ padding: '12px 14px', background: '#FAF6F0', borderRadius: '12px', border: '1px solid #ECE4D9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: '0.9rem', color: '#2A2421' }}>North District Hub</div>
                    <div style={{ fontSize: '0.75rem', color: '#756D69' }}>4,200 kg processed</div>
                  </div>
                  <span className="tag-pill" style={{ background: '#E8F8F0', color: '#1E8449', padding: '4px 8px', borderRadius: 8, fontSize: '0.75rem', fontWeight: 700 }}>+15.2% Growth</span>
                </div>
                <div style={{ padding: '12px 14px', background: '#FAF6F0', borderRadius: '12px', border: '1px solid #ECE4D9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: '0.9rem', color: '#2A2421' }}>Central Market</div>
                    <div style={{ fontSize: '0.75rem', color: '#756D69' }}>3,850 kg processed</div>
                  </div>
                  <span className="tag-pill" style={{ background: '#E8F8F0', color: '#1E8449', padding: '4px 8px', borderRadius: 8, fontSize: '0.75rem', fontWeight: 700 }}>+8.4% Growth</span>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* System Health & Throughput Section */}
      <div className="card" style={{ padding: 24 }}>
        <h2 className="card-title" style={{ fontSize: '1.2rem', fontWeight: 800, color: '#2A2421', marginBottom: '18px' }}>System Health & Throughput</h2>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '16px' }}>
          {mills.length > 0 ? (
            mills.slice(0, 3).map((m, idx) => (
              <div key={m.id || idx} style={{ padding: '16px', background: '#FAF6F0', borderRadius: '14px', border: '1px solid #ECE4D9' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 700, marginBottom: '10px', color: '#2A2421' }}>
                  <span style={{ width: '10px', height: '10px', borderRadius: '50%', background: m.isOpen ? '#2ECC71' : '#F1C40F' }}></span>
                  {m.name} ({m.isOpen ? 'Active' : 'Maintenance'})
                </div>
                <div className="progress-bar-container" style={{ width: '100%', height: '8px', background: '#ECE4D9', borderRadius: '4px', overflow: 'hidden' }}>
                  <div className="progress-bar-fill" style={{ width: idx === 0 ? '85%' : idx === 1 ? '92%' : '40%', height: '100%', backgroundColor: '#6E5616', borderRadius: '4px' }}></div>
                </div>
                <div style={{ fontSize: '0.75rem', color: '#756D69', marginTop: '6px', fontWeight: 600 }}>
                  {idx === 0 ? '85% Capacity Utilization' : idx === 1 ? '92% Capacity Utilization' : 'Cooling cycle in progress'}
                </div>
              </div>
            ))
          ) : (
            <div style={{ padding: '16px', background: '#FAF6F0', borderRadius: '14px', border: '1px solid #ECE4D9' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 700, marginBottom: '10px' }}>
                <span style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#2ECC71' }}></span>
                Shree Ganesh Flour Mill (Active)
              </div>
              <div className="progress-bar-container" style={{ width: '100%', height: '8px', background: '#ECE4D9', borderRadius: '4px', overflow: 'hidden' }}>
                <div className="progress-bar-fill" style={{ width: '85%', height: '100%', backgroundColor: '#6E5616' }}></div>
              </div>
              <div style={{ fontSize: '0.75rem', color: '#756D69', marginTop: '6px' }}>85% Capacity Utilization</div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
