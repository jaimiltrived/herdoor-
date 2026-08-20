import React from 'react';
import { Store, LayoutGrid, ReceiptText, Clock, Package, User, LogOut, ExternalLink } from 'lucide-react';

export default function Sidebar({ activeTab, onSelectTab }) {
  const navItems = [
    { id: 0, label: 'Dashboard Overview', icon: LayoutGrid },
    { id: 1, label: 'Order Management', icon: ReceiptText, badge: '12' },
    { id: 2, label: 'Order Process History', icon: Clock },
    { id: 3, label: 'Flour & Grain Inventory', icon: Package },
    { id: 4, label: 'Store Profile & Settings', icon: User },
  ];

  return (
    <aside className="desktop-sidebar">
      {/* Brand Title */}
      <div className="sidebar-brand">
        <div className="brand-icon-box">
          <Store size={26} />
        </div>
        <span className="brand-text serif-heading">HerDoor</span>
      </div>

      {/* Navigation List */}
      <nav className="sidebar-nav">
        {navItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;

          return (
            <button
              key={item.id}
              className={`sidebar-nav-item ${isActive ? 'active' : ''}`}
              onClick={() => onSelectTab(item.id)}
            >
              <Icon size={20} />
              <span style={{ flexGrow: 1 }}>{item.label}</span>
              {item.badge && (
                <span
                  style={{
                    backgroundColor: isActive ? 'white' : 'var(--soft-pink)',
                    color: isActive ? 'var(--primary-terracotta)' : 'var(--primary-terracotta)',
                    fontSize: '0.75rem',
                    fontWeight: 800,
                    padding: '2px 8px',
                    borderRadius: 10,
                  }}
                >
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </nav>

      {/* Sidebar Footer Merchant Profile */}
      <div className="sidebar-footer">
        <div className="merchant-profile-widget">
          <img
            src="https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80"
            alt="Sarah Jenkins"
            className="merchant-avatar"
          />
          <div style={{ overflow: 'hidden', flexGrow: 1 }}>
            <div style={{ fontWeight: 800, fontSize: '0.9rem', whiteSpace: 'nowrap', textOverflow: 'ellipsis', overflow: 'hidden' }}>
              Artisan Mill Co.
            </div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
              Sarah Jenkins
            </div>
          </div>
          <button className="icon-btn" title="Log Out" style={{ color: 'var(--primary-terracotta)' }}>
            <LogOut size={18} />
          </button>
        </div>
      </div>
    </aside>
  );
}
