import React from 'react';
import { Search, Bell, HelpCircle, Moon } from 'lucide-react';

export default function DesktopHeader() {
  return (
    <header className="super-admin-top-header">
      {/* Search Input Bar matching Image 1 */}
      <div className="search-pill-container">
        <Search size={18} color="#756D69" />
        <input
          type="text"
          placeholder="Search ledger, transactions..."
          className="search-input-field"
        />
      </div>

      {/* Header Right Actions matching Image 1 */}
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

        {/* User Profile Avatar */}
        <div className="header-user-avatar-box">
          <img
            src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80"
            alt="User Avatar"
            className="header-avatar-img"
          />
        </div>
      </div>
    </header>
  );
}
