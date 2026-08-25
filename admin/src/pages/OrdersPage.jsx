import React, { useState } from 'react';
import {
  Filter,
  Download,
  Wheat,
  Hourglass,
  CheckCircle2,
  Search,
  X,
  RotateCcw,
  Activity,
  Layers,
  Check,
  TrendingUp,
  PackageCheck
} from 'lucide-react';
import { pendingRequests } from '../data/mockData';

export default function OrdersPage({ onOpenAcceptModal, onSelectOrderDetails }) {
  const [activeFilterTab, setActiveFilterTab] = useState(0);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedGrain, setSelectedGrain] = useState('All');
  const [isFilterDrawerOpen, setIsFilterDrawerOpen] = useState(false);
  const [timeframe, setTimeframe] = useState('week');
  const [requests, setRequests] = useState(pendingRequests);

  const grainTypes = ['All', 'Organic Whole Wheat', 'Stoneground Rye', 'Multigrain Mix', 'Bajra Flour'];

  const handleDecline = (id) => {
    if (window.confirm(`Are you sure you want to decline Order ${id}?`)) {
      setRequests(requests.filter((r) => r.id !== id));
    }
  };

  const handleResetFilters = () => {
    setSearchQuery('');
    setSelectedGrain('All');
    setActiveFilterTab(0);
  };

  const hasActiveFilters = searchQuery !== '' || selectedGrain !== 'All';

  // Filter requests
  const filteredRequests = requests.filter((req) => {
    const matchesSearch =
      req.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      req.customerName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      req.grainType.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesGrain = selectedGrain === 'All' || req.grainType === selectedGrain;

    return matchesSearch && matchesGrain;
  });

  return (
    <div className="orders-page">
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="page-title serif-heading" style={{ fontSize: '2rem', fontWeight: 800, color: '#2A2421' }}>
            Order Management & Control
          </h1>
          <p style={{ fontSize: '0.92rem', color: '#756D69', marginTop: 4 }}>
            Review incoming requests, accept milling jobs & assign estimated completion times.
          </p>
        </div>

        <div style={{ display: 'flex', gap: 12 }}>
          <button
            className="btn-outline"
            onClick={() => setIsFilterDrawerOpen(!isFilterDrawerOpen)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 6,
              padding: '10px 16px',
              borderRadius: 14,
              backgroundColor: isFilterDrawerOpen || hasActiveFilters ? '#8C4A3E' : '#FFF',
              color: isFilterDrawerOpen || hasActiveFilters ? '#FFF' : '#2A2421',
              borderColor: isFilterDrawerOpen || hasActiveFilters ? '#8C4A3E' : '#ECE4D9',
              fontWeight: 700,
            }}
          >
            <Filter size={16} />
            <span>Filter</span>
            {hasActiveFilters && <span style={{ width: 8, height: 8, borderRadius: '50%', background: '#FFF' }}></span>}
          </button>
          <button className="btn-primary" style={{ backgroundColor: '#8C4A3E', background: 'linear-gradient(135deg, #8C4A3E, #6E372D)', padding: '10px 18px', borderRadius: 14 }}>
            <Download size={16} />
            <span>Export Report</span>
          </button>
        </div>
      </div>

      {/* 3 Individual Overview Stat Cards */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(3, 1fr)',
          gap: 20,
          marginBottom: 24,
        }}
      >
        <div
          className="card"
          style={{
            padding: 22,
            background: '#FFFFFF',
            borderRadius: 16,
            border: '1px solid #ECE4D9',
          }}
        >
          <div style={{ fontSize: '0.72rem', color: '#756D69', fontWeight: 800, letterSpacing: 0.5, textTransform: 'uppercase' }}>
            TOTAL ORDERS TODAY
          </div>
          <div style={{ fontSize: '2.1rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
            24
          </div>
          <span style={{ fontSize: '0.82rem', color: '#1E8449', fontWeight: 700, marginTop: 6, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            ↑ +6 vs yesterday
          </span>
        </div>

        <div
          className="card"
          style={{
            padding: 22,
            background: '#FFFFFF',
            borderRadius: 16,
            border: '1px solid #ECE4D9',
          }}
        >
          <div style={{ fontSize: '0.72rem', color: '#756D69', fontWeight: 800, letterSpacing: 0.5, textTransform: 'uppercase' }}>
            PENDING ACCEPTANCE
          </div>
          <div style={{ fontSize: '2.1rem', fontWeight: 800, color: '#8C4A3E', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
            {requests.length}
          </div>
          <span style={{ fontSize: '0.82rem', color: '#8C4A3E', fontWeight: 700, marginTop: 6, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            Requires Mill Owner Action
          </span>
        </div>

        <div
          className="card"
          style={{
            padding: 22,
            background: '#FFFFFF',
            borderRadius: 16,
            border: '1px solid #ECE4D9',
          }}
        >
          <div style={{ fontSize: '0.72rem', color: '#756D69', fontWeight: 800, letterSpacing: 0.5, textTransform: 'uppercase' }}>
            AVERAGE MILLING TIME
          </div>
          <div style={{ fontSize: '2.1rem', fontWeight: 800, color: '#6E5616', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
            28 min
          </div>
          <span style={{ fontSize: '0.82rem', color: '#1E8449', fontWeight: 700, marginTop: 6, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            4 mins faster than SLA
          </span>
        </div>
      </div>

      {/* Full View Interactive Order Velocity & Queue Graph */}
      <div className="card" style={{ padding: 24, marginBottom: 28 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Activity size={18} color="#8C4A3E" />
              <h2 className="card-title" style={{ fontSize: '1.15rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>
                Order Inflow & Milling Completion Velocity
              </h2>
            </div>
            <p style={{ fontSize: '0.78rem', color: '#756D69', margin: '3px 0 0 0' }}>Daily order submissions vs average turnaround time</p>
          </div>

          <div>
            <select
              value={timeframe}
              onChange={(e) => setTimeframe(e.target.value)}
              style={{
                padding: '6px 12px',
                borderRadius: '10px',
                border: '1px solid #ECE4D9',
                backgroundColor: '#FAF6F0',
                color: '#2A2421',
                fontWeight: 700,
                fontSize: '0.8rem',
                cursor: 'pointer',
                outline: 'none',
              }}
            >
              <option value="week">7 Days</option>
              <option value="month">30 Days</option>
              <option value="quarter">3 Months</option>
            </select>
          </div>
        </div>

        <div style={{ background: '#FAF6F0', borderRadius: 16, border: '1px solid #ECE4D9', padding: '18px 20px', position: 'relative' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <div style={{ display: 'flex', gap: 16, fontSize: '0.78rem', fontWeight: 700 }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#8C4A3E' }}>
                <span style={{ width: 10, height: 10, borderRadius: 3, background: '#8C4A3E' }}></span> Orders Placed (24)
              </span>
              <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#1E8449' }}>
                <span style={{ width: 10, height: 2, background: '#1E8449' }}></span> Fulfilled & Delivered (100%)
              </span>
            </div>
            <span style={{ fontSize: '0.75rem', color: '#1E8449', fontWeight: 700, background: '#E8F8F0', padding: '2px 8px', borderRadius: 6 }}>
              +24.2% Daily Velocity
            </span>
          </div>

          <svg viewBox="0 0 840 160" style={{ width: '100%', height: '170px', overflow: 'visible' }}>
            <defs>
              <linearGradient id="orderGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" stopColor="#8C4A3E" stopOpacity="0.25" />
                <stop offset="100%" stopColor="#8C4A3E" stopOpacity="0.0" />
              </linearGradient>
            </defs>

            {/* Y-Axis Scale Labels */}
            <text x="36" y="34" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">30 Orders</text>
            <text x="36" y="74" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">20 Orders</text>
            <text x="36" y="114" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">10 Orders</text>
            <text x="36" y="152" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">0</text>

            {/* Grid Lines */}
            <line x1="45" y1="30" x2="840" y2="30" stroke="#ECE4D9" strokeDasharray="3,3" />
            <line x1="45" y1="70" x2="840" y2="70" stroke="#ECE4D9" strokeDasharray="3,3" />
            <line x1="45" y1="110" x2="840" y2="110" stroke="#ECE4D9" strokeDasharray="3,3" />

            {/* X-Axis Baseline & Y-Axis Axis Line */}
            <line x1="45" y1="20" x2="45" y2="150" stroke="#D5C9B8" strokeWidth="1.5" />
            <line x1="45" y1="150" x2="840" y2="150" stroke="#D5C9B8" strokeWidth="1.5" />

            <path
              d={
                timeframe === 'week'
                  ? 'M 45,130 Q 190,105 340,90 T 520,60 T 700,42 T 820,30 L 820,150 L 45,150 Z'
                  : timeframe === 'month'
                  ? 'M 45,135 Q 190,115 340,105 T 520,75 T 700,50 T 820,38 L 820,150 L 45,150 Z'
                  : 'M 45,140 Q 190,120 340,95 T 520,55 T 700,35 T 820,25 L 820,150 L 45,150 Z'
              }
              fill="url(#orderGrad)"
            />
            <path
              d={
                timeframe === 'week'
                  ? 'M 45,130 Q 190,105 340,90 T 520,60 T 700,42 T 820,30'
                  : timeframe === 'month'
                  ? 'M 45,135 Q 190,115 340,105 T 520,75 T 700,50 T 820,38'
                  : 'M 45,140 Q 190,120 340,95 T 520,55 T 700,35 T 820,25'
              }
              fill="none"
              stroke="#8C4A3E"
              strokeWidth="3.5"
              strokeLinecap="round"
            />

            <circle cx="45" cy={timeframe === 'week' ? 130 : timeframe === 'month' ? 135 : 140} r="4.5" fill="#8C4A3E" stroke="white" strokeWidth="2" />
            <circle cx="190" cy={timeframe === 'week' ? 105 : timeframe === 'month' ? 115 : 120} r="4.5" fill="#8C4A3E" stroke="white" strokeWidth="2" />
            <circle cx="340" cy={timeframe === 'week' ? 90 : timeframe === 'month' ? 105 : 95} r="4.5" fill="#8C4A3E" stroke="white" strokeWidth="2" />
            <circle cx="520" cy={timeframe === 'week' ? 60 : timeframe === 'month' ? 75 : 55} r="4.5" fill="#8C4A3E" stroke="white" strokeWidth="2" />
            <circle cx="700" cy={timeframe === 'week' ? 42 : timeframe === 'month' ? 50 : 35} r="4.5" fill="#8C4A3E" stroke="white" strokeWidth="2" />
            <circle cx="820" cy={timeframe === 'week' ? 30 : timeframe === 'month' ? 38 : 25} r="6" fill="#1E8449" stroke="white" strokeWidth="2.5" />
          </svg>

          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', color: '#756D69', marginTop: 8, fontWeight: 600, paddingLeft: 45, paddingRight: 8 }}>
            <span>{timeframe === 'week' ? 'Mon' : timeframe === 'month' ? 'Week 1' : 'Month 1'}</span>
            <span>{timeframe === 'week' ? 'Tue' : timeframe === 'month' ? 'Week 2' : 'Month 2'}</span>
            <span>{timeframe === 'week' ? 'Wed' : timeframe === 'month' ? 'Week 3' : 'Month 3'}</span>
            <span>{timeframe === 'week' ? 'Thu' : timeframe === 'month' ? 'Week 4' : 'Quarter Avg'}</span>
            <span>{timeframe === 'week' ? 'Fri' : timeframe === 'month' ? 'Week 5' : 'Forecast'}</span>
            <span style={{ color: '#8C4A3E', fontWeight: 800 }}>Today (Peak)</span>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18, flexWrap: 'wrap', gap: 12 }}>
        {/* Status Filter Tab Pills */}
        <div className="filter-tabs-container" style={{ margin: 0 }}>
          <button
            className={`filter-tab ${activeFilterTab === 0 ? 'active' : ''}`}
            onClick={() => setActiveFilterTab(0)}
          >
            <span>NEW REQUESTS</span>
            <span className="tab-badge">{filteredRequests.length}</span>
          </button>
          <button
            className={`filter-tab ${activeFilterTab === 1 ? 'active' : ''}`}
            onClick={() => setActiveFilterTab(1)}
          >
            <Hourglass size={15} />
            <span>IN MILLING</span>
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

        {/* Search Input */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            background: '#FAF6F0',
            padding: '8px 16px',
            borderRadius: 24,
            border: '1px solid #ECE4D9',
            width: 260,
          }}
        >
          <Search size={15} color="#756D69" />
          <input
            placeholder="Search orders, customers..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            style={{ border: 'none', background: 'transparent', outline: 'none', fontSize: '0.85rem', width: '100%' }}
          />
          {searchQuery && (
            <X size={14} color="#756D69" style={{ cursor: 'pointer' }} onClick={() => setSearchQuery('')} />
          )}
        </div>
      </div>

      {/* Expandable Filter Drawer */}
      {isFilterDrawerOpen && (
        <div
          style={{
            background: '#FAF6F0',
            borderRadius: 16,
            border: '1px solid #ECE4D9',
            padding: 18,
            marginBottom: 20,
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
            gap: 16,
          }}
        >
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 6 }}>
              GRAIN SPECIFICATION
            </label>
            <select
              value={selectedGrain}
              onChange={(e) => setSelectedGrain(e.target.value)}
              style={{
                width: '100%',
                padding: '8px 12px',
                borderRadius: 10,
                border: '1px solid #ECE4D9',
                background: 'white',
                fontSize: '0.85rem',
                fontWeight: 600,
                color: '#2A2421',
              }}
            >
              {grainTypes.map((g) => (
                <option key={g} value={g}>{g}</option>
              ))}
            </select>
          </div>
        </div>
      )}

      {/* Request Cards Grid (2 Columns on Desktop) */}
      {filteredRequests.length === 0 ? (
        <div className="card" style={{ textAlign: 'center', padding: '48px 24px', color: '#756D69' }}>
          <PackageCheck size={40} color="#A59D96" style={{ margin: '0 auto 12px auto' }} />
          <div style={{ fontWeight: 800, fontSize: '1.1rem', color: '#2A2421' }}>No Orders Found</div>
          <p style={{ fontSize: '0.85rem', margin: '4px 0 16px 0' }}>Try adjusting your search criteria or grain filter.</p>
          <button onClick={handleResetFilters} className="btn-outline" style={{ padding: '8px 18px', borderRadius: 14 }}>
            Reset Filters
          </button>
        </div>
      ) : (
        <div className="grid-cards-2">
          {filteredRequests.map((req) => (
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
                    onClick={() => handleDecline(req.id)}
                  >
                    Decline
                  </button>
                  <button
                    className="btn-olive"
                    onClick={() => onOpenAcceptModal && onOpenAcceptModal(req)}
                  >
                    Accept Order
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
