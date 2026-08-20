import React from 'react';
import { Search, Bell, Sliders, Store, UserCheck } from 'lucide-react';

export default function DesktopHeader({ shopStatus, onToggleShopStatus, onOpenAvailabilityModal }) {
  return (
    <header className="desktop-top-header">
      {/* Search Input Bar */}
      <div className="search-bar-box">
        <Search size={18} color="var(--text-secondary)" />
        <input type="text" placeholder="Search orders (#HD-1042), customer name, or flour item..." />
      </div>

      {/* Header Right Actions */}
      <div className="header-right-actions">
        {/* Shop Status Toggle Button */}
        <button
          className="btn-outline"
          onClick={onOpenAvailabilityModal}
          style={{
            backgroundColor: shopStatus ? '#E8F8F0' : '#F2F4F4',
            borderColor: shopStatus ? '#2ECC71' : '#95A5A6',
            color: shopStatus ? '#1E8449' : '#7F8C8D',
            padding: '8px 18px',
          }}
        >
          <span className={shopStatus ? 'green-dot' : 'grey-dot'}></span>
          <span style={{ fontWeight: 800 }}>{shopStatus ? 'Accepting Orders' : 'Shop Closed'}</span>
        </button>

        {/* Quick Settings Launcher */}
        <button
          className="btn-outline"
          onClick={onOpenAvailabilityModal}
          title="Configure Service Radius & Hours"
        >
          <Sliders size={16} />
          <span>Settings</span>
        </button>

        {/* Notification Bell */}
        <button className="icon-btn notification-badge-wrapper" title="3 New Notifications">
          <Bell size={22} />
          <span className="red-dot"></span>
        </button>
      </div>
    </header>
  );
}
