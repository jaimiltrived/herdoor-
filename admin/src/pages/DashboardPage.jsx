import React from 'react';
import {
  Clock,
  ShieldCheck,
  ChevronRight,
  ArrowUpRight,
  Truck,
  Eye,
  Gift,
  Landmark,
  Users,
  Percent,
  BarChart3,
  Store,
  Sparkles,
  ArrowRight
} from 'lucide-react';
import { pendingRequests } from '../data/mockData';

export default function DashboardPage({
  orders = [],
  shopStatus = true,
  onToggleShopStatus = () => {},
  onOpenAcceptModal = () => {},
  onSelectOrderDetails = () => {},
  onNavigateTab = () => {},
}) {
  const [timeframe, setTimeframe] = React.useState('7d');
  const [hoveredPoint, setHoveredPoint] = React.useState(null);
  const [livePulseTick, setLivePulseTick] = React.useState(0);

  // Periodic heartbeat for real-time live graph animation
  React.useEffect(() => {
    const timer = setInterval(() => {
      setLivePulseTick((prev) => (prev + 1) % 100);
    }, 2500);
    return () => clearInterval(timer);
  }, []);

  // Compute dynamic live data points based on actual orders
  const baseOrderCount = orders.length || 12;
  const todayRevenue = orders
    .reduce((sum, o) => sum + (parseFloat(o.totalAmount || o.price || 180)), 0)
    .toLocaleString('en-IN', { maximumFractionDigits: 0 });

  const getDynamicTimelineData = () => {
    if (timeframe === '24h') {
      return [
        { label: '06:00', orders: Math.max(1, Math.round(baseOrderCount * 0.2)), volume: '18 kg', fulfillment: '100%', y: 130 },
        { label: '09:00', orders: Math.max(2, Math.round(baseOrderCount * 0.5)), volume: '42 kg', fulfillment: '98.5%', y: 100 },
        { label: '12:00', orders: Math.max(4, Math.round(baseOrderCount * 0.85)), volume: '86 kg', fulfillment: '99.0%', y: 65 },
        { label: '15:00', orders: Math.max(3, Math.round(baseOrderCount * 0.7)), volume: '64 kg', fulfillment: '99.2%', y: 78 },
        { label: '18:00', orders: Math.max(5, Math.round(baseOrderCount * 0.95)), volume: '95 kg', fulfillment: '98.8%', y: 48 },
        { label: 'Live Now', orders: baseOrderCount, volume: `${baseOrderCount * 12} kg`, fulfillment: '99.4%', y: 32 },
      ];
    } else if (timeframe === '30d') {
      return [
        { label: 'Week 1', orders: Math.max(10, baseOrderCount * 3), volume: '380 kg', fulfillment: '98.0%', y: 125 },
        { label: 'Week 2', orders: Math.max(18, baseOrderCount * 5), volume: '620 kg', fulfillment: '98.7%', y: 95 },
        { label: 'Week 3', orders: Math.max(26, baseOrderCount * 7), volume: '910 kg', fulfillment: '99.1%', y: 68 },
        { label: 'Week 4', orders: Math.max(35, baseOrderCount * 9), volume: '1,240 kg', fulfillment: '99.5%', y: 40 },
        { label: 'Peak Forecast', orders: Math.max(42, baseOrderCount * 11), volume: '1,580 kg', fulfillment: '99.6%', y: 26 },
      ];
    }
    // 7d default
    return [
      { label: 'Mon', orders: Math.max(2, Math.round(baseOrderCount * 0.35)), volume: '32 kg', fulfillment: '98.2%', y: 128 },
      { label: 'Tue', orders: Math.max(3, Math.round(baseOrderCount * 0.5)), volume: '48 kg', fulfillment: '98.8%', y: 104 },
      { label: 'Wed', orders: Math.max(4, Math.round(baseOrderCount * 0.65)), volume: '62 kg', fulfillment: '99.0%', y: 82 },
      { label: 'Thu', orders: Math.max(5, Math.round(baseOrderCount * 0.8)), volume: '76 kg', fulfillment: '99.2%', y: 64 },
      { label: 'Fri', orders: Math.max(7, Math.round(baseOrderCount * 0.95)), volume: '94 kg', fulfillment: '99.1%', y: 44 },
      { label: 'Sat', orders: Math.max(9, Math.round(baseOrderCount * 1.1)), volume: '118 kg', fulfillment: '99.5%', y: 34 },
      { label: 'Live (Peak)', orders: baseOrderCount + 3, volume: `${(baseOrderCount + 3) * 14} kg`, fulfillment: '99.4%', y: 26 },
    ];
  };

  const timelineData = getDynamicTimelineData();
  const width = 840;
  const startX = 55;
  const endX = 810;
  const stepX = (endX - startX) / (timelineData.length - 1);

  const calculatedPoints = timelineData.map((item, idx) => ({
    ...item,
    x: startX + idx * stepX,
  }));

  // Build dynamic spline path
  let pathD = `M ${calculatedPoints[0].x} ${calculatedPoints[0].y}`;
  for (let i = 0; i < calculatedPoints.length - 1; i++) {
    const cpX = (calculatedPoints[i].x + calculatedPoints[i + 1].x) / 2;
    pathD += ` C ${cpX} ${calculatedPoints[i].y}, ${cpX} ${calculatedPoints[i + 1].y}, ${calculatedPoints[i + 1].x} ${calculatedPoints[i + 1].y}`;
  }
  const areaD = `${pathD} L ${calculatedPoints[calculatedPoints.length - 1].x} 150 L ${calculatedPoints[0].x} 150 Z`;
  const latestPt = calculatedPoints[calculatedPoints.length - 1];
  const quickAccessActions = [
    {
      id: 16,
      title: 'Gift & Vouchers',
      subtitle: 'Issue promo rewards & codes',
      icon: Gift,
      color: '#8C4A3E',
      bg: '#FFECEB',
      badge: 'PROMO HUB'
    },
    {
      id: 10,
      title: 'Accounting Ledger',
      subtitle: 'Revenue, expenses & tax P&L',
      icon: Landmark,
      color: '#7A6818',
      bg: '#EFE6D2',
      badge: 'FINANCIALS'
    },
    {
      id: 2,
      title: 'Citizen Directory',
      subtitle: 'Manage registered users & VIPs',
      icon: Users,
      color: '#1E8449',
      bg: '#E8F8F0',
      badge: 'CUSTOMERS'
    },
    {
      id: 8,
      title: 'Commission Rates',
      subtitle: 'Configure merchant tier rates',
      icon: Percent,
      color: '#8C6E15',
      bg: '#FBF4DF',
      badge: 'REVENUE'
    },
    {
      id: 15,
      title: 'Advanced Analytics',
      subtitle: 'Predictive multi-grain forecast',
      icon: BarChart3,
      color: '#6B701D',
      bg: '#EFF3DB',
      badge: 'INTELLIGENCE'
    },
    {
      id: 1,
      title: 'Flour Mills & Fleet',
      subtitle: 'Mill capacity & dispatch riders',
      icon: Store,
      color: '#2A2421',
      bg: '#F3EBE1',
      badge: 'OPERATIONS'
    },
  ];

  return (
    <div className="dashboard-page">
      {/* Hero Banner Header */}
      <div
        style={{
          backgroundColor: '#F3EBE1',
          borderRadius: 20,
          padding: '24px 28px',
          marginBottom: 28,
          display: 'flex',
          justify: 'space-between',
          alignItems: 'center',
          border: '1px solid #ECE4D9',
          boxShadow: '0 4px 16px rgba(140, 74, 62, 0.05)'
        }}
      >
        <div>
          <h1 className="serif-heading" style={{ fontSize: '1.8rem', fontWeight: 800, color: '#2A2421' }}>
            Welcome back to HerDoor Portal 👋
          </h1>
          <p style={{ fontSize: '0.92rem', color: '#756D69', marginTop: 4 }}>
            Super Admin Platform Console • Monitoring <strong>48 active flour mills</strong> & <strong>12 new order requests</strong> today.
          </p>
        </div>
        <button
          className="btn-primary"
          onClick={() => onNavigateTab(5)}
          style={{ backgroundColor: '#8C4A3E', background: 'linear-gradient(135deg, #8C4A3E, #6E372D)' }}
        >
          <span>View Orders Console</span>
          <ChevronRight size={18} />
        </button>
      </div>

      {/* Quick Access Shortcuts Grid (Requested by User) */}
      <div style={{ marginBottom: 32 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Sparkles size={20} color="#8C4A3E" />
            <h2 className="serif-heading" style={{ fontSize: '1.35rem', fontWeight: 800, color: '#2A2421' }}>
              Quick Access Console & Gift Shortcuts
            </h2>
          </div>
          <span style={{ fontSize: '0.8rem', color: '#756D69', fontWeight: 600 }}>1-Click Platform Launcher</span>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 16 }}>
          {quickAccessActions.map((qa) => {
            const IconComp = qa.icon;
            return (
              <div
                key={qa.id}
                onClick={() => onNavigateTab(qa.id)}
                style={{
                  backgroundColor: 'white',
                  borderRadius: 18,
                  border: '1px solid #ECE4D9',
                  padding: '18px 20px',
                  cursor: 'pointer',
                  transition: 'all 0.22s cubic-bezier(0.16, 1, 0.3, 1)',
                  boxShadow: '0 4px 16px rgba(140, 74, 62, 0.04)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  gap: 14,
                }}
                className="quick-access-tile"
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 14, flex: 1, minWidth: 0 }}>
                  <div
                    style={{
                      width: 46,
                      height: 46,
                      borderRadius: 14,
                      backgroundColor: qa.bg,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: qa.color,
                      flexShrink: 0,
                      alignSelf: 'center',
                    }}
                  >
                    <IconComp size={22} />
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', minWidth: 0, flex: 1 }}>
                    <span
                      style={{
                        fontSize: '0.65rem',
                        fontWeight: 800,
                        color: qa.color,
                        letterSpacing: 0.5,
                        textTransform: 'uppercase',
                        marginBottom: 2,
                      }}
                    >
                      {qa.badge}
                    </span>
                    <div style={{ fontWeight: 800, fontSize: '0.98rem', color: '#2A2421', lineHeight: 1.25 }}>{qa.title}</div>
                    <div style={{ fontSize: '0.78rem', color: '#756D69', marginTop: 2, lineHeight: 1.3 }}>{qa.subtitle}</div>
                  </div>
                </div>
                <ArrowRight size={16} color="#A59D96" style={{ flexShrink: 0, alignSelf: 'center' }} />
              </div>
            );
          })}
        </div>
      </div>

      {/* Top Banner Stats Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: 20, marginBottom: 28 }}>
        {/* Operating Status Card */}
        <div className="card shop-status-card">
          <div className="status-header">
            <div>
              <div className="status-title">Platform Gateway Status</div>
              <div className="status-indicator" style={{ marginTop: 4 }}>
                <span className={shopStatus ? 'green-dot' : 'grey-dot'}></span>
                <span>{shopStatus ? 'System Operational' : 'Maintenance Mode'}</span>
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
              <Clock size={18} color="#6E5616" />
            </div>
            <div>
              <div style={{ fontSize: '0.7rem', color: '#756D69' }}>Console Hours</div>
              <div style={{ fontSize: '0.95rem', fontWeight: 800, color: '#2A2421' }}>
                24/7 Real-Time Sync
              </div>
            </div>
          </div>
        </div>

        {/* New Orders Widget */}
        <div className="card new-orders-card">
          <div className="stats-top">
            <div className="pink-icon-bg">
              <ShieldCheck size={22} color="white" />
            </div>
            <span className="badge-tag" style={{ backgroundColor: '#FFECEB', color: '#8C4A3E' }}>+3 New</span>
          </div>

          <div>
            <div className="stat-number" style={{ color: '#2A2421' }}>{pendingRequests.length || 2}</div>
            <div className="stat-label">Pending Milling Requests</div>
          </div>
        </div>

        {/* Today's Platform Revenue */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.85rem', color: '#756D69', fontWeight: 600 }}>Today's Revenue</span>
            <span style={{ backgroundColor: '#E8F8F0', color: '#1E8449', fontSize: '0.75rem', fontWeight: 800, padding: '4px 10px', borderRadius: 12, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              <ArrowUpRight size={14} />
              +18.4%
            </span>
          </div>
          <div>
            <div className="serif-heading" style={{ fontSize: '2.2rem', fontWeight: 800, color: '#8C4A3E' }}>
              ₹{todayRevenue}
            </div>
            <div style={{ fontSize: '0.85rem', color: '#756D69' }}>
              {orders.length} Active Orders Fulfilled
            </div>
          </div>
        </div>

        {/* Active Dispatch Fleet */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ fontSize: '0.85rem', color: '#756D69', fontWeight: 600 }}>Delivery Fleet</span>
            <span style={{ backgroundColor: '#EFE6D2', color: '#6E5616', fontSize: '0.75rem', fontWeight: 800, padding: '4px 10px', borderRadius: 12 }}>
              14 Online
            </span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 10 }}>
            <div style={{ width: 42, height: 42, borderRadius: 12, backgroundColor: '#FFECEB', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#8C4A3E' }}>
              <Truck size={22} />
            </div>
            <div>
              <div style={{ fontWeight: 800, fontSize: '1rem', color: '#2A2421' }}>Express Delivery Active</div>
              <div style={{ fontSize: '0.8rem', color: '#756D69' }}>Bins A-1 to Bin A-8</div>
            </div>
          </div>
        </div>
      </div>

      {/* Platform Real-Time Velocity & Order Inflow Graph */}
      <div className="card" style={{ padding: 24, marginBottom: 28, position: 'relative' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20, flexWrap: 'wrap', gap: 12 }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <BarChart3 size={20} color="#8C4A3E" />
              <h2 className="card-title" style={{ fontSize: '1.2rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>
                Platform Order Velocity & Milling Inflow
              </h2>
              <span className="live-stream-badge">
                <span className="live-stream-dot"></span>
                <span>REAL-TIME STREAM</span>
              </span>
            </div>
            <p style={{ fontSize: '0.78rem', color: '#756D69', margin: '3px 0 0 0' }}>Live daily milling volume vs target customer deliveries</p>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{ display: 'flex', gap: 14, fontSize: '0.78rem', fontWeight: 700 }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#8C4A3E' }}>
                <span style={{ width: 10, height: 10, borderRadius: 3, background: '#8C4A3E' }}></span> Orders Volume ({orders.length || 24})
              </span>
              <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#1E8449' }}>
                <span style={{ width: 10, height: 2, background: '#1E8449' }}></span> Target Fulfillment (99.4%)
              </span>
            </div>

            <select
              value={timeframe}
              onChange={(e) => setTimeframe(e.target.value)}
              style={{
                padding: '6px 12px',
                borderRadius: 10,
                border: '1px solid #ECE4D9',
                backgroundColor: '#FAF6F0',
                fontWeight: 700,
                fontSize: '0.8rem',
                cursor: 'pointer',
                outline: 'none',
              }}
            >
              <option value="24h">24 Hours</option>
              <option value="7d">7 Days</option>
              <option value="30d">30 Days</option>
            </select>
          </div>
        </div>

        <div style={{ background: '#FAF6F0', borderRadius: 16, border: '1px solid #ECE4D9', padding: '18px 20px', position: 'relative' }}>
          {/* Floating Interactive Tooltip */}
          {hoveredPoint && (
            <div
              className="chart-floating-tooltip"
              style={{
                left: `${(hoveredPoint.x / 840) * 100}%`,
                top: `${hoveredPoint.y}px`,
              }}
            >
              <div style={{ color: '#FF9A93', fontSize: '0.7rem' }}>{hoveredPoint.label} Telemetry</div>
              <div>{hoveredPoint.orders} Orders • {hoveredPoint.volume}</div>
              <div style={{ color: '#2ECC71', fontSize: '0.7rem', marginTop: 2 }}>{hoveredPoint.fulfillment} Fulfillment SLA</div>
            </div>
          )}

          <svg viewBox="0 0 840 160" style={{ width: '100%', height: '160px', overflow: 'visible' }}>
            <defs>
              <linearGradient id="dashVelocityGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" stopColor="#8C4A3E" stopOpacity="0.30" />
                <stop offset="100%" stopColor="#8C4A3E" stopOpacity="0.0" />
              </linearGradient>
            </defs>
            <line x1="45" y1="30" x2="820" y2="30" stroke="#ECE4D9" strokeDasharray="3,3" />
            <line x1="45" y1="70" x2="820" y2="70" stroke="#ECE4D9" strokeDasharray="3,3" />
            <line x1="45" y1="110" x2="820" y2="110" stroke="#ECE4D9" strokeDasharray="3,3" />
            <line x1="45" y1="150" x2="820" y2="150" stroke="#D5C9B8" strokeWidth="1.5" />
            <line x1="45" y1="45" x2="820" y2="45" stroke="#1E8449" strokeWidth="2" strokeDasharray="6,6" />

            <path
              d={areaD}
              fill="url(#dashVelocityGrad)"
              style={{ transition: 'all 0.4s ease' }}
            />
            <path
              d={pathD}
              fill="none"
              stroke="#8C4A3E"
              strokeWidth="3.5"
              strokeLinecap="round"
              style={{ transition: 'all 0.4s ease' }}
            />

            {/* Calculated Data Points with Hover Detection */}
            {calculatedPoints.map((pt, i) => (
              <g
                key={i}
                onMouseEnter={() => setHoveredPoint(pt)}
                onMouseLeave={() => setHoveredPoint(null)}
                style={{ cursor: 'pointer' }}
              >
                <circle
                  cx={pt.x}
                  cy={pt.y}
                  r={hoveredPoint?.label === pt.label ? 7 : (i === calculatedPoints.length - 1 ? 6 : 4.5)}
                  fill={i === calculatedPoints.length - 1 ? '#1E8449' : '#8C4A3E'}
                  stroke="white"
                  strokeWidth="2.5"
                  className="graph-interactive-node"
                />
              </g>
            ))}

            {/* Pulsating Real-Time Radar Beacon on Latest Node */}
            <circle
              cx={latestPt.x}
              cy={latestPt.y}
              r="6"
              fill="none"
              stroke="#1E8449"
              strokeWidth="2"
              className="live-pulse-radar"
            />
          </svg>

          <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', color: '#756D69', marginTop: 8, fontWeight: 600, paddingLeft: 45, paddingRight: 8 }}>
            {calculatedPoints.map((pt, idx) => (
              <span
                key={idx}
                style={{
                  color: idx === calculatedPoints.length - 1 ? '#8C4A3E' : '#756D69',
                  fontWeight: idx === calculatedPoints.length - 1 ? 800 : 600,
                }}
              >
                {pt.label}
              </span>
            ))}
          </div>
        </div>
      </div>

      {/* Active Processing Queue & Orders Table */}
      <div className="table-card-container">
        <div className="desktop-table-header">
          <div>
            <h2 className="serif-heading" style={{ fontSize: '1.35rem', fontWeight: 800 }}>
              Active Processing Queue & Orders
            </h2>
            <div style={{ fontSize: '0.8rem', color: '#756D69', marginTop: 2 }}>
              Real-time milling & delivery status control table.
            </div>
          </div>
          <button className="btn-outline" onClick={() => onNavigateTab(5)}>
            <span>View Orders Console</span>
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
                <td style={{ fontWeight: 800, fontSize: '0.95rem', color: '#8C4A3E' }}>
                  {ord.id}
                </td>
                <td>
                  <div style={{ fontWeight: 800, fontSize: '0.95rem' }}>{ord.customerName}</div>
                  <div style={{ fontSize: '0.75rem', color: '#756D69' }}>Bin: {ord.binLocation || 'Bin A-4'}</div>
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
                <td style={{ fontSize: '0.85rem', color: '#756D69' }}>
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
            <div style={{ fontSize: '0.8rem', color: '#756D69', marginTop: 2 }}>
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
                <td style={{ fontWeight: 800, fontSize: '0.9rem', color: '#756D69' }}>{req.id}</td>
                <td style={{ fontWeight: 800, fontSize: '0.95rem' }}>
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
