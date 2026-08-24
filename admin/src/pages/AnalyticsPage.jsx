import React from 'react';
import { Download, RefreshCw, Cpu, Activity, Clock, Users } from 'lucide-react';

export default function AnalyticsPage() {
  return (
    <div className="analytics-page-container">
      {/* Page Header */}
      <div className="page-header-flex">
        <div>
          <h1 className="page-title serif-heading">Advanced Analytics</h1>
          <p className="page-subtitle">Deep-dive into platform data and predictive trends.</p>
        </div>
        <div className="page-actions-group">
          <button className="btn-primary btn-with-icon" style={{ backgroundColor: '#8C4A3E' }}>
            <Download size={16} />
            <span>Generate Report</span>
          </button>
        </div>
      </div>

      {/* 3 Metric Cards */}
      <div className="metrics-grid-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '20px', marginBottom: '28px' }}>
        <div className="metric-card">
          <span className="metric-label">Monthly Milling Volume</span>
          <div className="metric-value" style={{ fontSize: '2.2rem', fontWeight: 800, marginTop: '8px' }}>12,450 kg</div>
          <span className="trend-badge positive" style={{ fontSize: '0.8rem', marginTop: '8px', display: 'inline-flex' }}>+8.2% vs last month</span>
        </div>

        <div className="metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <span className="metric-label">Active Subscriptions</span>
              <div className="metric-value" style={{ fontSize: '2.2rem', fontWeight: 800, marginTop: '8px' }}>842</div>
            </div>
            <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: '#EFE6D2', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#6E5616' }}>
              <RefreshCw size={20} />
            </div>
          </div>
          <span className="trend-badge positive" style={{ fontSize: '0.8rem', marginTop: '8px', display: 'inline-flex' }}>+12% vs last month</span>
        </div>

        <div className="metric-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <span className="metric-label">Avg. Order Value</span>
              <div className="metric-value" style={{ fontSize: '2.2rem', fontWeight: 800, marginTop: '8px' }}>Rs.45.20</div>
            </div>
            <div style={{ width: '40px', height: '40px', borderRadius: '50%', background: '#FFECEB', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#FF9A93' }}>
              <Activity size={20} />
            </div>
          </div>
          <span style={{ fontSize: '0.8rem', color: '#756D69', marginTop: '8px', display: 'inline-block' }}>Steady vs last month</span>
        </div>
      </div>

      {/* Main Grid: Forecast chart on left, Hubs on right */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 320px', gap: '24px', marginBottom: '28px' }}>
        {/* Multi-Grain Demand Forecast Chart */}
        <div className="card">
          <div className="card-header-flex" style={{ marginBottom: '16px' }}>
            <h2 className="card-title">Multi-Grain Demand Forecast</h2>
            <div style={{ display: 'flex', gap: '12px', fontSize: '0.8rem', fontWeight: 600 }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}><span style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#8C4A3E' }}></span> Wheat</span>
              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}><span style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#CBA034' }}></span> Maize</span>
              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}><span style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#6B701D' }}></span> Millet</span>
            </div>
          </div>

          <div style={{ position: 'relative', background: '#FFF', borderRadius: '16px', border: '1px stroke #ECE4D9', padding: '20px' }}>
            <div style={{ position: 'absolute', top: '16px', right: '20px', background: '#FAF6F0', padding: '4px 10px', borderRadius: '8px', border: '1px solid #ECE4D9', fontSize: '0.75rem', fontWeight: 700, color: '#6E5616' }}>
              Wheat: +18% Trend
            </div>

            <svg viewBox="0 0 500 160" style={{ width: '100%', height: '160px' }}>
              <path d="M 20,130 Q 150,110 250,100 T 480,30" fill="none" stroke="#8C4A3E" strokeWidth="4" />
              <path d="M 20,140 Q 150,100 250,90 T 480,20" fill="none" stroke="#CBA034" strokeWidth="3" strokeDasharray="6,6" />
              <path d="M 20,150 Q 150,140 250,130 T 480,100" fill="none" stroke="#6B701D" strokeWidth="3" />
            </svg>
          </div>
        </div>

        {/* Top Performing Hubs */}
        <div className="card">
          <h2 className="card-title" style={{ marginBottom: '18px' }}>Top Performing Hubs</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div style={{ padding: '12px', background: '#FAF6F0', borderRadius: '12px', border: '1px solid #ECE4D9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>North District Hub</div>
                <div style={{ fontSize: '0.75rem', color: '#756D69' }}>4,200 kg processed</div>
              </div>
              <span className="tag-pill" style={{ background: '#E8F8F0', color: '#1E8449' }}>+15.2% Growth</span>
            </div>

            <div style={{ padding: '12px', background: '#FAF6F0', borderRadius: '12px', border: '1px solid #ECE4D9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>Central Market</div>
                <div style={{ fontSize: '0.75rem', color: '#756D69' }}>3,850 kg processed</div>
              </div>
              <span className="tag-pill" style={{ background: '#E8F8F0', color: '#1E8449' }}>+8.4% Growth</span>
            </div>

            <div style={{ padding: '12px', background: '#FAF6F0', borderRadius: '12px', border: '1px solid #ECE4D9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>East Riverside</div>
                <div style={{ fontSize: '0.75rem', color: '#756D69' }}>2,100 kg processed</div>
              </div>
              <span className="tag-pill" style={{ background: '#E8F8F0', color: '#1E8449' }}>+2.1% Growth</span>
            </div>
          </div>
        </div>
      </div>

      {/* System Health & Throughput Section */}
      <div className="card">
        <h2 className="card-title" style={{ marginBottom: '18px' }}>System Health & Throughput</h2>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '16px' }}>
          <div style={{ padding: '16px', background: '#FAF6F0', borderRadius: '14px', border: '1px solid #ECE4D9' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 700, marginBottom: '10px' }}>
              <span style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#2ECC71' }}></span>
              Mill A-1 (Active)
            </div>
            <div className="progress-bar-container">
              <div className="progress-bar-fill" style={{ width: '85%', backgroundColor: '#6E5616' }}></div>
            </div>
            <div style={{ fontSize: '0.75rem', color: '#756D69', marginTop: '6px' }}>85% Capacity Utilization</div>
          </div>

          <div style={{ padding: '16px', background: '#FAF6F0', borderRadius: '14px', border: '1px solid #ECE4D9' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 700, marginBottom: '10px' }}>
              <span style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#2ECC71' }}></span>
              Mill B-4 (Active)
            </div>
            <div className="progress-bar-container">
              <div className="progress-bar-fill" style={{ width: '92%', backgroundColor: '#6E5616' }}></div>
            </div>
            <div style={{ fontSize: '0.75rem', color: '#756D69', marginTop: '6px' }}>92% Capacity Utilization</div>
          </div>

          <div style={{ padding: '16px', background: '#FAF6F0', borderRadius: '14px', border: '1px solid #ECE4D9' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 700, marginBottom: '10px' }}>
              <span style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#F1C40F' }}></span>
              Mill C-2 (Maintenance)
            </div>
            <div className="progress-bar-container">
              <div className="progress-bar-fill" style={{ width: '20%', backgroundColor: '#F1C40F' }}></div>
            </div>
            <div style={{ fontSize: '0.75rem', color: '#756D69', marginTop: '6px' }}>Cooling cycle in progress</div>
          </div>
        </div>
      </div>
    </div>
  );
}
