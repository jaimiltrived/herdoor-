import React, { useState } from 'react';
import { Store, Sliders, Check, X } from 'lucide-react';

export default function ServiceAvailabilityModal({ isOpen, onClose, shopStatus, onToggleShopStatus }) {
  const [radius, setRadius] = useState(5.0);
  const [statusMode, setStatusMode] = useState(shopStatus ? 0 : 2); // 0: Accepting, 1: High Demand, 2: Closed

  if (!isOpen) return null;

  const handleSave = () => {
    onToggleShopStatus(statusMode !== 2);
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-dialog" onClick={(e) => e.stopPropagation()}>
        <div className="modal-handle"></div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
          <div>
            <h2 className="serif-heading" style={{ fontSize: '1.35rem', fontWeight: 800 }}>
              Service Availability & Store Settings
            </h2>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
              Configure store operation limits, delivery radius & hours.
            </p>
          </div>
          <button className="icon-btn" onClick={onClose}><X size={20} /></button>
        </div>

        {/* Operating Status Selector */}
        <div style={{ marginBottom: 20 }}>
          <label style={{ fontSize: '0.85rem', fontWeight: 700, display: 'block', marginBottom: 8 }}>
            Store Operating Mode:
          </label>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10, backgroundColor: 'white', padding: 14, borderRadius: 16, border: '1px solid var(--border-light)' }}>
            {[
              { id: 0, title: 'Accepting Orders', desc: 'Normal store operations', color: '#2ECC71' },
              { id: 1, title: 'High Demand (Busy)', desc: 'Adds +20 mins buffer time to orders', color: '#F39C12' },
              { id: 2, title: 'Shop Closed', desc: 'Pause incoming customer requests', color: '#95A5A6' },
            ].map((item) => (
              <div
                key={item.id}
                onClick={() => setStatusMode(item.id)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justify: 'space-between',
                  padding: 10,
                  borderRadius: 12,
                  backgroundColor: statusMode === item.id ? 'var(--surface-cream)' : 'transparent',
                  cursor: 'pointer'
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <div style={{ width: 12, height: 12, borderRadius: '50%', backgroundColor: item.color }}></div>
                  <div>
                    <div style={{ fontWeight: 700, fontSize: '0.9rem' }}>{item.title}</div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>{item.desc}</div>
                  </div>
                </div>
                {statusMode === item.id && <Check size={18} color="var(--primary-terracotta)" />}
              </div>
            ))}
          </div>
        </div>

        {/* Delivery Radius Slider */}
        <div style={{ marginBottom: 24, backgroundColor: 'white', padding: 16, borderRadius: 16, border: '1px solid var(--border-light)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
            <span style={{ fontSize: '0.85rem', fontWeight: 700 }}>Coverage Radius:</span>
            <span style={{ backgroundColor: 'var(--mustard-dark)', color: 'white', fontWeight: 800, fontSize: '0.8rem', padding: '2px 10px', borderRadius: 10 }}>
              {radius.toFixed(1)} km
            </span>
          </div>
          <input
            type="range"
            min="1"
            max="15"
            step="0.5"
            value={radius}
            onChange={(e) => setRadius(parseFloat(e.target.value))}
            style={{ width: '100%', accentColor: 'var(--mustard-dark)', cursor: 'pointer' }}
          />
          <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', marginTop: 6 }}>
            Customers outside this range will be notified of radius restrictions.
          </div>
        </div>

        <button className="btn-olive" onClick={handleSave} style={{ width: '100%', padding: 14 }}>
          Save Availability Settings
        </button>
      </div>
    </div>
  );
}
