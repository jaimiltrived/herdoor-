import React, { useState } from 'react';
import { Search, Bell, HelpCircle, Moon, LogOut, Shield } from 'lucide-react';

export default function DesktopHeader({ currentUser, onLogout }) {
  const [showDropdown, setShowDropdown] = useState(false);
  const user = currentUser || { name: 'Super Admin', email: 'admin@herdoor.com', role: 'ADMIN' };

  return (
    <header className="super-admin-top-header">
      {/* Search Input Bar */}
      <div className="search-pill-container">
        <Search size={18} color="#756D69" />
        <input
          type="text"
          placeholder="Search ledger, transactions, mills, riders..."
          className="search-input-field"
        />
      </div>

      {/* Header Right Actions */}
      <div className="header-right-tools">
        {/* Notification Bell */}
        <button className="icon-btn notification-wrapper" title="Notifications">
          <Bell size={20} color="#2A2421" />
          <span className="notification-dot"></span>
        </button>

        {/* Help Circle */}
        <button className="icon-btn" title="Help & Support">
          <HelpCircle size={20} color="#2A2421" />
        </button>

        {/* Dark Mode Moon Icon */}
        <button className="icon-btn" title="Toggle Dark Mode">
          <Moon size={20} color="#2A2421" />
        </button>

        {/* User Profile Avatar with Dropdown */}
        <div style={{ position: 'relative' }}>
          <div
            className="header-user-avatar-box"
            onClick={() => setShowDropdown(!showDropdown)}
            style={{ cursor: 'pointer' }}
            title={`${user.name} (${user.email})`}
          >
            <img
              src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80"
              alt="User Avatar"
              className="header-avatar-img"
            />
          </div>

          {showDropdown && (
            <div
              style={{
                position: 'absolute',
                top: '100%',
                right: 0,
                marginTop: 8,
                width: 220,
                background: '#FFFFFF',
                borderRadius: 14,
                boxShadow: '0 10px 25px -5px rgba(0,0,0,0.15), 0 0 0 1px rgba(0,0,0,0.05)',
                padding: 12,
                zIndex: 100,
              }}
            >
              <div style={{ paddingBottom: 8, borderBottom: '1px solid #F0EAE1', marginBottom: 8 }}>
                <div style={{ fontWeight: 800, fontSize: '0.88rem', color: '#2A2421' }}>{user.name}</div>
                <div style={{ fontSize: '0.74rem', color: '#756D69' }}>{user.email}</div>
                <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, marginTop: 4, padding: '2px 8px', borderRadius: 12, background: '#FAF3EA', color: '#B25036', fontSize: '0.68rem', fontWeight: 800 }}>
                  <Shield size={10} />
                  <span>{user.role}</span>
                </div>
              </div>
              <button
                onClick={() => {
                  setShowDropdown(false);
                  onLogout?.();
                }}
                style={{
                  width: '100%',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  padding: '8px 10px',
                  border: 'none',
                  borderRadius: 8,
                  background: '#FDF2F2',
                  color: '#C0392B',
                  fontWeight: 700,
                  fontSize: '0.82rem',
                  cursor: 'pointer',
                  transition: 'background 0.15s ease',
                }}
              >
                <LogOut size={15} />
                <span>Sign Out of Portal</span>
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
