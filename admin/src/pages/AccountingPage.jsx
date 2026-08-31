import React, { useState } from 'react';
import { Download, FileText, TrendingUp, CheckCircle2, Info, Wallet, Landmark, Plus, Pencil, Trash2, X, Check } from 'lucide-react';

export default function AccountingPage() {
  const [timeframe, setTimeframe] = useState('Monthly');

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
    // Monthly default
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

            {/* Custom SVG Bar/Line Canvas with Interactive Hover */}
            <div className="chart-wrapper" style={{ position: 'relative' }}>
              {hoverPoint && (
                <div
                  className="chart-floating-tooltip"
                  style={{
                    left: `${(hoverPoint.x / 600) * 100}%`,
                    top: `${hoverPoint.y}px`,
                  }}
                >
                  <div style={{ color: hoverPoint.color, fontSize: '0.7rem' }}>{hoverPoint.type} • {hoverPoint.label}</div>
                  <div>₹{hoverPoint.val.toLocaleString('en-IN')}</div>
                </div>
              )}

              <svg viewBox="0 0 600 230" className="revenue-expenses-svg" style={{ overflow: 'visible' }}>
                {/* Grid Lines */}
                <line x1="40" y1="30" x2="580" y2="30" stroke="#ECE4D9" strokeDasharray="4" />
                <text x="35" y="34" fontSize="10" fontWeight="700" fill="#A59D96" textAnchor="end">₹{(maxScale / 1000000).toFixed(1)}M</text>

                <line x1="40" y1="75" x2="580" y2="75" stroke="#ECE4D9" strokeDasharray="4" />
                <text x="35" y="79" fontSize="10" fontWeight="700" fill="#A59D96" textAnchor="end">₹{((maxScale * 0.75) / 1000000).toFixed(1)}M</text>

                <line x1="40" y1="120" x2="580" y2="120" stroke="#ECE4D9" strokeDasharray="4" />
                <text x="35" y="124" fontSize="10" fontWeight="700" fill="#A59D96" textAnchor="end">₹{((maxScale * 0.5) / 1000000).toFixed(1)}M</text>

                <line x1="40" y1="165" x2="580" y2="165" stroke="#ECE4D9" strokeDasharray="4" />
                <text x="35" y="169" fontSize="10" fontWeight="700" fill="#A59D96" textAnchor="end">₹{((maxScale * 0.25) / 1000000).toFixed(1)}M</text>

                <line x1="40" y1="200" x2="580" y2="200" stroke="#CBA034" strokeWidth="1.5" />
                <text x="35" y="204" fontSize="10" fontWeight="700" fill="#A59D96" textAnchor="end">0</text>

                {/* X Labels */}
                {chartData.labels.map((lbl, idx) => (
                  <text
                    key={idx}
                    x={startX + idx * stepX}
                    y="218"
                    fontSize="11"
                    fill={idx === chartData.labels.length - 1 ? '#8C4A3E' : '#756D69'}
                    fontWeight={idx === chartData.labels.length - 1 ? 800 : 600}
                    textAnchor="middle"
                  >
                    {lbl}
                  </text>
                ))}

                {/* Revenue Line (Olive Green/Gold) */}
                <path
                  d={revPath}
                  fill="none"
                  stroke="#7A6818"
                  strokeWidth="3.5"
                  strokeLinecap="round"
                  style={{ transition: 'all 0.4s ease' }}
                />

                {/* Expenses Line (Terracotta) */}
                <path
                  d={expPath}
                  fill="none"
                  stroke="#8C4A3E"
                  strokeWidth="3.5"
                  strokeLinecap="round"
                  style={{ transition: 'all 0.4s ease' }}
                />

                {/* Revenue Data Points */}
                {revPoints.map((pt, i) => (
                  <circle
                    key={`r_${i}`}
                    cx={pt.x}
                    cy={pt.y}
                    r={hoverPoint?.label === pt.label && hoverPoint?.type === 'Revenue' ? 7 : (i === revPoints.length - 1 ? 6 : 4)}
                    fill="#7A6818"
                    stroke="white"
                    strokeWidth="2"
                    className="graph-interactive-node"
                    onMouseEnter={() => setHoverPoint(pt)}
                    onMouseLeave={() => setHoverPoint(null)}
                  />
                ))}

                {/* Expenses Data Points */}
                {expPoints.map((pt, i) => (
                  <circle
                    key={`e_${i}`}
                    cx={pt.x}
                    cy={pt.y}
                    r={hoverPoint?.label === pt.label && hoverPoint?.type === 'Expenses' ? 7 : (i === expPoints.length - 1 ? 6 : 4)}
                    fill="#8C4A3E"
                    stroke="white"
                    strokeWidth="2"
                    className="graph-interactive-node"
                    onMouseEnter={() => setHoverPoint(pt)}
                    onMouseLeave={() => setHoverPoint(null)}
                  />
                ))}

                {/* Pulsing Radar Node on Live Head */}
                <circle
                  cx={revPoints[revPoints.length - 1].x}
                  cy={revPoints[revPoints.length - 1].y}
                  r="6"
                  fill="none"
                  stroke="#7A6818"
                  strokeWidth="2"
                  className="live-pulse-radar"
                />
              </svg>

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
