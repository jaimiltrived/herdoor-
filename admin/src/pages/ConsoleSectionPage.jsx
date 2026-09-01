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

  // Dynamic bar series calculator for console section graphs
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

    const calculatedCounts = factors.map(f => Math.max(1, Math.round(itemCount * f)));
    const maxVal = Math.max(...calculatedCounts, 10);
    const maxScale = Math.ceil((maxVal * 1.15) / 5) * 5;

    const leftPad = svgWidth > 600 ? 55 : 45;
    const rightPad = 25;
    const topPad = 25;
    const bottomPad = 40;
    const svgHeight = 220;
    const chartWidth = svgWidth - leftPad - rightPad;
    const chartHeight = svgHeight - topPad - bottomPad;

    const groupWidth = chartWidth / labels.length;
    const barWidth = Math.min(26, groupWidth * 0.36);

    const points = labels.map((lbl, idx) => {
      const groupCenterX = leftPad + idx * groupWidth + groupWidth / 2;
      const count = calculatedCounts[idx];
      const barHeight = Math.max(4, (count / maxScale) * chartHeight);
      const barX = groupCenterX - barWidth / 2;
      const barY = topPad + chartHeight - barHeight;
      const progress = idx / (labels.length - 1);
      const isPeak = idx === labels.length - 1;

      return {
        idx,
        label: lbl,
        count,
        pct: Math.min(100, Math.round(65 + progress * 34)),
        groupCenterX,
        barX,
        barY,
        barHeight,
        isPeak,
      };
    });

    const yTicks = [
      { val: maxScale, y: topPad, text: `${maxScale}` },
      { val: Math.round(maxScale * 0.66), y: topPad + chartHeight * 0.34, text: `${Math.round(maxScale * 0.66)}` },
      { val: Math.round(maxScale * 0.33), y: topPad + chartHeight * 0.67, text: `${Math.round(maxScale * 0.33)}` },
      { val: 0, y: topPad + chartHeight, text: '0' },
    ];

    return {
      points,
      yTicks,
      leftPad,
      rightPad,
      topPad,
      bottomPad,
      chartWidth,
      chartHeight,
      groupWidth,
      barWidth,
      maxScale,
      svgWidth,
      svgHeight,
    };
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

            {/* Full-width SVG Bar Canvas */}
            <div style={{ background: '#FAF6F0', borderRadius: 16, border: '1px solid #ECE4D9', padding: '18px 20px', position: 'relative' }}>
              {/* Floating Tooltip */}
              {hoveredPoint && (
                <div
                  className="chart-floating-tooltip"
                  style={{
                    left: `${(hoveredPoint.groupCenterX / fullSeries.svgWidth) * 100}%`,
                    top: `${hoveredPoint.barY + 30}px`,
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
                    {hoveredPoint.label} Telemetry
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: '0.84rem', color: '#FFFFFF', fontWeight: 800, marginBottom: 3 }}>
                    <span style={{ width: 8, height: 8, borderRadius: 2, backgroundColor: '#8C4A3E', display: 'inline-block' }}></span>
                    <span>Volume: {hoveredPoint.count} Records Processed</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: '0.76rem', color: '#2ECC71', fontWeight: 700 }}>
                    <span style={{ width: 8, height: 8, borderRadius: 2, backgroundColor: '#1E8449', display: 'inline-block' }}></span>
                    <span>SLA: {hoveredPoint.pct}% Resolution Index</span>
                  </div>
                </div>
              )}

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
                <div style={{ display: 'flex', gap: 16, fontSize: '0.78rem', fontWeight: 700 }}>
                  <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#8C4A3E' }}>
                    <span style={{ width: 10, height: 10, borderRadius: 3, background: '#8C4A3E' }}></span> {chartConfig.m1}
                  </span>
                  <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#CBA034' }}>
                    <span style={{ width: 10, height: 2, background: '#CBA034' }}></span> {chartConfig.m2}
                  </span>
                </div>
                <span style={{ fontSize: '0.75rem', color: '#1E8449', fontWeight: 700, background: '#E8F8F0', padding: '3px 9px', borderRadius: 8 }}>
                  {chartConfig.growth}
                </span>
              </div>

              <svg viewBox={`0 0 ${fullSeries.svgWidth} ${fullSeries.svgHeight}`} style={{ width: '100%', height: '220px', overflow: 'visible' }}>
                <defs>
                  <linearGradient id={`grad_full_${title.replace(/\s+/g, '')}`} x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" stopColor="#8C4A3E" />
                    <stop offset="100%" stopColor="#B86B5D" />
                  </linearGradient>
                  <linearGradient id={`grad_peak_${title.replace(/\s+/g, '')}`} x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" stopColor="#1E8449" />
                    <stop offset="100%" stopColor="#2ECC71" />
                  </linearGradient>
                </defs>

                {/* Y-Axis Grid Lines & Scale Labels */}
                {fullSeries.yTicks.map((tick, i) => (
                  <g key={`ytick_full_${i}`}>
                    <line
                      x1={fullSeries.leftPad}
                      y1={tick.y}
                      x2={fullSeries.leftPad + fullSeries.chartWidth}
                      y2={tick.y}
                      stroke={tick.val === 0 ? '#DAC8B3' : '#ECE4D9'}
                      strokeWidth={tick.val === 0 ? 1.5 : 1}
                      strokeDasharray={tick.val === 0 ? undefined : '4 4'}
                    />
                    <text
                      x={fullSeries.leftPad - 10}
                      y={tick.y + 4}
                      textAnchor="end"
                      fontSize="10"
                      fontWeight="700"
                      fill="#756D69"
                    >
                      {tick.text}
                    </text>
                  </g>
                ))}

                {/* Target SLA Guideline */}
                <line
                  x1={fullSeries.leftPad}
                  y1={fullSeries.topPad + fullSeries.chartHeight * 0.2}
                  x2={fullSeries.leftPad + fullSeries.chartWidth}
                  y2={fullSeries.topPad + fullSeries.chartHeight * 0.2}
                  stroke="#CBA034"
                  strokeWidth="2"
                  strokeDasharray="6 6"
                />

                {/* Bars */}
                {fullSeries.points.map((pt) => {
                  const isHovered = hoveredPoint?.label === pt.label;

                  return (
                    <g
                      key={`bar_full_${pt.idx}`}
                      style={{ cursor: 'pointer' }}
                      onMouseEnter={() => setHoveredPoint(pt)}
                      onMouseLeave={() => setHoveredPoint(null)}
                    >
                      <rect
                        x={pt.groupCenterX - fullSeries.groupWidth / 2 + 2}
                        y={fullSeries.topPad}
                        width={fullSeries.groupWidth - 4}
                        height={fullSeries.chartHeight}
                        fill={isHovered ? 'rgba(140, 74, 62, 0.07)' : 'transparent'}
                        rx="8"
                      />

                      <rect
                        x={pt.barX}
                        y={pt.barY}
                        width={fullSeries.barWidth}
                        height={pt.barHeight}
                        fill={pt.isPeak ? `url(#grad_peak_${title.replace(/\s+/g, '')})` : `url(#grad_full_${title.replace(/\s+/g, '')})`}
                        rx="5"
                        style={{
                          transition: 'all 0.3s ease',
                          filter: isHovered ? 'brightness(1.1) drop-shadow(0 4px 6px rgba(140, 74, 62, 0.3))' : 'none',
                        }}
                      />

                      <text
                        x={pt.groupCenterX}
                        y={pt.barY - 6}
                        textAnchor="middle"
                        fontSize="9.5"
                        fontWeight={isHovered || pt.isPeak ? '800' : '600'}
                        fill={pt.isPeak ? '#1E8449' : (isHovered ? '#8C4A3E' : '#756D69')}
                      >
                        {pt.count}
                      </text>

                      {pt.isPeak && (
                        <circle
                          cx={pt.groupCenterX}
                          cy={pt.barY}
                          r="4"
                          fill="#1E8449"
                          stroke="#FFF"
                          strokeWidth="1.5"
                          className="live-pulse-radar"
                        />
                      )}

                      <text
                        x={pt.groupCenterX}
                        y={fullSeries.topPad + fullSeries.chartHeight + 20}
                        textAnchor="middle"
                        fontSize={pt.isPeak ? '11.5' : '11'}
                        fontWeight={pt.isPeak ? '800' : (isHovered ? '700' : '600')}
                        fill={pt.isPeak ? '#8C4A3E' : (isHovered ? '#2A2421' : '#756D69')}
                      >
                        {pt.label}
                      </text>
                    </g>
                  );
                })}

                <line
                  x1={fullSeries.leftPad}
                  y1={fullSeries.topPad + fullSeries.chartHeight}
                  x2={fullSeries.leftPad + fullSeries.chartWidth}
                  y2={fullSeries.topPad + fullSeries.chartHeight}
                  stroke="#DAC8B3"
                  strokeWidth="1.5"
                />
              </svg>
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

              {/* SVG Bar Chart Canvas */}
              <div style={{ background: '#FAF6F0', borderRadius: 16, border: '1px solid #ECE4D9', padding: '18px 20px', position: 'relative' }}>
                {hoveredPoint && (
                  <div
                    className="chart-floating-tooltip"
                    style={{
                      left: `${(hoveredPoint.groupCenterX / sideSeries.svgWidth) * 100}%`,
                      top: `${hoveredPoint.barY + 30}px`,
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
                      {hoveredPoint.label} Telemetry
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: '0.84rem', color: '#FFFFFF', fontWeight: 800, marginBottom: 3 }}>
                      <span style={{ width: 8, height: 8, borderRadius: 2, backgroundColor: '#8C4A3E', display: 'inline-block' }}></span>
                      <span>Volume: {hoveredPoint.count} Records Processed</span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: '0.76rem', color: '#2ECC71', fontWeight: 700 }}>
                      <span style={{ width: 8, height: 8, borderRadius: 2, backgroundColor: '#1E8449', display: 'inline-block' }}></span>
                      <span>SLA: {hoveredPoint.pct}% Resolution Index</span>
                    </div>
                  </div>
                )}

                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
                  <div style={{ display: 'flex', gap: 16, fontSize: '0.78rem', fontWeight: 700 }}>
                    <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#8C4A3E' }}>
                      <span style={{ width: 10, height: 10, borderRadius: 3, background: '#8C4A3E' }}></span> {chartConfig.m1}
                    </span>
                    <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#CBA034' }}>
                      <span style={{ width: 10, height: 2, background: '#CBA034' }}></span> {chartConfig.m2}
                    </span>
                  </div>
                  <span style={{ fontSize: '0.75rem', color: '#1E8449', fontWeight: 700, background: '#E8F8F0', padding: '3px 9px', borderRadius: 8 }}>
                    {chartConfig.growth}
                  </span>
                </div>

                <svg viewBox={`0 0 ${sideSeries.svgWidth} ${sideSeries.svgHeight}`} style={{ width: '100%', height: '220px', overflow: 'visible' }}>
                  <defs>
                    <linearGradient id={`gradient_${title.replace(/\s+/g, '')}`} x1="0%" y1="0%" x2="0%" y2="100%">
                      <stop offset="0%" stopColor="#8C4A3E" />
                      <stop offset="100%" stopColor="#B86B5D" />
                    </linearGradient>
                    <linearGradient id={`gradient_peak_${title.replace(/\s+/g, '')}`} x1="0%" y1="0%" x2="0%" y2="100%">
                      <stop offset="0%" stopColor="#1E8449" />
                      <stop offset="100%" stopColor="#2ECC71" />
                    </linearGradient>
                  </defs>

                  {/* Y-Axis Grid Lines & Scale Labels */}
                  {sideSeries.yTicks.map((tick, i) => (
                    <g key={`ytick_side_${i}`}>
                      <line
                        x1={sideSeries.leftPad}
                        y1={tick.y}
                        x2={sideSeries.leftPad + sideSeries.chartWidth}
                        y2={tick.y}
                        stroke={tick.val === 0 ? '#DAC8B3' : '#ECE4D9'}
                        strokeWidth={tick.val === 0 ? 1.5 : 1}
                        strokeDasharray={tick.val === 0 ? undefined : '4 4'}
                      />
                      <text
                        x={sideSeries.leftPad - 10}
                        y={tick.y + 4}
                        textAnchor="end"
                        fontSize="10"
                        fontWeight="700"
                        fill="#756D69"
                      >
                        {tick.text}
                      </text>
                    </g>
                  ))}

                  {/* Target SLA Line */}
                  <line
                    x1={sideSeries.leftPad}
                    y1={sideSeries.topPad + sideSeries.chartHeight * 0.2}
                    x2={sideSeries.leftPad + sideSeries.chartWidth}
                    y2={sideSeries.topPad + sideSeries.chartHeight * 0.2}
                    stroke="#CBA034"
                    strokeWidth="2"
                    strokeDasharray="6 6"
                  />

                  {/* Bars */}
                  {sideSeries.points.map((pt) => {
                    const isHovered = hoveredPoint?.label === pt.label;

                    return (
                      <g
                        key={`bar_side_${pt.idx}`}
                        style={{ cursor: 'pointer' }}
                        onMouseEnter={() => setHoveredPoint(pt)}
                        onMouseLeave={() => setHoveredPoint(null)}
                      >
                        <rect
                          x={pt.groupCenterX - sideSeries.groupWidth / 2 + 2}
                          y={sideSeries.topPad}
                          width={sideSeries.groupWidth - 4}
                          height={sideSeries.chartHeight}
                          fill={isHovered ? 'rgba(140, 74, 62, 0.07)' : 'transparent'}
                          rx="8"
                        />

                        <rect
                          x={pt.barX}
                          y={pt.barY}
                          width={sideSeries.barWidth}
                          height={pt.barHeight}
                          fill={pt.isPeak ? `url(#gradient_peak_${title.replace(/\s+/g, '')})` : `url(#gradient_${title.replace(/\s+/g, '')})`}
                          rx="5"
                          style={{
                            transition: 'all 0.3s ease',
                            filter: isHovered ? 'brightness(1.1) drop-shadow(0 4px 6px rgba(140, 74, 62, 0.3))' : 'none',
                          }}
                        />

                        <text
                          x={pt.groupCenterX}
                          y={pt.barY - 6}
                          textAnchor="middle"
                          fontSize="9.5"
                          fontWeight={isHovered || pt.isPeak ? '800' : '600'}
                          fill={pt.isPeak ? '#1E8449' : (isHovered ? '#8C4A3E' : '#756D69')}
                        >
                          {pt.count}
                        </text>

                        {pt.isPeak && (
                          <circle
                            cx={pt.groupCenterX}
                            cy={pt.barY}
                            r="4"
                            fill="#1E8449"
                            stroke="#FFF"
                            strokeWidth="1.5"
                            className="live-pulse-radar"
                          />
                        )}

                        <text
                          x={pt.groupCenterX}
                          y={sideSeries.topPad + sideSeries.chartHeight + 20}
                          textAnchor="middle"
                          fontSize={pt.isPeak ? '11.5' : '11'}
                          fontWeight={pt.isPeak ? '800' : (isHovered ? '700' : '600')}
                          fill={pt.isPeak ? '#8C4A3E' : (isHovered ? '#2A2421' : '#756D69')}
                        >
                          {pt.label}
                        </text>
                      </g>
                    );
                  })}

                  <line
                    x1={sideSeries.leftPad}
                    y1={sideSeries.topPad + sideSeries.chartHeight}
                    x2={sideSeries.leftPad + sideSeries.chartWidth}
                    y2={sideSeries.topPad + sideSeries.chartHeight}
                    stroke="#DAC8B3"
                    strokeWidth="1.5"
                  />
                </svg>
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
