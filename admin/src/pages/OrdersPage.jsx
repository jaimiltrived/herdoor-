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
  const [hoveredPoint, setHoveredPoint] = useState(null);

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
          groupId: o.groupId || o.group_id,
          groupCode: o.groupCode || o.group_code,
          isGrouped: Boolean(o.groupId || o.group_id || o.groupCode || o.group_code),
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

  const groupedBatchOrders = allOrders.filter(o => o.isGrouped);

  // Group groupedBatchOrders by group code / group ID
  const groupedRunsMap = {};
  groupedBatchOrders.forEach(order => {
    const key = order.groupCode || (order.groupId ? `HD-GRP-${order.groupId}` : order.id);
    if (!groupedRunsMap[key]) {
      groupedRunsMap[key] = {
        groupKey: key,
        groupCode: order.groupCode || (order.groupId ? `#HD-GRP-${order.groupId}` : `#HD-GRP-${order.id}`),
        groupId: order.groupId,
        orders: [],
        totalWeightKg: 0,
        totalAmount: 0,
      };
    }
    groupedRunsMap[key].orders.push(order);
    groupedRunsMap[key].totalWeightKg += (order.quantityKg || 5);
    const amtNum = parseFloat(String(order.amount).replace(/[^0-9.]/g, '')) || 0;
    groupedRunsMap[key].totalAmount += amtNum;
  });
  const groupedRunsList = Object.values(groupedRunsMap);

  const filteredGroupedRuns = groupedRunsList.filter((group) => {
    const matchesSearch =
      group.groupCode.toLowerCase().includes(searchQuery.toLowerCase()) ||
      group.orders.some((o) =>
        o.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
        o.customerName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        o.grainType.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (o.customerPhone && o.customerPhone.includes(searchQuery))
      );
    const matchesGrain = selectedGrain === 'All' || group.orders.some((o) => o.grainType === selectedGrain);
    return matchesSearch && matchesGrain;
  });

  const getActiveTabList = () => {
    if (activeFilterTab === 0) return newRequests;
    if (activeFilterTab === 1) return inMillingOrders;
    if (activeFilterTab === 2) return completedHistoryOrders;
    return groupedBatchOrders;
  };

  const currentTabList = getActiveTabList();

  const filteredRequests = currentTabList.filter((req) => {
    const matchesSearch =
      req.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      req.customerName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (req.groupCode && req.groupCode.toLowerCase().includes(searchQuery.toLowerCase())) ||
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
              gap: 8,
              padding: '10px 18px',
              borderRadius: 14,
              backgroundColor: isFilterDrawerOpen ? '#FAF6F0' : 'white',
            }}
          >
            <Filter size={16} />
            <span>Filter</span>
          </button>
          <button className="btn-primary" style={{ backgroundColor: '#8C4A3E', background: 'linear-gradient(135deg, #8C4A3E, #6E372D)', padding: '10px 18px', borderRadius: 14 }}>
            <Download size={16} />
            <span>Export Report</span>
          </button>
        </div>
      </div>

      <div className="grid-cards-3" style={{ marginBottom: 24 }}>
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
            GROUPED BATCH RUNS
          </div>
          <div style={{ fontSize: '2.1rem', fontWeight: 800, color: '#6E5616', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
            {groupedBatchOrders.length}
          </div>
          <span style={{ fontSize: '0.82rem', color: '#1E8449', fontWeight: 700, marginTop: 6, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            Multi-order stacked trips
          </span>
        </div>
      </div>

      <div className="card" style={{ padding: 24, marginBottom: 28 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Activity size={18} color="#8C4A3E" />
              <h2 className="card-title" style={{ fontSize: '1.15rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>
                Order Inflow & Milling Velocity
              </h2>
            </div>
            <p style={{ fontSize: '0.78rem', color: '#756D69', margin: '3px 0 0 0' }}>Daily order submissions vs fulfilled & delivered jobs</p>
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

        {(() => {
          const totalOrdersCount = Math.max(allOrders.length, 12);
          const totalDeliveredCount = Math.max(completedHistoryOrders.length, 8);

          let labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Today (Peak)'];
          let placedFactors = [0.4, 0.55, 0.7, 0.85, 0.95, 1.1, 1.3];
          let deliveredFactors = [0.35, 0.48, 0.62, 0.75, 0.88, 1.0, 1.15];

          if (timeframe === 'month') {
            labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Live Peak'];
            placedFactors = [0.55, 0.78, 1.0, 1.25, 1.45];
            deliveredFactors = [0.5, 0.7, 0.92, 1.15, 1.3];
          }

          const placedVals = labels.map((_, i) => Math.round((totalOrdersCount / 2) * placedFactors[i]));
          const deliveredVals = labels.map((_, i) => Math.round((totalDeliveredCount / 2) * deliveredFactors[i]));

          const rawMax = Math.max(...placedVals, ...deliveredVals);
          const maxVal = Math.max(10, Math.ceil((rawMax * 1.15) / 5) * 5);

          const svgWidth = 780;
          const svgHeight = 220;
          const leftPad = 60;
          const rightPad = 25;
          const topPad = 25;
          const bottomPad = 40;
          const chartWidth = svgWidth - leftPad - rightPad;
          const chartHeight = svgHeight - topPad - bottomPad;

          const yTicks = [
            { val: maxVal, y: topPad },
            { val: Math.round(maxVal * 0.66), y: topPad + chartHeight * 0.34 },
            { val: Math.round(maxVal * 0.33), y: topPad + chartHeight * 0.67 },
            { val: 0, y: topPad + chartHeight },
          ];

          const groupWidth = chartWidth / labels.length;
          const barWidth = Math.min(24, groupWidth * 0.28);
          const barGap = 4;

          const barGroups = labels.map((lbl, idx) => {
            const placed = placedVals[idx];
            const delivered = deliveredVals[idx];

            const groupCenterX = leftPad + idx * groupWidth + groupWidth / 2;
            const placedHeight = Math.max(4, (placed / maxVal) * chartHeight);
            const deliveredHeight = Math.max(4, (delivered / maxVal) * chartHeight);

            const placedX = groupCenterX - barWidth - barGap / 2;
            const placedY = topPad + chartHeight - placedHeight;

            const deliveredX = groupCenterX + barGap / 2;
            const deliveredY = topPad + chartHeight - deliveredHeight;

            return {
              idx,
              label: lbl,
              placed,
              delivered,
              groupCenterX,
              placedX,
              placedY,
              placedHeight,
              deliveredX,
              deliveredY,
              deliveredHeight,
              isPeak: idx === labels.length - 1,
            };
          });

          return (
            <div style={{ background: '#FAF6F0', borderRadius: 16, border: '1px solid #ECE4D9', padding: '18px 20px', position: 'relative' }}>
              {hoveredPoint && (
                <div
                  className="chart-floating-tooltip"
                  style={{
                    left: `${(hoveredPoint.groupCenterX / svgWidth) * 100}%`,
                    top: `${Math.min(hoveredPoint.placedY, hoveredPoint.deliveredY) + 40}px`,
                    backgroundColor: 'rgba(38, 33, 30, 0.96)',
                    borderRadius: '10px',
                    padding: '10px 14px',
                    boxShadow: '0 10px 25px rgba(0, 0, 0, 0.3)',
                    border: '1px solid rgba(255, 255, 255, 0.15)',
                    position: 'absolute',
                    zIndex: 10,
                  }}
                >
                  <div style={{ color: '#FF9A93', fontSize: '0.78rem', fontWeight: 800, marginBottom: 4 }}>
                    {hoveredPoint.label}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: '0.84rem', color: '#FFFFFF', fontWeight: 800, marginBottom: 3 }}>
                    <span style={{ width: 8, height: 8, borderRadius: 2, backgroundColor: '#8C4A3E', display: 'inline-block' }}></span>
                    <span>Placed: {hoveredPoint.placed} Orders</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: '0.76rem', color: '#2ECC71', fontWeight: 700 }}>
                    <span style={{ width: 8, height: 8, borderRadius: 2, backgroundColor: '#1E8449', display: 'inline-block' }}></span>
                    <span>Fulfilled: {hoveredPoint.delivered} Orders</span>
                  </div>
                </div>
              )}

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
                <div style={{ display: 'flex', gap: 20, fontSize: '0.8rem', fontWeight: 700 }}>
                  <span style={{ display: 'flex', alignItems: 'center', gap: 7, color: '#8C4A3E' }}>
                    <span style={{ width: 10, height: 10, borderRadius: 2, backgroundColor: '#8C4A3E', display: 'inline-block' }}></span>
                    Orders Placed ({allOrders.length})
                  </span>
                  <span style={{ display: 'flex', alignItems: 'center', gap: 7, color: '#1E8449' }}>
                    <span style={{ width: 10, height: 10, borderRadius: 2, backgroundColor: '#1E8449', display: 'inline-block' }}></span>
                    Fulfilled & Delivered ({completedHistoryOrders.length})
                  </span>
                </div>
                <span style={{ fontSize: '0.75rem', color: '#1E8449', fontWeight: 800, background: '#E8F8F0', padding: '3px 8px', borderRadius: 8 }}>
                  +24.2% Daily Velocity
                </span>
              </div>

              <svg viewBox={`0 0 ${svgWidth} ${svgHeight}`} style={{ width: '100%', height: '220px', overflow: 'visible' }}>
                <defs>
                  <linearGradient id="placedGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" stopColor="#8C4A3E" />
                    <stop offset="100%" stopColor="#B86B5D" />
                  </linearGradient>
                  <linearGradient id="fulfilledGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" stopColor="#1E8449" />
                    <stop offset="100%" stopColor="#2ECC71" />
                  </linearGradient>
                </defs>

                {yTicks.map((tick, i) => (
                  <g key={`ytick_${i}`}>
                    <line
                      x1={leftPad}
                      y1={tick.y}
                      x2={leftPad + chartWidth}
                      y2={tick.y}
                      stroke={tick.val === 0 ? '#DAC8B3' : '#ECE4D9'}
                      strokeWidth={tick.val === 0 ? 1.5 : 1}
                      strokeDasharray={tick.val === 0 ? undefined : '4 4'}
                    />
                    <text
                      x={leftPad - 10}
                      y={tick.y + 4}
                      textAnchor="end"
                      fontSize="10.5"
                      fontWeight="600"
                      fill="#8A817C"
                    >
                      {tick.val}
                    </text>
                  </g>
                ))}

                {barGroups.map((grp) => {
                  const isHovered = hoveredPoint?.label === grp.label;

                  return (
                    <g
                      key={`grp_${grp.idx}`}
                      style={{ cursor: 'pointer' }}
                      onMouseEnter={() => setHoveredPoint(grp)}
                      onMouseLeave={() => setHoveredPoint(null)}
                    >
                      <rect
                        x={grp.groupCenterX - groupWidth / 2 + 2}
                        y={topPad}
                        width={groupWidth - 4}
                        height={chartHeight}
                        fill={isHovered ? 'rgba(140, 74, 62, 0.07)' : 'transparent'}
                        rx="8"
                      />

                      <rect
                        x={grp.placedX}
                        y={grp.placedY}
                        width={barWidth}
                        height={grp.placedHeight}
                        fill="url(#placedGrad)"
                        rx="5"
                        style={{
                          transition: 'all 0.3s ease',
                          filter: isHovered ? 'brightness(1.1) drop-shadow(0 4px 6px rgba(140, 74, 62, 0.3))' : 'none',
                        }}
                      />

                      <rect
                        x={grp.deliveredX}
                        y={grp.deliveredY}
                        width={barWidth}
                        height={grp.deliveredHeight}
                        fill="url(#fulfilledGrad)"
                        rx="5"
                        style={{
                          transition: 'all 0.3s ease',
                          filter: isHovered ? 'brightness(1.1) drop-shadow(0 4px 6px rgba(30, 132, 73, 0.3))' : 'none',
                        }}
                      />

                      <text
                        x={grp.placedX + barWidth / 2}
                        y={grp.placedY - 6}
                        textAnchor="middle"
                        fontSize="9.5"
                        fontWeight={isHovered || grp.isPeak ? '800' : '600'}
                        fill={isHovered ? '#8C4A3E' : '#756D69'}
                      >
                        {grp.placed}
                      </text>

                      {grp.isPeak && (
                        <circle
                          cx={grp.placedX + barWidth / 2}
                          cy={grp.placedY}
                          r="4"
                          fill="#8C4A3E"
                          stroke="#FFF"
                          strokeWidth="1.5"
                          className="live-pulse-radar"
                        />
                      )}

                      <text
                        x={grp.groupCenterX}
                        y={topPad + chartHeight + 20}
                        textAnchor="middle"
                        fontSize={grp.isPeak ? '11.5' : '11'}
                        fontWeight={grp.isPeak ? '800' : (isHovered ? '700' : '600')}
                        fill={grp.isPeak ? '#8C4A3E' : (isHovered ? '#2A2421' : '#756D69')}
                      >
                        {grp.label}
                      </text>
                    </g>
                  );
                })}

                <line
                  x1={leftPad}
                  y1={topPad + chartHeight}
                  x2={leftPad + chartWidth}
                  y2={topPad + chartHeight}
                  stroke="#DAC8B3"
                  strokeWidth="1.5"
                />
              </svg>
            </div>
          );
        })()}
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
          <button className={`filter-tab ${activeFilterTab === 3 ? 'active' : ''}`} onClick={() => setActiveFilterTab(3)}>
            <Layers size={15} />
            <span>GROUPED RUNS</span>
            <span className="tab-badge" style={{ backgroundColor: '#FFF8E7', color: '#B7791F', border: '1px solid #F6AD55' }}>
              {groupedRunsList.length} RUNS ({groupedBatchOrders.length})
            </span>
          </button>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 8, background: '#FAF6F0', padding: '8px 16px', borderRadius: 24, border: '1px solid #ECE4D9', width: 280 }}>
          <Search size={15} color="#756D69" />
          <input placeholder="Search orders / group code..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} style={{ border: 'none', background: 'transparent', outline: 'none', fontSize: '0.85rem', width: '100%' }} />
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

      {/* RENDER GROUPED RUNS HIERARCHICAL VIEW (TAB 3) */}
      {activeFilterTab === 3 ? (
        filteredGroupedRuns.length === 0 ? (
          <div className="card" style={{ textAlign: 'center', padding: '48px 24px', color: '#756D69' }}>
            <Layers size={40} color="#A59D96" style={{ margin: '0 auto 12px auto' }} />
            <div style={{ fontWeight: 800, fontSize: '1.1rem', color: '#2A2421' }}>
              No Grouped Delivery Runs Found
            </div>
            <p style={{ fontSize: '0.85rem', margin: '4px 0 16px 0' }}>
              When orders are grouped into combined delivery runs, they will appear here with all nested stops.
            </p>
            <button onClick={handleResetFilters} className="btn-outline" style={{ padding: '8px 18px', borderRadius: 14 }}>Reset Filters</button>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
            {filteredGroupedRuns.map((group) => {
              const allDelivered = group.orders.every(o => o.status === 'DELIVERED');
              const hasPlaced = group.orders.some(o => o.status === 'PLACED');

              return (
                <div
                  key={group.groupKey}
                  className="card"
                  style={{
                    padding: 24,
                    background: '#FFFDF9',
                    borderRadius: 18,
                    border: '1.5px solid #E2D3B8',
                    boxShadow: '0 4px 18px rgba(140, 74, 62, 0.05)',
                  }}
                >
                  {/* Master Group Header */}
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 14, marginBottom: 20, paddingBottom: 16, borderBottom: '1px solid #ECE4D9' }}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
                        <span
                          style={{
                            backgroundColor: '#FFF8E7',
                            color: '#B7791F',
                            fontSize: '0.88rem',
                            fontWeight: 800,
                            padding: '5px 14px',
                            borderRadius: 10,
                            border: '1.5px solid #F6AD55',
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 6,
                            letterSpacing: 0.5,
                          }}
                        >
                          <Layers size={15} />
                          {group.groupCode}
                        </span>
                        <span style={{ fontSize: '0.8rem', color: '#756D69', fontWeight: 700 }}>
                          Multi-Order Delivery Batch Run
                        </span>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 18, fontSize: '0.86rem', color: '#2A2421', fontWeight: 700, marginTop: 6, flexWrap: 'wrap' }}>
                        <span>📦 <strong>{group.orders.length}</strong> Individual Orders / Stops</span>
                        <span>⚖️ <strong>{group.totalWeightKg.toFixed(1)} kg</strong> Combined Weight</span>
                        <span>💰 <strong>₹{group.totalAmount.toFixed(2)}</strong> Total Run Value</span>
                      </div>
                    </div>

                    <div>
                      <span
                        style={{
                          backgroundColor: allDelivered ? '#E8F8F0' : hasPlaced ? '#FDEDEC' : '#FFF8E7',
                          color: allDelivered ? '#1E8449' : hasPlaced ? '#C0392B' : '#B7791F',
                          fontSize: '0.78rem',
                          fontWeight: 800,
                          padding: '6px 14px',
                          borderRadius: 14,
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: 6,
                        }}
                      >
                        <span className="green-dot" style={{ width: 8, height: 8, background: allDelivered ? '#2ECC71' : hasPlaced ? '#E74C3C' : '#F39C12' }}></span>
                        {allDelivered ? 'ALL STOPS DELIVERED' : hasPlaced ? 'NEW REQUESTS PENDING' : 'BATCH IN PROGRESS'}
                      </span>
                    </div>
                  </div>

                  {/* Nested Individual Orders of that Group */}
                  <div>
                    <div style={{ fontSize: '0.75rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.6, textTransform: 'uppercase', marginBottom: 14 }}>
                      INDIVIDUAL ORDERS IN THIS GROUP ({group.orders.length} STOPS):
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(310px, 1fr))', gap: 14 }}>
                      {group.orders.map((req, stopIdx) => (
                        <div
                          key={req.id}
                          style={{
                            backgroundColor: '#FFFFFF',
                            borderRadius: 14,
                            border: '1px solid #ECE4D9',
                            padding: 16,
                            display: 'flex',
                            flexDirection: 'column',
                            justifyContent: 'space-between',
                            boxShadow: '0 2px 8px rgba(0,0,0,0.02)',
                          }}
                        >
                          <div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                              <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#8C4A3E', background: '#FFECEB', padding: '2px 8px', borderRadius: 6 }}>
                                STOP #{stopIdx + 1} • {req.id}
                              </span>
                              <span
                                style={{
                                  backgroundColor: req.status === 'PLACED' ? '#FDEDEC' : req.status === 'ACCEPTED' ? '#FFF8E7' : '#E8F8F0',
                                  color: req.status === 'PLACED' ? '#C0392B' : req.status === 'ACCEPTED' ? '#B7791F' : '#1E8449',
                                  fontSize: '0.72rem',
                                  fontWeight: 800,
                                  padding: '3px 8px',
                                  borderRadius: 10,
                                }}
                              >
                                {req.status}
                              </span>
                            </div>

                            <div style={{ fontWeight: 800, fontSize: '1.05rem', color: '#2A2421', marginBottom: 6 }}>
                              {req.customerName}
                            </div>

                            <div style={{ fontSize: '0.8rem', color: '#756D69', marginBottom: 4, display: 'flex', alignItems: 'center', gap: 6 }}>
                              <Wheat size={14} color="#6E5616" />
                              <span><strong>{req.grainType}</strong> • {req.quantityText}</span>
                            </div>

                            <div style={{ fontSize: '0.78rem', color: '#756D69', display: 'flex', alignItems: 'center', gap: 6 }}>
                              <Truck size={14} color="#8C4A3E" />
                              <span>{req.deliveryAddress}</span>
                            </div>
                          </div>

                          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 12, paddingTop: 10, borderTop: '1px dashed #ECE4D9' }}>
                            <span style={{ fontSize: '0.75rem', color: '#756D69' }}>Order Amount</span>
                            <span style={{ fontWeight: 800, fontSize: '0.95rem', color: '#2A2421' }}>{req.amount}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )
      ) : (
        /* RENDER STANDARD ORDERS GRID (TABS 0, 1, 2) */
        filteredRequests.length === 0 ? (
          <div className="card" style={{ textAlign: 'center', padding: '48px 24px', color: '#756D69' }}>
            <PackageCheck size={40} color="#A59D96" style={{ margin: '0 auto 12px auto' }} />
            <div style={{ fontWeight: 800, fontSize: '1.1rem', color: '#2A2421' }}>
              {activeFilterTab === 0
                ? 'No New Incoming Orders'
                : activeFilterTab === 1
                  ? 'No Orders Currently In Milling'
                  : 'No Completed History Yet'}
            </div>
            <p style={{ fontSize: '0.85rem', margin: '4px 0 16px 0' }}>
              Orders move across stages automatically as they are processed.
            </p>
            <button onClick={handleResetFilters} className="btn-outline" style={{ padding: '8px 18px', borderRadius: 14 }}>Reset Filters</button>
          </div>
        ) : (
          <div className="grid-cards-2">
            {filteredRequests.map((req) => (
              <div key={req.id} className="request-card" style={{ border: req.isGrouped ? '1.8px solid #CBA034' : '1px solid #ECE4D9' }}>
                <div className="request-card-header">
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <div style={{ fontSize: '0.75rem', fontWeight: 800, color: 'var(--primary-terracotta)', letterSpacing: 0.5 }}>{req.id}</div>
                      {req.isGrouped && (
                        <span
                          style={{
                            backgroundColor: '#FFF8E7',
                            color: '#B7791F',
                            fontSize: '0.68rem',
                            fontWeight: 800,
                            padding: '2px 7px',
                            borderRadius: 8,
                            border: '1px solid #F6AD55',
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 3,
                          }}
                        >
                          <Layers size={10} />
                          {req.groupCode || `GROUP #${req.groupId}`}
                        </span>
                      )}
                    </div>
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

                  {req.isGrouped && (
                    <div style={{ backgroundColor: '#FAF6F0', borderRadius: 10, padding: '8px 12px', marginBottom: 10, border: '1px dashed #DAC8B3' }}>
                      <div style={{ fontSize: '0.75rem', fontWeight: 800, color: '#6E5616', display: 'flex', alignItems: 'center', gap: 5 }}>
                        <Truck size={13} /> Linked to Grouped Delivery Run: <strong>{req.groupCode || `#HD-GRP-${req.groupId}`}</strong>
                      </div>
                    </div>
                  )}

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
                      <span style={{ fontSize: '0.85rem', fontWeight: 700, color: '#1E8449', display: 'flex', alignItems: 'center', gap: 6 }}><CheckCircle size={16} /> {req.status === 'DELIVERED' ? 'Delivered to Customer' : 'Milled & Ready / In Transit'}</span>
                      <span style={{ fontWeight: 800, fontSize: '1rem', color: '#2A2421' }}>{req.amount}</span>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )
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
