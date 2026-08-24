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

  return (
    <div className="accounting-page-container">
      {/* Top Page Header */}
      <div className="page-header-flex">
        <div>
          <h1 className="page-title serif-heading">Accounting & Ledger</h1>
          <p className="page-subtitle">Real-time financial overview and platform performance.</p>
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
            <span className="metric-value">₹4,250,000</span>
          </div>
          <div className="metric-footer-row">
            <span className="trend-badge positive">
              <TrendingUp size={14} />
              12.5% vs last month
            </span>
          </div>
        </div>

        {/* Card 2: Platform Expenses */}
        <div className="metric-card">
          <div className="metric-header-row">
            <span className="metric-label">Platform Expenses</span>
          </div>
          <div className="metric-value-row">
            <span className="metric-value">₹840,500</span>
          </div>
          <div className="metric-footer-row">
            <span className="trend-badge negative">
              <TrendingUp size={14} />
              3.2% vs last month
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
            <span className="metric-value">24.8%</span>
          </div>
          <div className="metric-footer-row">
            <span className="trend-badge check-target">
              <CheckCircle2 size={14} />
              Above target (22%)
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
            <span className="metric-value">₹614,250</span>
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
          <div className="card chart-card">
            <div className="card-header-flex">
              <h2 className="card-title">Revenue vs. Expenses</h2>
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

            {/* Custom SVG Bar/Line Canvas */}
            <div className="chart-wrapper">
              <svg viewBox="0 0 600 220" className="revenue-expenses-svg">
                {/* Grid Lines */}
                <line x1="40" y1="20" x2="580" y2="20" stroke="#ECE4D9" strokeDasharray="4" />
                <text x="30" y="24" fontSize="11" fill="#A59D96" textAnchor="end">₹5M</text>

                <line x1="40" y1="60" x2="580" y2="60" stroke="#ECE4D9" strokeDasharray="4" />
                <text x="30" y="64" fontSize="11" fill="#A59D96" textAnchor="end">₹4M</text>

                <line x1="40" y1="100" x2="580" y2="100" stroke="#ECE4D9" strokeDasharray="4" />
                <text x="30" y="104" fontSize="11" fill="#A59D96" textAnchor="end">₹3M</text>

                <line x1="40" y1="140" x2="580" y2="140" stroke="#ECE4D9" strokeDasharray="4" />
                <text x="30" y="144" fontSize="11" fill="#A59D96" textAnchor="end">₹2M</text>

                <line x1="40" y1="180" x2="580" y2="180" stroke="#ECE4D9" strokeDasharray="4" />
                <text x="30" y="184" fontSize="11" fill="#A59D96" textAnchor="end">₹1M</text>

                <line x1="40" y1="200" x2="580" y2="200" stroke="#CBA034" strokeWidth="1.5" />
                <text x="30" y="204" fontSize="11" fill="#A59D96" textAnchor="end">0</text>

                {/* X Labels */}
                <text x="120" y="215" fontSize="12" fill="#756D69" textAnchor="middle">Jan</text>
                <text x="220" y="215" fontSize="12" fill="#756D69" textAnchor="middle">Feb</text>
                <text x="320" y="215" fontSize="12" fill="#756D69" textAnchor="middle">Mar</text>
                <text x="420" y="215" fontSize="12" fill="#756D69" textAnchor="middle">Apr</text>
                <text x="520" y="215" fontSize="12" fill="#756D69" textAnchor="middle" fontWeight="bold">May</text>

                {/* Revenue Line (Olive Green/Gold) */}
                <path
                  d="M 120,150 L 220,130 L 320,110 L 420,80 L 520,50"
                  fill="none"
                  stroke="#7A6818"
                  strokeWidth="3.5"
                  strokeLinecap="round"
                />

                {/* Expenses Line (Terracotta) */}
                <path
                  d="M 120,175 L 220,165 L 320,160 L 420,140 L 520,120"
                  fill="none"
                  stroke="#8C4A3E"
                  strokeWidth="3.5"
                  strokeLinecap="round"
                />

                {/* Data Points */}
                <circle cx="120" cy="150" r="4" fill="#7A6818" />
                <circle cx="220" cy="130" r="4" fill="#7A6818" />
                <circle cx="320" cy="110" r="4" fill="#7A6818" />
                <circle cx="420" cy="80" r="4" fill="#7A6818" />
                <circle cx="520" cy="50" r="6" fill="#7A6818" stroke="white" strokeWidth="2" />

                <circle cx="120" cy="175" r="4" fill="#8C4A3E" />
                <circle cx="220" cy="165" r="4" fill="#8C4A3E" />
                <circle cx="320" cy="160" r="4" fill="#8C4A3E" />
                <circle cx="420" cy="140" r="4" fill="#8C4A3E" />
                <circle cx="520" cy="120" r="6" fill="#8C4A3E" stroke="white" strokeWidth="2" />
              </svg>

              {/* Chart Legend */}
              <div className="chart-legend">
                <span className="legend-item">
                  <span className="legend-dot" style={{ backgroundColor: '#7A6818' }}></span>
                  Revenue
                </span>
                <span className="legend-item">
                  <span className="legend-dot" style={{ backgroundColor: '#8C4A3E' }}></span>
                  Expenses
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
            <h2 className="card-title" style={{ marginBottom: '20px' }}>Tax Provisions</h2>

            <div className="tax-row">
              <span className="tax-label">GST Output</span>
              <span className="tax-val">₹420,000</span>
            </div>
            <div className="progress-bar-container">
              <div className="progress-bar-fill" style={{ width: '85%', backgroundColor: '#7A6818' }}></div>
            </div>

            <div className="tax-row" style={{ marginTop: '16px' }}>
              <span className="tax-label">GST Input (Credit)</span>
              <span className="tax-val" style={{ color: '#2ECC71' }}>-₹180,000</span>
            </div>
            <div className="progress-bar-container">
              <div className="progress-bar-fill" style={{ width: '40%', backgroundColor: '#2ECC71' }}></div>
            </div>

            <div className="divider-line"></div>

            <div className="tax-summary-row">
              <span className="summary-label">Net Payable</span>
              <span className="summary-amount">₹240,000</span>
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
