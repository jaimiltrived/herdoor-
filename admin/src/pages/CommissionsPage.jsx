import React from 'react';
import { Download, TrendingUp, Sliders, DollarSign } from 'lucide-react';

export default function CommissionsPage() {
  const recentEarnings = [
    { id: 'ORD-8924', source: 'Sunrise Mills • 15%', amount: '+Rs.12.45', time: '2 mins ago' },
    { id: 'ORD-8923', source: 'Valley Wheat • 10%', amount: '+Rs.8.20', time: '15 mins ago' },
    { id: 'ORD-8922', source: 'City Grind • 15%', amount: '+Rs.22.50', time: '1 hour ago' },
    { id: 'ORD-8921', source: 'Artisan Mill • 12%', amount: '+Rs.16.80', time: '2 hours ago' },
  ];

  return (
    <div className="commissions-page-container">
      {/* Header */}
      <div className="page-header-flex">
        <div>
          <h1 className="page-title serif-heading">Commission Management</h1>
          <p className="page-subtitle">Monitor platform revenue, configure merchant tier rates, and view detailed earning ledgers across all regions.</p>
        </div>
        <div className="page-actions-group">
          <button className="btn-primary btn-with-icon" style={{ backgroundColor: '#8C4A3E' }}>
            <Download size={16} />
            <span>Export Report</span>
          </button>
        </div>
      </div>

      {/* Main 2-column Grid */}
      <div className="commissions-grid">
        {/* Left Area */}
        <div className="commissions-left">
          {/* Revenue Over Time Card */}
          <div className="card chart-card">
            <div className="card-header-flex">
              <div>
                <span className="card-label-sub">Revenue Over Time</span>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginTop: '4px' }}>
                  <span style={{ fontSize: '2rem', fontWeight: 800, fontFamily: 'Playfair Display' }}>Rs.42,850.00</span>
                  <span className="trend-badge positive" style={{ fontSize: '0.8rem' }}>
                    <TrendingUp size={12} /> +12.5%
                  </span>
                </div>
              </div>
              <select className="custom-select">
                <option>This Month</option>
                <option>Last Month</option>
                <option>This Quarter</option>
              </select>
            </div>

            {/* Simulated Bar Chart */}
            <div className="bar-chart-container" style={{ marginTop: '24px', height: '180px', display: 'flex', alignItems: 'flex-end', gap: '16px', padding: '0 20px 10px 20px', borderBottom: '1px solid #ECE4D9' }}>
              <div style={{ flex: 1, height: '40%', backgroundColor: '#EFE6D2', borderRadius: '6px 6px 0 0' }}></div>
              <div style={{ flex: 1, height: '70%', backgroundColor: '#E0CD94', borderRadius: '6px 6px 0 0' }}></div>
              <div style={{ flex: 1, height: '55%', backgroundColor: '#E0CD94', borderRadius: '6px 6px 0 0' }}></div>
              <div style={{ flex: 1, height: '95%', backgroundColor: '#6E5616', borderRadius: '6px 6px 0 0' }}></div>
            </div>
          </div>

          {/* Tier & Regional Configuration */}
          <div className="card config-card" style={{ marginTop: '24px' }}>
            <h2 className="card-title">Tier & Regional Configuration</h2>
            <p style={{ color: '#756D69', fontSize: '0.88rem', marginBottom: '20px' }}>Adjust base rates applied to incoming orders before regional modifiers.</p>

            <div className="config-grid" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
              {/* Merchant Tiers */}
              <div>
                <h4 style={{ fontSize: '0.85rem', color: '#756D69', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '12px' }}>Merchant Tiers</h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  <div className="config-box-item" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 16px', background: '#FAF6F0', borderRadius: '12px', border: '1px solid #ECE4D9' }}>
                    <span style={{ fontWeight: 600, fontSize: '0.9rem' }}>Standard Partner</span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <input type="text" defaultValue="15" style={{ width: '40px', padding: '6px', textAlign: 'center', fontWeight: 700, borderRadius: '8px', border: '1px solid #CBA034', background: '#FFF' }} />
                      <span style={{ fontWeight: 700 }}>%</span>
                    </div>
                  </div>

                  <div className="config-box-item" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 16px', background: '#FAF6F0', borderRadius: '12px', border: '1px solid #ECE4D9' }}>
                    <span style={{ fontWeight: 600, fontSize: '0.9rem', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span>👑</span> Premium Mill
                    </span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <input type="text" defaultValue="10" style={{ width: '40px', padding: '6px', textAlign: 'center', fontWeight: 700, borderRadius: '8px', border: '1px solid #CBA034', background: '#FFF' }} />
                      <span style={{ fontWeight: 700 }}>%</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Regional Modifiers */}
              <div>
                <h4 style={{ fontSize: '0.85rem', color: '#756D69', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '12px' }}>Regional Modifiers</h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 14px', background: '#FFF', borderRadius: '12px', border: '1px solid #ECE4D9' }}>
                    <span style={{ fontWeight: 600, fontSize: '0.88rem' }}>Urban Centers</span>
                    <span className="tag-pill" style={{ background: '#EFE6D2', color: '#6E5616' }}>+2.0%</span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 14px', background: '#FFF', borderRadius: '12px', border: '1px solid #ECE4D9' }}>
                    <span style={{ fontWeight: 600, fontSize: '0.88rem' }}>Rural / Outer Ring</span>
                    <span className="tag-pill" style={{ background: '#EFE6D2', color: '#6E5616' }}>-1.5%</span>
                  </div>
                  <button style={{ background: 'none', border: 'none', color: '#6E5616', fontWeight: 700, fontSize: '0.85rem', cursor: 'pointer', textAlign: 'left', marginTop: '6px' }}>
                    + Add Region
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Right Area - Recent Earnings */}
        <div className="commissions-right">
          <div className="card recent-earnings-card" style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
            <div className="card-header-flex" style={{ marginBottom: '20px' }}>
              <h2 className="card-title">Recent Earnings</h2>
              <button className="icon-btn" title="Filter"><Sliders size={18} /></button>
            </div>

            <div className="earnings-list" style={{ display: 'flex', flexDirection: 'column', gap: '12px', flexGrow: 1 }}>
              {recentEarnings.map((item, idx) => (
                <div key={idx} className="earning-item-row" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 14px', background: '#FAF6F0', borderRadius: '14px', border: '1px solid #ECE4D9' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{ width: '38px', height: '38px', borderRadius: '10px', background: '#EFE6D2', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#6E5616' }}>
                      <DollarSign size={18} />
                    </div>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>{item.id}</div>
                      <div style={{ fontSize: '0.75rem', color: '#756D69' }}>{item.source}</div>
                    </div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontWeight: 800, color: '#6E5616', fontSize: '0.9rem' }}>{item.amount}</div>
                    <div style={{ fontSize: '0.75rem', color: '#A59D96' }}>{item.time}</div>
                  </div>
                </div>
              ))}
            </div>

            <button className="btn-outline" style={{ marginTop: '20px', width: '100%', padding: '12px' }}>
              View Full Ledger
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
