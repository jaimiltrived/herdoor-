import React, { useState } from 'react';
import {
  Search,
  Filter,
  Plus,
  Pencil,
  Trash2,
  X,
  Check,
  TrendingUp,
  Activity,
  Layers,
  Sparkles,
  SlidersHorizontal,
  ChevronDown,
  RotateCcw,
  BarChart3,
  Factory
} from 'lucide-react';

export default function MillsPage() {
  const [mills, setMills] = useState([
    { id: 1, name: 'Sunrise Flour Mill', loc: 'North District', output: 450, outputText: '450 kg', status: 'Active', rating: 4.9, owner: 'Rajesh Sharma', phone: '+91 98765 43210', capacity: 500 },
    { id: 2, name: 'Artisan Mill Co.', loc: 'East Valley', output: 620, outputText: '620 kg', status: 'Active', rating: 4.8, owner: 'Vikram Patel', phone: '+91 98123 45678', capacity: 700 },
    { id: 3, name: 'Valley Grain Hub', loc: 'Central Market', output: 310, outputText: '310 kg', status: 'Maintenance', rating: 4.7, owner: 'Amit Verma', phone: '+91 98334 11223', capacity: 400 },
    { id: 4, name: 'Shree Ram Stone Mill', loc: 'North District', output: 540, outputText: '540 kg', status: 'Active', rating: 4.9, owner: 'Ramesh Gupta', phone: '+91 98456 78901', capacity: 600 },
    { id: 5, name: 'Green Valley Organic Mill', loc: 'South Hub', output: 280, outputText: '280 kg', status: 'Active', rating: 4.6, owner: 'Suresh Joshi', phone: '+91 98234 56789', capacity: 350 },
    { id: 6, name: 'Heritage Wheat Works', loc: 'Westside', output: 190, outputText: '190 kg', status: 'Inactive', rating: 4.3, owner: 'Manoj Kumar', phone: '+91 98789 01234', capacity: 300 },
  ]);

  // Search & Filter States
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('All');
  const [selectedLocation, setSelectedLocation] = useState('All');
  const [minRating, setMinRating] = useState('All');
  const [quickFilter, setQuickFilter] = useState('All');
  const [isFilterDrawerOpen, setIsFilterDrawerOpen] = useState(false);
  const [timeframe, setTimeframe] = useState('week'); // 'week' | 'month'

  // Modal States
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingMill, setEditingMill] = useState(null);

  // Form State
  const [formData, setFormData] = useState({
    name: '',
    loc: 'North District',
    output: '',
    status: 'Active',
    rating: '4.8',
    owner: '',
    phone: '',
    capacity: '500',
  });

  const locations = ['North District', 'East Valley', 'Central Market', 'South Hub', 'Westside'];

  // Handle Quick Filters
  const handleQuickFilterClick = (filterName) => {
    setQuickFilter(filterName);
    if (filterName === 'All') {
      setSelectedStatus('All');
      setSelectedLocation('All');
      setMinRating('All');
    } else if (filterName === 'Active') {
      setSelectedStatus('Active');
    } else if (filterName === 'Maintenance') {
      setSelectedStatus('Maintenance');
    } else if (filterName === 'High Output (>500kg)') {
      setSelectedStatus('All');
    } else if (filterName === 'Top Rated (★ 4.8+)') {
      setMinRating('4.8');
    }
  };

  const handleResetFilters = () => {
    setSearchQuery('');
    setSelectedStatus('All');
    setSelectedLocation('All');
    setMinRating('All');
    setQuickFilter('All');
  };

  const hasActiveFilters = searchQuery !== '' || selectedStatus !== 'All' || selectedLocation !== 'All' || minRating !== 'All' || quickFilter !== 'All';

  // Filter Logic
  const filteredMills = mills.filter((mill) => {
    // Search
    const matchesSearch =
      mill.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      mill.loc.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (mill.owner && mill.owner.toLowerCase().includes(searchQuery.toLowerCase()));

    // Status filter
    const matchesStatus = selectedStatus === 'All' || mill.status === selectedStatus;

    // Location filter
    const matchesLocation = selectedLocation === 'All' || mill.loc === selectedLocation;

    // Rating filter
    let matchesRating = true;
    if (minRating === '4.8') matchesRating = mill.rating >= 4.8;
    else if (minRating === '4.5') matchesRating = mill.rating >= 4.5;

    // Quick filter specials
    let matchesQuick = true;
    if (quickFilter === 'High Output (>500kg)') {
      matchesQuick = mill.output >= 500;
    } else if (quickFilter === 'Top Rated (★ 4.8+)') {
      matchesQuick = mill.rating >= 4.8;
    }

    return matchesSearch && matchesStatus && matchesLocation && matchesRating && matchesQuick;
  });

  // Modal Open Handlers
  const handleOpenAdd = () => {
    setFormData({
      name: '',
      loc: 'North District',
      output: '',
      status: 'Active',
      rating: '4.8',
      owner: '',
      phone: '',
      capacity: '500',
    });
    setIsAddModalOpen(true);
  };

  const handleOpenEdit = (mill) => {
    setEditingMill(mill);
    setFormData({
      name: mill.name,
      loc: mill.loc,
      output: mill.output.toString(),
      status: mill.status,
      rating: mill.rating.toString(),
      owner: mill.owner || '',
      phone: mill.phone || '',
      capacity: (mill.capacity || 500).toString(),
    });
    setIsEditModalOpen(true);
  };

  const handleSaveAdd = (e) => {
    e.preventDefault();
    const outputNum = parseInt(formData.output, 10) || 300;
    const newMill = {
      id: Date.now(),
      name: formData.name || 'New Flour Mill',
      loc: formData.loc,
      output: outputNum,
      outputText: `${outputNum} kg`,
      status: formData.status,
      rating: parseFloat(formData.rating) || 4.8,
      owner: formData.owner || 'Mill Owner',
      phone: formData.phone || '+91 98000 00000',
      capacity: parseInt(formData.capacity, 10) || 500,
    };
    setMills([newMill, ...mills]);
    setIsAddModalOpen(false);
  };

  const handleSaveEdit = (e) => {
    e.preventDefault();
    if (!editingMill) return;
    const outputNum = parseInt(formData.output, 10) || editingMill.output;
    const updated = mills.map((m) => {
      if (m.id === editingMill.id) {
        return {
          ...m,
          name: formData.name,
          loc: formData.loc,
          output: outputNum,
          outputText: `${outputNum} kg`,
          status: formData.status,
          rating: parseFloat(formData.rating) || m.rating,
          owner: formData.owner,
          phone: formData.phone,
          capacity: parseInt(formData.capacity, 10) || m.capacity,
        };
      }
      return m;
    });
    setMills(updated);
    setIsEditModalOpen(false);
    setEditingMill(null);
  };

  const handleDelete = (id) => {
    if (window.confirm('Are you sure you want to remove this flour mill?')) {
      setMills(mills.filter((m) => m.id !== id));
    }
  };

  // Status Badge Colors
  const getStatusBadge = (status) => {
    if (status === 'Active') {
      return { bg: '#E8F8F0', color: '#1E8449', dot: '#2ECC71' };
    } else if (status === 'Maintenance') {
      return { bg: '#FFF8E7', color: '#B7791F', dot: '#F6AD55' };
    } else {
      return { bg: '#FDEDEC', color: '#C0392B', dot: '#E74C3C' };
    }
  };

  return (
    <div className="console-section-container">
      {/* Page Header */}
      <div className="page-header-flex" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h1 className="page-title serif-heading" style={{ fontSize: '2rem', fontWeight: 800, color: '#2A2421' }}>Flour Mills</h1>
          <p className="page-subtitle" style={{ fontSize: '0.92rem', color: '#756D69', marginTop: 4 }}>
            Manage registered artisan mill partners, operational capacity, and milling rates.
          </p>
        </div>
        <div className="page-actions-group">
          <button
            className="btn-primary btn-with-icon"
            style={{ backgroundColor: '#8C4A3E', background: 'linear-gradient(135deg, #8C4A3E, #6E372D)', padding: '10px 18px', borderRadius: 14 }}
            onClick={handleOpenAdd}
          >
            <Plus size={18} />
            <span>Add New Flour Mill</span>
          </button>
        </div>
      </div>

      {/* Top 3 KPI Metrics Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: 20, marginBottom: 28 }}>
        <div className="card" style={{ padding: 22 }}>
          <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>ACTIVE MILLS</span>
          <div style={{ fontSize: '2.3rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>48</div>
          <span style={{ fontSize: '0.82rem', fontWeight: 700, color: '#1E8449', marginTop: 6, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            ↑ +3 this month
          </span>
        </div>

        <div className="card" style={{ padding: 22 }}>
          <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>TOTAL CAPACITY</span>
          <div style={{ fontSize: '2.3rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>18,500 kg</div>
          <span style={{ fontSize: '0.82rem', fontWeight: 700, color: '#1E8449', marginTop: 6, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            88% utilized
          </span>
        </div>

        <div className="card" style={{ padding: 22 }}>
          <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>AVG MILLING TIME</span>
          <div style={{ fontSize: '2.3rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>24 mins</div>
          <span style={{ fontSize: '0.82rem', fontWeight: 700, color: '#1E8449', marginTop: 6, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            -4 mins faster
          </span>
        </div>
      </div>

      {/* Interactive Production & Capacity Analytics Graph Section */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 340px', gap: 24, marginBottom: 28 }}>
        {/* Main Milling Volume & Output Trend Graph */}
        <div className="card" style={{ padding: 24 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <Activity size={18} color="#8C4A3E" />
                <h2 className="card-title" style={{ fontSize: '1.15rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>
                  Mill Milling Output & Capacity Forecast
                </h2>
              </div>
              <p style={{ fontSize: '0.78rem', color: '#756D69', margin: '3px 0 0 0' }}>Daily stoneground volume (kg) vs maximum rated capacity</p>
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

          {/* SVG Graph Graphic */}
          <div style={{ background: '#FAF6F0', borderRadius: 16, border: '1px solid #ECE4D9', padding: '18px 20px', position: 'relative' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
              <div style={{ display: 'flex', gap: 16, fontSize: '0.78rem', fontWeight: 700 }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#8C4A3E' }}>
                  <span style={{ width: 10, height: 10, borderRadius: 3, background: '#8C4A3E' }}></span> Output Volume (kg)
                </span>
                <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#CBA034' }}>
                  <span style={{ width: 10, height: 2, background: '#CBA034' }}></span> Max Capacity (18.5k kg)
                </span>
              </div>
              <span style={{ fontSize: '0.75rem', color: '#1E8449', fontWeight: 700, background: '#E8F8F0', padding: '2px 8px', borderRadius: 6 }}>
                +14.8% Peak Output
              </span>
            </div>

            <svg viewBox="0 0 540 160" style={{ width: '100%', height: '160px', overflow: 'visible' }}>
              <defs>
                <linearGradient id="millGradient" x1="0%" y1="0%" x2="0%" y2="100%">
                  <stop offset="0%" stopColor="#8C4A3E" stopOpacity="0.25" />
                  <stop offset="100%" stopColor="#8C4A3E" stopOpacity="0.0" />
                </linearGradient>
              </defs>

              {/* Y-Axis Scale Labels */}
              <text x="32" y="34" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">600kg</text>
              <text x="32" y="74" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">450kg</text>
              <text x="32" y="114" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">300kg</text>
              <text x="32" y="152" textAnchor="end" fontSize="10" fontWeight="700" fill="#756D69">0kg</text>

              {/* Grid Lines */}
              <line x1="40" y1="30" x2="540" y2="30" stroke="#ECE4D9" strokeDasharray="3,3" />
              <line x1="40" y1="70" x2="540" y2="70" stroke="#ECE4D9" strokeDasharray="3,3" />
              <line x1="40" y1="110" x2="540" y2="110" stroke="#ECE4D9" strokeDasharray="3,3" />

              {/* X-Axis Baseline & Y-Axis Axis Line */}
              <line x1="40" y1="20" x2="40" y2="150" stroke="#D5C9B8" strokeWidth="1.5" />
              <line x1="40" y1="150" x2="540" y2="150" stroke="#D5C9B8" strokeWidth="1.5" />

              {/* Capacity Reference Line */}
              <line x1="40" y1="40" x2="540" y2="40" stroke="#CBA034" strokeWidth="2" strokeDasharray="6,6" />

              {/* Area Fill */}
              <path
                d={
                  timeframe === 'week'
                    ? 'M 40,130 Q 100,110 170,95 T 300,65 T 440,48 T 520,38 L 520,150 L 40,150 Z'
                    : timeframe === 'month'
                    ? 'M 40,135 Q 100,120 170,110 T 300,80 T 440,55 T 520,42 L 520,150 L 40,150 Z'
                    : 'M 40,140 Q 100,125 170,100 T 300,60 T 440,40 T 520,28 L 520,150 L 40,150 Z'
                }
                fill="url(#millGradient)"
              />

              {/* Output Curve */}
              <path
                d={
                  timeframe === 'week'
                    ? 'M 40,130 Q 100,110 170,95 T 300,65 T 440,48 T 520,38'
                    : timeframe === 'month'
                    ? 'M 40,135 Q 100,120 170,110 T 300,80 T 440,55 T 520,42'
                    : 'M 40,140 Q 100,125 170,100 T 300,60 T 440,40 T 520,28'
                }
                fill="none"
                stroke="#8C4A3E"
                strokeWidth="3.5"
                strokeLinecap="round"
              />

              {/* Data points */}
              <circle cx="40" cy={timeframe === 'week' ? 130 : timeframe === 'month' ? 135 : 140} r="4.5" fill="#8C4A3E" stroke="white" strokeWidth="2" />
              <circle cx="170" cy={timeframe === 'week' ? 95 : timeframe === 'month' ? 110 : 100} r="4.5" fill="#8C4A3E" stroke="white" strokeWidth="2" />
              <circle cx="300" cy={timeframe === 'week' ? 65 : timeframe === 'month' ? 80 : 60} r="4.5" fill="#8C4A3E" stroke="white" strokeWidth="2" />
              <circle cx="440" cy={timeframe === 'week' ? 48 : timeframe === 'month' ? 55 : 40} r="4.5" fill="#8C4A3E" stroke="white" strokeWidth="2" />
              <circle cx="520" cy={timeframe === 'week' ? 38 : timeframe === 'month' ? 42 : 28} r="6" fill="#1E8449" stroke="white" strokeWidth="2.5" />
            </svg>

            {/* X-axis labels */}
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', color: '#756D69', marginTop: 8, fontWeight: 600, paddingLeft: 40, paddingRight: 4 }}>
              <span>{timeframe === 'week' ? 'Mon' : timeframe === 'month' ? 'Week 1' : 'Month 1'}</span>
              <span>{timeframe === 'week' ? 'Tue' : timeframe === 'month' ? 'Week 2' : 'Month 2'}</span>
              <span>{timeframe === 'week' ? 'Wed' : timeframe === 'month' ? 'Week 3' : 'Month 3'}</span>
              <span>{timeframe === 'week' ? 'Thu' : timeframe === 'month' ? 'Week 4' : 'Quarter Avg'}</span>
              <span>{timeframe === 'week' ? 'Fri' : timeframe === 'month' ? 'Week 5' : 'Forecast'}</span>
              <span style={{ color: '#8C4A3E', fontWeight: 800 }}>Today (Peak)</span>
            </div>
          </div>
        </div>

        {/* Capacity Distribution by Hub */}
        <div className="card" style={{ padding: 24, display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 16 }}>
              <Layers size={18} color="#6E5616" />
              <h2 className="card-title" style={{ fontSize: '1.1rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>
                Mill Capacity Load
              </h2>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              {mills.slice(0, 4).map((m) => {
                const percent = Math.min(100, Math.round((m.output / (m.capacity || 600)) * 100));
                return (
                  <div key={m.id}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8rem', fontWeight: 700, marginBottom: 4 }}>
                      <span style={{ color: '#2A2421' }}>{m.name}</span>
                      <span style={{ color: percent > 85 ? '#C0392B' : '#6E5616' }}>{percent}% ({m.output}kg)</span>
                    </div>
                    <div style={{ width: '100%', height: 7, backgroundColor: '#F3EBE1', borderRadius: 10, overflow: 'hidden' }}>
                      <div
                        style={{
                          width: `${percent}%`,
                          height: '100%',
                          backgroundColor: percent > 85 ? '#8C4A3E' : '#CBA034',
                          borderRadius: 10,
                          transition: 'width 0.4s ease',
                        }}
                      ></div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          <div style={{ marginTop: 18, padding: '12px 14px', background: '#FAF6F0', borderRadius: 12, border: '1px solid #ECE4D9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <span style={{ fontSize: '0.72rem', color: '#756D69' }}>Overall Fleet Health</span>
              <div style={{ fontSize: '0.9rem', fontWeight: 800, color: '#1E8449' }}>94.6% Operational</div>
            </div>
            <span style={{ background: '#E8F8F0', color: '#1E8449', fontSize: '0.72rem', fontWeight: 800, padding: '4px 8px', borderRadius: 8 }}>
              Optimal
            </span>
          </div>
        </div>
      </div>

      {/* Main Records Table with Advanced Search & Filter Bar */}
      <div className="card" style={{ padding: 24 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18, flexWrap: 'wrap', gap: 12 }}>
          <div>
            <h2 className="card-title" style={{ fontSize: '1.25rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>
              Flour Mills Records
            </h2>
            <span style={{ fontSize: '0.78rem', color: '#756D69' }}>Showing {filteredMills.length} of {mills.length} registered mills</span>
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
                width: 240,
              }}
            >
              <Search size={15} color="#756D69" />
              <input
                placeholder="Search flour mills..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{ border: 'none', background: 'transparent', outline: 'none', fontSize: '0.85rem', width: '100%' }}
              />
              {searchQuery && (
                <X size={14} color="#756D69" style={{ cursor: 'pointer' }} onClick={() => setSearchQuery('')} />
              )}
            </div>

            {/* Filter Drawer Toggle Button */}
            <button
              onClick={() => setIsFilterDrawerOpen(!isFilterDrawerOpen)}
              className="btn-outline"
              style={{
                padding: '8px 16px',
                borderRadius: 24,
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                backgroundColor: isFilterDrawerOpen || hasActiveFilters ? '#8C4A3E' : '#FFF',
                color: isFilterDrawerOpen || hasActiveFilters ? '#FFF' : '#2A2421',
                borderColor: isFilterDrawerOpen || hasActiveFilters ? '#8C4A3E' : '#ECE4D9',
                fontWeight: 700,
                fontSize: '0.85rem',
                cursor: 'pointer',
              }}
            >
              <Filter size={15} />
              <span>Filter</span>
              {hasActiveFilters && (
                <span style={{ background: '#FFF', color: '#8C4A3E', width: 18, height: 18, borderRadius: '50%', fontSize: '0.7rem', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  •
                </span>
              )}
            </button>
          </div>
        </div>

        {/* Quick Filter Chips */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 18, flexWrap: 'wrap' }}>
          <span style={{ fontSize: '0.78rem', fontWeight: 700, color: '#756D69', marginRight: 4 }}>Quick Filters:</span>
          {['All', 'Active', 'Maintenance', 'High Output (>500kg)', 'Top Rated (★ 4.8+)'].map((filterName) => (
            <button
              key={filterName}
              onClick={() => handleQuickFilterClick(filterName)}
              style={{
                border: quickFilter === filterName ? '1px solid #8C4A3E' : '1px solid #ECE4D9',
                background: quickFilter === filterName ? '#FFECEB' : '#FAF6F0',
                color: quickFilter === filterName ? '#8C4A3E' : '#2A2421',
                padding: '5px 12px',
                borderRadius: 14,
                fontSize: '0.78rem',
                fontWeight: quickFilter === filterName ? 800 : 600,
                cursor: 'pointer',
                transition: 'all 0.15s ease',
              }}
            >
              {filterName}
            </button>
          ))}

          {hasActiveFilters && (
            <button
              onClick={handleResetFilters}
              style={{
                border: 'none',
                background: 'transparent',
                color: '#C0392B',
                fontSize: '0.78rem',
                fontWeight: 700,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: 4,
                marginLeft: 'auto',
              }}
            >
              <RotateCcw size={12} />
              <span>Reset All</span>
            </button>
          )}
        </div>

        {/* Expandable Advanced Filter Panel */}
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
            {/* Status Selector */}
            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 6 }}>
                STATUS
              </label>
              <select
                value={selectedStatus}
                onChange={(e) => setSelectedStatus(e.target.value)}
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
                <option value="All">All Statuses</option>
                <option value="Active">Active Only</option>
                <option value="Maintenance">Maintenance</option>
                <option value="Inactive">Inactive</option>
              </select>
            </div>

            {/* Location Selector */}
            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 6 }}>
                LOCATION / DISTRICT
              </label>
              <select
                value={selectedLocation}
                onChange={(e) => setSelectedLocation(e.target.value)}
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
                <option value="All">All Locations</option>
                {locations.map((loc) => (
                  <option key={loc} value={loc}>{loc}</option>
                ))}
              </select>
            </div>

            {/* Minimum Rating */}
            <div>
              <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 6 }}>
                MINIMUM RATING
              </label>
              <select
                value={minRating}
                onChange={(e) => setMinRating(e.target.value)}
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
                <option value="All">All Ratings</option>
                <option value="4.8">★ 4.8 & Above</option>
                <option value="4.5">★ 4.5 & Above</option>
              </select>
            </div>
          </div>
        )}

        {/* Flour Mills Table */}
        <div className="table-wrapper" style={{ overflowX: 'auto' }}>
          <table className="custom-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: '#FAF6F0', textAlign: 'left' }}>
                <th style={{ padding: '12px 16px', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5 }}>MILL NAME</th>
                <th style={{ padding: '12px 16px', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5 }}>LOCATION</th>
                <th style={{ padding: '12px 16px', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5 }}>DAILY OUTPUT</th>
                <th style={{ padding: '12px 16px', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5 }}>STATUS</th>
                <th style={{ padding: '12px 16px', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5 }}>RATING</th>
                <th style={{ padding: '12px 16px', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textAlign: 'right' }}>ACTIONS</th>
              </tr>
            </thead>
            <tbody>
              {filteredMills.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', color: '#756D69', padding: '40px 20px' }}>
                    <Factory size={36} color="#A59D96" style={{ margin: '0 auto 10px auto', display: 'block' }} />
                    <div style={{ fontWeight: 800, fontSize: '1rem', color: '#2A2421' }}>No Flour Mills Found</div>
                    <p style={{ fontSize: '0.82rem', color: '#756D69', margin: '4px 0 14px 0' }}>Try adjusting your search query or active filter settings.</p>
                    <button
                      onClick={handleResetFilters}
                      className="btn-outline"
                      style={{ padding: '6px 14px', borderRadius: 12, fontSize: '0.8rem' }}
                    >
                      Clear All Filters
                    </button>
                  </td>
                </tr>
              ) : (
                filteredMills.map((mill) => {
                  const badge = getStatusBadge(mill.status);
                  return (
                    <tr key={mill.id} style={{ borderBottom: '1px solid #ECE4D9' }}>
                      <td style={{ padding: '16px', fontWeight: 800, color: '#2A2421' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <div style={{ width: 34, height: 34, borderRadius: 10, background: '#F3EBE1', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#8C4A3E' }}>
                            <Factory size={18} />
                          </div>
                          <div>
                            <div style={{ fontSize: '0.92rem', fontWeight: 800 }}>{mill.name}</div>
                            {mill.owner && <div style={{ fontSize: '0.75rem', color: '#756D69' }}>{mill.owner}</div>}
                          </div>
                        </div>
                      </td>
                      <td style={{ padding: '16px', fontWeight: 600, color: '#2A2421', fontSize: '0.88rem' }}>{mill.loc}</td>
                      <td style={{ padding: '16px', fontWeight: 700, color: '#2A2421', fontSize: '0.88rem' }}>{mill.outputText}</td>
                      <td style={{ padding: '16px' }}>
                        <span
                          style={{
                            background: badge.bg,
                            color: badge.color,
                            padding: '4px 10px',
                            borderRadius: 12,
                            fontSize: '0.75rem',
                            fontWeight: 800,
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: 6,
                          }}
                        >
                          <span style={{ width: 6, height: 6, borderRadius: '50%', background: badge.dot }}></span>
                          {mill.status}
                        </span>
                      </td>
                      <td style={{ padding: '16px', fontWeight: 800, color: '#6E5616', fontSize: '0.88rem' }}>★ {mill.rating}</td>
                      <td style={{ padding: '16px', textAlign: 'right' }}>
                        <div style={{ display: 'inline-flex', gap: 8 }}>
                          <button
                            className="btn-outline"
                            style={{ padding: '6px 12px', borderRadius: 8, fontSize: '0.78rem', display: 'inline-flex', alignItems: 'center', gap: 4 }}
                            onClick={() => handleOpenEdit(mill)}
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
                            onClick={() => handleDelete(mill.id)}
                          >
                            <Trash2 size={13} color="#C0392B" />
                            <span>Delete</span>
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add New Mill Modal */}
      {isAddModalOpen && (
        <div className="modal-overlay" style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999 }}>
          <div className="modal-dialog" style={{ backgroundColor: 'white', borderRadius: 20, padding: 28, width: 480, maxWidth: '90%' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
              <h2 className="serif-heading" style={{ fontSize: '1.4rem', fontWeight: 800, margin: 0 }}>Add New Flour Mill</h2>
              <button onClick={() => setIsAddModalOpen(false)} style={{ border: 'none', background: 'transparent', cursor: 'pointer' }}>
                <X size={20} color="#756D69" />
              </button>
            </div>

            <form onSubmit={handleSaveAdd}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>MILL NAME</label>
                  <input
                    required
                    placeholder="e.g. Ganga Stoneground Flour Mill"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem' }}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>LOCATION</label>
                    <select
                      value={formData.loc}
                      onChange={(e) => setFormData({ ...formData, loc: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem', background: 'white' }}
                    >
                      {locations.map((l) => (
                        <option key={l} value={l}>{l}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>DAILY OUTPUT (KG)</label>
                    <input
                      type="number"
                      required
                      placeholder="e.g. 500"
                      value={formData.output}
                      onChange={(e) => setFormData({ ...formData, output: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem' }}
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>STATUS</label>
                    <select
                      value={formData.status}
                      onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem', background: 'white' }}
                    >
                      <option value="Active">Active</option>
                      <option value="Maintenance">Maintenance</option>
                      <option value="Inactive">Inactive</option>
                    </select>
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>RATING</label>
                    <input
                      type="number"
                      step="0.1"
                      min="1.0"
                      max="5.0"
                      value={formData.rating}
                      onChange={(e) => setFormData({ ...formData, rating: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem' }}
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>OPERATOR NAME</label>
                    <input
                      placeholder="e.g. Ramesh Kumar"
                      value={formData.owner}
                      onChange={(e) => setFormData({ ...formData, owner: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem' }}
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>PHONE</label>
                    <input
                      placeholder="+91 98..."
                      value={formData.phone}
                      onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem' }}
                    />
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 24 }}>
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
                  Create Mill Partner
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Mill Modal */}
      {isEditModalOpen && (
        <div className="modal-overlay" style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999 }}>
          <div className="modal-dialog" style={{ backgroundColor: 'white', borderRadius: 20, padding: 28, width: 480, maxWidth: '90%' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
              <h2 className="serif-heading" style={{ fontSize: '1.4rem', fontWeight: 800, margin: 0 }}>Edit Flour Mill</h2>
              <button onClick={() => setIsEditModalOpen(false)} style={{ border: 'none', background: 'transparent', cursor: 'pointer' }}>
                <X size={20} color="#756D69" />
              </button>
            </div>

            <form onSubmit={handleSaveEdit}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>MILL NAME</label>
                  <input
                    required
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem' }}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>LOCATION</label>
                    <select
                      value={formData.loc}
                      onChange={(e) => setFormData({ ...formData, loc: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem', background: 'white' }}
                    >
                      {locations.map((l) => (
                        <option key={l} value={l}>{l}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>DAILY OUTPUT (KG)</label>
                    <input
                      type="number"
                      required
                      value={formData.output}
                      onChange={(e) => setFormData({ ...formData, output: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem' }}
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>STATUS</label>
                    <select
                      value={formData.status}
                      onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem', background: 'white' }}
                    >
                      <option value="Active">Active</option>
                      <option value="Maintenance">Maintenance</option>
                      <option value="Inactive">Inactive</option>
                    </select>
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>RATING</label>
                    <input
                      type="number"
                      step="0.1"
                      value={formData.rating}
                      onChange={(e) => setFormData({ ...formData, rating: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem' }}
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>OPERATOR NAME</label>
                    <input
                      value={formData.owner}
                      onChange={(e) => setFormData({ ...formData, owner: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem' }}
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 4 }}>PHONE</label>
                    <input
                      value={formData.phone}
                      onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid #ECE4D9', fontSize: '0.9rem' }}
                    />
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 24 }}>
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
