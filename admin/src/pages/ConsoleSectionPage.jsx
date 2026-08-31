import React, { useState, useEffect } from 'react';
import {
  Search,
  Filter,
  Plus,
  Pencil,
  Trash2,
  X,
  Check,
  Activity,
  Layers,
  RotateCcw,
  SlidersHorizontal,
  TrendingUp,
  ShieldCheck,
  Truck,
  Users,
  Building2,
  DollarSign,
  LifeBuoy,
  Lock,
  AlertTriangle,
  RotateCcw as RefreshIcon,
  UserCheck
} from 'lucide-react';

export default function ConsoleSectionPage({
  title,
  description,
  icon: IconComponent,
  stats = [],
  tableHeaders = [],
  tableData = []
}) {
  const [items, setItems] = useState(tableData);
  const [searchQuery, setSearchQuery] = useState('');
  const [hoveredPoint, setHoveredPoint] = useState(null);
  const [timeframe, setTimeframe] = useState('week');

  // Dynamic curve calculator for console section graphs
  const getDynamicConsoleSeries = (svgWidth = 840) => {
    const itemCount = items.length || 8;
    let labels = [];
    let factors = [];

    if (timeframe === 'week') {
      labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Live (Peak)'];
      factors = [0.35, 0.52, 0.68, 0.82, 0.94, 1.12, 1.3];
    } else if (timeframe === 'month') {
      labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Live Peak'];
      factors = [0.4, 0.65, 0.85, 1.1, 1.35, 1.6];
    } else {
      labels = ['Month 1', 'Month 2', 'Month 3', 'Forecast'];
      factors = [0.5, 0.9, 1.4, 2.0];
    }

    const startX = svgWidth > 600 ? 55 : 45;
    const endX = svgWidth - 25;
    const stepX = (endX - startX) / (labels.length - 1);

    const points = labels.map((lbl, idx) => {
      const x = startX + idx * stepX;
      const progress = idx / (labels.length - 1);
      const y = 135 - progress * 105;
      const count = Math.max(1, Math.round(itemCount * factors[idx]));
      return { x, y, label: lbl, count, pct: Math.min(100, Math.round(65 + progress * 34)) };
    });

    let pathD = `M ${points[0].x} ${points[0].y}`;
    for (let i = 0; i < points.length - 1; i++) {
      const cpX = (points[i].x + points[i + 1].x) / 2;
      pathD += ` C ${cpX} ${points[i].y}, ${cpX} ${points[i + 1].y}, ${points[i + 1].x} ${points[i + 1].y}`;
    }
    const areaD = `${pathD} L ${points[points.length - 1].x} 150 L ${points[0].x} 150 Z`;

    return { points, pathD, areaD };
  };

  const fullSeries = getDynamicConsoleSeries(840);
  const sideSeries = getDynamicConsoleSeries(540);

  // Modal States
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingIndex, setEditingIndex] = useState(null);

  // Form States
  const [formData, setFormData] = useState({});

  useEffect(() => {
    setItems(tableData);
  }, [tableData]);

  // Section-specific metadata for charts and visuals
  const getSectionChartConfig = () => {
    switch (title) {
      case 'Delivery Partners':
        return {
          icon: Truck,
          chartTitle: 'Fleet Delivery Volume & Route Fulfillment',
          subtext: 'Daily completed dispatches vs SLA route benchmarks',
          m1: 'Deliveries (342 Orders)',
          m2: 'Target Route SLA (95%)',
          growth: '+18.4% On-Time',
          sideTitle: 'Delivery Zones Distribution',
          sideBars: [
            { label: 'North District', val: '48 orders', pct: 88 },
            { label: 'Central Market', val: '36 orders', pct: 72 },
            { label: 'East Valley', val: '52 orders', pct: 94 },
          ],
          healthLabel: 'Fleet Fulfillment Rate',
          healthVal: '99.4% On-Time Deliveries',
        };
      case 'Wholesalers':
        return {
          icon: Building2,
          chartTitle: 'Wholesale Grain Reserves & Procurement Volume',
          subtext: 'Bulk grain intake (kg) across registered procurement depots',
          m1: 'Stock Reserves (84,000 kg)',
          m2: 'Procurement Target',
          growth: '+12.5% Inflow',
          sideTitle: 'Grain Stock Allocation',
          sideBars: [
            { label: 'Organic Whole Wheat', val: '32,000 kg', pct: 85 },
            { label: 'Stoneground Rye', val: '24,500 kg', pct: 70 },
            { label: 'Multigrain Mix', val: '27,500 kg', pct: 80 },
          ],
          healthLabel: 'Procurement Stability',
          healthVal: '100% Verified Suppliers',
        };
      case 'Riders':
        return {
          icon: Users,
          chartTitle: 'Live Rider Fleet Activity & Battery SLA',
          subtext: 'Active riders on road vs assigned delivery orders',
          m1: 'Active Riders (42 Online)',
          m2: 'Battery Standard (>70%)',
          growth: '+98.4% SLA Score',
          sideTitle: 'Rider Deployment Zones',
          sideBars: [
            { label: 'North Sector', val: '18 Riders', pct: 92 },
            { label: 'East Sector', val: '14 Riders', pct: 78 },
            { label: 'Central Market', val: '10 Riders', pct: 85 },
          ],
          healthLabel: 'Fleet Safety & Readiness',
          healthVal: '98.4% Optimal Performance',
        };
      case 'Support Desk':
        return {
          icon: LifeBuoy,
          chartTitle: 'Ticket Resolution Velocity & Response Times',
          subtext: 'Inquiry response times vs customer satisfaction index',
          m1: 'Resolved Today (28 Tickets)',
          m2: 'Avg Response (<10 mins)',
          growth: '99% CSAT Rating',
          sideTitle: 'Ticket Inquiries Breakdown',
          sideBars: [
            { label: 'Order Tracking', val: '45% volume', pct: 80 },
            { label: 'Grain Specifications', val: '30% volume', pct: 60 },
            { label: 'Merchant Queries', val: '25% volume', pct: 50 },
          ],
          healthLabel: 'Support Operations SLA',
          healthVal: '< 8 min Response Time',
        };
      case 'Withdrawals & Payouts':
        return {
          icon: DollarSign,
          chartTitle: 'Merchant Settlements & Automated Batch Runs',
          subtext: 'Daily disbursed merchant revenue vs pending batch runs',
          m1: 'Disbursed MTD (₹1,840,000)',
          m2: 'Pending Batch (₹145,000)',
          growth: '+100% Verified',
          sideTitle: 'Bank Settlement Rails',
          sideBars: [
            { label: 'HDFC Direct (Fast-Rail)', val: '₹145,000', pct: 85 },
            { label: 'ICICI Bank (Auto IMPS)', val: '₹82,500', pct: 65 },
            { label: 'SBI Enterprise NEFT', val: '₹60,000', pct: 50 },
          ],
          healthLabel: 'Automated Payout Engine',
          healthVal: 'Active • Real-Time Payouts',
        };
      case 'Platform Security':
        return {
          icon: Lock,
          chartTitle: 'Security Access Audit & Session Logs',
          subtext: 'Encrypted administrative connections and authentication checks',
          m1: 'Active Sessions (14)',
          m2: 'Threat Alerts (0)',
          growth: '99/100 Security Score',
          sideTitle: 'Access Channels',
          sideBars: [
            { label: 'Super Admin Portal', val: '8 Sessions', pct: 88 },
            { label: 'Merchant Console API', val: '4 Sessions', pct: 60 },
            { label: 'Rider Gateway', val: '2 Sessions', pct: 40 },
          ],
          healthLabel: 'System Integrity',
          healthVal: 'All Systems Encrypted',
        };
      case 'Fraud Monitor':
        return {
          icon: AlertTriangle,
          chartTitle: 'AI Risk Engine & Transaction Anomaly Monitor',
          subtext: 'Real-time transaction fraud scoring vs anomaly triggers',
          m1: 'Passed Transactions (100%)',
          m2: 'Risk Threshold (Low)',
          growth: '0.01% Risk Level',
          sideTitle: 'Security Vector Checks',
          sideBars: [
            { label: 'IP Geolocation Match', val: '100% Passed', pct: 95 },
            { label: 'Card Velocity Checks', val: '100% Passed', pct: 95 },
            { label: 'Account Integrity Scan', val: '100% Passed', pct: 90 },
          ],
          healthLabel: 'Fraud Threat Index',
          healthVal: 'Zero Anomalies Detected',
        };
      case 'Refunds & Returns':
        return {
          icon: RefreshIcon,
          chartTitle: 'Return Processing Velocity & Resolution Index',
          subtext: 'Customer refund volume vs chargeback mitigation metrics',
          m1: 'Processed MTD (₹4,500)',
          m2: 'Refund Limit (1.0%)',
          growth: '0.12% Return Rate',
          sideTitle: 'Return Reason Analysis',
          sideBars: [
            { label: 'Order Cancellation', val: '₹1,500', pct: 60 },
            { label: 'Weight Re-calibration', val: '₹1,200', pct: 45 },
            { label: 'Package Exchange', val: '₹1,800', pct: 55 },
          ],
          healthLabel: 'Chargeback Ratio',
          healthVal: '0.12% (Far Below 1% Limit)',
        };
      default:
        return {
          icon: Activity,
          chartTitle: `${title} Operational Performance Trend`,
          subtext: `Real-time activity tracking and operational capacity metrics`,
          m1: `Current Volume (${items.length} records)`,
          m2: 'Target Efficiency (95%)',
          growth: '+15.2% Growth',
          sideTitle: 'Operational Allocation',
          sideBars: [
            { label: 'Active Category 1', val: 'High Activity', pct: 85 },
            { label: 'Active Category 2', val: 'Normal Activity', pct: 70 },
            { label: 'Standby / Queue', val: 'Optimal', pct: 50 },
          ],
          healthLabel: 'Status Overview',
          healthVal: 'Optimal Performance',
        };
    }
  };

  const chartConfig = getSectionChartConfig();
  const ChartIcon = chartConfig.icon;

  // Statuses extracted from tableData
  // Handle open Add Modal
  const handleOpenAddModal = () => {
    const initialForm = {};
    tableHeaders.forEach((header) => {
      initialForm[header] = '';
    });
    setFormData(initialForm);
    setIsAddModalOpen(true);
  };

  // Handle open Edit Modal
  const handleOpenEditModal = (row, index) => {
    setEditingIndex(index);
    const formObj = {};
    tableHeaders.forEach((header, colIdx) => {
      const keys = Object.keys(row);
      formObj[header] = row[keys[colIdx]] || '';
    });
    setFormData(formObj);
    setIsEditModalOpen(true);
  };

  // Save new record
  const handleSaveNew = (e) => {
    e.preventDefault();
    const newRow = {};
    const firstRow = items[0] || {};
    const keys = Object.keys(firstRow);
    tableHeaders.forEach((header, idx) => {
      const key = keys[idx] || `col_${idx}`;
      newRow[key] = formData[header] || (idx === 0 ? `#SEC-${Date.now().toString().slice(-4)}` : idx === tableHeaders.length - 1 ? 'Just now' : 'SUCCESS');
    });
    setItems([newRow, ...items]);
    setIsAddModalOpen(false);
  };

  // Save edited record
  const handleSaveEdit = (e) => {
    e.preventDefault();
    if (editingIndex === null) return;
    const existing = items[editingIndex] || {};
    const updatedRow = { ...existing };
    const keys = Object.keys(existing);
    tableHeaders.forEach((header, idx) => {
      const key = keys[idx] || `col_${idx}`;
      if (formData[header] !== undefined) {
        updatedRow[key] = formData[header];
      }
    });

    const newItems = [...items];
    newItems[editingIndex] = updatedRow;
    setItems(newItems);
    setIsEditModalOpen(false);
    setEditingIndex(null);
  };

  // Delete record
  const handleDelete = (index) => {
    if (window.confirm(`Are you sure you want to delete this ${title.replace(/s$/, '')} record?`)) {
      setItems(items.filter((_, idx) => idx !== index));
    }
  };

  // Filter items by search query
  const filteredItems = items.filter((row) => {
    if (!searchQuery) return true;
    return Object.values(row).some((val) =>
      String(val).toLowerCase().includes(searchQuery.toLowerCase())
    );
  });

  // Get status pill styling
  const getStatusBadgeStyle = (val) => {
    const str = String(val).toLowerCase();
    if (['active', 'on duty', 'completed', 'resolved', 'passed', 'success', 'optimal', 'low'].includes(str)) {
      return { bg: '#E8F8F0', color: '#1E8449', dot: '#2ECC71' };
    } else if (['processing', 'in progress', 'pending', 'normal'].includes(str)) {
      return { bg: '#FFF8E7', color: '#B7791F', dot: '#F6AD55' };
    } else if (['offline', 'failed', 'high', 'inactive', 'dispute'].includes(str)) {
      return { bg: '#FDEDEC', color: '#C0392B', dot: '#E74C3C' };
    }
    return null;
  };

  return (
    <div className="console-section-container">
      {/* Section Header */}
      <div className="page-header-flex" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="page-title serif-heading" style={{ fontSize: '2rem', fontWeight: 800, color: '#2A2421' }}>{title}</h1>
          <p className="page-subtitle" style={{ fontSize: '0.92rem', color: '#756D69', marginTop: 4 }}>{description}</p>
        </div>
        <div className="page-actions-group">
          <button
            className="btn-primary btn-with-icon"
            style={{ backgroundColor: '#8C4A3E', background: 'linear-gradient(135deg, #8C4A3E, #6E372D)', padding: '10px 18px', borderRadius: 14 }}
            onClick={handleOpenAddModal}
          >
            <Plus size={18} />
            <span>Add New {title.replace(/s$/, '')}</span>
          </button>
        </div>
      </div>

      {/* If 3 or more stat cards: Top Stats Grid + Full View Graph Card */}
      {stats.length >= 3 && (
        <>
          {/* Top Horizontal Stats Grid */}
          <div style={{ display: 'grid', gridTemplateColumns: `repeat(${stats.length}, 1fr)`, gap: 20, marginBottom: 24 }}>
            {stats.map((s, idx) => (
              <div
                className="card"
                key={idx}
                style={{
                  padding: 22,
                  background: '#FFFFFF',
                  borderRadius: 16,
                  border: '1px solid #ECE4D9',
                }}
              >
                <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>
                  {s.label}
                </span>
                <div style={{ fontSize: '2.1rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
                  {s.value}
                </div>
                <span
                  style={{
                    fontSize: '0.82rem',
                    fontWeight: 700,
                    color: s.isPositive ? '#1E8449' : '#C0392B',
                    marginTop: 6,
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: 4
                  }}
                >
                  {s.change}
                </span>
              </div>
            ))}
          </div>

          {/* Full View Graph Card */}
          <div className="card" style={{ padding: 24, marginBottom: 28, position: 'relative' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20, flexWrap: 'wrap', gap: 12 }}>
              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <ChartIcon size={18} color="#8C4A3E" />
                  <h2 className="card-title" style={{ fontSize: '1.15rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>
                    {chartConfig.chartTitle}
                  </h2>
                  <span className="live-stream-badge">
                    <span className="live-stream-dot"></span>
                    <span>LIVE</span>
                  </span>
                </div>
                <p style={{ fontSize: '0.78rem', color: '#756D69', margin: '3px 0 0 0' }}>{chartConfig.subtext}</p>
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

            {/* Full-width SVG Canvas */}
            <div style={{ background: '#FAF6F0', borderRadius: 16, border: '1px solid #ECE4D9', padding: '18px 20px', position: 'relative' }}>
              {/* Floating Tooltip */}
              {hoveredPoint && (
                <div
                  className="chart-floating-tooltip"
                  style={{
                    left: `${(hoveredPoint.x / 840) * 100}%`,
                    top: `${hoveredPoint.y}px`,
                  }}
                >
                  <div style={{ color: '#FF9A93', fontSize: '0.7rem' }}>{hoveredPoint.label} Telemetry</div>
                  <div>{hoveredPoint.count} Records Processed</div>
                  <div style={{ color: '#2ECC71', fontSize: '0.7rem', marginTop: 2 }}>{hoveredPoint.pct}% Efficiency SLA</div>
                </div>
              )}

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                <div style={{ display: 'flex', gap: 16, fontSize: '0.78rem', fontWeight: 700 }}>
                  <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#8C4A3E' }}>
                    <span style={{ width: 10, height: 10, borderRadius: 3, background: '#8C4A3E' }}></span> {chartConfig.m1}
                  </span>
                  <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#CBA034' }}>
                    <span style={{ width: 10, height: 2, background: '#CBA034' }}></span> {chartConfig.m2}
                  </span>
                </div>
                <span style={{ fontSize: '0.75rem', color: '#1E8449', fontWeight: 700, background: '#E8F8F0', padding: '2px 8px', borderRadius: 6 }}>
                  {chartConfig.growth}
                </span>
              </div>

              <svg viewBox="0 0 840 160" style={{ width: '100%', height: '170px', overflow: 'visible' }}>
                <defs>
                  <linearGradient id={`gradient_full_${title.replace(/\s+/g, '')}`} x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" stopColor="#8C4A3E" stopOpacity="0.25" />
                    <stop offset="100%" stopColor="#8C4A3E" stopOpacity="0.0" />
                  </linearGradient>
                </defs>

                {/* Y-Axis Scale Labels */}
                <text x="36" y="34" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">100%</text>
                <text x="36" y="74" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">75%</text>
                <text x="36" y="114" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">50%</text>
                <text x="36" y="152" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">0%</text>

                {/* Grid Lines */}
                <line x1="45" y1="30" x2="840" y2="30" stroke="#ECE4D9" strokeDasharray="3,3" />
                <line x1="45" y1="70" x2="840" y2="70" stroke="#ECE4D9" strokeDasharray="3,3" />
                <line x1="45" y1="110" x2="840" y2="110" stroke="#ECE4D9" strokeDasharray="3,3" />

                {/* X-Axis Baseline & Y-Axis Axis Line */}
                <line x1="45" y1="20" x2="45" y2="150" stroke="#D5C9B8" strokeWidth="1.5" />
                <line x1="45" y1="150" x2="840" y2="150" stroke="#D5C9B8" strokeWidth="1.5" />

                {/* Target SLA Line */}
                <line x1="45" y1="45" x2="840" y2="45" stroke="#CBA034" strokeWidth="2" strokeDasharray="6,6" />

                {/* Area Fill */}
                <path
                  d={fullSeries.areaD}
                  fill={`url(#gradient_full_${title.replace(/\s+/g, '')})`}
                  style={{ transition: 'all 0.4s ease' }}
                />

                {/* Trend Curve */}
                <path
                  d={fullSeries.pathD}
                  fill="none"
                  stroke="#8C4A3E"
                  strokeWidth="3.5"
                  strokeLinecap="round"
                  style={{ transition: 'all 0.4s ease' }}
                />

                {/* Data points */}
                {fullSeries.points.map((pt, i) => (
                  <circle
                    key={i}
                    cx={pt.x}
                    cy={pt.y}
                    r={hoveredPoint?.label === pt.label ? 7 : (i === fullSeries.points.length - 1 ? 6 : 4.5)}
                    fill={i === fullSeries.points.length - 1 ? '#1E8449' : '#8C4A3E'}
                    stroke="white"
                    strokeWidth="2"
                    className="graph-interactive-node"
                    onMouseEnter={() => setHoveredPoint(pt)}
                    onMouseLeave={() => setHoveredPoint(null)}
                  />
                ))}

                {/* Pulsing Radar Node on Live Head */}
                <circle
                  cx={fullSeries.points[fullSeries.points.length - 1].x}
                  cy={fullSeries.points[fullSeries.points.length - 1].y}
                  r="6"
                  fill="none"
                  stroke="#1E8449"
                  strokeWidth="2"
                  className="live-pulse-radar"
                />
              </svg>

              {/* X-axis labels */}
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', color: '#756D69', marginTop: 8, fontWeight: 600, paddingLeft: 45, paddingRight: 8 }}>
                {fullSeries.points.map((pt, idx) => (
                  <span
                    key={idx}
                    style={{
                      color: idx === fullSeries.points.length - 1 ? '#8C4A3E' : '#756D69',
                      fontWeight: idx === fullSeries.points.length - 1 ? 800 : 600,
                    }}
                  >
                    {pt.label}
                  </span>
                ))}
              </div>
            </div>
          </div>
        </>
      )}

      {/* If 1 or 2 stat cards: Side-by-side layout */}
      {stats.length < 3 && (
        <div style={{ display: 'grid', gridTemplateColumns: stats.length > 0 ? '1fr 340px' : '1fr', gap: 24, marginBottom: 28, alignItems: 'stretch' }}>
          {/* Main Trend Graph */}
          <div className="card" style={{ padding: 24, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', position: 'relative' }}>
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20, flexWrap: 'wrap', gap: 10 }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <ChartIcon size={18} color="#8C4A3E" />
                    <h2 className="card-title" style={{ fontSize: '1.15rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>
                      {chartConfig.chartTitle}
                    </h2>
                    <span className="live-stream-badge">
                      <span className="live-stream-dot"></span>
                      <span>LIVE</span>
                    </span>
                  </div>
                  <p style={{ fontSize: '0.78rem', color: '#756D69', margin: '3px 0 0 0' }}>{chartConfig.subtext}</p>
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

              {/* SVG Graph Canvas */}
              <div style={{ background: '#FAF6F0', borderRadius: 16, border: '1px solid #ECE4D9', padding: '18px 20px', position: 'relative' }}>
                {hoveredPoint && (
                  <div
                    className="chart-floating-tooltip"
                    style={{
                      left: `${(hoveredPoint.x / 540) * 100}%`,
                      top: `${hoveredPoint.y}px`,
                    }}
                  >
                    <div style={{ color: '#FF9A93', fontSize: '0.7rem' }}>{hoveredPoint.label} Telemetry</div>
                    <div>{hoveredPoint.count} Records Processed</div>
                  </div>
                )}

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                  <div style={{ display: 'flex', gap: 16, fontSize: '0.78rem', fontWeight: 700 }}>
                    <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#8C4A3E' }}>
                      <span style={{ width: 10, height: 10, borderRadius: 3, background: '#8C4A3E' }}></span> {chartConfig.m1}
                    </span>
                    <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#CBA034' }}>
                      <span style={{ width: 10, height: 2, background: '#CBA034' }}></span> {chartConfig.m2}
                    </span>
                  </div>
                  <span style={{ fontSize: '0.75rem', color: '#1E8449', fontWeight: 700, background: '#E8F8F0', padding: '2px 8px', borderRadius: 6 }}>
                    {chartConfig.growth}
                  </span>
                </div>

                <svg viewBox="0 0 540 160" style={{ width: '100%', height: '160px', overflow: 'visible' }}>
                  <defs>
                    <linearGradient id={`gradient_${title.replace(/\s+/g, '')}`} x1="0%" y1="0%" x2="0%" y2="100%">
                      <stop offset="0%" stopColor="#8C4A3E" stopOpacity="0.25" />
                      <stop offset="100%" stopColor="#8C4A3E" stopOpacity="0.0" />
                    </linearGradient>
                  </defs>

                  {/* Y-Axis Scale Labels */}
                  <text x="32" y="34" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">100%</text>
                  <text x="32" y="74" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">75%</text>
                  <text x="32" y="114" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">50%</text>
                  <text x="32" y="152" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">0%</text>

                  {/* Grid Lines */}
                  <line x1="40" y1="30" x2="540" y2="30" stroke="#ECE4D9" strokeDasharray="3,3" />
                  <line x1="40" y1="70" x2="540" y2="70" stroke="#ECE4D9" strokeDasharray="3,3" />
                  <line x1="40" y1="110" x2="540" y2="110" stroke="#ECE4D9" strokeDasharray="3,3" />

                  {/* X-Axis Baseline & Y-Axis Axis Line */}
                  <line x1="40" y1="20" x2="40" y2="150" stroke="#D5C9B8" strokeWidth="1.5" />
                  <line x1="40" y1="150" x2="540" y2="150" stroke="#D5C9B8" strokeWidth="1.5" />

                  {/* Target SLA Line */}
                  <line x1="40" y1="45" x2="540" y2="45" stroke="#CBA034" strokeWidth="2" strokeDasharray="6,6" />

                  {/* Area Fill */}
                  <path
                    d={sideSeries.areaD}
                    fill={`url(#gradient_${title.replace(/\s+/g, '')})`}
                    style={{ transition: 'all 0.4s ease' }}
                  />

                  {/* Trend Curve */}
                  <path
                    d={sideSeries.pathD}
                    fill="none"
                    stroke="#8C4A3E"
                    strokeWidth="3.5"
                    strokeLinecap="round"
                    style={{ transition: 'all 0.4s ease' }}
                  />

                  {/* Data points */}
                  {sideSeries.points.map((pt, i) => (
                    <circle
                      key={i}
                      cx={pt.x}
                      cy={pt.y}
                      r={hoveredPoint?.label === pt.label ? 7 : (i === sideSeries.points.length - 1 ? 6 : 4.5)}
                      fill={i === sideSeries.points.length - 1 ? '#1E8449' : '#8C4A3E'}
                      stroke="white"
                      strokeWidth="2"
                      className="graph-interactive-node"
                      onMouseEnter={() => setHoveredPoint(pt)}
                      onMouseLeave={() => setHoveredPoint(null)}
                    />
                  ))}

                  {/* Radar beacon on live head */}
                  <circle
                    cx={sideSeries.points[sideSeries.points.length - 1].x}
                    cy={sideSeries.points[sideSeries.points.length - 1].y}
                    r="6"
                    fill="none"
                    stroke="#1E8449"
                    strokeWidth="2"
                    className="live-pulse-radar"
                  />
                </svg>

                {/* X-axis labels */}
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', color: '#756D69', marginTop: 8, fontWeight: 600, paddingLeft: 40, paddingRight: 4 }}>
                  {sideSeries.points.map((pt, idx) => (
                    <span
                      key={idx}
                      style={{
                        color: idx === sideSeries.points.length - 1 ? '#8C4A3E' : '#756D69',
                        fontWeight: idx === sideSeries.points.length - 1 ? 800 : 600,
                      }}
                    >
                      {pt.label}
                    </span>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* Right Side: Stats Cards Stack */}
          {stats.length > 0 && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              {stats.map((s, idx) => (
                <div
                  className="card"
                  key={idx}
                  style={{
                    padding: 22,
                    flex: 1,
                    display: 'flex',
                    flexDirection: 'column',
                    justifyContent: 'center',
                    background: '#FFFFFF',
                    borderRadius: 16,
                    border: '1px solid #ECE4D9',
                  }}
                >
                  <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>
                    {s.label}
                  </span>
                  <div style={{ fontSize: '2.1rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
                    {s.value}
                  </div>
                  <span
                    style={{
                      fontSize: '0.82rem',
                      fontWeight: 700,
                      color: s.isPositive ? '#1E8449' : '#C0392B',
                      marginTop: 6,
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: 4
                    }}
                  >
                    {s.change}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Main Records Table with Search & Advanced Filters */}
      <div className="card" style={{ padding: 24 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18, flexWrap: 'wrap', gap: 12 }}>
          <div>
            <h2 className="card-title" style={{ fontSize: '1.25rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>
              {title} Records
            </h2>
            <span style={{ fontSize: '0.78rem', color: '#756D69' }}>Showing {filteredItems.length} of {items.length} records</span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
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
                placeholder={`Search ${title.toLowerCase()}...`}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{ border: 'none', background: 'transparent', outline: 'none', fontSize: '0.85rem', width: '100%' }}
              />
              {searchQuery && (
                <X size={14} color="#756D69" style={{ cursor: 'pointer' }} onClick={() => setSearchQuery('')} />
              )}
            </div>
          </div>
        </div>

        {/* Table Content */}
        <div className="table-wrapper" style={{ overflowX: 'auto' }}>
          <table className="custom-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: '#FAF6F0', textAlign: 'left' }}>
                {tableHeaders.map((h, i) => (
                  <th key={i} style={{ padding: '12px 16px', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5 }}>
                    {h.toUpperCase()}
                  </th>
                ))}
                <th style={{ padding: '12px 16px', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textAlign: 'right' }}>
                  ACTIONS
                </th>
              </tr>
            </thead>
            <tbody>
              {filteredItems.length === 0 ? (
                <tr>
                  <td colSpan={tableHeaders.length + 1} style={{ textAlign: 'center', color: '#756D69', padding: '40px 20px' }}>
                    <div style={{ fontWeight: 800, fontSize: '1rem', color: '#2A2421' }}>No Records Found</div>
                    <p style={{ fontSize: '0.82rem', color: '#756D69', margin: '4px 0 14px 0' }}>No records match "{searchQuery}".</p>
                    <button
                      onClick={() => setSearchQuery('')}
                      className="btn-outline"
                      style={{ padding: '6px 14px', borderRadius: 12, fontSize: '0.8rem' }}
                    >
                      Clear Search
                    </button>
                  </td>
                </tr>
              ) : (
                filteredItems.map((row, i) => (
                  <tr key={i} style={{ borderBottom: '1px solid #ECE4D9' }}>
                    {Object.values(row).map((val, cellIdx) => {
                      const badgeStyle = getStatusBadgeStyle(val);
                      return (
                        <td key={cellIdx} style={{ padding: '16px', fontWeight: cellIdx === 0 ? 800 : 600, color: '#2A2421', fontSize: '0.88rem' }}>
                          {badgeStyle ? (
                            <span
                              style={{
                                background: badgeStyle.bg,
                                color: badgeStyle.color,
                                padding: '4px 10px',
                                borderRadius: 12,
                                fontSize: '0.75rem',
                                fontWeight: 800,
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: 6,
                              }}
                            >
                              <span style={{ width: 6, height: 6, borderRadius: '50%', background: badgeStyle.dot }}></span>
                              {val}
                            </span>
                          ) : (
                            val
                          )}
                        </td>
                      );
                    })}
                    <td style={{ padding: '16px', textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: '8px' }}>
                        <button
                          className="btn-outline"
                          style={{ padding: '6px 12px', borderRadius: 8, fontSize: '0.78rem', display: 'inline-flex', alignItems: 'center', gap: 4 }}
                          title="Edit Record"
                          onClick={() => handleOpenEditModal(row, i)}
                        >
                          <Pencil size={13} />
                          <span>Edit</span>
                        </button>
                        <button
                          className="btn-outline"
                          style={{
                            padding: '6px 12px',
                            borderRadius: 8,
                            fontSize: '0.78rem',
                            borderColor: '#FADBD8',
                            color: '#C0392B',
                            backgroundColor: '#FDEDEC',
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 4,
                          }}
                          title="Delete Record"
                          onClick={() => handleDelete(i)}
                        >
                          <Trash2 size={13} color="#C0392B" />
                          <span>Delete</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add New Record Modal */}
      {isAddModalOpen && (
        <div className="modal-overlay" style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999 }}>
          <div className="modal-dialog" style={{ backgroundColor: 'white', borderRadius: 20, padding: 28, width: 480, maxWidth: '90%' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2 className="serif-heading" style={{ fontSize: '1.4rem', fontWeight: 800, margin: 0 }}>Add New {title.replace(/s$/, '')}</h2>
              <button onClick={() => setIsAddModalOpen(false)} style={{ border: 'none', background: 'transparent', cursor: 'pointer' }}>
                <X size={20} color="#756D69" />
              </button>
            </div>

            <form onSubmit={handleSaveNew}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                {tableHeaders.map((header, idx) => (
                  <div key={idx}>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: '4px' }}>
                      {header.toUpperCase()}
                    </label>
                    <input
                      required
                      placeholder={`Enter ${header.toLowerCase()}...`}
                      value={formData[header] || ''}
                      onChange={(e) => setFormData({ ...formData, [header]: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem' }}
                    />
                  </div>
                ))}
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '24px' }}>
                <button
                  type="button"
                  className="btn-outline"
                  onClick={() => setIsAddModalOpen(false)}
                  style={{ padding: '10px 18px', borderRadius: 12 }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-primary"
                  style={{ backgroundColor: '#8C4A3E', padding: '10px 20px', borderRadius: 12 }}
                >
                  Save Record
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Record Modal */}
      {isEditModalOpen && (
        <div className="modal-overlay" style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999 }}>
          <div className="modal-dialog" style={{ backgroundColor: 'white', borderRadius: 20, padding: 28, width: 480, maxWidth: '90%' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2 className="serif-heading" style={{ fontSize: '1.4rem', fontWeight: 800, margin: 0 }}>Edit {title.replace(/s$/, '')}</h2>
              <button onClick={() => setIsEditModalOpen(false)} style={{ border: 'none', background: 'transparent', cursor: 'pointer' }}>
                <X size={20} color="#756D69" />
              </button>
            </div>

            <form onSubmit={handleSaveEdit}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                {tableHeaders.map((header, idx) => (
                  <div key={idx}>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: '4px' }}>
                      {header.toUpperCase()}
                    </label>
                    <input
                      required
                      value={formData[header] || ''}
                      onChange={(e) => setFormData({ ...formData, [header]: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem' }}
                    />
                  </div>
                ))}
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '24px' }}>
                <button
                  type="button"
                  className="btn-outline"
                  onClick={() => setIsEditModalOpen(false)}
                  style={{ padding: '10px 18px', borderRadius: 12 }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-primary"
                  style={{ backgroundColor: '#8C4A3E', padding: '10px 20px', borderRadius: 12 }}
                >
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
