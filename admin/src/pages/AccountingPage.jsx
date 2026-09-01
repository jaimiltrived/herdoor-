import React, { useState } from 'react';
import { Download, FileText, TrendingUp, CheckCircle2, Info, Wallet, Landmark, Plus, Pencil, Trash2, X, Check } from 'lucide-react';

export default function AccountingPage() {
  const [timeframe, setTimeframe] = useState('7 Days');

  const [ledgerEntries, setLedgerEntries] = useState([
    {
      date: 'Oct 24, 2023',
      id: 'TXN-8472-A',
      account: 'Revenue: Mill Comm.',
      accountType: 'revenue',
      description: 'Commission payout run #42',
      debit: '',
      credit: '- ₹145,000.00',
      creditColor: '#2ECC71'
    },
    {
      date: 'Oct 23, 2023',
      id: 'TXN-8471-B',
      account: 'Expense: Logistics',
      accountType: 'expense',
      description: 'Delivery Partner weekly settlement',
      debit: '₹82,500.00',
      debitColor: '#8C4A3E',
      credit: '-'
    },
    {
      date: 'Oct 23, 2023',
      id: 'TXN-8470-C',
      account: 'Asset: Bank C/A',
      accountType: 'asset',
      description: 'Customer wholesale advance deposit',
      debit: '₹500,000.00',
      debitColor: '#2A2421',
      credit: '-'
    },
    {
      date: 'Oct 22, 2023',
      id: 'TXN-8469-D',
      account: 'Expense: IT/Cloud',
      accountType: 'expense',
      description: 'AWS Monthly Infrastructure Bill',
      debit: '₹14,200.00',
      debitColor: '#8C4A3E',
      credit: '-'
    },
    {
      date: 'Oct 21, 2023',
      id: 'TXN-8468-E',
      account: 'Revenue: Merchant Sub',
      accountType: 'revenue',
      description: 'Monthly Milling Pro tier renewals',
      debit: '',
      credit: '- ₹64,000.00',
      creditColor: '#2ECC71'
    }
  ]);

  // Modals
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingIndex, setEditingIndex] = useState(null);

  const [form, setForm] = useState({
    account: 'Revenue: Mill Comm.',
    accountType: 'revenue',
    description: '',
    debit: '',
    credit: '',
  });

  const handleOpenAdd = () => {
    setForm({ account: 'Revenue: Mill Comm.', accountType: 'revenue', description: '', debit: '', credit: '' });
    setIsAddModalOpen(true);
  };

  const handleOpenEdit = (entry, idx) => {
    setEditingIndex(idx);
    setForm({
      account: entry.account,
      accountType: entry.accountType,
      description: entry.description,
      debit: entry.debit,
      credit: entry.credit,
    });
    setIsEditModalOpen(true);
  };

  const handleSaveNew = (e) => {
    e.preventDefault();
    const newEntry = {
      date: 'Oct 25, 2023',
      id: `TXN-${Math.floor(8000 + Math.random() * 1000)}-X`,
      account: form.account,
      accountType: form.accountType,
      description: form.description,
      debit: form.debit ? `₹${form.debit}` : '',
      debitColor: form.debit ? '#8C4A3E' : 'inherit',
      credit: form.credit ? `- ₹${form.credit}` : '-',
      creditColor: form.credit ? '#2ECC71' : 'inherit',
    };
    setLedgerEntries([newEntry, ...ledgerEntries]);
    setIsAddModalOpen(false);
  };

  const handleSaveEdit = (e) => {
    e.preventDefault();
    if (editingIndex === null) return;
    const updated = [...ledgerEntries];
    updated[editingIndex] = {
      ...updated[editingIndex],
      account: form.account,
      accountType: form.accountType,
      description: form.description,
      debit: form.debit,
      credit: form.credit,
    };
    setLedgerEntries(updated);
    setIsEditModalOpen(false);
    setEditingIndex(null);
  };

  const handleDelete = (idx) => {
    if (window.confirm('Delete ledger transaction entry?')) {
      setLedgerEntries(ledgerEntries.filter((_, i) => i !== idx));
    }
  };

  const [hoverPoint, setHoverPoint] = useState(null);

  // Parse numeric values from ledger entries
  const parseAmount = (valStr) => {
    if (!valStr || valStr === '-') return 0;
    const cleaned = String(valStr).replace(/[^0-9.]/g, '');
    return parseFloat(cleaned) || 0;
  };

  // Calculate live financial metrics from active ledger entries
  const totalRevenue = ledgerEntries
    .filter((e) => e.accountType === 'revenue' || e.credit !== '-')
    .reduce((sum, e) => sum + parseAmount(e.credit), 0) || 4250000;

  const totalExpenses = ledgerEntries
    .filter((e) => e.accountType === 'expense' || e.debit)
    .reduce((sum, e) => sum + parseAmount(e.debit), 0) || 840500;

  const netProfit = totalRevenue - totalExpenses;
  const netProfitMargin = totalRevenue > 0 ? ((netProfit / totalRevenue) * 100).toFixed(1) : '24.8';
  const gstOutput = Math.round(totalRevenue * 0.0988);
  const gstInput = Math.round(totalExpenses * 0.214);
  const netTaxPayable = gstOutput - gstInput;

  // Generate dynamic chart points based on timeframe and ledger
  const getDynamicAccountingDataset = () => {
    if (timeframe === 'Quarterly') {
      const labels = ['Q1 (Jan-Mar)', 'Q2 (Apr-Jun)', 'Q3 (Jul-Sep)', 'Q4 (Oct-Dec)'];
      const revData = [
        Math.round(totalRevenue * 0.7),
        Math.round(totalRevenue * 0.85),
        Math.round(totalRevenue * 0.95),
        totalRevenue,
      ];
      const expData = [
        Math.round(totalExpenses * 0.65),
        Math.round(totalExpenses * 0.8),
        Math.round(totalExpenses * 0.9),
        totalExpenses,
      ];
      return { labels, revData, expData };
    }
    if (timeframe === 'Monthly') {
      const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Live (Oct)'];
      const revData = [
        Math.round(totalRevenue * 0.35),
        Math.round(totalRevenue * 0.5),
        Math.round(totalRevenue * 0.65),
        Math.round(totalRevenue * 0.82),
        Math.round(totalRevenue * 0.92),
        totalRevenue,
      ];
      const expData = [
        Math.round(totalExpenses * 0.3),
        Math.round(totalExpenses * 0.45),
        Math.round(totalExpenses * 0.58),
        Math.round(totalExpenses * 0.72),
        Math.round(totalExpenses * 0.88),
        totalExpenses,
      ];
      return { labels, revData, expData };
    }
    // 7 Days default
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Live (Today)'];
    const revData = [
      Math.round(totalRevenue * 0.38),
      Math.round(totalRevenue * 0.52),
      Math.round(totalRevenue * 0.68),
      Math.round(totalRevenue * 0.8),
      Math.round(totalRevenue * 0.92),
      Math.round(totalRevenue * 1.08),
      Math.round(totalRevenue * 1.22),
    ];
    const expData = [
      Math.round(totalExpenses * 0.32),
      Math.round(totalExpenses * 0.46),
      Math.round(totalExpenses * 0.6),
      Math.round(totalExpenses * 0.74),
      Math.round(totalExpenses * 0.85),
      Math.round(totalExpenses * 0.96),
      Math.round(totalExpenses * 1.1),
    ];
    return { labels, revData, expData };
  };

  const chartData = getDynamicAccountingDataset();
  const maxScale = Math.max(...chartData.revData, ...chartData.expData, 1000000) * 1.2;
  const chartWidth = 540;
  const startX = 60;
  const endX = 560;
  const stepX = (endX - startX) / (chartData.labels.length - 1);

  const revPoints = chartData.revData.map((val, idx) => {
    const x = startX + idx * stepX;
    const y = 200 - (val / maxScale) * 170;
    return { x, y, val, label: chartData.labels[idx], type: 'Revenue', color: '#7A6818' };
  });

  const expPoints = chartData.expData.map((val, idx) => {
    const x = startX + idx * stepX;
    const y = 200 - (val / maxScale) * 170;
    return { x, y, val, label: chartData.labels[idx], type: 'Expenses', color: '#8C4A3E' };
  });

  const buildPath = (points) => {
    let p = `M ${points[0].x},${points[0].y}`;
    for (let i = 0; i < points.length - 1; i++) {
      const xc = (points[i].x + points[i + 1].x) / 2;
      const yc = (points[i].y + points[i + 1].y) / 2;
      p += ` Q ${points[i].x},${points[i].y} ${xc},${yc}`;
    }
    p += ` T ${points[points.length - 1].x},${points[points.length - 1].y}`;
    return p;
  };

  const revPath = buildPath(revPoints);
  const expPath = buildPath(expPoints);

  return (
    <div className="accounting-page-container">
      {/* Top Page Header */}
      <div className="page-header-flex">
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <h1 className="page-title serif-heading">Accounting & Ledger</h1>
            <span className="live-stream-badge">
              <span className="live-stream-dot"></span>
              <span>LIVE LEDGER SYNC</span>
            </span>
          </div>
          <p className="page-subtitle">Real-time financial overview, ledger calculations, and tax provisioning.</p>
        </div>
        <div className="page-actions-group">
          <button className="btn-outline btn-with-icon">
            <Download size={16} />
            <span>Export Data</span>
          </button>
          <button className="btn-primary btn-with-icon" style={{ backgroundColor: '#8C4A3E' }} onClick={handleOpenAdd}>
            <Plus size={16} />
            <span>Add Ledger Entry</span>
          </button>
          <button className="btn-primary btn-with-icon" style={{ backgroundColor: '#6E5616' }}>
            <FileText size={16} />
            <span>Generate P&L</span>
          </button>
        </div>
      </div>

      {/* 4 Metric Cards */}
      <div className="metrics-grid-4">
        {/* Card 1: Gross Revenue */}
        <div className="metric-card">
          <div className="metric-header-row">
            <span className="metric-label">Gross Revenue (MTD)</span>
          </div>
          <div className="metric-value-row">
            <span className="metric-value">₹{totalRevenue.toLocaleString('en-IN')}</span>
          </div>
          <div className="metric-footer-row">
            <span className="trend-badge positive">
              <TrendingUp size={14} />
              +14.8% vs target
            </span>
          </div>
        </div>

        {/* Card 2: Platform Expenses */}
        <div className="metric-card">
          <div className="metric-header-row">
            <span className="metric-label">Platform Expenses</span>
          </div>
          <div className="metric-value-row">
            <span className="metric-value">₹{totalExpenses.toLocaleString('en-IN')}</span>
          </div>
          <div className="metric-footer-row">
            <span className="trend-badge negative">
              <TrendingUp size={14} />
              {((totalExpenses / totalRevenue) * 100).toFixed(1)}% of Gross
            </span>
          </div>
        </div>

        {/* Card 3: Net Profit Margin */}
        <div className="metric-card watermark-card">
          <div className="metric-header-row">
            <span className="metric-label">Net Profit Margin</span>
            <Wallet size={28} className="watermark-icon" />
          </div>
          <div className="metric-value-row">
            <span className="metric-value">{netProfitMargin}%</span>
          </div>
          <div className="metric-footer-row">
            <span className="trend-badge check-target">
              <CheckCircle2 size={14} />
              ₹{netProfit.toLocaleString('en-IN')} Net
            </span>
          </div>
        </div>

        {/* Card 4: Est. Tax Liability */}
        <div className="metric-card watermark-card">
          <div className="metric-header-row">
            <span className="metric-label">Est. Tax Liability</span>
            <Landmark size={28} className="watermark-icon" />
          </div>
          <div className="metric-value-row">
            <span className="metric-value">₹{netTaxPayable.toLocaleString('en-IN')}</span>
          </div>
          <div className="metric-footer-row">
            <span className="info-badge">
              <Info size={14} />
              Provisioned for Q3
            </span>
          </div>
        </div>
      </div>

      {/* Main Grid: Left Chart + Table, Right Tax Provisions + Reports */}
      <div className="accounting-main-layout">
        {/* Left Column */}
        <div className="left-column">
          {/* Revenue vs Expenses Chart Card */}
          <div className="card chart-card" style={{ position: 'relative' }}>
            <div className="card-header-flex">
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <h2 className="card-title">Revenue vs. Expenses</h2>
                <span className="live-stream-badge">
                  <span className="live-stream-dot"></span>
                  <span>SYNC</span>
                </span>
              </div>
              <div className="pill-toggle-container">
                <button
                  className={`pill-toggle-btn ${timeframe === '7 Days' ? 'active' : ''}`}
                  onClick={() => setTimeframe('7 Days')}
                >
                  7 Days
                </button>
                <button
                  className={`pill-toggle-btn ${timeframe === 'Monthly' ? 'active' : ''}`}
                  onClick={() => setTimeframe('Monthly')}
                >
                  Monthly
                </button>
                <button
                  className={`pill-toggle-btn ${timeframe === 'Quarterly' ? 'active' : ''}`}
                  onClick={() => setTimeframe('Quarterly')}
                >
                  Quarterly
                </button>
              </div>
            </div>
            {/* Custom SVG Bar Chart Canvas with Interactive Hover */}
            {(() => {
              const svgWidth = 600;
              const svgHeight = 230;
              const leftPad = 65;
              const rightPad = 25;
              const topPad = 25;
              const bottomPad = 40;
              const chartWidth = svgWidth - leftPad - rightPad;
              const chartHeight = svgHeight - topPad - bottomPad;

              const maxVal = maxScale;
              const yTicks = [
                { val: maxVal, text: `₹${(maxVal / 1000000).toFixed(1)}M`, y: topPad },
                { val: maxVal * 0.75, text: `₹${((maxVal * 0.75) / 1000000).toFixed(1)}M`, y: topPad + chartHeight * 0.25 },
                { val: maxVal * 0.5, text: `₹${((maxVal * 0.5) / 1000000).toFixed(1)}M`, y: topPad + chartHeight * 0.5 },
                { val: maxVal * 0.25, text: `₹${((maxVal * 0.25) / 1000000).toFixed(1)}M`, y: topPad + chartHeight * 0.75 },
                { val: 0, text: '0', y: topPad + chartHeight },
              ];

              const groupWidth = chartWidth / chartData.labels.length;
              const barWidth = Math.min(20, groupWidth * 0.28);
              const barGap = 4;

              const barGroups = chartData.labels.map((lbl, idx) => {
                const rev = chartData.revData[idx];
                const exp = chartData.expData[idx];

                const groupCenterX = leftPad + idx * groupWidth + groupWidth / 2;
                const revHeight = Math.max(4, (rev / maxVal) * chartHeight);
                const expHeight = Math.max(4, (exp / maxVal) * chartHeight);

                const revX = groupCenterX - barWidth - barGap / 2;
                const revY = topPad + chartHeight - revHeight;

                const expX = groupCenterX + barGap / 2;
                const expY = topPad + chartHeight - expHeight;

                return {
                  idx,
                  label: lbl,
                  rev,
                  exp,
                  groupCenterX,
                  revX,
                  revY,
                  revHeight,
                  expX,
                  expY,
                  expHeight,
                  isPeak: idx === chartData.labels.length - 1,
                };
              });

              return (
                <div className="chart-wrapper" style={{ position: 'relative' }}>
                  {hoverPoint && (
                    <div
                      className="chart-floating-tooltip"
                      style={{
                        left: `${(hoverPoint.groupCenterX / svgWidth) * 100}%`,
                        top: `${Math.min(hoverPoint.revY, hoverPoint.expY) + 30}px`,
                        backgroundColor: 'rgba(38, 33, 30, 0.96)',
                        borderRadius: '10px',
                        padding: '10px 14px',
                        boxShadow: '0 10px 25px rgba(0, 0, 0, 0.3)',
                        border: '1px solid rgba(255, 255, 255, 0.15)',
                        position: 'absolute',
                        zIndex: 10,
                      }}
                    >
                      <div style={{ color: '#FF9A93', fontSize: '0.78rem', fontWeight: 800, marginBottom: 4 }}>
                        {hoverPoint.label} Overview
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: '0.84rem', color: '#F0D47C', fontWeight: 800, marginBottom: 3 }}>
                        <span style={{ width: 8, height: 8, borderRadius: 2, backgroundColor: '#CBA034', display: 'inline-block' }}></span>
                        <span>Revenue: ₹{hoverPoint.rev.toLocaleString('en-IN')}</span>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: '0.76rem', color: '#FF9A93', fontWeight: 700 }}>
                        <span style={{ width: 8, height: 8, borderRadius: 2, backgroundColor: '#8C4A3E', display: 'inline-block' }}></span>
                        <span>Expenses: ₹{hoverPoint.exp.toLocaleString('en-IN')}</span>
                      </div>
                    </div>
                  )}

                  <svg viewBox={`0 0 ${svgWidth} ${svgHeight}`} className="revenue-expenses-svg" style={{ overflow: 'visible', width: '100%', height: '230px' }}>
                    <defs>
                      <linearGradient id="accRevGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset="0%" stopColor="#CBA034" />
                        <stop offset="100%" stopColor="#EAD186" />
                      </linearGradient>
                      <linearGradient id="accExpGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                        <stop offset="0%" stopColor="#8C4A3E" />
                        <stop offset="100%" stopColor="#B86B5D" />
                      </linearGradient>
                    </defs>

                    {/* Grid Lines */}
                    {yTicks.map((tick, i) => (
                      <g key={`ytick_${i}`}>
                        <line
                          x1={leftPad}
                          y1={tick.y}
                          x2={leftPad + chartWidth}
                          y2={tick.y}
                          stroke={tick.val === 0 ? '#DAC8B3' : '#ECE4D9'}
                          strokeWidth={tick.val === 0 ? 1.5 : 1}
                          strokeDasharray={tick.val === 0 ? undefined : '4 4'}
                        />
                        <text
                          x={leftPad - 10}
                          y={tick.y + 4}
                          fontSize="10"
                          fontWeight="700"
                          fill="#A59D96"
                          textAnchor="end"
                        >
                          {tick.text}
                        </text>
                      </g>
                    ))}

                    {/* Bars */}
                    {barGroups.map((grp) => {
                      const isHovered = hoverPoint?.label === grp.label;

                      return (
                        <g
                          key={`grp_${grp.idx}`}
                          style={{ cursor: 'pointer' }}
                          onMouseEnter={() => setHoverPoint(grp)}
                          onMouseLeave={() => setHoverPoint(null)}
                        >
                          <rect
                            x={grp.groupCenterX - groupWidth / 2 + 2}
                            y={topPad}
                            width={groupWidth - 4}
                            height={chartHeight}
                            fill={isHovered ? 'rgba(203, 160, 52, 0.07)' : 'transparent'}
                            rx="8"
                          />

                          <rect
                            x={grp.revX}
                            y={grp.revY}
                            width={barWidth}
                            height={grp.revHeight}
                            fill="url(#accRevGrad)"
                            rx="5"
                            style={{
                              transition: 'all 0.3s ease',
                              filter: isHovered ? 'brightness(1.1) drop-shadow(0 4px 6px rgba(203, 160, 52, 0.3))' : 'none',
                            }}
                          />

                          <rect
                            x={grp.expX}
                            y={grp.expY}
                            width={barWidth}
                            height={grp.expHeight}
                            fill="url(#accExpGrad)"
                            rx="5"
                            style={{
                              transition: 'all 0.3s ease',
                              filter: isHovered ? 'brightness(1.1) drop-shadow(0 4px 6px rgba(140, 74, 62, 0.3))' : 'none',
                            }}
                          />

                          <text
                            x={grp.groupCenterX}
                            y={topPad + chartHeight + 20}
                            textAnchor="middle"
                            fontSize={grp.isPeak ? '11.5' : '11'}
                            fontWeight={grp.isPeak ? '800' : (isHovered ? '700' : '600')}
                            fill={grp.isPeak ? '#8C4A3E' : (isHovered ? '#2A2421' : '#756D69')}
                          >
                            {grp.label}
                          </text>
                        </g>
                      );
                    })}

                    <line
                      x1={leftPad}
                      y1={topPad + chartHeight}
                      x2={leftPad + chartWidth}
                      y2={topPad + chartHeight}
                      stroke="#DAC8B3"
                      strokeWidth="1.5"
                    />
                  </svg>
                </div>
              );
            })()}

              {/* Chart Legend */}
              <div className="chart-legend" style={{ marginTop: 14 }}>
                <span className="legend-item">
                  <span className="legend-dot" style={{ backgroundColor: '#7A6818' }}></span>
                  Revenue (₹{totalRevenue.toLocaleString('en-IN')})
                </span>
                <span className="legend-item">
                  <span className="legend-dot" style={{ backgroundColor: '#8C4A3E' }}></span>
                  Expenses (₹{totalExpenses.toLocaleString('en-IN')})
                </span>
              </div>
            </div>

          {/* General Ledger entries Table (Image 2) */}
          <div className="card table-card">
            <div className="card-header-flex">
              <h2 className="card-title">General Ledger entries</h2>
              <a href="#ledger" className="link-action">View Full Ledger &rarr;</a>
            </div>

            <div className="table-wrapper">
              <table className="custom-table">
                <thead>
                  <tr>
                    <th>DATE</th>
                    <th>TRANSACTION ID</th>
                    <th>ACCOUNT</th>
                    <th>DESCRIPTION</th>
                    <th>DEBIT (DR)</th>
                    <th>CREDIT (CR)</th>
                    <th style={{ textAlign: 'right' }}>ACTIONS</th>
                  </tr>
                </thead>
                <tbody>
                  {ledgerEntries.map((row, idx) => (
                    <tr key={idx}>
                      <td style={{ fontWeight: 600 }}>{row.date}</td>
                      <td style={{ color: '#756D69', fontFamily: 'monospace' }}>{row.id}</td>
                      <td>
                        <span className={`account-badge ${row.accountType}`}>
                          {row.account}
                        </span>
                      </td>
                      <td style={{ fontWeight: 500 }}>{row.description}</td>
                      <td style={{ color: row.debitColor || 'inherit', fontWeight: 600 }}>{row.debit}</td>
                      <td style={{ color: row.creditColor || 'inherit', fontWeight: 700 }}>{row.credit}</td>
                      <td style={{ textAlign: 'right' }}>
                        <div style={{ display: 'inline-flex', gap: '6px' }}>
                          <button
                            className="btn-outline"
                            style={{ padding: '4px 8px', borderRadius: '6px', fontSize: '0.75rem' }}
                            title="Edit Entry"
                            onClick={() => handleOpenEdit(row, idx)}
                          >
                            <Pencil size={12} />
                            <span>Edit</span>
                          </button>
                          <button
                            className="btn-outline"
                            style={{
                              padding: '4px 8px',
                              borderRadius: '6px',
                              fontSize: '0.75rem',
                              borderColor: '#FADBD8',
                              color: '#C0392B',
                              backgroundColor: '#FDEDEC',
                            }}
                            title="Delete Entry"
                            onClick={() => handleDelete(idx)}
                          >
                            <Trash2 size={12} color="#C0392B" />
                            <span>Delete</span>
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Right Column */}
        <div className="right-column">
          {/* Tax Provisions Card */}
          <div className="card tax-card">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2 className="card-title" style={{ margin: 0 }}>Tax Provisions</h2>
              <span className="live-stream-badge">
                <span className="live-stream-dot"></span>
                <span>GST 18%</span>
              </span>
            </div>

            <div className="tax-row">
              <span className="tax-label">GST Output (Payable)</span>
              <span className="tax-val">₹{gstOutput.toLocaleString('en-IN')}</span>
            </div>
            <div className="progress-bar-container">
              <div className="progress-bar-fill" style={{ width: '85%', backgroundColor: '#7A6818' }}></div>
            </div>

            <div className="tax-row" style={{ marginTop: '16px' }}>
              <span className="tax-label">GST Input (Credit)</span>
              <span className="tax-val" style={{ color: '#2ECC71' }}>-₹{gstInput.toLocaleString('en-IN')}</span>
            </div>
            <div className="progress-bar-container">
              <div className="progress-bar-fill" style={{ width: '42%', backgroundColor: '#2ECC71' }}></div>
            </div>

            <div className="divider-line"></div>

            <div className="tax-summary-row">
              <span className="summary-label">Net Tax Liability</span>
              <span className="summary-amount">₹{netTaxPayable.toLocaleString('en-IN')}</span>
            </div>
          </div>

          {/* Financial Reports Card */}
          <div className="card reports-card">
            <h2 className="card-title" style={{ marginBottom: '20px' }}>Financial Reports</h2>

            <div className="report-item">
              <div className="report-icon-box">
                <FileText size={18} color="#8C4A3E" />
              </div>
              <div className="report-info">
                <span className="report-name">Profit & Loss (Q2)</span>
              </div>
              <button className="icon-btn download-btn" title="Download Report">
                <Download size={18} color="#756D69" />
              </button>
            </div>

            <div className="report-item">
              <div className="report-icon-box">
                <Landmark size={18} color="#7A6818" />
              </div>
              <div className="report-info">
                <span className="report-name">Balance Sheet</span>
              </div>
              <button className="icon-btn download-btn" title="Download Report">
                <Download size={18} color="#756D69" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Add Modal */}
      {isAddModalOpen && (
        <div className="modal-overlay">
          <div className="modal-dialog">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2 className="serif-heading" style={{ fontSize: '1.4rem', fontWeight: 800 }}>
                Add New Ledger Entry
              </h2>
              <button className="icon-btn" onClick={() => setIsAddModalOpen(false)}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveNew}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '24px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Account Category
                  </label>
                  <select
                    value={form.account}
                    onChange={(e) => {
                      const val = e.target.value;
                      let type = 'revenue';
                      if (val.includes('Expense')) type = 'expense';
                      if (val.includes('Asset')) type = 'asset';
                      setForm({ ...form, account: val, accountType: type });
                    }}
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                  >
                    <option value="Revenue: Mill Comm.">Revenue: Mill Comm.</option>
                    <option value="Revenue: Merchant Sub">Revenue: Merchant Sub</option>
                    <option value="Expense: Logistics">Expense: Logistics</option>
                    <option value="Expense: IT/Cloud">Expense: IT/Cloud</option>
                    <option value="Asset: Bank C/A">Asset: Bank C/A</option>
                  </select>
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Description
                  </label>
                  <input
                    type="text" required
                    value={form.description}
                    onChange={(e) => setForm({ ...form, description: e.target.value })}
                    placeholder="Transaction description..."
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Debit (DR) Amount (₹)
                    </label>
                    <input
                      type="text"
                      value={form.debit}
                      onChange={(e) => setForm({ ...form, debit: e.target.value })}
                      placeholder="e.g. 14,200.00"
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    />
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Credit (CR) Amount (₹)
                    </label>
                    <input
                      type="text"
                      value={form.credit}
                      onChange={(e) => setForm({ ...form, credit: e.target.value })}
                      placeholder="e.g. 145,000.00"
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    />
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" className="btn-outline" onClick={() => setIsAddModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn-primary" style={{ backgroundColor: '#8C4A3E' }}>
                  <Check size={16} /> Save Entry
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Modal */}
      {isEditModalOpen && (
        <div className="modal-overlay">
          <div className="modal-dialog">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2 className="serif-heading" style={{ fontSize: '1.4rem', fontWeight: 800 }}>
                Edit Ledger Entry
              </h2>
              <button className="icon-btn" onClick={() => setIsEditModalOpen(false)}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveEdit}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '24px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Account Category
                  </label>
                  <input
                    type="text" required
                    value={form.account}
                    onChange={(e) => setForm({ ...form, account: e.target.value })}
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Description
                  </label>
                  <input
                    type="text" required
                    value={form.description}
                    onChange={(e) => setForm({ ...form, description: e.target.value })}
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Debit (DR)
                    </label>
                    <input
                      type="text"
                      value={form.debit}
                      onChange={(e) => setForm({ ...form, debit: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    />
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Credit (CR)
                    </label>
                    <input
                      type="text"
                      value={form.credit}
                      onChange={(e) => setForm({ ...form, credit: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    />
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" className="btn-outline" onClick={() => setIsEditModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn-primary" style={{ backgroundColor: '#6E5616' }}>
                  <Check size={16} /> Update Entry
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
