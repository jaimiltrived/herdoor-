import React from 'react';
import {
  LayoutGrid,
  Store,
  Users,
  Truck,
  Building2,
  ShoppingBag,
  Bike,
  Headphones,
  Percent,
  Wallet,
  Landmark,
  Shield,
  ShieldAlert,
  RotateCcw,
  UserCheck,
  BarChart3,
  Gift,
  LogOut
} from 'lucide-react';

export default function Sidebar({ activeTab, onSelectTab }) {
  const navItems = [
    { id: 0, label: 'Dashboard', icon: LayoutGrid },
    { id: 1, label: 'Flour Mills', icon: Store },
    { id: 2, label: 'Citizens', icon: Users },
    { id: 3, label: 'Delivery Partners', icon: Truck },
    { id: 4, label: 'Wholesalers', icon: Building2 },
    { id: 5, label: 'Orders', icon: ShoppingBag },
    { id: 6, label: 'Riders', icon: Bike },
    { id: 7, label: 'Support', icon: Headphones },
    { id: 8, label: 'Commissions', icon: Percent },
    { id: 9, label: 'Withdrawals', icon: Wallet },
    { id: 10, label: 'Accounting', icon: Landmark },
    { id: 11, label: 'Security', icon: Shield },
    { id: 12, label: 'Fraud Monitor', icon: ShieldAlert },
    { id: 13, label: 'Refunds', icon: RotateCcw },
    { id: 14, label: 'Admins', icon: UserCheck },
    { id: 15, label: 'Analytics', icon: BarChart3 },
    { id: 16, label: 'Gift & Vouchers', icon: Gift },
  ];

  return (
    <aside className="super-admin-sidebar">
      {/* Brand & Console Title */}
      <div className="sidebar-brand-header">
        <div className="brand-avatar-box">
          <img
            src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80"
            alt="Super Admin"
            className="brand-avatar-img"
          />
        </div>
        <div className="brand-title-group">
          <h2 className="brand-main-title serif-heading">HerDoor Portal</h2>
          <span className="brand-subtitle">Super Admin Console</span>
        </div>
      </div>

      {/* Navigation List */}
      <nav className="sidebar-nav-list">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;

          return (
            <button
              key={item.id}
              className={`sidebar-item ${isActive ? 'active-pill' : ''}`}
              onClick={() => onSelectTab(item.id)}
            >
              <Icon size={18} className="sidebar-item-icon" />
              <span className="sidebar-item-label">{item.label}</span>
              {isActive && <div className="active-indicator-bar"></div>}
            </button>
          );
        })}
      </nav>

      {/* Sidebar Footer User Info */}
      <div className="sidebar-footer-profile">
        <div className="profile-widget">
          <img
            src="https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80"
            alt="Admin Avatar"
            className="footer-avatar"
          />
          <div className="profile-text">
            <span className="profile-name">Super Admin</span>
            <span className="profile-role">Platform Lead</span>
          </div>
          <button className="icon-btn logout-btn" title="Log Out">
            <LogOut size={16} />
          </button>
        </div>
      </div>
    </aside>
  );
}
