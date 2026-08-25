import React, { useState } from 'react';
import { Gift, Plus, Pencil, Trash2, Search, Filter, Check, X, Tag, Percent, Award, ArrowUpRight } from 'lucide-react';

export default function GiftsPage() {
  const [vouchers, setVouchers] = useState([
    { code: 'WELCOME50', type: 'Flat ₹50 OFF', recipient: 'All New Citizens', maxUses: 500, usedCount: 342, expiry: 'Dec 31, 2026', status: 'Active', statusBg: '#E8F8F0', statusColor: '#1E8449' },
    { code: 'FESTIVE100', type: 'Flat ₹100 OFF', recipient: 'VIP Citizens', maxUses: 200, usedCount: 189, expiry: 'Nov 15, 2026', status: 'Active', statusBg: '#E8F8F0', statusColor: '#1E8449' },
    { code: 'GRAINPROMO15', type: '15% Discount', recipient: 'Whole Wheat Orders', maxUses: 1000, usedCount: 820, expiry: 'Oct 30, 2026', status: 'Active', statusBg: '#E8F8F0', statusColor: '#1E8449' },
    { code: 'FREEMILLING', type: '100% Free Grinding', recipient: 'Loyalty Reward', maxUses: 50, usedCount: 50, expiry: 'Aug 20, 2026', status: 'Expired', statusBg: '#F2F4F4', statusColor: '#7F8C8D' },
  ]);

  const [searchQuery, setSearchQuery] = useState('');
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingIndex, setEditingIndex] = useState(null);

  const [form, setForm] = useState({
    code: '',
    type: 'Flat ₹50 OFF',
    recipient: 'All Citizens',
    maxUses: 100,
    expiry: 'Dec 31, 2026',
    status: 'Active',
  });

  const handleOpenAdd = () => {
    setForm({ code: '', type: 'Flat ₹50 OFF', recipient: 'All Citizens', maxUses: 100, expiry: 'Dec 31, 2026', status: 'Active' });
    setIsAddModalOpen(true);
  };

  const handleOpenEdit = (v, idx) => {
    setEditingIndex(idx);
    setForm({
      code: v.code,
      type: v.type,
      recipient: v.recipient,
      maxUses: v.maxUses,
      expiry: v.expiry,
      status: v.status,
    });
    setIsEditModalOpen(true);
  };

  const handleSaveNew = (e) => {
    e.preventDefault();
    const newVoucher = {
      code: form.code.toUpperCase() || 'GIFT' + Math.floor(100 + Math.random() * 900),
      type: form.type,
      recipient: form.recipient,
      maxUses: Number(form.maxUses) || 100,
      usedCount: 0,
      expiry: form.expiry,
      status: form.status,
      statusBg: form.status === 'Active' ? '#E8F8F0' : '#F2F4F4',
      statusColor: form.status === 'Active' ? '#1E8449' : '#7F8C8D',
    };
    setVouchers([newVoucher, ...vouchers]);
    setIsAddModalOpen(false);
  };

  const handleSaveEdit = (e) => {
    e.preventDefault();
    if (editingIndex === null) return;
    const updated = [...vouchers];
    updated[editingIndex] = {
      ...updated[editingIndex],
      code: form.code.toUpperCase(),
      type: form.type,
      recipient: form.recipient,
      maxUses: Number(form.maxUses) || updated[editingIndex].maxUses,
      expiry: form.expiry,
      status: form.status,
      statusBg: form.status === 'Active' ? '#E8F8F0' : '#F2F4F4',
      statusColor: form.status === 'Active' ? '#1E8449' : '#7F8C8D',
    };
    setVouchers(updated);
    setIsEditModalOpen(false);
    setEditingIndex(null);
  };

  const handleDelete = (idx) => {
    if (window.confirm('Delete gift voucher promo code?')) {
      setVouchers(vouchers.filter((_, i) => i !== idx));
    }
  };

  const filteredVouchers = vouchers.filter(v =>
    v.code.toLowerCase().includes(searchQuery.toLowerCase()) ||
    v.type.toLowerCase().includes(searchQuery.toLowerCase()) ||
    v.recipient.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="gifts-page-container">
      {/* Page Header */}
      <div className="page-header-flex">
        <div>
          <h1 className="page-title serif-heading">Gift Cards & Voucher Management</h1>
          <p className="page-subtitle">Create promotional gift codes, issue customer reward vouchers, and track redemption statistics.</p>
        </div>
        <div className="page-actions-group">
          <button className="btn-primary btn-with-icon" style={{ backgroundColor: '#8C4A3E' }} onClick={handleOpenAdd}>
            <Plus size={16} />
            <span>Issue Gift Voucher</span>
          </button>
        </div>
      </div>

      {/* 4 Metric Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 20, marginBottom: '28px' }}>
        <div className="card" style={{ padding: 22 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
            <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>ACTIVE VOUCHERS</span>
            <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#FFECEB', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Gift size={16} color="#8C4A3E" />
            </div>
          </div>
          <div style={{ fontSize: '2.3rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
            {vouchers.filter(v => v.status === 'Active').length} Promos
          </div>
          <div style={{ marginTop: 6 }}>
            <span style={{ fontSize: '0.82rem', fontWeight: 700, color: '#1E8449', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              ↑ +4 active this month
            </span>
          </div>
        </div>

        <div className="card" style={{ padding: 22 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
            <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>TOTAL GIFT VALUE</span>
            <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#EFE6D2', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Tag size={16} color="#6E5616" />
            </div>
          </div>
          <div style={{ fontSize: '2.3rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
            ₹125,000
          </div>
          <div style={{ marginTop: 6 }}>
            <span style={{ fontSize: '0.82rem', color: '#756D69', fontWeight: 600 }}>
              Allocated for rewards
            </span>
          </div>
        </div>

        <div className="card" style={{ padding: 22 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
            <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>REDEEMED VALUE</span>
            <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#E8F8F0', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Award size={16} color="#1E8449" />
            </div>
          </div>
          <div style={{ fontSize: '2.3rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
            ₹98,400
          </div>
          <div style={{ marginTop: 6 }}>
            <span style={{ fontSize: '0.82rem', fontWeight: 700, color: '#1E8449', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              1,401 Redemptions
            </span>
          </div>
        </div>

        <div className="card" style={{ padding: 22 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
            <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>REDEMPTION RATE</span>
            <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#F7F2EB', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Percent size={16} color="#756D69" />
            </div>
          </div>
          <div style={{ fontSize: '2.3rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
            84.2%
          </div>
          <div style={{ marginTop: 6 }}>
            <span style={{ fontSize: '0.82rem', fontWeight: 700, color: '#1E8449', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              High Engagement
            </span>
          </div>
        </div>
      </div>

      {/* Main Vouchers Table Card */}
      <div className="card">
        <div className="card-header-flex" style={{ marginBottom: '20px' }}>
          <h2 className="card-title">Promotional Gift Codes & Rewards</h2>
          <div style={{ display: 'flex', gap: '10px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', background: '#FAF6F0', padding: '6px 14px', borderRadius: '20px', border: '1px solid #ECE4D9' }}>
              <Search size={14} color="#756D69" />
              <input
                placeholder="Search voucher code..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{ border: 'none', background: 'transparent', outline: 'none', fontSize: '0.85rem' }}
              />
            </div>
            <button className="btn-outline" style={{ padding: '6px 14px', borderRadius: '20px' }}>
              <Filter size={14} /> Filter
            </button>
          </div>
        </div>

        <div className="table-wrapper">
          <table className="custom-table">
            <thead>
              <tr>
                <th>Voucher Code</th>
                <th>Reward / Benefit</th>
                <th>Target Recipient</th>
                <th>Redemptions</th>
                <th>Expiry Date</th>
                <th>Status</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredVouchers.map((v, idx) => (
                <tr key={idx}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <Tag size={15} color="#8C4A3E" />
                      <span style={{ fontWeight: 800, fontFamily: 'monospace', fontSize: '0.95rem', color: '#8C4A3E' }}>
                        {v.code}
                      </span>
                    </div>
                  </td>
                  <td style={{ fontWeight: 700 }}>{v.type}</td>
                  <td style={{ color: '#756D69', fontWeight: 600 }}>{v.recipient}</td>
                  <td>
                    <div style={{ fontSize: '0.85rem', fontWeight: 700 }}>
                      {v.usedCount} / {v.maxUses}
                    </div>
                    <div className="progress-bar-container" style={{ height: '4px', width: '80px', marginTop: '4px' }}>
                      <div className="progress-bar-fill" style={{ width: `${Math.min(100, (v.usedCount / v.maxUses) * 100)}%`, backgroundColor: '#6E5616' }}></div>
                    </div>
                  </td>
                  <td style={{ fontWeight: 600, fontSize: '0.85rem' }}>{v.expiry}</td>
                  <td>
                    <span className="tag-pill" style={{ background: v.statusBg, color: v.statusColor, padding: '4px 12px', borderRadius: '12px' }}>
                      {v.status}
                    </span>
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div style={{ display: 'inline-flex', gap: '8px' }}>
                      <button
                        className="btn-outline"
                        style={{ padding: '6px 10px', borderRadius: '8px', fontSize: '0.78rem' }}
                        onClick={() => handleOpenEdit(v, idx)}
                        title="Edit Voucher"
                      >
                        <Pencil size={13} />
                        <span>Edit</span>
                      </button>
                      <button
                        className="btn-outline"
                        style={{
                          padding: '6px 10px',
                          borderRadius: '8px',
                          fontSize: '0.78rem',
                          borderColor: '#FADBD8',
                          color: '#C0392B',
                          backgroundColor: '#FDEDEC',
                        }}
                        onClick={() => handleDelete(idx)}
                        title="Delete Voucher"
                      >
                        <Trash2 size={13} color="#C0392B" />
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

      {/* Add Modal */}
      {isAddModalOpen && (
        <div className="modal-overlay">
          <div className="modal-dialog">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2 className="serif-heading" style={{ fontSize: '1.4rem', fontWeight: 800 }}>
                Issue New Gift Voucher
              </h2>
              <button className="icon-btn" onClick={() => setIsAddModalOpen(false)}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveNew}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '24px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Voucher Promo Code
                  </label>
                  <input
                    type="text" required
                    value={form.code}
                    onChange={(e) => setForm({ ...form, code: e.target.value })}
                    placeholder="e.g. DIWALI50 or GRAIN100"
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none', textTransform: 'uppercase', fontFamily: 'monospace', fontWeight: 700 }}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Reward Type / Benefit
                    </label>
                    <input
                      type="text" required
                      value={form.type}
                      onChange={(e) => setForm({ ...form, type: e.target.value })}
                      placeholder="e.g. Flat ₹50 OFF"
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    />
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Target Recipient
                    </label>
                    <input
                      type="text" required
                      value={form.recipient}
                      onChange={(e) => setForm({ ...form, recipient: e.target.value })}
                      placeholder="e.g. All Citizens / VIP"
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Max Redemption Count
                    </label>
                    <input
                      type="number" required
                      value={form.maxUses}
                      onChange={(e) => setForm({ ...form, maxUses: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    />
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Expiry Date
                    </label>
                    <input
                      type="text" required
                      value={form.expiry}
                      onChange={(e) => setForm({ ...form, expiry: e.target.value })}
                      placeholder="e.g. Dec 31, 2026"
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    />
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" className="btn-outline" onClick={() => setIsAddModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn-primary" style={{ backgroundColor: '#8C4A3E' }}>
                  <Check size={16} /> Save Voucher
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
                Edit Gift Voucher Code
              </h2>
              <button className="icon-btn" onClick={() => setIsEditModalOpen(false)}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveEdit}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '24px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Voucher Code
                  </label>
                  <input
                    type="text" required
                    value={form.code}
                    onChange={(e) => setForm({ ...form, code: e.target.value })}
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none', textTransform: 'uppercase', fontFamily: 'monospace', fontWeight: 700 }}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Reward Type
                    </label>
                    <input
                      type="text" required
                      value={form.type}
                      onChange={(e) => setForm({ ...form, type: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    />
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Status
                    </label>
                    <select
                      value={form.status}
                      onChange={(e) => setForm({ ...form, status: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    >
                      <option value="Active">Active</option>
                      <option value="Expired">Expired</option>
                    </select>
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" className="btn-outline" onClick={() => setIsEditModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn-primary" style={{ backgroundColor: '#6E5616' }}>
                  <Check size={16} /> Update Voucher
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
