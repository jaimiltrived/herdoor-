import React, { useState } from 'react';
import { Filter, Download, Wheat, Hourglass, CheckCircle2, ShieldCheck } from 'lucide-react';
import { pendingRequests } from '../data/mockData';

export default function OrdersPage({ onOpenAcceptModal, onSelectOrderDetails }) {
  const [activeFilterTab, setActiveFilterTab] = useState(0);

  return (
    <div className="orders-page">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24 }}>
        <div>
          <h1 className="serif-heading" style={{ fontSize: '1.75rem', fontWeight: 800 }}>
            Order Management & Control
          </h1>
          <p style={{ fontSize: '0.9rem', color: 'var(--text-secondary)', marginTop: 4 }}>
            Review incoming requests, accept milling jobs & assign estimated completion times.
          </p>
        </div>

        {/* Action Buttons: Filter & Export */}
        <div style={{ display: 'flex', gap: 12 }}>
          <button className="btn-outline">
            <Filter size={16} />
            <span>Filter</span>
          </button>
          <button className="btn-primary">
            <Download size={16} />
            <span>Export Report</span>
          </button>
        </div>
      </div>

      {/* Today's Overview Stats Box */}
      <div
        style={{
          backgroundColor: 'var(--surface)',
          borderRadius: 20,
          border: '1px solid var(--border-light)',
          padding: '20px 26px',
          marginBottom: 24,
          boxShadow: 'var(--shadow-sm)',
          display: 'flex',
          gap: 40,
        }}
      >
        <div>
          <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Total Orders Today</div>
          <div className="serif-heading" style={{ fontSize: '2.2rem', fontWeight: 800, color: 'var(--text-primary)', marginTop: 2 }}>
            24
          </div>
        </div>
        <div style={{ borderLeft: '1px solid var(--border-light)', paddingLeft: 40 }}>
          <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Pending Acceptance</div>
          <div className="serif-heading" style={{ fontSize: '2.2rem', fontWeight: 800, color: 'var(--primary-terracotta)', marginTop: 2 }}>
            8
          </div>
        </div>
        <div style={{ borderLeft: '1px solid var(--border-light)', paddingLeft: 40 }}>
          <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Average Milling Time</div>
          <div className="serif-heading" style={{ fontSize: '2.2rem', fontWeight: 800, color: 'var(--mustard-dark)', marginTop: 2 }}>
            28 min
          </div>
        </div>
      </div>

      {/* Status Filter Tab Pills */}
      <div className="filter-tabs-container">
        <button
          className={`filter-tab ${activeFilterTab === 0 ? 'active' : ''}`}
          onClick={() => setActiveFilterTab(0)}
        >
          <span>NEW REQUESTS</span>
          <span className="tab-badge">12</span>
        </button>
        <button
          className={`filter-tab ${activeFilterTab === 1 ? 'active' : ''}`}
          onClick={() => setActiveFilterTab(1)}
        >
          <Hourglass size={15} />
          <span>IN MILLING (PENDING)</span>
          <span className="tab-badge">8</span>
        </button>
        <button
          className={`filter-tab ${activeFilterTab === 2 ? 'active' : ''}`}
          onClick={() => setActiveFilterTab(2)}
        >
          <CheckCircle2 size={15} />
          <span>COMPLETED HISTORY</span>
        </button>
      </div>

      {/* Request Cards Grid (2 Columns on Desktop) */}
      <div className="grid-cards-2">
        {pendingRequests.map((req) => (
          <div key={req.id} className="request-card">
            <div className="request-card-header">
              <div>
                <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--primary-terracotta)', letterSpacing: 0.5 }}>
                  {req.id}
                </div>
                <div className="serif-heading" style={{ fontSize: '1.35rem', fontWeight: 800, marginTop: 2 }}>
                  {req.customerName}
                </div>
              </div>
              <span
                style={{
                  backgroundColor: 'var(--soft-pink)',
                  color: 'var(--primary-terracotta)',
                  fontSize: '0.75rem',
                  fontWeight: 800,
                  padding: '5px 12px',
                  borderRadius: 14,
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 6,
                }}
              >
                <span className="green-dot" style={{ width: 8, height: 8 }}></span>
                New Request
              </span>
            </div>

            <div className="request-card-body">
              <div className="request-spec-row">
                <div
                  style={{
                    width: 42,
                    height: 42,
                    borderRadius: 12,
                    backgroundColor: 'var(--surface-cream)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: 'var(--mustard-dark)',
                  }}
                >
                  <Wheat size={22} />
                </div>
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                    Grain Type & Milling Spec
                  </div>
                  <div style={{ fontSize: '1rem', fontWeight: 800 }}>{req.grainType}</div>
                </div>
              </div>

              <div className="request-spec-row">
                <div
                  style={{
                    width: 42,
                    height: 42,
                    borderRadius: 12,
                    backgroundColor: 'var(--surface-cream)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: 'var(--mustard-dark)',
                  }}
                >
                  <Hourglass size={22} />
                </div>
                <div>
                  <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                    Quantity Requested
                  </div>
                  <div style={{ fontSize: '1rem', fontWeight: 800 }}>{req.quantityText}</div>
                </div>
              </div>

              <div className="request-actions">
                <button
                  className="btn-outline"
                  onClick={() => alert(`Order ${req.id} Declined`)}
                >
                  Decline
                </button>
                <button
                  className="btn-olive"
                  onClick={() => onOpenAcceptModal(req)}
                >
                  Accept Order
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
