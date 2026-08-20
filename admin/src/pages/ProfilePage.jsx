import React from 'react';
import { Store, Sliders, ShieldCheck, MapPin, CreditCard, QrCode, Bell, LogOut } from 'lucide-react';

export default function ProfilePage({ onOpenAvailabilityModal }) {
  return (
    <div className="profile-page">
      <h1 className="serif-heading" style={{ fontSize: '1.6rem', fontWeight: 800, marginBottom: 16 }}>
        Store Profile & Settings
      </h1>

      {/* Header Card */}
      <div className="card" style={{ padding: 20, display: 'flex', gap: 16, alignItems: 'center' }}>
        <img
          src="https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80"
          alt="Merchant Owner"
          style={{ width: 64, height: 64, borderRadius: '50%', objectFit: 'cover', border: '2px solid var(--primary-terracotta)' }}
        />
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <span className="serif-heading" style={{ fontSize: '1.3rem', fontWeight: 800 }}>Artisan Mill Co.</span>
            <ShieldCheck size={18} color="var(--mustard-gold)" />
          </div>
          <div style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginTop: 2 }}>Owner: Sarah Jenkins</div>
          <span style={{ backgroundColor: '#EDE9D9', color: '#6E5616', fontSize: '0.7rem', fontWeight: 800, padding: '3px 8px', borderRadius: 8, marginTop: 6, display: 'inline-block' }}>
            Verified Merchant
          </span>
        </div>
      </div>

      {/* Settings Options List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        <div
          className="card"
          style={{ padding: 16, display: 'flex', alignItems: 'center', gap: 14, cursor: 'pointer' }}
          onClick={onOpenAvailabilityModal}
        >
          <div style={{ width: 40, height: 40, borderRadius: 10, backgroundColor: 'var(--surface-cream)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-terracotta)' }}>
            <Sliders size={20} />
          </div>
          <div style={{ flexGrow: 1 }}>
            <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>Service Availability & Store Status</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Configure order limits, radius & operating hours</div>
          </div>
        </div>

        <div className="card" style={{ padding: 16, display: 'flex', alignItems: 'center', gap: 14, cursor: 'pointer' }}>
          <div style={{ width: 40, height: 40, borderRadius: 10, backgroundColor: 'var(--surface-cream)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-terracotta)' }}>
            <MapPin size={20} />
          </div>
          <div style={{ flexGrow: 1 }}>
            <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>Store Location & Address</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>124 Heritage Way, Grain District</div>
          </div>
        </div>

        <div className="card" style={{ padding: 16, display: 'flex', alignItems: 'center', gap: 14, cursor: 'pointer' }}>
          <div style={{ width: 40, height: 40, borderRadius: 10, backgroundColor: 'var(--surface-cream)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-terracotta)' }}>
            <CreditCard size={20} />
          </div>
          <div style={{ flexGrow: 1 }}>
            <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>Payout Accounts & Banking</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Direct deposit active (**** 4821)</div>
          </div>
        </div>

        <div className="card" style={{ padding: 16, display: 'flex', alignItems: 'center', gap: 14, cursor: 'pointer' }}>
          <div style={{ width: 40, height: 40, borderRadius: 10, backgroundColor: 'var(--surface-cream)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-terracotta)' }}>
            <QrCode size={20} />
          </div>
          <div style={{ flexGrow: 1 }}>
            <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>QR Code & Bin Management</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Configure pickup bin locations (Bin A-1 to A-8)</div>
          </div>
        </div>

        <div className="card" style={{ padding: 16, display: 'flex', alignItems: 'center', gap: 14, cursor: 'pointer' }}>
          <div style={{ width: 40, height: 40, borderRadius: 10, backgroundColor: 'var(--surface-cream)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-terracotta)' }}>
            <Bell size={20} />
          </div>
          <div style={{ flexGrow: 1 }}>
            <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>Merchant Notifications</div>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Push & SMS alerts enabled</div>
          </div>
        </div>
      </div>

      <button className="btn-outline" style={{ width: '100%', marginTop: 24, padding: 14, borderRadius: 25, color: 'var(--primary-terracotta)', borderColor: 'var(--primary-terracotta)' }}>
        <LogOut size={18} />
        <span>Log Out Merchant Account</span>
      </button>
    </div>
  );
}
