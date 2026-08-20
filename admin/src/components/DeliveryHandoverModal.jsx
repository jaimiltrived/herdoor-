import React, { useState } from 'react';
import { Truck, Phone, QrCode, CheckCircle2, X } from 'lucide-react';

export default function DeliveryHandoverModal({ isOpen, order, onClose, onConfirmDispatch }) {
  const [pin, setPin] = useState('4821');
  const [isDone, setIsDone] = useState(false);

  if (!isOpen || !order) return null;

  const handleDispatch = () => {
    setIsDone(true);
    setTimeout(() => {
      onConfirmDispatch(order.id);
      setIsDone(false);
      onClose();
    }, 1500);
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-dialog" onClick={(e) => e.stopPropagation()}>
        <div className="modal-handle"></div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
          <div>
            <h2 className="serif-heading" style={{ fontSize: '1.35rem', fontWeight: 800 }}>
              Handover to Delivery Person
            </h2>
            <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
              Verify driver PIN or scan QR code for order {order.id}.
            </p>
          </div>
          <button className="icon-btn" onClick={onClose}><X size={20} /></button>
        </div>

        {/* Pickup & Bin Banner */}
        <div style={{ backgroundColor: 'var(--soft-pink)', padding: 14, borderRadius: 16, display: 'flex', alignItems: 'center', gap: 14, marginBottom: 16 }}>
          <div style={{ width: 42, height: 42, borderRadius: '50%', backgroundColor: '#FFB3AC', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-terracotta)' }}>
            <Truck size={22} />
          </div>
          <div style={{ flexGrow: 1 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--primary-terracotta)' }}>{order.id}</span>
              <span style={{ backgroundColor: 'var(--primary-terracotta)', color: 'white', fontSize: '0.7rem', fontWeight: 800, padding: '2px 8px', borderRadius: 6 }}>
                {order.binLocation || 'Bin A-4'}
              </span>
            </div>
            <div style={{ fontWeight: 800, fontSize: '1rem', marginTop: 2 }}>{order.customerName}</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>{order.itemsSummary}</div>
          </div>
        </div>

        {/* Assigned Driver Card */}
        <div style={{ backgroundColor: 'white', border: '1px solid var(--border-light)', borderRadius: 16, padding: 14, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 12 }}>
          <img
            src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80"
            alt="Driver"
            style={{ width: 48, height: 48, borderRadius: '50%', objectFit: 'cover', border: '2px solid var(--mustard-dark)' }}
          />
          <div style={{ flexGrow: 1 }}>
            <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>{order.driverName || 'Rajesh Kumar'}</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>{order.driverVehicle || 'Electric Bike #EB-4821'}</div>
            <div style={{ fontSize: '0.75rem', color: '#2ECC71', fontWeight: 700, marginTop: 2 }}>● Arrived at Store Bin A-4</div>
          </div>
          <button className="icon-btn" style={{ backgroundColor: 'var(--surface-cream)', padding: 10 }}>
            <Phone size={18} color="var(--mustard-dark)" />
          </button>
        </div>

        {/* QR Code Scanner Box Simulation */}
        <div style={{ textAlign: 'center', backgroundColor: 'var(--surface-warm)', padding: 18, borderRadius: 16, border: '2px dashed var(--primary-terracotta)', marginBottom: 20 }}>
          <div style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
            <QrCode size={110} color="var(--primary-terracotta)" />
            {isDone && (
              <div style={{ position: 'absolute', inset: 0, backgroundColor: 'rgba(46, 204, 113, 0.9)', borderRadius: 12, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: 'white' }}>
                <CheckCircle2 size={48} />
                <span style={{ fontWeight: 800, fontSize: '0.85rem', marginTop: 4 }}>VERIFIED</span>
              </div>
            )}
          </div>
          <div style={{ marginTop: 12, fontSize: '0.8rem', fontWeight: 600, color: 'var(--text-secondary)' }}>
            Scan Driver QR Code or Enter PIN:
          </div>
          <input
            type="text"
            value={pin}
            onChange={(e) => setPin(e.target.value)}
            style={{ marginTop: 8, padding: '6px 14px', borderRadius: 8, border: '1px solid var(--border-light)', textAlign: 'center', fontWeight: 800, fontSize: '1.1rem', letterSpacing: 3, width: 100 }}
          />
        </div>

        <button
          className="btn-primary"
          onClick={handleDispatch}
          disabled={isDone}
          style={{ width: '100%', padding: 14, backgroundColor: isDone ? '#2ECC71' : 'var(--primary-terracotta)' }}
        >
          <Truck size={18} />
          <span>{isDone ? 'Handover Dispatched!' : 'Confirm Handover & Dispatch Order'}</span>
        </button>
      </div>
    </div>
  );
}
