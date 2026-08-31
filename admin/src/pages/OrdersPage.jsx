import React, { useState, useEffect } from 'react';
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
  PackageCheck,
  Clock,
  CheckCircle,
  Truck
} from 'lucide-react';
import { apiService } from '../services/apiService';

export default function OrdersPage({ onOpenAcceptModal, onSelectOrderDetails }) {
  const [activeFilterTab, setActiveFilterTab] = useState(0);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedGrain, setSelectedGrain] = useState('All');
  const [isFilterDrawerOpen, setIsFilterDrawerOpen] = useState(false);
  const [timeframe, setTimeframe] = useState('week');
  const [allOrders, setAllOrders] = useState([]);
  const [acceptingOrder, setAcceptingOrder] = useState(null);
  const [estimatedMinutes, setEstimatedMinutes] = useState('30');

  const grainTypes = ['All', 'Wheat (Gehun)', 'Organic Whole Wheat', 'Stoneground Rye', 'Multigrain Mix', 'Bajra Flour', 'Juwar Flour', 'Chana Dal'];

  useEffect(() => {
    loadOrders();
    const interval = setInterval(loadOrders, 3000);
    return () => clearInterval(interval);
  }, []);

  const loadOrders = async () => {
    try {
      const dbOrders = await apiService.getOrders();
      if (dbOrders && dbOrders.length > 0) {
        const formatted = dbOrders.map(o => ({
          id: o.orderNumber || `#HD-${o.id}`,
          numericId: o.id,
          customerName: o.customerName || 'Customer',
          customerPhone: o.customerPhone || '+91 98765 43210',
          grainType: o.grainTypeName || 'Wheat (Gehun)',
          quantityText: `${o.quantityKg || 5} kg`,
          quantityKg: o.quantityKg || 5,
          amount: `₹${o.totalAmount || 180}`,
          deliveryAddress: o.fulfillmentType === 'DELIVERY' ? 'Home Delivery (Ahmedabad)' : 'Self Pickup at Mill',
          fulfillmentType: o.fulfillmentType || 'DELIVERY',
          status: (o.status || 'PLACED').toUpperCase(),
          timeAgo: 'Just now',
          paymentStatus: o.paymentStatus || 'PAID',
        }));
        setAllOrders(formatted);
      }
    } catch (e) {
      console.warn('Load orders error:', e);
    }
  };

  const handleDecline = async (id) => {
    if (window.confirm(`Are you sure you want to decline Order ${id}?`)) {
      const numId = String(id).replace(/\D/g, '');
      await apiService.rejectOrder(numId);
      await loadOrders();
    }
  };

  const handleOpenAccept = (order) => {
    setAcceptingOrder(order);
    setEstimatedMinutes('30');
  };

  const handleConfirmAccept = async () => {
    if (!acceptingOrder) return;
    const numId = acceptingOrder.numericId || String(acceptingOrder.id).replace(/\D/g, '');
    await apiService.acceptOrder(numId, `${estimatedMinutes} mins`);
    await loadOrders();
    setAcceptingOrder(null);
  };

  const handleMoveToReady = async (order) => {
    const numId = order.numericId || String(order.id).replace(/\D/g, '');
    await apiService.updateOrderStatus(numId, 'READY_FOR_PICKUP');
    await loadOrders();
  };

  const handleResetFilters = () => {
    setSearchQuery('');
    setSelectedGrain('All');
    setActiveFilterTab(0);
  };

  const newRequests = allOrders.filter(o =>
    o.status === 'PLACED' || o.status === 'NEW' || o.status === 'PENDING'
  );

  const inMillingOrders = allOrders.filter(o =>
    o.status === 'ACCEPTED' || o.status === 'PROCESSING' || o.status === 'MILLING' || o.status === 'PACKING' || o.status === 'IN PROGRESS'
  );

  const completedHistoryOrders = allOrders.filter(o =>
    o.status === 'READY' || o.status === 'READY_FOR_PICKUP' || o.status === 'OUT_FOR_DELIVERY' || o.status === 'DELIVERED' || o.status === 'COMPLETED' || o.status === 'PICKED_UP'
  );

  const getActiveTabList = () => {
    if (activeFilterTab === 0) return newRequests;
    if (activeFilterTab === 1) return inMillingOrders;
    return completedHistoryOrders;
  };

  const currentTabList = getActiveTabList();

  const filteredRequests = currentTabList.filter((req) => {
    const matchesSearch =
      req.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      req.customerName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      req.grainType.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesGrain = selectedGrain === 'All' || req.grainType === selectedGrain;

    return matchesSearch && matchesGrain;
  });

  const hasActiveFilters = searchQuery !== '' || selectedGrain !== 'All';

  return (
    <div className="orders-page">
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

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(3, 1fr)',
          gap: 20,
          marginBottom: 24,
        }}
      >
        <div className="card" style={{ padding: 22, background: '#FFFFFF', borderRadius: 16, border: '1px solid #ECE4D9' }}>
          <div style={{ fontSize: '0.72rem', color: '#756D69', fontWeight: 800, letterSpacing: 0.5, textTransform: 'uppercase' }}>
            TOTAL ORDERS TODAY
          </div>
          <div style={{ fontSize: '2.1rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
            {allOrders.length}
          </div>
          <span style={{ fontSize: '0.82rem', color: '#1E8449', fontWeight: 700, marginTop: 6, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            ↑ 100% Synced from Database
          </span>
        </div>

        <div className="card" style={{ padding: 22, background: '#FFFFFF', borderRadius: 16, border: '1px solid #ECE4D9' }}>
          <div style={{ fontSize: '0.72rem', color: '#756D69', fontWeight: 800, letterSpacing: 0.5, textTransform: 'uppercase' }}>
            PENDING ACCEPTANCE
          </div>
          <div style={{ fontSize: '2.1rem', fontWeight: 800, color: '#8C4A3E', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
            {newRequests.length}
          </div>
          <span style={{ fontSize: '0.82rem', color: '#8C4A3E', fontWeight: 700, marginTop: 6, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            Requires Mill Owner Action
          </span>
        </div>

        <div className="card" style={{ padding: 22, background: '#FFFFFF', borderRadius: 16, border: '1px solid #ECE4D9' }}>
          <div style={{ fontSize: '0.72rem', color: '#756D69', fontWeight: 800, letterSpacing: 0.5, textTransform: 'uppercase' }}>
            AVERAGE MILLING TIME
          </div>
          <div style={{ fontSize: '2.1rem', fontWeight: 800, color: '#6E5616', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
            24 min
          </div>
          <span style={{ fontSize: '0.82rem', color: '#1E8449', fontWeight: 700, marginTop: 6, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            4 mins faster than SLA
          </span>
        </div>
      </div>

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
              style={{ padding: '6px 12px', borderRadius: '10px', border: '1px solid #ECE4D9', backgroundColor: '#FAF6F0', color: '#2A2421', fontWeight: 700, fontSize: '0.8rem', cursor: 'pointer', outline: 'none' }}
            >
              <option value="week">7 Days</option>
              <option value="month">30 Days</option>
            </select>
          </div>
        </div>

        <div style={{ background: '#FAF6F0', borderRadius: 16, border: '1px solid #ECE4D9', padding: '18px 20px', position: 'relative' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <div style={{ display: 'flex', gap: 16, fontSize: '0.78rem', fontWeight: 700 }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#8C4A3E' }}>
                <span style={{ width: 10, height: 10, borderRadius: 3, background: '#8C4A3E' }}></span> Orders Placed ({allOrders.length})
              </span>
              <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#1E8449' }}>
                <span style={{ width: 10, height: 2, background: '#1E8449' }}></span> Fulfilled & Delivered ({completedHistoryOrders.length})
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
            <path
              d="M 50 120 C 150 110, 250 85, 380 75 C 500 65, 650 45, 820 30"
              fill="none"
              stroke="#8C4A3E"
              strokeWidth="3.5"
            />
            <path
              d="M 50 120 C 150 110, 250 85, 380 75 C 500 65, 650 45, 820 30 L 820 150 L 50 150 Z"
              fill="url(#orderGrad)"
            />
            <line x1="50" y1="45" x2="820" y2="45" stroke="#D4A373" strokeWidth="1.5" strokeDasharray="5 5" />
            <circle cx="50" cy="120" r="4.5" fill="#8C4A3E" stroke="white" strokeWidth="2" />
            <circle cx="200" cy="100" r="4.5" fill="#8C4A3E" stroke="white" strokeWidth="2" />
            <circle cx="380" cy="75" r="4.5" fill="#8C4A3E" stroke="white" strokeWidth="2" />
            <circle cx="580" cy="55" r="4.5" fill="#8C4A3E" stroke="white" strokeWidth="2" />
            <circle cx="820" cy="30" r="6" fill="#1E8449" stroke="white" strokeWidth="2.5" />
          </svg>

          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', color: '#756D69', marginTop: 8, fontWeight: 600, paddingLeft: 45, paddingRight: 8 }}>
            <span>{timeframe === 'week' ? 'Mon' : 'Week 1'}</span>
            <span>{timeframe === 'week' ? 'Tue' : 'Week 2'}</span>
            <span>{timeframe === 'week' ? 'Wed' : 'Week 3'}</span>
            <span>{timeframe === 'week' ? 'Thu' : 'Week 4'}</span>
            <span>{timeframe === 'week' ? 'Fri' : 'Forecast'}</span>
            <span style={{ color: '#8C4A3E', fontWeight: 800 }}>Today (Peak)</span>
          </div>
        </div>
      </div>

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18, flexWrap: 'wrap', gap: 12 }}>
        <div className="filter-tabs-container" style={{ margin: 0 }}>
          <button className={`filter-tab ${activeFilterTab === 0 ? 'active' : ''}`} onClick={() => setActiveFilterTab(0)}>
            <span>NEW REQUESTS</span>
            <span className="tab-badge">{newRequests.length}</span>
          </button>
          <button className={`filter-tab ${activeFilterTab === 1 ? 'active' : ''}`} onClick={() => setActiveFilterTab(1)}>
            <Hourglass size={15} />
            <span>IN MILLING</span>
            <span className="tab-badge">{inMillingOrders.length}</span>
          </button>
          <button className={`filter-tab ${activeFilterTab === 2 ? 'active' : ''}`} onClick={() => setActiveFilterTab(2)}>
            <CheckCircle2 size={15} />
            <span>COMPLETED HISTORY</span>
            <span className="tab-badge">{completedHistoryOrders.length}</span>
          </button>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: '#FAF6F0', padding: '8px 16px', borderRadius: 24, border: '1px solid #ECE4D9', width: 260 }}>
          <Search size={15} color="#756D69" />
          <input placeholder="Search orders..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} style={{ border: 'none', background: 'transparent', outline: 'none', fontSize: '0.85rem', width: '100%' }} />
          {searchQuery && <X size={14} color="#756D69" style={{ cursor: 'pointer' }} onClick={() => setSearchQuery('')} />}
        </div>
      </div>

      {isFilterDrawerOpen && (
        <div style={{ background: '#FAF6F0', borderRadius: 16, border: '1px solid #ECE4D9', padding: 18, marginBottom: 20, display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16 }}>
          <div>
            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 6 }}>GRAIN SPECIFICATION</label>
            <select value={selectedGrain} onChange={(e) => setSelectedGrain(e.target.value)} style={{ width: '100%', padding: '8px 12px', borderRadius: 10, border: '1px solid #ECE4D9', background: 'white', fontSize: '0.85rem', fontWeight: 600 }}>
              {grainTypes.map((g) => <option key={g} value={g}>{g}</option>)}
            </select>
          </div>
        </div>
      )}

      {filteredRequests.length === 0 ? (
        <div className="card" style={{ textAlign: 'center', padding: '48px 24px', color: '#756D69' }}>
          <PackageCheck size={40} color="#A59D96" style={{ margin: '0 auto 12px auto' }} />
          <div style={{ fontWeight: 800, fontSize: '1.1rem', color: '#2A2421' }}>
            {activeFilterTab === 0 ? 'No New Incoming Orders' : activeFilterTab === 1 ? 'No Orders Currently In Milling' : 'No Completed History Yet'}
          </div>
          <p style={{ fontSize: '0.85rem', margin: '4px 0 16px 0' }}>
            {activeFilterTab === 0 ? 'New customer order requests will appear here automatically.' : 'Orders move across stages automatically as they are processed.'}
          </p>
          <button onClick={handleResetFilters} className="btn-outline" style={{ padding: '8px 18px', borderRadius: 14 }}>Reset Filters</button>
        </div>
      ) : (
        <div className="grid-cards-2">
          {filteredRequests.map((req) => (
            <div key={req.id} className="request-card">
              <div className="request-card-header">
                <div>
                  <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--primary-terracotta)', letterSpacing: 0.5 }}>{req.id}</div>
                  <div className="serif-heading" style={{ fontSize: '1.35rem', fontWeight: 800, marginTop: 2 }}>{req.customerName}</div>
                </div>
                <span
                  style={{
                    backgroundColor: req.status === 'PLACED' ? '#FDEDEC' : req.status === 'ACCEPTED' ? '#FFF8E7' : '#E8F8F0',
                    color: req.status === 'PLACED' ? '#C0392B' : req.status === 'ACCEPTED' ? '#B7791F' : '#1E8449',
                    fontSize: '0.75rem',
                    fontWeight: 800,
                    padding: '5px 12px',
                    borderRadius: 14,
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: 6,
                  }}
                >
                  <span className="green-dot" style={{ width: 8, height: 8, background: req.status === 'PLACED' ? '#E74C3C' : '#2ECC71' }}></span>
                  {req.status}
                </span>
              </div>
              <div className="request-card-body">
                <div className="request-spec-row">
                  <div style={{ width: 42, height: 42, borderRadius: 12, backgroundColor: 'var(--surface-cream)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--mustard-dark)' }}><Wheat size={22} /></div>
                  <div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>Grain Type</div>
                    <div style={{ fontSize: '1rem', fontWeight: 800 }}>{req.grainType}</div>
                  </div>
                </div>
                <div className="request-spec-row">
                  <div style={{ width: 42, height: 42, borderRadius: 12, backgroundColor: 'var(--surface-cream)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--mustard-dark)' }}><Hourglass size={22} /></div>
                  <div>
                    <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>Quantity Requested</div>
                    <div style={{ fontSize: '1rem', fontWeight: 800 }}>{req.quantityText}</div>
                  </div>
                </div>

                {activeFilterTab === 0 && (
                  <div className="request-actions">
                    <button className="btn-outline" onClick={() => handleDecline(req.id)}>Decline</button>
                    <button className="btn-olive" onClick={() => handleOpenAccept(req)}>Accept Order</button>
                  </div>
                )}
                {activeFilterTab === 1 && (
                  <div className="request-actions">
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: '0.82rem', fontWeight: 700, color: '#6E5616' }}><Clock size={16} /> Milling in Progress • ETA 25m</div>
                    <button className="btn-olive" onClick={() => handleMoveToReady(req)} style={{ padding: '8px 14px', borderRadius: 10 }}>Mark Ready for Dispatch</button>
                  </div>
                )}
                {activeFilterTab === 2 && (
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 12, paddingTop: 10, borderTop: '1px solid #ECE4D9' }}>
                    <span style={{ fontSize: '0.85rem', fontWeight: 700, color: '#1E8449', display: 'flex', alignItems: 'center', gap: 6 }}><CheckCircle size={16} /> Milled & Ready / Dispatched</span>
                    <span style={{ fontWeight: 800, fontSize: '1rem', color: '#2A2421' }}>{req.amount}</span>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {acceptingOrder && (
        <div className="modal-backdrop">
          <div className="modal-content" style={{ maxWidth: 440, padding: 24, borderRadius: 20 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <h3 style={{ fontSize: '1.25rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>Accept Milling Job</h3>
              <button className="btn-icon" onClick={() => setAcceptingOrder(null)}><X size={18} /></button>
            </div>
            <p style={{ fontSize: '0.88rem', color: '#756D69', marginBottom: 16 }}>
              Set estimated turnaround time for <strong>{acceptingOrder.customerName}</strong> ({acceptingOrder.quantityText} {acceptingOrder.grainType}).
            </p>
            <div style={{ marginBottom: 20 }}>
              <label style={{ display: 'block', fontSize: '0.78rem', fontWeight: 800, color: '#756D69', marginBottom: 8 }}>ESTIMATED MILLING DURATION</label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
                {['15', '30', '45'].map((mins) => (
                  <button
                    key={mins}
                    type="button"
                    onClick={() => setEstimatedMinutes(mins)}
                    style={{ padding: '10px 0', borderRadius: 12, border: estimatedMinutes === mins ? '2px solid #8C4A3E' : '1px solid #ECE4D9', backgroundColor: estimatedMinutes === mins ? '#FFECEB' : '#FFF', color: estimatedMinutes === mins ? '#8C4A3E' : '#2A2421', fontWeight: 800, cursor: 'pointer' }}
                  >
                    {mins} mins
                  </button>
                ))}
              </div>
            </div>
            <div style={{ display: 'flex', gap: 12, justifyContent: 'flex-end' }}>
              <button className="btn-outline" onClick={() => setAcceptingOrder(null)}>Cancel</button>
              <button className="btn-primary" style={{ backgroundColor: '#8C4A3E' }} onClick={handleConfirmAccept}>Confirm & Accept Job</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
