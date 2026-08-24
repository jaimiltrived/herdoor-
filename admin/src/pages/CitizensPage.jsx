import React, { useState } from 'react';
import { Download, Users, UserCheck, Calendar, RotateCcw, Search, Filter, Plus, Pencil, Trash2, X, Check } from 'lucide-react';

export default function CitizensPage() {
  const [citizens, setCitizens] = useState([
    { initials: 'JD', name: 'Jane Doe', id: '#CZ-8921', location: 'North District', orders: 42, contact: 'jane.doe@email.com', status: 'Active', statusBg: '#E8F8F0', statusColor: '#1E8449' },
    { initials: 'AS', name: 'Ahmed Smith', id: '#CZ-7432', location: 'East Valley', orders: 18, contact: 'ahmed.s@provider.net', status: 'Active', statusBg: '#E8F8F0', statusColor: '#1E8449' },
    { initials: 'ML', name: 'Maria Lopez', id: '#CZ-9012', location: 'Westside', orders: 5, contact: 'm.lopez@webmail.com', status: 'Inactive', statusBg: '#F2F4F4', statusColor: '#7F8C8D' },
    { initials: 'RC', name: 'Robert Chen', id: '#CZ-3321', location: 'Central Park', orders: 89, contact: '+1 (555) 012-3456', status: 'VIP', statusBg: '#FBF4DF', statusColor: '#8C6E15' },
  ]);

  const [searchQuery, setSearchQuery] = useState('');
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingIndex, setEditingIndex] = useState(null);

  const [form, setForm] = useState({
    name: '',
    location: '',
    orders: 0,
    contact: '',
    status: 'Active',
  });

  const handleOpenAdd = () => {
    setForm({ name: '', location: '', orders: 0, contact: '', status: 'Active' });
    setIsAddModalOpen(true);
  };

  const handleOpenEdit = (c, idx) => {
    setEditingIndex(idx);
    setForm({
      name: c.name,
      location: c.location,
      orders: c.orders,
      contact: c.contact,
      status: c.status,
    });
    setIsEditModalOpen(true);
  };

  const handleSaveNew = (e) => {
    e.preventDefault();
    const initials = form.name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2) || 'CZ';
    const newId = `#CZ-${Math.floor(1000 + Math.random() * 9000)}`;
    let bg = '#E8F8F0', color = '#1E8449';
    if (form.status === 'VIP') { bg = '#FBF4DF'; color = '#8C6E15'; }
    if (form.status === 'Inactive') { bg = '#F2F4F4'; color = '#7F8C8D'; }

    const newCitizen = {
      initials,
      name: form.name,
      id: newId,
      location: form.location,
      orders: Number(form.orders) || 0,
      contact: form.contact,
      status: form.status,
      statusBg: bg,
      statusColor: color,
    };

    setCitizens([newCitizen, ...citizens]);
    setIsAddModalOpen(false);
  };

  const handleSaveEdit = (e) => {
    e.preventDefault();
    if (editingIndex === null) return;
    let bg = '#E8F8F0', color = '#1E8449';
    if (form.status === 'VIP') { bg = '#FBF4DF'; color = '#8C6E15'; }
    if (form.status === 'Inactive') { bg = '#F2F4F4'; color = '#7F8C8D'; }

    const updated = [...citizens];
    updated[editingIndex] = {
      ...updated[editingIndex],
      name: form.name,
      location: form.location,
      orders: Number(form.orders) || 0,
      contact: form.contact,
      status: form.status,
      statusBg: bg,
      statusColor: color,
    };

    setCitizens(updated);
    setIsEditModalOpen(false);
    setEditingIndex(null);
  };

  const handleDelete = (idx) => {
    if (window.confirm('Delete citizen record?')) {
      setCitizens(citizens.filter((_, i) => i !== idx));
    }
  };

  const filteredCitizens = citizens.filter((c) =>
    c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
    c.location.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="citizens-page-container">
      {/* Page Header */}
      <div className="page-header-flex">
        <div>
          <h1 className="page-title serif-heading">Citizen Management</h1>
          <p className="page-subtitle">Overview of registered customers and their activities.</p>
        </div>
        <div className="page-actions-group">
          <button className="btn-outline btn-with-icon">
            <Download size={16} />
            <span>Export Data</span>
          </button>
          <button className="btn-primary btn-with-icon" style={{ backgroundColor: '#6E5616' }} onClick={handleOpenAdd}>
            <Plus size={16} />
            <span>Add New Citizen</span>
          </button>
        </div>
      </div>

      {/* 4 Top Metric Cards */}
      <div className="metrics-grid-4" style={{ marginBottom: '28px' }}>
        <div className="metric-card">
          <div className="metric-header-row">
            <span className="metric-label">TOTAL CITIZENS</span>
            <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#F7F2EB', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Users size={16} color="#756D69" />
            </div>
          </div>
          <div className="metric-value-row">
            <span className="metric-value">{citizens.length * 3112 + 10}</span>
          </div>
          <div className="metric-footer-row">
            <span className="trend-badge positive" style={{ fontSize: '0.78rem' }}>
              ↑ +5.2% from last month
            </span>
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-header-row">
            <span className="metric-label">ACTIVE MONTHLY</span>
            <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#F7F2EB', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <UserCheck size={16} color="#756D69" />
            </div>
          </div>
          <div className="metric-value-row">
            <span className="metric-value">8,102</span>
          </div>
          <div className="metric-footer-row">
            <span className="trend-badge positive" style={{ fontSize: '0.78rem' }}>
              ↑ +2.1% from last month
            </span>
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-header-row">
            <span className="metric-label">AVG. ORDER FREQUENCY</span>
            <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#F7F2EB', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Calendar size={16} color="#756D69" />
            </div>
          </div>
          <div className="metric-value-row">
            <span className="metric-value">2.4</span>
          </div>
          <div className="metric-footer-row">
            <span style={{ fontSize: '0.78rem', color: '#756D69' }}>
              Orders per month
            </span>
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-header-row">
            <span className="metric-label">RETENTION RATE</span>
            <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: '#F7F2EB', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <RotateCcw size={16} color="#756D69" />
            </div>
          </div>
          <div className="metric-value-row">
            <span className="metric-value">78%</span>
          </div>
          <div className="metric-footer-row">
            <span className="trend-badge positive" style={{ fontSize: '0.78rem' }}>
              ↑ +1.5% from last month
            </span>
          </div>
        </div>
      </div>

      {/* Main Grid: Left Citizen Directory, Right Trend & Heatmap */}
      <div className="citizens-main-grid" style={{ display: 'grid', gridTemplateColumns: '1fr 340px', gap: '24px' }}>
        {/* Left Directory Card */}
        <div className="card citizen-directory-card">
          <div className="card-header-flex" style={{ marginBottom: '20px' }}>
            <h2 className="card-title">Citizen Directory</h2>
            <div style={{ display: 'flex', gap: '10px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', background: '#FAF6F0', padding: '6px 14px', borderRadius: '20px', border: '1px solid #ECE4D9' }}>
                <Search size={14} color="#756D69" />
                <input
                  placeholder="Search name or ID..."
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
                  <th>Citizen</th>
                  <th>Location / City</th>
                  <th>Orders</th>
                  <th>Contact</th>
                  <th>Status</th>
                  <th style={{ textAlign: 'right' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredCitizens.map((c, idx) => (
                  <tr key={idx}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: '#CBA034', color: 'white', fontWeight: 800, fontSize: '0.85rem', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          {c.initials}
                        </div>
                        <div>
                          <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>{c.name}</div>
                          <div style={{ fontSize: '0.75rem', color: '#756D69', fontFamily: 'monospace' }}>ID: {c.id}</div>
                        </div>
                      </div>
                    </td>
                    <td style={{ fontWeight: 600 }}>{c.location}</td>
                    <td style={{ fontWeight: 700 }}>{c.orders}</td>
                    <td style={{ color: '#756D69', fontSize: '0.85rem' }}>{c.contact}</td>
                    <td>
                      <span className="tag-pill" style={{ background: c.statusBg, color: c.statusColor, padding: '4px 12px', borderRadius: '12px' }}>
                        {c.status}
                      </span>
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: '8px' }}>
                        <button
                          className="btn-outline"
                          style={{ padding: '6px 10px', borderRadius: '8px', fontSize: '0.78rem' }}
                          onClick={() => handleOpenEdit(c, idx)}
                          title="Edit Citizen"
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
                          title="Delete Citizen"
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

        {/* Right Cards: Acquisition Trend & Geographic Heatmap */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          {/* Acquisition Trend Card */}
          <div className="card">
            <h3 className="card-title" style={{ fontSize: '0.9rem', letterSpacing: '0.5px', textTransform: 'uppercase', marginBottom: '14px' }}>Acquisition Trend</h3>
            <svg viewBox="0 0 300 120" style={{ width: '100%', height: '120px' }}>
              <path d="M 10,90 Q 60,70 110,80 T 210,40 T 290,20" fill="none" stroke="#6E5616" strokeWidth="2.5" />
              <circle cx="290" cy="20" r="4" fill="#6E5616" />
            </svg>
          </div>

          {/* Geographic Heatmap Card */}
          <div className="card">
            <h3 className="card-title" style={{ fontSize: '0.9rem', letterSpacing: '0.5px', textTransform: 'uppercase', marginBottom: '14px' }}>Geographic Heatmap</h3>
            <div style={{ height: '140px', background: '#F3EBE1', borderRadius: '14px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#756D69', fontSize: '0.85rem', textAlign: 'center', padding: '16px' }}>
              Map data visualization active for HerDoor Service Areas.
            </div>
            <div style={{ marginTop: '16px', display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '0.85rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>🟡 North District</span><b>45%</b></div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>🔴 South Valley</span><b>30%</b></div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}><span>🟢 East Side</span><b>25%</b></div>
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
                Register New Citizen
              </h2>
              <button className="icon-btn" onClick={() => setIsAddModalOpen(false)}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveNew}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '24px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Full Name
                  </label>
                  <input
                    type="text" required
                    value={form.name}
                    onChange={(e) => setForm({ ...form, name: e.target.value })}
                    placeholder="e.g. Sarah Connor"
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Location / City
                  </label>
                  <input
                    type="text" required
                    value={form.location}
                    onChange={(e) => setForm({ ...form, location: e.target.value })}
                    placeholder="e.g. North District"
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Contact Email or Phone
                  </label>
                  <input
                    type="text" required
                    value={form.contact}
                    onChange={(e) => setForm({ ...form, contact: e.target.value })}
                    placeholder="sarah@email.com or +1 555-0192"
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
                    <option value="VIP">VIP</option>
                    <option value="Inactive">Inactive</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" className="btn-outline" onClick={() => setIsAddModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn-primary" style={{ backgroundColor: '#6E5616' }}>
                  <Check size={16} /> Save Citizen
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
                Edit Citizen Profile
              </h2>
              <button className="icon-btn" onClick={() => setIsEditModalOpen(false)}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveEdit}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '24px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Full Name
                  </label>
                  <input
                    type="text" required
                    value={form.name}
                    onChange={(e) => setForm({ ...form, name: e.target.value })}
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Location / City
                  </label>
                  <input
                    type="text" required
                    value={form.location}
                    onChange={(e) => setForm({ ...form, location: e.target.value })}
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Contact
                  </label>
                  <input
                    type="text" required
                    value={form.contact}
                    onChange={(e) => setForm({ ...form, contact: e.target.value })}
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
                    <option value="VIP">VIP</option>
                    <option value="Inactive">Inactive</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" className="btn-outline" onClick={() => setIsEditModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn-primary" style={{ backgroundColor: '#6E5616' }}>
                  <Check size={16} /> Update Profile
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
