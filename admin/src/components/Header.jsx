import React from 'react';
import { Menu, Bell, Store } from 'lucide-react';

export default function Header({ shopStatus, onToggleShopStatus, onOpenAvailabilityModal }) {
  return (
    <header className="admin-header">
      <div className="header-left">
        <button className="icon-btn" title="Toggle Menu" onClick={onOpenAvailabilityModal}>
          <Menu size={24} />
        </button>
        <span className="brand-title serif-heading">HerDoor Merchant</span>
      </div>

      <div className="header-right">
        <button className="icon-btn notification-badge-wrapper" title="Notifications">
          <Bell size={22} />
          <span className="red-dot"></span>
        </button>

        <button 
          className="btn-outline" 
          onClick={onOpenAvailabilityModal}
          style={{ padding: '6px 14px', fontSize: '0.8rem', borderRadius: '20px' }}
        >
          <Store size={15} />
          <span>{shopStatus ? 'Accepting' : 'Closed'}</span>
        </button>
      </div>
    </header>
  );
}
