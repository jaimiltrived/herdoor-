import React, { useState } from 'react';
import { CheckCircle2, X } from 'lucide-react';

export default function AcceptOrderModal({ isOpen, order, onClose, onConfirmAccept }) {
  const [selectedTime, setSelectedTime] = useState('30 Mins');

  if (!isOpen || !order) return null;

  const timeOptions = ['15 Mins', '30 Mins', '45 Mins', '1 Hour'];

  const handleConfirm = () => {
    onConfirmAccept(order.id, selectedTime);
    onClose();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-dialog" onClick={(e) => e.stopPropagation()}>
        <div className="modal-handle"></div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
          <div>
            <h2 className="serif-heading" style={{ fontSize: '1.4rem', fontWeight: 800 }}>
              Accept Order & Set Completion Time
            </h2>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginTop: 4 }}>
              Estimate when order <strong>{order.id}</strong> for {order.customerName} will be ready.
            </p>
          </div>
          <button className="icon-btn" onClick={onClose}><X size={20} /></button>
        </div>

        <div style={{ margin: '20px 0' }}>
          <label style={{ fontSize: '0.85rem', fontWeight: 700, display: 'block', marginBottom: 10 }}>
            Select Estimated Completion Time:
          </label>
          <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
            {timeOptions.map((timeStr) => {
              const isSelected = selectedTime === timeStr;
              return (
                <button
                  key={timeStr}
                  onClick={() => setSelectedTime(timeStr)}
                  style={{
                    padding: '8px 18px',
                    borderRadius: '20px',
                    border: '1px solid ' + (isSelected ? 'var(--primary-terracotta)' : 'var(--border-light)'),
                    backgroundColor: isSelected ? 'var(--primary-terracotta)' : 'var(--surface-cream)',
                    color: isSelected ? 'white' : 'var(--text-primary)',
                    fontWeight: 700,
                    fontSize: '0.85rem',
                    cursor: 'pointer',
                    transition: 'all 0.2s'
                  }}
                >
                  {timeStr}
                </button>
              );
            })}
          </div>
        </div>

        <button className="btn-olive" onClick={handleConfirm} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
          <CheckCircle2 size={18} />
          <span>Confirm Acceptance & Notify Customer</span>
        </button>
      </div>
    </div>
  );
}
