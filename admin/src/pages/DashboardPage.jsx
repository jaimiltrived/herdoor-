import React from 'react';
import { Clock, ShieldCheck, ChevronRight, ArrowUpRight, Truck, Eye, CheckCircle2, UserCheck } from 'lucide-react';
import { pendingRequests } from '../data/mockData';

export default function DashboardPage({
  orders,
  shopStatus,
  onToggleShopStatus,
  onOpenAcceptModal,
  onSelectOrderDetails,
  onNavigateTab,
}) {
  return (
    <div className="dashboard-page">
      {/* Hero Banner Header */}
      <div
        style={{
          backgroundColor: 'var(--surface-warm)',
          borderRadius: 20,
          padding: '24px 28px',
          marginBottom: 28,
          display: 'flex',
          justify: 'space-between',
          alignItems: 'center',
          border: '1px solid var(--border-light)',
        }}
      >
        <div>
          <h1 className="serif-heading" style={{ fontSize: '1.7rem', fontWeight: 800, color: 'var(--text-primary)' }}>
            Welcome back, Artisan Mill Co. 👋
          </h1>
          <p style={{ fontSize: '0.9rem', color: 'var(--text-secondary)', marginTop: 4 }}>
            Live Store Management Dashboard • You have <strong>12 pending order requests</strong> waiting for acceptance today.
          </p>
        </div>
        <button className="btn-primary" onClick={() => onNavigateTab(1)}>
          <span>Open Order Control Center</span>
          <ChevronRight size={18} />
        </button>
      </div>

      {/* Top Banner Stats Grid (4 Widescreen Columns) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: 20, marginBottom: 28 }}>
        {/* Shop Status Card */}
        <div className="card shop-status-card">
          <div className="status-header">
            <div>
              <div className="status-title">Shop Operating Status</div>
              <div className="status-indicator" style={{ marginTop: 4 }}>
                <span className={shopStatus ? 'green-dot' : 'grey-dot'}></span>
                <span>{shopStatus ? 'Accepting Orders' : 'Shop Closed'}</span>
              </div>
            </div>

            <label className="switch">
              <input
                type="checkbox"
                checked={shopStatus}
                onChange={(e) => onToggleShopStatus(e.target.checked)}
              />
              <span className="slider"></span>
            </label>
          </div>

          <div className="hours-box">
            <div className="clock-icon-bg">
              <Clock size={18} />
            </div>
            <div>
              <div style={{ fontSize: '0.7rem', color: 'var(--text-secondary)' }}>Today's Hours</div>
              <div style={{ fontSize: '0.95rem', fontWeight: 800, color: 'var(--text-primary)' }}>
                8:00 AM - 6:00 PM
              </div>
            </div>
          </div>
        </div>

        {/* New Orders Stats Widget */}
        <div className="card new-orders-card">
          <div className="stats-top">
            <div className="pink-icon-bg">
              <ShieldCheck size={22} />
            </div>
            <span className="badge-tag">+3 New</span>
          </div>

          <div>
            <div className="stat-number">12</div>
            <div className="stat-label">New Orders Waiting</div>
          </div>
        </div>

        {/* Today's Sales Revenue */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Today's Sales</span>
            <span style={{ backgroundColor: '#E8F8F0', color: '#1E8449', fontSize: '0.75rem', fontWeight: 800, padding: '4px 10px', borderRadius: 12, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              <ArrowUpRight size={14} />
              +18.4%
            </span>
          </div>
          <div>
            <div style={{ fontSize: '2.4rem', fontWeight: 800, fontFamily: 'Playfair Display, serif' }}>$482.50</div>
            <div style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>24 Orders Processed</div>
          </div>
        </div>

        {/* Delivery Partner Status Card */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Dispatch Partners</span>
            <span style={{ backgroundColor: 'var(--surface-cream)', color: 'var(--mustard-dark)', fontSize: '0.75rem', fontWeight: 800, padding: '4px 10px', borderRadius: 12 }}>
              4 Online
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 10 }}>
            <div style={{ width: 42, height: 42, borderRadius: 12, backgroundColor: 'var(--soft-pink)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-terracotta)' }}>
              <Truck size={22} />
            </div>
            <div>
              <div style={{ fontWeight: 800, fontSize: '1rem' }}>Bin Pickup Active</div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Bin A-1 to Bin A-8</div>
            </div>
          </div>
        </div>
      </div>

      {/* Desktop Web Operations Data Table */}
      <div className="table-card-container">
        <div className="desktop-table-header">
          <div>
            <h2 className="serif-heading" style={{ fontSize: '1.35rem', fontWeight: 800 }}>
              Active Processing Queue & Orders
            </h2>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: 2 }}>
              Real-time milling & delivery status control table.
            </div>
          </div>
          <button className="btn-outline" onClick={() => onNavigateTab(1)}>
            <span>View Full Control Center</span>
            <ChevronRight size={16} />
          </button>
        </div>

        <table className="desktop-data-table">
          <thead>
            <tr>
              <th>Order ID</th>
              <th>Customer Name</th>
              <th>Items & Specs</th>
              <th>Status</th>
              <th>Order Time</th>
              <th style={{ textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((ord) => (
              <tr key={ord.id}>
                <td style={{ fontWeight: 800, fontFamily: 'Playfair Display, serif', fontSize: '1.05rem', color: 'var(--primary-terracotta)' }}>
                  {ord.id}
                </td>
                <td>
                  <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>{ord.customerName}</div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>Bin: {ord.binLocation || 'Bin A-4'}</div>
                </td>
                <td>
                  <div style={{ fontWeight: 600, fontSize: '0.9rem' }}>{ord.itemsSummary}</div>
                </td>
                <td>
                  <span
                    className={`tag-pill ${
                      ord.statusTag === 'NEW'
                        ? 'tag-new'
                        : (ord.statusTag === 'Ready for Pickup' ? 'tag-new' : 'tag-progress')
                    }`}
                  >
                    {ord.statusTag}
                  </span>
                </td>
                <td style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                    <Clock size={14} />
                    <span>{ord.timeAgo}</span>
                  </div>
                </td>
                <td style={{ textAlign: 'right' }}>
                  {ord.statusTag === 'NEW' ? (
                    <button className="btn-olive" onClick={() => onOpenAcceptModal(ord)}>
                      Accept Order
                    </button>
                  ) : (
                    <button className="btn-outline" onClick={() => onSelectOrderDetails(ord)}>
                      <Eye size={15} />
                      <span>Timeline</span>
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Incoming Requests Section */}
      <div className="table-card-container">
        <div className="desktop-table-header">
          <div>
            <h2 className="serif-heading" style={{ fontSize: '1.35rem', fontWeight: 800 }}>
              Incoming Customer Requests
            </h2>
            <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', marginTop: 2 }}>
              Customer custom grain milling & order inquiries.
            </div>
          </div>
        </div>

        <table className="desktop-data-table">
          <thead>
            <tr>
              <th>Request ID</th>
              <th>Customer</th>
              <th>Grain Type</th>
              <th>Quantity</th>
              <th>Request Status</th>
              <th style={{ textAlign: 'right' }}>Action</th>
            </tr>
          </thead>
          <tbody>
            {pendingRequests.map((req) => (
              <tr key={req.id}>
                <td style={{ fontWeight: 800, fontSize: '0.9rem', color: 'var(--text-secondary)' }}>{req.id}</td>
                <td style={{ fontWeight: 800, fontFamily: 'Playfair Display, serif', fontSize: '1.05rem' }}>
                  {req.customerName}
                </td>
                <td style={{ fontWeight: 700, fontSize: '0.9rem' }}>{req.grainType}</td>
                <td style={{ fontWeight: 700, fontSize: '0.9rem' }}>{req.quantityText}</td>
                <td>
                  <span className="badge-tag" style={{ fontSize: '0.7rem' }}>New Request</span>
                </td>
                <td style={{ textAlign: 'right' }}>
                  <button className="btn-olive" onClick={() => onOpenAcceptModal(req)}>
                    Accept Request
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
