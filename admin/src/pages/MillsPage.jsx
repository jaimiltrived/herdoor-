import React, { useState, useEffect } from 'react';
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
  Factory,
  FileText,
  CheckCircle2,
  XCircle,
  Clock,
  ExternalLink,
  ShieldCheck,
  MapPin,
  Phone,
  Mail,
  Store,
  Eye,
  AlertCircle
} from 'lucide-react';
import { apiService } from '../services/apiService';

export default function MillsPage() {
  // Main Tab: 'mills' | 'applications'
  const [activeTab, setActiveTab] = useState('mills');

  const [mills, setMills] = useState([
    { id: 101, name: 'Shree Ganesh Flour Mill', loc: '12 Market Yard, Ellisbridge, Ahmedabad', output: 450, outputText: '450 kg', status: 'Active', rating: 4.9, owner: 'Suresh Mill Owner', phone: '+91 98765 43211', capacity: 500 },
    { id: 102, name: 'Navrang Quality Atta Mill', loc: 'Shop 4, Navrangpura Cross Road, Ahmedabad', output: 620, outputText: '620 kg', status: 'Active', rating: 4.8, owner: 'Vikram Patel', phone: '+91 98123 45678', capacity: 700 },
  ]);

  // Merchant Applications State
  const [applications, setApplications] = useState([]);
  const [appMetrics, setAppMetrics] = useState({ total: 0, pending: 0, approved: 0, rejected: 0 });
  const [appStatusFilter, setAppStatusFilter] = useState('ALL');
  const [selectedAppForReview, setSelectedAppForReview] = useState(null);
  const [isReviewModalOpen, setIsReviewModalOpen] = useState(false);
  const [rejectReasonInput, setRejectReasonInput] = useState('');
  const [isRejectMode, setIsRejectMode] = useState(false);
  const [isProcessingApp, setIsProcessingApp] = useState(false);
  const [approvalLoginId, setApprovalLoginId] = useState('');
  const [approvalPassword, setApprovalPassword] = useState('Password123!');
  const [sendWelcomeEmailCheck, setSendWelcomeEmailCheck] = useState(true);

  // Search & Filter States
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedStatus, setSelectedStatus] = useState('All');
  const [selectedLocation, setSelectedLocation] = useState('All');
  const [minRating, setMinRating] = useState('All');
  const [quickFilter, setQuickFilter] = useState('All');
  const [isFilterDrawerOpen, setIsFilterDrawerOpen] = useState(false);
  const [timeframe, setTimeframe] = useState('week'); // 'week' | 'month' | 'quarter'
  const [hoveredMillPoint, setHoveredMillPoint] = useState(null);

  // Modal States
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingMill, setEditingMill] = useState(null);

  // Form State
  const [formData, setFormData] = useState({
    name: '',
    loc: 'Ellisbridge, Ahmedabad',
    output: '',
    status: 'Active',
    rating: '4.8',
    owner: '',
    phone: '',
    capacity: '500',
  });

  const locations = ['North District', 'East Valley', 'Central Market', 'South Hub', 'Westside', 'Ellisbridge, Ahmedabad', 'Navrangpura, Ahmedabad'];

  useEffect(() => {
    loadMills();
    loadApplications();
    const interval = setInterval(() => {
      loadMills();
      loadApplications();
    }, 4000);
    return () => clearInterval(interval);
  }, []);

  const loadMills = async () => {
    try {
      const dbMills = await apiService.getMills();
      if (dbMills && dbMills.length > 0) {
        const formatted = dbMills.map(m => {
          const cap = m.capacityKgPerDay || 500;
          const out = m.currentLoadKg > 0 ? m.currentLoadKg : Math.round(cap * 0.8);
          return {
            id: m.id,
            name: m.name,
            loc: m.address || 'Ahmedabad',
            output: out,
            outputText: `${out} kg`,
            status: m.isOpen ? 'Active' : 'Maintenance',
            rating: m.rating || 4.8,
            owner: m.name.split(' ')[0] + ' Owner',
            phone: m.phone || '+91 98765 43210',
            capacity: cap,
            specialty: m.specialty || 'Fresh Stone Ground Flour',
            workingHours: m.workingHours || '08:00 AM - 08:00 PM',
          };
        });
        setMills(formatted);
      }
    } catch (e) {
      console.warn('Load mills error:', e);
    }
  };

  const loadApplications = async () => {
    try {
      const data = await apiService.getMerchantApplications();
      if (data && data.applications) {
        setApplications(data.applications);
        if (data.metrics) {
          setAppMetrics(data.metrics);
        }
      }
    } catch (e) {
      console.warn('Load applications error:', e);
    }
  };

  const handleApproveApplication = async (appId) => {
    setIsProcessingApp(true);
    try {
      await apiService.approveMerchantApplication(appId, {
        loginId: approvalLoginId || selectedAppForReview?.applicantEmail || 'merchant@herdoor.com',
        temporaryPassword: approvalPassword || 'Password123!',
        sendWelcomeEmail: sendWelcomeEmailCheck,
        adminNotes: 'Application approved by Super Admin. Store verified & active on network.'
      });
      setIsReviewModalOpen(false);
      setSelectedAppForReview(null);
      await loadApplications();
      await loadMills();
    } catch (err) {
      console.error('Approve error:', err);
    } finally {
      setIsProcessingApp(false);
    }
  };

  const handleRejectApplication = async (appId) => {
    if (!rejectReasonInput.trim()) {
      alert('Please provide a reason for rejecting the application.');
      return;
    }
    setIsProcessingApp(true);
    try {
      await apiService.rejectMerchantApplication(appId, rejectReasonInput.trim());
      setIsReviewModalOpen(false);
      setSelectedAppForReview(null);
      setIsRejectMode(false);
      setRejectReasonInput('');
      await loadApplications();
    } catch (err) {
      console.error('Reject error:', err);
    } finally {
      setIsProcessingApp(false);
    }
  };


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
    const matchesLocation = selectedLocation === 'All' || mill.loc.toLowerCase().includes(selectedLocation.toLowerCase());

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
      loc: 'Ellisbridge, Ahmedabad',
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

  const handleSaveAdd = async (e) => {
    e.preventDefault();
    const capacityNum = parseInt(formData.capacity, 10) || 500;
    const outputNum = parseInt(formData.output, 10) || Math.round(capacityNum * 0.8);

    await apiService.createMill({
      name: formData.name || 'New Flour Mill',
      address: formData.loc,
      phone: formData.phone || '+91 98765 43210',
      capacityKgPerDay: capacityNum,
      specialty: 'Artisan Stoneground Flour',
      services: ['Flour Grinding', 'Home Delivery']
    });

    await loadMills();
    setIsAddModalOpen(false);
  };

  const handleSaveEdit = async (e) => {
    e.preventDefault();
    if (!editingMill) return;
    const capacityNum = parseInt(formData.capacity, 10) || editingMill.capacity;

    await apiService.updateMill(editingMill.id, {
      name: formData.name,
      address: formData.loc,
      phone: formData.phone,
      capacityKgPerDay: capacityNum,
      isOpen: formData.status === 'Active'
    });

    await loadMills();
    setIsEditModalOpen(false);
    setEditingMill(null);
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to remove this flour mill from database?')) {
      await apiService.deleteMill(id);
      await loadMills();
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

  const activeMillsCount = mills.filter(m => m.status === 'Active').length;
  const totalCapacityKg = mills.reduce((sum, m) => sum + (parseInt(m.capacity, 10) || 500), 0);

  const getAppStatusBadge = (status) => {
    if (status === 'APPROVED') {
      return { bg: '#E8F8F0', color: '#1E8449', dot: '#2ECC71', label: 'Approved & Active' };
    } else if (status === 'PENDING') {
      return { bg: '#FFF8E7', color: '#B7791F', dot: '#F6AD55', label: 'Pending Review' };
    } else {
      return { bg: '#FDEDEC', color: '#C0392B', dot: '#E74C3C', label: 'Rejected' };
    }
  };

  const filteredApplications = applications.filter((app) => {
    if (appStatusFilter !== 'ALL' && app.status !== appStatusFilter) return false;
    if (!searchQuery) return true;
    const q = searchQuery.toLowerCase();
    return (
      app.storeName?.toLowerCase().includes(q) ||
      app.applicantName?.toLowerCase().includes(q) ||
      app.applicantPhone?.toLowerCase().includes(q) ||
      app.city?.toLowerCase().includes(q) ||
      app.address?.toLowerCase().includes(q)
    );
  });

  return (
    <div className="console-section-container">
      {/* Page Header */}
      <div className="page-header-flex" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h1 className="page-title serif-heading" style={{ fontSize: '2rem', fontWeight: 800, color: '#2A2421' }}>
            {activeTab === 'mills' ? 'Flour Mills Network' : 'Merchant Partner Applications'}
          </h1>
          <p className="page-subtitle" style={{ fontSize: '0.92rem', color: '#756D69', marginTop: 4 }}>
            {activeTab === 'mills'
              ? 'Manage registered artisan mill partners, operational capacity, and milling rates.'
              : 'Review user-submitted shopkeeper onboarding requests, inspect licenses, and approve stores.'}
          </p>
        </div>
        <div className="page-actions-group" style={{ display: 'flex', gap: 12 }}>
          {activeTab === 'mills' ? (
            <button
              className="btn-primary btn-with-icon"
              style={{ backgroundColor: '#8C4A3E', background: 'linear-gradient(135deg, #8C4A3E, #6E372D)', padding: '10px 18px', borderRadius: 14 }}
              onClick={handleOpenAdd}
            >
              <Plus size={18} />
              <span>Add New Flour Mill</span>
            </button>
          ) : (
            <button
              className="btn-outline btn-with-icon"
              style={{ padding: '10px 18px', borderRadius: 14 }}
              onClick={loadApplications}
            >
              <RotateCcw size={16} />
              <span>Refresh Applications</span>
            </button>
          )}
        </div>
      </div>

      {/* Main Tab Switcher Bar */}
      <div style={{ display: 'flex', gap: 10, marginBottom: 24, borderBottom: '1px solid #ECE4D9', paddingBottom: 14 }}>
        <button
          onClick={() => setActiveTab('mills')}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            padding: '10px 22px',
            borderRadius: 14,
            border: activeTab === 'mills' ? '1.5px solid #8C4A3E' : '1px solid #ECE4D9',
            backgroundColor: activeTab === 'mills' ? '#8C4A3E' : '#FFFFFF',
            color: activeTab === 'mills' ? '#FFFFFF' : '#756D69',
            fontWeight: 800,
            fontSize: '0.92rem',
            cursor: 'pointer',
            boxShadow: activeTab === 'mills' ? '0 4px 12px rgba(140, 74, 62, 0.2)' : 'none',
            transition: 'all 0.2s ease',
          }}
        >
          <Factory size={18} />
          <span>Active Flour Mills ({mills.length})</span>
        </button>

        <button
          onClick={() => setActiveTab('applications')}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            padding: '10px 22px',
            borderRadius: 14,
            border: activeTab === 'applications' ? '1.5px solid #8C4A3E' : '1px solid #ECE4D9',
            backgroundColor: activeTab === 'applications' ? '#8C4A3E' : '#FFFFFF',
            color: activeTab === 'applications' ? '#FFFFFF' : '#756D69',
            fontWeight: 800,
            fontSize: '0.92rem',
            cursor: 'pointer',
            boxShadow: activeTab === 'applications' ? '0 4px 12px rgba(140, 74, 62, 0.2)' : 'none',
            transition: 'all 0.2s ease',
          }}
        >
          <FileText size={18} />
          <span>Merchant Applications</span>
          {appMetrics.pending > 0 && (
            <span
              style={{
                backgroundColor: activeTab === 'applications' ? '#FFF' : '#C0392B',
                color: activeTab === 'applications' ? '#8C4A3E' : '#FFF',
                padding: '2px 8px',
                borderRadius: 10,
                fontSize: '0.75rem',
                fontWeight: 800,
              }}
            >
              {appMetrics.pending} PENDING
            </span>
          )}
        </button>
      </div>

      {activeTab === 'applications' ? (
        /* ================= MERCHANT APPLICATIONS VIEW ================= */
        <div>
          {/* Applications Top KPI Metrics */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 18, marginBottom: 24 }}>
            <div className="card" style={{ padding: 20 }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>PENDING VERIFICATION</span>
              <div style={{ fontSize: '2.2rem', fontWeight: 800, color: '#B7791F', fontFamily: "'Plus Jakarta Sans', sans-serif", marginTop: 4 }}>
                {appMetrics.pending}
              </div>
              <span style={{ fontSize: '0.8rem', fontWeight: 700, color: '#B7791F', marginTop: 4, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                Needs Admin Approval
              </span>
            </div>

            <div className="card" style={{ padding: 20 }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>APPROVED MERCHANTS</span>
              <div style={{ fontSize: '2.2rem', fontWeight: 800, color: '#1E8449', fontFamily: "'Plus Jakarta Sans', sans-serif", marginTop: 4 }}>
                {appMetrics.approved}
              </div>
              <span style={{ fontSize: '0.8rem', fontWeight: 700, color: '#1E8449', marginTop: 4, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                Active in Store Network
              </span>
            </div>

            <div className="card" style={{ padding: 20 }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>REJECTED REQUESTS</span>
              <div style={{ fontSize: '2.2rem', fontWeight: 800, color: '#C0392B', fontFamily: "'Plus Jakarta Sans', sans-serif", marginTop: 4 }}>
                {appMetrics.rejected}
              </div>
              <span style={{ fontSize: '0.8rem', fontWeight: 700, color: '#756D69', marginTop: 4, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                Requires resubmission
              </span>
            </div>

            <div className="card" style={{ padding: 20 }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>TOTAL APPLICATIONS</span>
              <div style={{ fontSize: '2.2rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', sans-serif", marginTop: 4 }}>
                {applications.length}
              </div>
              <span style={{ fontSize: '0.8rem', fontWeight: 700, color: '#756D69', marginTop: 4, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                All-time registrations
              </span>
            </div>
          </div>

          {/* Filter & Search Bar */}
          <div className="card" style={{ padding: 18, marginBottom: 20 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 14 }}>
              {/* Status Filter Buttons */}
              <div style={{ display: 'flex', gap: 8 }}>
                {['ALL', 'PENDING', 'APPROVED', 'REJECTED'].map((st) => (
                  <button
                    key={st}
                    onClick={() => setAppStatusFilter(st)}
                    style={{
                      padding: '8px 16px',
                      borderRadius: 12,
                      border: appStatusFilter === st ? '1px solid #8C4A3E' : '1px solid #ECE4D9',
                      backgroundColor: appStatusFilter === st ? '#8C4A3E' : '#FAF6F0',
                      color: appStatusFilter === st ? '#FFF' : '#2A2421',
                      fontWeight: 700,
                      fontSize: '0.82rem',
                      cursor: 'pointer',
                    }}
                  >
                    {st === 'ALL' ? 'All Applications' : st}
                  </button>
                ))}
              </div>

              {/* Search Box */}
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  background: '#FAF6F0',
                  padding: '8px 16px',
                  borderRadius: 24,
                  border: '1px solid #ECE4D9',
                  width: 280,
                }}
              >
                <Search size={16} color="#756D69" />
                <input
                  placeholder="Search store, owner or phone..."
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

          {/* Applications Table */}
          <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
            <div style={{ padding: '18px 24px', borderBottom: '1px solid #ECE4D9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <Store size={18} color="#8C4A3E" />
                <h2 style={{ fontSize: '1.1rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>
                  Storekeeper Candidate Requests ({filteredApplications.length})
                </h2>
              </div>
              <span style={{ fontSize: '0.8rem', color: '#756D69' }}>Real-time verification queue</span>
            </div>

            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.88rem' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid #ECE4D9', background: '#FAF6F0', color: '#756D69', fontSize: '0.75rem', fontWeight: 800, letterSpacing: 0.5 }}>
                    <th style={{ padding: '14px 20px' }}>STORE & OWNER</th>
                    <th style={{ padding: '14px 20px' }}>LOCATION & PINCODE</th>
                    <th style={{ padding: '14px 20px' }}>OPERATIONS</th>
                    <th style={{ padding: '14px 20px' }}>SERVICES</th>
                    <th style={{ padding: '14px 20px' }}>STATUS</th>
                    <th style={{ padding: '14px 20px', textAlign: 'right' }}>ACTIONS</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredApplications.length === 0 ? (
                    <tr>
                      <td colSpan="6" style={{ padding: '40px 20px', textAlign: 'center', color: '#756D69' }}>
                        <Store size={36} color="#CBA034" style={{ marginBottom: 10, display: 'inline-block' }} />
                        <div style={{ fontWeight: 700, fontSize: '1rem', color: '#2A2421' }}>No Merchant Applications Found</div>
                        <div style={{ fontSize: '0.85rem' }}>Users submitting shopkeeper applications will appear here in real-time.</div>
                      </td>
                    </tr>
                  ) : (
                    filteredApplications.map((app) => {
                      const badge = getAppStatusBadge(app.status);
                      return (
                        <tr key={app.id} style={{ borderBottom: '1px solid #ECE4D9', transition: 'background 0.2s ease' }}>
                          {/* Store & Owner */}
                          <td style={{ padding: '16px 20px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                              <img
                                src={app.storeImage || 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=120&q=80'}
                                alt="Store"
                                style={{ width: 44, height: 44, borderRadius: 10, objectFit: 'cover', border: '1px solid #ECE4D9' }}
                              />
                              <div>
                                <div style={{ fontWeight: 800, color: '#2A2421', fontSize: '0.95rem' }}>{app.storeName}</div>
                                <div style={{ fontSize: '0.8rem', color: '#756D69' }}>
                                  👤 {app.applicantName} • 📞 {app.applicantPhone || app.phone}
                                </div>
                                <div style={{ fontSize: '0.75rem', color: '#6E5616', marginTop: 2 }}>
                                  License: {app.licenseNumber || 'FSSAI Verified'}
                                </div>
                              </div>
                            </div>
                          </td>

                          {/* Location */}
                          <td style={{ padding: '16px 20px', color: '#2A2421' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontWeight: 700 }}>
                              <MapPin size={14} color="#8C4A3E" />
                              <span>{app.city || 'Ahmedabad'}, {app.pincode}</span>
                            </div>
                            <div style={{ fontSize: '0.78rem', color: '#756D69', marginTop: 2, maxWidth: 220, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                              {app.address}
                            </div>
                          </td>

                          {/* Operations */}
                          <td style={{ padding: '16px 20px' }}>
                            <div style={{ fontWeight: 700, color: '#2A2421' }}>{app.capacityKgPerDay || 500} kg/day</div>
                            <div style={{ fontSize: '0.78rem', color: '#756D69' }}>Radius: {app.deliveryRadiusKm || 5.0} km</div>
                            <div style={{ fontSize: '0.75rem', color: '#756D69' }}>🕒 {app.workingHours || '08:00 AM - 08:00 PM'}</div>
                          </td>

                          {/* Services */}
                          <td style={{ padding: '16px 20px' }}>
                            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, maxWidth: 220 }}>
                              {(app.services || ['Flour Grinding', 'Packing']).slice(0, 3).map((srv, idx) => (
                                <span
                                  key={idx}
                                  style={{
                                    backgroundColor: '#F3EBE1',
                                    color: '#6E5616',
                                    fontSize: '0.72rem',
                                    fontWeight: 700,
                                    padding: '2px 8px',
                                    borderRadius: 8,
                                  }}
                                >
                                  {srv}
                                </span>
                              ))}
                            </div>
                          </td>

                          {/* Status */}
                          <td style={{ padding: '16px 20px' }}>
                            <span
                              style={{
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: 6,
                                padding: '4px 12px',
                                borderRadius: 20,
                                backgroundColor: badge.bg,
                                color: badge.color,
                                fontWeight: 800,
                                fontSize: '0.78rem',
                              }}
                            >
                              <span style={{ width: 7, height: 7, borderRadius: '50%', backgroundColor: badge.dot }}></span>
                              {badge.label}
                            </span>
                          </td>

                          {/* Actions */}
                          <td style={{ padding: '16px 20px', textAlign: 'right' }}>
                            <button
                              onClick={() => {
                                setSelectedAppForReview(app);
                                setApprovalLoginId(app.applicantEmail || app.phone || 'merchant@herdoor.com');
                                setApprovalPassword('Password123!');
                                setSendWelcomeEmailCheck(true);
                                setIsReviewModalOpen(true);
                                setIsRejectMode(false);
                                setRejectReasonInput('');
                              }}
                              style={{
                                padding: '8px 16px',
                                borderRadius: 10,
                                border: '1px solid #8C4A3E',
                                backgroundColor: '#FAF6F0',
                                color: '#8C4A3E',
                                fontWeight: 800,
                                fontSize: '0.82rem',
                                cursor: 'pointer',
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: 6,
                              }}
                            >
                              <Eye size={14} />
                              <span>Review Details</span>
                            </button>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      ) : (
        /* ================= ACTIVE MILLS VIEW ================= */
        <div>
          {/* Top 3 KPI Metrics Cards */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: 20, marginBottom: 28 }}>
            <div className="card" style={{ padding: 22 }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>ACTIVE MILLS</span>
              <div style={{ fontSize: '2.3rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
                {activeMillsCount || mills.length}
              </div>
              <span style={{ fontSize: '0.82rem', fontWeight: 700, color: '#1E8449', marginTop: 6, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                ↑ 100% Operational
              </span>
            </div>

            <div className="card" style={{ padding: 22 }}>
              <span style={{ fontSize: '0.72rem', fontWeight: 800, color: '#756D69', letterSpacing: 0.5, textTransform: 'uppercase' }}>TOTAL CAPACITY</span>
              <div style={{ fontSize: '2.3rem', fontWeight: 800, color: '#2A2421', fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif", letterSpacing: '-0.5px', marginTop: 4 }}>
                {totalCapacityKg.toLocaleString()} kg
              </div>
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
            <div className="card" style={{ padding: 24, position: 'relative' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20, flexWrap: 'wrap', gap: 10 }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <Activity size={18} color="#8C4A3E" />
                    <h2 className="card-title" style={{ fontSize: '1.15rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>
                      Mill Milling Output & Capacity Forecast
                    </h2>
                    <span className="live-stream-badge">
                      <span className="live-stream-dot"></span>
                      <span>LIVE TELEMETRY</span>
                    </span>
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

              {/* Dynamic SVG Graph Graphic */}
              {(() => {
                const totalOut = mills.reduce((s, m) => s + (parseInt(m.output, 10) || 400), 0);
                const totalCap = Math.max(totalCapacityKg, totalOut * 1.15, 1000);

                let labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Live (Peak)'];
                let outFactors = [0.45, 0.58, 0.68, 0.82, 0.94, 1.1, 1.25];
                let capFactors = [0.85, 0.88, 0.9, 0.95, 0.98, 1.05, 1.15];

                if (timeframe === 'month') {
                  labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Live Peak'];
                  outFactors = [0.55, 0.78, 1.0, 1.22, 1.45];
                  capFactors = [0.9, 1.0, 1.15, 1.3, 1.5];
                } else if (timeframe === 'quarter') {
                  labels = ['Month 1', 'Month 2', 'Month 3', 'Forecast'];
                  outFactors = [0.7, 1.1, 1.5, 2.0];
                  capFactors = [1.0, 1.35, 1.75, 2.2];
                }

                const maxVal = Math.max(...outFactors.map(f => totalOut * f), ...capFactors.map(f => totalCap * f)) * 1.15;
                const startX = 25;
                const endX = 475;
                const stepX = (endX - startX) / (labels.length - 1);

                const outPoints = labels.map((lbl, idx) => {
                  const val = Math.round(totalOut * outFactors[idx]);
                  const x = startX + idx * stepX;
                  const y = 145 - (val / maxVal) * 115;
                  return { x, y, val, label: lbl, type: 'Output' };
                });

                const capPoints = labels.map((lbl, idx) => {
                  const val = Math.round(totalCap * capFactors[idx]);
                  const x = startX + idx * stepX;
                  const y = 145 - (val / maxVal) * 115;
                  return { x, y, val, label: lbl, type: 'Capacity' };
                });

                let outPath = `M ${outPoints[0].x} ${outPoints[0].y}`;
                for (let i = 0; i < outPoints.length - 1; i++) {
                  const cpX = (outPoints[i].x + outPoints[i + 1].x) / 2;
                  outPath += ` C ${cpX} ${outPoints[i].y}, ${cpX} ${outPoints[i + 1].y}, ${outPoints[i + 1].x} ${outPoints[i + 1].y}`;
                }
                const outArea = `${outPath} L ${outPoints[outPoints.length - 1].x} 150 L ${outPoints[0].x} 150 Z`;

                let capPath = `M ${capPoints[0].x} ${capPoints[0].y}`;
                for (let i = 0; i < capPoints.length - 1; i++) {
                  const cpX = (capPoints[i].x + capPoints[i + 1].x) / 2;
                  capPath += ` C ${cpX} ${capPoints[i].y}, ${cpX} ${capPoints[i + 1].y}, ${capPoints[i + 1].x} ${capPoints[i + 1].y}`;
                }

                return (
                  <div style={{ background: '#FAF6F0', borderRadius: 16, border: '1px solid #ECE4D9', padding: '18px 20px', position: 'relative' }}>
                    {hoveredMillPoint && (
                      <div
                        className="chart-floating-tooltip"
                        style={{
                          left: `${(hoveredMillPoint.x / 500) * 100}%`,
                          top: `${hoveredMillPoint.y}px`,
                        }}
                      >
                        <div style={{ color: '#FF9A93', fontSize: '0.7rem' }}>{hoveredMillPoint.type} • {hoveredMillPoint.label}</div>
                        <div>{hoveredMillPoint.val.toLocaleString()} kg</div>
                      </div>
                    )}

                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                      <div style={{ display: 'flex', gap: 16, fontSize: '0.78rem', fontWeight: 700 }}>
                        <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#8C4A3E' }}>
                          <span style={{ width: 10, height: 10, borderRadius: 3, background: '#8C4A3E' }}></span> Output Volume ({totalOut.toLocaleString()} kg)
                        </span>
                        <span style={{ display: 'flex', alignItems: 'center', gap: 6, color: '#CBA034' }}>
                          <span style={{ width: 10, height: 2, background: '#CBA034' }}></span> Total Rated Capacity ({totalCap.toLocaleString()} kg)
                        </span>
                      </div>
                      <span style={{ fontSize: '0.75rem', fontWeight: 800, color: '#1E8449', backgroundColor: '#E8F8F0', padding: '3px 8px', borderRadius: 8 }}>
                        +14.2% Growth
                      </span>
                    </div>

                    <svg viewBox="0 0 500 160" style={{ width: '100%', height: '160px', overflow: 'visible' }}>
                      <defs>
                        <linearGradient id="millAreaGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                          <stop offset="0%" stopColor="#8C4A3E" stopOpacity="0.25" />
                          <stop offset="100%" stopColor="#8C4A3E" stopOpacity="0.0" />
                        </linearGradient>
                      </defs>

                      {/* Grid Horizontal Reference Lines */}
                      <line x1="0" y1="30" x2="500" y2="30" stroke="#ECE4D9" strokeDasharray="4 4" />
                      <line x1="0" y1="70" x2="500" y2="70" stroke="#ECE4D9" strokeDasharray="4 4" />
                      <line x1="0" y1="110" x2="500" y2="110" stroke="#ECE4D9" strokeDasharray="4 4" />
                      <line x1="0" y1="150" x2="500" y2="150" stroke="#ECE4D9" strokeWidth="1.5" />

                      {/* Area Fill */}
                      <path
                        d={outArea}
                        fill="url(#millAreaGrad)"
                        style={{ transition: 'all 0.4s ease' }}
                      />

                      {/* Target Capacity Line (Dashed Golden) */}
                      <path
                        d={capPath}
                        fill="none"
                        stroke="#CBA034"
                        strokeWidth="2.5"
                        strokeDasharray="6 4"
                        style={{ transition: 'all 0.4s ease' }}
                      />

                      {/* Output Line (Terracotta) */}
                      <path
                        d={outPath}
                        fill="none"
                        stroke="#8C4A3E"
                        strokeWidth="3.5"
                        strokeLinecap="round"
                        style={{ transition: 'all 0.4s ease' }}
                      />

                      {/* Data Points */}
                      {outPoints.map((pt, i) => (
                        <circle
                          key={`out_${i}`}
                          cx={pt.x}
                          cy={pt.y}
                          r={hoveredMillPoint?.label === pt.label ? 7 : (i === outPoints.length - 1 ? 6 : 4.5)}
                          fill={i === outPoints.length - 1 ? '#1E8449' : '#FFF'}
                          stroke="#8C4A3E"
                          strokeWidth="2.5"
                          className="graph-interactive-node"
                          onMouseEnter={() => setHoveredMillPoint(pt)}
                          onMouseLeave={() => setHoveredMillPoint(null)}
                        />
                      ))}

                      {/* Live Pulsing Beacon on Latest Output Point */}
                      <circle
                        cx={outPoints[outPoints.length - 1].x}
                        cy={outPoints[outPoints.length - 1].y}
                        r="6"
                        fill="none"
                        stroke="#1E8449"
                        strokeWidth="2"
                        className="live-pulse-radar"
                      />
                    </svg>

                    {/* X-axis labels */}
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.72rem', color: '#756D69', marginTop: 8, fontWeight: 600, paddingLeft: 16, paddingRight: 8 }}>
                      {labels.map((lbl, idx) => (
                        <span
                          key={idx}
                          style={{
                            color: idx === labels.length - 1 ? '#8C4A3E' : '#756D69',
                            fontWeight: idx === labels.length - 1 ? 800 : 600,
                          }}
                        >
                          {lbl}
                        </span>
                      ))}
                    </div>
                  </div>
                );
              })()}
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
                <span style={{ fontSize: '0.78rem', color: '#756D69', fontWeight: 600 }}>Emergency Overflow Buffer</span>
                <span style={{ fontSize: '0.82rem', fontWeight: 800, color: '#1E8449' }}>+350 kg Avail</span>
              </div>
            </div>
          </div>

          {/* Quick Filter Bar */}
          <div style={{ display: 'flex', gap: 10, marginBottom: 18, flexWrap: 'wrap' }}>
            {['All', 'Active', 'Maintenance', 'High Output (>500kg)', 'Top Rated (★ 4.8+)'].map((filter) => (
              <button
                key={filter}
                onClick={() => handleQuickFilterClick(filter)}
                style={{
                  padding: '7px 16px',
                  borderRadius: 20,
                  fontSize: '0.82rem',
                  fontWeight: 700,
                  border: quickFilter === filter ? '1px solid #8C4A3E' : '1px solid #ECE4D9',
                  backgroundColor: quickFilter === filter ? '#8C4A3E' : '#FFF',
                  color: quickFilter === filter ? '#FFF' : '#756D69',
                  cursor: 'pointer',
                  transition: 'all 0.2s ease',
                }}
              >
                {filter}
              </button>
            ))}
          </div>

          {/* Main Flour Mills Table Container Card */}
          <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
            {/* Header & Controls Toolbar */}
            <div
              style={{
                padding: '20px 24px',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                borderBottom: '1px solid #ECE4D9',
                flexWrap: 'wrap',
                gap: 16,
              }}
            >
              <div>
                <h2 className="card-title" style={{ fontSize: '1.2rem', fontWeight: 800, color: '#2A2421', margin: 0 }}>
                  Active Mill Stations ({filteredMills.length})
                </h2>
                <span style={{ fontSize: '0.8rem', color: '#756D69' }}>
                  Live metrics synchronized with IoT chakki stones
                </span>
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

            {/* Slide-Down Filter Drawer */}
            {isFilterDrawerOpen && (
              <div
                style={{
                  padding: '18px 24px',
                  backgroundColor: '#FAF6F0',
                  borderBottom: '1px solid #ECE4D9',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 20,
                  flexWrap: 'wrap',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <label style={{ fontSize: '0.8rem', fontWeight: 800, color: '#756D69' }}>STATUS:</label>
                  <select
                    value={selectedStatus}
                    onChange={(e) => setSelectedStatus(e.target.value)}
                    style={{ padding: '6px 12px', borderRadius: 8, border: '1px solid #ECE4D9', background: '#FFF', fontSize: '0.85rem', fontWeight: 600 }}
                  >
                    <option value="All">All Statuses</option>
                    <option value="Active">Active</option>
                    <option value="Maintenance">Maintenance</option>
                    <option value="Inactive">Inactive</option>
                  </select>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <label style={{ fontSize: '0.8rem', fontWeight: 800, color: '#756D69' }}>LOCATION:</label>
                  <select
                    value={selectedLocation}
                    onChange={(e) => setSelectedLocation(e.target.value)}
                    style={{ padding: '6px 12px', borderRadius: 8, border: '1px solid #ECE4D9', background: '#FFF', fontSize: '0.85rem', fontWeight: 600 }}
                  >
                    <option value="All">All Locations</option>
                    {locations.map((loc) => (
                      <option key={loc} value={loc}>{loc}</option>
                    ))}
                  </select>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <label style={{ fontSize: '0.8rem', fontWeight: 800, color: '#756D69' }}>MIN RATING:</label>
                  <select
                    value={minRating}
                    onChange={(e) => setMinRating(e.target.value)}
                    style={{ padding: '6px 12px', borderRadius: 8, border: '1px solid #ECE4D9', background: '#FFF', fontSize: '0.85rem', fontWeight: 600 }}
                  >
                    <option value="All">Any Rating</option>
                    <option value="4.8">★ 4.8 and up</option>
                    <option value="4.5">★ 4.5 and up</option>
                    <option value="4.0">★ 4.0 and up</option>
                  </select>
                </div>

                {hasActiveFilters && (
                  <button
                    onClick={handleResetFilters}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: 4,
                      border: 'none',
                      background: 'transparent',
                      color: '#8C4A3E',
                      fontSize: '0.8rem',
                      fontWeight: 800,
                      cursor: 'pointer',
                    }}
                  >
                    <RotateCcw size={13} />
                    <span>Reset</span>
                  </button>
                )}
              </div>
            )}

            {/* Table */}
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '0.88rem' }}>
                <thead>
                  <tr style={{ borderBottom: '1px solid #ECE4D9', background: '#FAF6F0', color: '#756D69', fontSize: '0.75rem', fontWeight: 800, letterSpacing: 0.5 }}>
                    <th style={{ padding: '14px 20px' }}>MILL NAME</th>
                    <th style={{ padding: '14px 20px' }}>LOCATION</th>
                    <th style={{ padding: '14px 20px' }}>DAILY OUTPUT</th>
                    <th style={{ padding: '14px 20px' }}>STATUS</th>
                    <th style={{ padding: '14px 20px' }}>RATING</th>
                    <th style={{ padding: '14px 20px', textAlign: 'right' }}>ACTIONS</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredMills.length === 0 ? (
                    <tr>
                      <td colSpan="6" style={{ padding: '40px 20px', textAlign: 'center', color: '#756D69' }}>
                        No mills match your filter criteria.
                      </td>
                    </tr>
                  ) : (
                    filteredMills.map((mill) => {
                      const badge = getStatusBadge(mill.status);
                      return (
                        <tr key={mill.id} style={{ borderBottom: '1px solid #ECE4D9', transition: 'background 0.2s ease' }}>
                          <td style={{ padding: '16px 20px' }}>
                            <div style={{ fontWeight: 800, color: '#2A2421' }}>{mill.name}</div>
                            <div style={{ fontSize: '0.78rem', color: '#756D69' }}>
                              Owner: {mill.owner} • {mill.phone}
                            </div>
                          </td>
                          <td style={{ padding: '16px 20px', color: '#2A2421' }}>
                            <span style={{ fontWeight: 600 }}>{mill.loc}</span>
                          </td>
                          <td style={{ padding: '16px 20px' }}>
                            <span style={{ fontWeight: 800, color: '#2A2421' }}>{mill.outputText}</span>
                            <div style={{ fontSize: '0.75rem', color: '#756D69' }}>Cap: {mill.capacity} kg/day</div>
                          </td>
                          <td style={{ padding: '16px 20px' }}>
                            <span
                              style={{
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: 6,
                                padding: '4px 10px',
                                borderRadius: 16,
                                backgroundColor: badge.bg,
                                color: badge.color,
                                fontWeight: 800,
                                fontSize: '0.75rem',
                              }}
                            >
                              <span style={{ width: 6, height: 6, borderRadius: '50%', backgroundColor: badge.dot }}></span>
                              {mill.status}
                            </span>
                          </td>
                          <td style={{ padding: '16px 20px' }}>
                            <span style={{ fontWeight: 800, color: '#2A2421' }}>★ {mill.rating}</span>
                          </td>
                          <td style={{ padding: '16px 20px', textAlign: 'right' }}>
                            <div style={{ display: 'inline-flex', gap: 6 }}>
                              <button
                                className="btn-outline"
                                style={{ padding: '6px 12px', fontSize: '0.75rem', borderRadius: 8, display: 'inline-flex', alignItems: 'center', gap: 4 }}
                                onClick={() => handleOpenEdit(mill)}
                              >
                                <Pencil size={13} />
                                <span>Edit</span>
                              </button>
                              <button
                                className="btn-outline"
                                style={{
                                  padding: '6px 12px',
                                  fontSize: '0.75rem',
                                  borderRadius: 8,
                                  borderColor: '#FDEDEC',
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
        </div>
      )}

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

      {/* Merchant Application Review & Approval Modal */}
      {isReviewModalOpen && selectedAppForReview && (
        <div className="modal-overlay" style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999, padding: 20 }}>
          <div className="modal-dialog" style={{ backgroundColor: 'white', borderRadius: 24, padding: 30, width: 680, maxWidth: '95%', maxHeight: '90vh', overflowY: 'auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 20, borderBottom: '1px solid #ECE4D9', paddingBottom: 16 }}>
              <div>
                <span style={{ fontSize: '0.75rem', fontWeight: 800, color: '#8C4A3E', letterSpacing: 0.5, textTransform: 'uppercase' }}>
                  MERCHANT APPLICATION ID: #{selectedAppForReview.id}
                </span>
                <h2 className="serif-heading" style={{ fontSize: '1.6rem', fontWeight: 800, color: '#2A2421', margin: '4px 0 0 0' }}>
                  {selectedAppForReview.storeName}
                </h2>
                <div style={{ fontSize: '0.85rem', color: '#756D69', marginTop: 4 }}>
                  Submitted by {selectedAppForReview.applicantName} • {new Date(selectedAppForReview.createdAt).toLocaleDateString()}
                </div>
              </div>
              <button
                onClick={() => {
                  setIsReviewModalOpen(false);
                  setSelectedAppForReview(null);
                }}
                style={{ border: 'none', background: 'transparent', cursor: 'pointer', padding: 4 }}
              >
                <X size={22} color="#756D69" />
              </button>
            </div>

            {/* Application Visual Preview (Storefront & License) */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14, marginBottom: 20 }}>
              <div>
                <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 6 }}>
                  STOREFRONT PHOTO
                </label>
                <div style={{ borderRadius: 14, overflow: 'hidden', border: '1px solid #ECE4D9', height: 160, background: '#FAF6F0' }}>
                  <img
                    src={selectedAppForReview.storeImage || 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=500&q=80'}
                    alt="Store Front"
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  />
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#756D69', marginBottom: 6 }}>
                  FSSAI / TRADE LICENSE DOCUMENT
                </label>
                <div style={{ borderRadius: 14, overflow: 'hidden', border: '1px solid #ECE4D9', height: 160, background: '#FAF6F0', position: 'relative' }}>
                  <img
                    src={selectedAppForReview.licenseDocument || 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=500&q=80'}
                    alt="License"
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  />
                  <div style={{ position: 'absolute', bottom: 8, right: 8, background: 'rgba(0,0,0,0.7)', color: '#FFF', padding: '3px 8px', borderRadius: 6, fontSize: '0.7rem', fontWeight: 700 }}>
                    {selectedAppForReview.licenseNumber || 'FSSAI Verified'}
                  </div>
                </div>
              </div>
            </div>

            {/* Store Information Grid */}
            <div style={{ background: '#FAF6F0', borderRadius: 16, border: '1px solid #ECE4D9', padding: 18, marginBottom: 20 }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, fontSize: '0.85rem' }}>
                <div>
                  <span style={{ color: '#756D69', fontWeight: 700, fontSize: '0.75rem' }}>OWNER CONTACT:</span>
                  <div style={{ fontWeight: 800, color: '#2A2421', marginTop: 2 }}>{selectedAppForReview.applicantName}</div>
                  <div style={{ color: '#756D69' }}>📞 {selectedAppForReview.applicantPhone || selectedAppForReview.phone}</div>
                  <div style={{ color: '#756D69' }}>✉️ {selectedAppForReview.applicantEmail || 'applicant@herdoor.com'}</div>
                </div>

                <div>
                  <span style={{ color: '#756D69', fontWeight: 700, fontSize: '0.75rem' }}>STORE LOCATION:</span>
                  <div style={{ fontWeight: 800, color: '#2A2421', marginTop: 2 }}>{selectedAppForReview.city || 'Ahmedabad'}, {selectedAppForReview.pincode}</div>
                  <div style={{ color: '#756D69' }}>{selectedAppForReview.address}</div>
                </div>

                <div>
                  <span style={{ color: '#756D69', fontWeight: 700, fontSize: '0.75rem' }}>OPERATING PARAMETERS:</span>
                  <div style={{ fontWeight: 700, color: '#2A2421', marginTop: 2 }}>
                    Grinding Capacity: <span style={{ color: '#8C4A3E' }}>{selectedAppForReview.capacityKgPerDay || 500} kg/day</span>
                  </div>
                  <div style={{ color: '#756D69' }}>Delivery Radius: {selectedAppForReview.deliveryRadiusKm || 5.0} km</div>
                  <div style={{ color: '#756D69' }}>Hours: {selectedAppForReview.workingHours || '08:00 AM - 08:00 PM'}</div>
                </div>

                <div>
                  <span style={{ color: '#756D69', fontWeight: 700, fontSize: '0.75rem' }}>SPECIALTY & SERVICES:</span>
                  <div style={{ fontWeight: 700, color: '#2A2421', marginTop: 2 }}>{selectedAppForReview.specialty || 'Whole Flour Specialist'}</div>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, marginTop: 4 }}>
                    {(selectedAppForReview.services || ['Flour Grinding', 'Packing']).map((s, idx) => (
                      <span key={idx} style={{ background: '#FFF', border: '1px solid #ECE4D9', padding: '1px 6px', borderRadius: 6, fontSize: '0.72rem', fontWeight: 700, color: '#6E5616' }}>
                        {s}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            {/* Merchant Activation Credentials & Onboarding Email Section */}
            {selectedAppForReview.status === 'PENDING' && !isRejectMode && (
              <div style={{ background: '#F0F9F4', border: '1.5px solid #D4EFDF', borderRadius: 16, padding: 18, marginBottom: 20 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                  <span style={{ fontSize: '1.1rem' }}>🔐</span>
                  <div style={{ fontWeight: 800, color: '#196F3D', fontSize: '0.95rem' }}>
                    Shopkeeper Demo / Initial Login Credentials & Email Dispatch
                  </div>
                </div>
                <p style={{ fontSize: '0.8rem', color: '#27AE60', margin: '0 0 12px 0', lineHeight: 1.4 }}>
                  When approved, HerDoor will send a welcome email to the applicant with their active store status, demo login ID, and temporary password.
                </p>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: 800, color: '#196F3D', marginBottom: 4 }}>
                      MERCHANT LOGIN ID / EMAIL:
                    </label>
                    <input
                      type="text"
                      value={approvalLoginId}
                      onChange={(e) => setApprovalLoginId(e.target.value)}
                      placeholder="e.g. shop.ramesh@herdoor.com"
                      style={{
                        width: '100%',
                        padding: '9px 12px',
                        borderRadius: 10,
                        border: '1px solid #A9DFBF',
                        fontSize: '0.88rem',
                        fontWeight: 600,
                        backgroundColor: '#FFF',
                        outline: 'none',
                      }}
                    />
                  </div>

                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                      <label style={{ fontSize: '0.75rem', fontWeight: 800, color: '#196F3D' }}>
                        DEMO / TEMPORARY PASSWORD:
                      </label>
                      <button
                        type="button"
                        onClick={() => {
                          const rand = 'Chakki@' + Math.floor(1000 + Math.random() * 9000);
                          setApprovalPassword(rand);
                        }}
                        style={{ border: 'none', background: 'transparent', color: '#1E8449', fontSize: '0.72rem', fontWeight: 800, cursor: 'pointer' }}
                      >
                        ⚡ Generate
                      </button>
                    </div>
                    <input
                      type="text"
                      value={approvalPassword}
                      onChange={(e) => setApprovalPassword(e.target.value)}
                      placeholder="e.g. Password123!"
                      style={{
                        width: '100%',
                        padding: '9px 12px',
                        borderRadius: 10,
                        border: '1px solid #A9DFBF',
                        fontSize: '0.88rem',
                        fontWeight: 700,
                        backgroundColor: '#FFF',
                        outline: 'none',
                        color: '#2A2421',
                      }}
                    />
                  </div>
                </div>

                <div style={{ marginTop: 12, display: 'flex', alignItems: 'center', gap: 8 }}>
                  <input
                    type="checkbox"
                    id="sendWelcomeEmail"
                    checked={sendWelcomeEmailCheck}
                    onChange={(e) => setSendWelcomeEmailCheck(e.target.checked)}
                    style={{ width: 16, height: 16, accentColor: '#1E8449', cursor: 'pointer' }}
                  />
                  <label htmlFor="sendWelcomeEmail" style={{ fontSize: '0.82rem', fontWeight: 700, color: '#1E8449', cursor: 'pointer' }}>
                    📧 Dispatch official Merchant Onboarding Welcome Email with credentials to {approvalLoginId || 'applicant'}
                  </label>
                </div>
              </div>
            )}

            {/* If application is already approved, show active credentials status */}
            {selectedAppForReview.status === 'APPROVED' && selectedAppForReview.credentials && (
              <div style={{ background: '#EAFAF1', border: '1px solid #A9DFBF', borderRadius: 16, padding: 16, marginBottom: 20 }}>
                <div style={{ fontWeight: 800, color: '#1E8449', fontSize: '0.9rem', marginBottom: 6 }}>
                  ✅ Active Merchant Login Credentials (Dispatched)
                </div>
                <div style={{ fontSize: '0.82rem', color: '#2C3E50', display: 'flex', gap: 20 }}>
                  <div><strong>Login ID:</strong> {selectedAppForReview.credentials.loginId}</div>
                  <div><strong>Temporary Password:</strong> {selectedAppForReview.credentials.temporaryPassword}</div>
                </div>
              </div>
            )}

            {/* Rejection Feedback Mode */}
            {isRejectMode && (
              <div style={{ marginBottom: 20, background: '#FDEDEC', border: '1px solid #FADBD8', borderRadius: 14, padding: 16 }}>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: 800, color: '#C0392B', marginBottom: 6 }}>
                  REASON FOR REJECTION (Will be sent to user):
                </label>
                <textarea
                  rows="3"
                  placeholder="e.g. FSSAI registration document is blurry or expired. Please re-upload clear certificate."
                  value={rejectReasonInput}
                  onChange={(e) => setRejectReasonInput(e.target.value)}
                  style={{ width: '100%', padding: '10px 12px', borderRadius: 10, border: '1px solid #FADBD8', fontSize: '0.85rem', outline: 'none' }}
                />
              </div>
            )}

            {/* Modal Actions */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 10, borderTop: '1px solid #ECE4D9', paddingTop: 18 }}>
              <div>
                {selectedAppForReview.status === 'PENDING' && !isRejectMode && (
                  <button
                    type="button"
                    onClick={() => setIsRejectMode(true)}
                    style={{
                      padding: '10px 18px',
                      borderRadius: 12,
                      border: '1px solid #C0392B',
                      background: '#FFF',
                      color: '#C0392B',
                      fontWeight: 800,
                      fontSize: '0.85rem',
                      cursor: 'pointer',
                    }}
                  >
                    Reject Application...
                  </button>
                )}
                {isRejectMode && (
                  <button
                    type="button"
                    onClick={() => setIsRejectMode(false)}
                    style={{
                      padding: '10px 18px',
                      borderRadius: 12,
                      border: '1px solid #ECE4D9',
                      background: '#FFF',
                      color: '#756D69',
                      fontWeight: 700,
                      fontSize: '0.85rem',
                      cursor: 'pointer',
                    }}
                  >
                    Cancel Rejection
                  </button>
                )}
              </div>

              <div style={{ display: 'flex', gap: 10 }}>
                <button
                  type="button"
                  className="btn-outline"
                  onClick={() => {
                    setIsReviewModalOpen(false);
                    setSelectedAppForReview(null);
                  }}
                  style={{ padding: '10px 18px', borderRadius: 12 }}
                >
                  Close
                </button>

                {isRejectMode ? (
                  <button
                    type="button"
                    onClick={() => handleRejectApplication(selectedAppForReview.id)}
                    disabled={isProcessingApp}
                    style={{
                      padding: '10px 22px',
                      borderRadius: 12,
                      border: 'none',
                      background: '#C0392B',
                      color: '#FFF',
                      fontWeight: 800,
                      fontSize: '0.9rem',
                      cursor: 'pointer',
                    }}
                  >
                    {isProcessingApp ? 'Rejecting...' : 'Confirm Rejection'}
                  </button>
                ) : (
                  selectedAppForReview.status === 'PENDING' && (
                    <button
                      type="button"
                      onClick={() => handleApproveApplication(selectedAppForReview.id)}
                      disabled={isProcessingApp}
                      style={{
                        padding: '10px 24px',
                        borderRadius: 12,
                        border: 'none',
                        background: 'linear-gradient(135deg, #1E8449, #196F3D)',
                        color: '#FFF',
                        fontWeight: 800,
                        fontSize: '0.92rem',
                        cursor: 'pointer',
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: 6,
                        boxShadow: '0 4px 12px rgba(30, 132, 73, 0.3)',
                      }}
                    >
                      <CheckCircle2 size={16} />
                      <span>{isProcessingApp ? 'Approving Store...' : 'Approve & Onboard Store'}</span>
                    </button>
                  )
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
