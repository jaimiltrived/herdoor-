import React from 'react';
import { LayoutGrid, ReceiptText, Clock, Package, User } from 'lucide-react';

export default function NavigationBar({ activeTab, onSelectTab }) {
  const tabs = [
    { id: 0, label: 'Dashboard', icon: LayoutGrid },
    { id: 1, label: 'Orders', icon: ReceiptText },
    { id: 2, label: 'Process', icon: Clock },
    { id: 3, label: 'Inventory', icon: Package },
    { id: 4, label: 'Profile', icon: User },
  ];

  return (
    <nav className="nav-pill-bar">
      {tabs.map((tab) => {
        const Icon = tab.icon;
        const isActive = activeTab === tab.id;

        return (
          <button
            key={tab.id}
            className={`nav-item ${isActive ? 'active' : ''}`}
            onClick={() => onSelectTab(tab.id)}
          >
            <Icon size={20} />
            <span>{tab.label}</span>
          </button>
        );
      })}
    </nav>
  );
}
