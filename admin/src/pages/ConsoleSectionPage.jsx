import React, { useState, useEffect } from 'react';
import { Search, Filter, Plus, Pencil, Trash2, X, Check } from 'lucide-react';

export default function ConsoleSectionPage({ title, description, icon: IconComponent, stats = [], tableHeaders = [], tableData = [] }) {
  const [items, setItems] = useState(tableData);
  const [searchQuery, setSearchQuery] = useState('');

  // Modal States
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingIndex, setEditingIndex] = useState(null);

  // Form States
  const [formData, setFormData] = useState({});

  useEffect(() => {
    setItems(tableData);
  }, [tableData]);

  // Handle opening Add Modal
  const handleOpenAddModal = () => {
    const initialForm = {};
    tableHeaders.forEach((header) => {
      initialForm[header] = '';
    });
    setFormData(initialForm);
    setIsAddModalOpen(true);
  };

  // Handle opening Edit Modal
  const handleOpenEditModal = (row, index) => {
    setEditingIndex(index);
    const formObj = {};
    tableHeaders.forEach((header, colIdx) => {
      const keys = Object.keys(row);
      formObj[header] = row[keys[colIdx]] || '';
    });
    setFormData(formObj);
    setIsEditModalOpen(true);
  };

  // Save new record
  const handleSaveNew = (e) => {
    e.preventDefault();
    const newRow = {};
    tableHeaders.forEach((header, idx) => {
      newRow[`col_${idx}`] = formData[header] || 'N/A';
    });
    setItems([newRow, ...items]);
    setIsAddModalOpen(false);
  };

  // Save edited record
  const handleSaveEdit = (e) => {
    e.preventDefault();
    if (editingIndex === null) return;
    const updatedRow = {};
    tableHeaders.forEach((header, idx) => {
      updatedRow[`col_${idx}`] = formData[header] || 'N/A';
    });

    const newItems = [...items];
    newItems[editingIndex] = updatedRow;
    setItems(newItems);
    setIsEditModalOpen(false);
    setEditingIndex(null);
  };

  // Delete record
  const handleDelete = (index) => {
    if (window.confirm('Are you sure you want to delete this record?')) {
      setItems(items.filter((_, idx) => idx !== index));
    }
  };

  // Filter items by search query
  const filteredItems = items.filter((row) => {
    if (!searchQuery) return true;
    return Object.values(row).some((val) =>
      String(val).toLowerCase().includes(searchQuery.toLowerCase())
    );
  });

  return (
    <div className="console-section-container">
      {/* Section Header */}
      <div className="page-header-flex">
        <div>
          <h1 className="page-title serif-heading">{title}</h1>
          <p className="page-subtitle">{description}</p>
        </div>
        <div className="page-actions-group">
          <button
            className="btn-primary btn-with-icon"
            style={{ backgroundColor: '#8C4A3E' }}
            onClick={handleOpenAddModal}
          >
            <Plus size={16} />
            <span>Add New {title.replace(/s$/, '')}</span>
          </button>
        </div>
      </div>

      {/* Stats row if provided */}
      {stats.length > 0 && (
        <div className="metrics-grid-4" style={{ marginBottom: '28px' }}>
          {stats.map((s, idx) => (
            <div className="metric-card" key={idx}>
              <span className="metric-label">{s.label}</span>
              <div className="metric-value" style={{ fontSize: '2rem', fontWeight: 800, marginTop: '4px' }}>
                {s.value}
              </div>
              <span
                className={`trend-badge ${s.isPositive ? 'positive' : 'info'}`}
                style={{ fontSize: '0.78rem', marginTop: '6px', display: 'inline-flex' }}
              >
                {s.change}
              </span>
            </div>
          ))}
        </div>
      )}

      {/* Main Table Card */}
      <div className="card">
        <div className="card-header-flex" style={{ marginBottom: '20px' }}>
          <h2 className="card-title">{title} Records</h2>
          <div style={{ display: 'flex', gap: '10px' }}>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                background: '#FAF6F0',
                padding: '6px 14px',
                borderRadius: '20px',
                border: '1px solid #ECE4D9',
              }}
            >
              <Search size={14} color="#756D69" />
              <input
                placeholder={`Search ${title.toLowerCase()}...`}
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
                {tableHeaders.map((h, i) => (
                  <th key={i}>{h}</th>
                ))}
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredItems.length === 0 ? (
                <tr>
                  <td colSpan={tableHeaders.length + 1} style={{ textAlign: 'center', color: '#756D69', padding: '24px' }}>
                    No records found. Click "+ Add New" to create one.
                  </td>
                </tr>
              ) : (
                filteredItems.map((row, i) => (
                  <tr key={i}>
                    {Object.values(row).map((val, cellIdx) => (
                      <td key={cellIdx} style={{ fontWeight: cellIdx === 0 ? 700 : 500 }}>
                        {val}
                      </td>
                    ))}
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: '8px' }}>
                        <button
                          className="btn-outline"
                          style={{ padding: '6px 10px', borderRadius: '8px', fontSize: '0.78rem' }}
                          title="Edit Record"
                          onClick={() => handleOpenEditModal(row, i)}
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
                          title="Delete Record"
                          onClick={() => handleDelete(i)}
                        >
                          <Trash2 size={13} color="#C0392B" />
                          <span>Delete</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add New Record Modal */}
      {isAddModalOpen && (
        <div className="modal-overlay">
          <div className="modal-dialog">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2 className="serif-heading" style={{ fontSize: '1.4rem', fontWeight: 800 }}>
                Add New {title.replace(/s$/, '')}
              </h2>
              <button className="icon-btn" onClick={() => setIsAddModalOpen(false)}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveNew}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '24px' }}>
                {tableHeaders.map((header, idx) => (
                  <div key={idx}>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      {header}
                    </label>
                    <input
                      type="text"
                      required
                      value={formData[header] || ''}
                      onChange={(e) => setFormData({ ...formData, [header]: e.target.value })}
                      placeholder={`Enter ${header.toLowerCase()}...`}
                      style={{
                        width: '100%',
                        padding: '10px 14px',
                        borderRadius: '12px',
                        border: '1px solid var(--border-light)',
                        outline: 'none',
                        fontSize: '0.9rem',
                      }}
                    />
                  </div>
                ))}
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" className="btn-outline" onClick={() => setIsAddModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn-primary" style={{ backgroundColor: '#8C4A3E' }}>
                  <Check size={16} />
                  <span>Save Record</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Record Modal */}
      {isEditModalOpen && (
        <div className="modal-overlay">
          <div className="modal-dialog">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2 className="serif-heading" style={{ fontSize: '1.4rem', fontWeight: 800 }}>
                Edit Record Details
              </h2>
              <button className="icon-btn" onClick={() => setIsEditModalOpen(false)}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveEdit}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '24px' }}>
                {tableHeaders.map((header, idx) => (
                  <div key={idx}>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      {header}
                    </label>
                    <input
                      type="text"
                      required
                      value={formData[header] || ''}
                      onChange={(e) => setFormData({ ...formData, [header]: e.target.value })}
                      style={{
                        width: '100%',
                        padding: '10px 14px',
                        borderRadius: '12px',
                        border: '1px solid var(--border-light)',
                        outline: 'none',
                        fontSize: '0.9rem',
                      }}
                    />
                  </div>
                ))}
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" className="btn-outline" onClick={() => setIsEditModalOpen(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn-primary" style={{ backgroundColor: '#6E5616' }}>
                  <Check size={16} />
                  <span>Update Record</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
