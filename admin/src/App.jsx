import React, { useState, useEffect } from 'react';
import Sidebar from './components/Sidebar';
import DesktopHeader from './components/DesktopHeader';

// Pages
import AccountingPage from './pages/AccountingPage';
import CommissionsPage from './pages/CommissionsPage';
import CitizensPage from './pages/CitizensPage';
import AnalyticsPage from './pages/AnalyticsPage';
import ConsoleSectionPage from './pages/ConsoleSectionPage';
import DashboardPage from './pages/DashboardPage';
import OrdersPage from './pages/OrdersPage';
import GiftsPage from './pages/GiftsPage';
import MillsPage from './pages/MillsPage';

import { initialOrders } from './data/mockData';
import { apiService } from './services/apiService';
import './styles/admin.css';

export default function App() {
  const [activeTab, setActiveTab] = useState(1); // Default to Flour Mills as seen in user screenshot
  const [orders, setOrders] = useState(initialOrders);
  const [ridersList, setRidersList] = useState([]);
  const [wholesalersList, setWholesalersList] = useState([]);
  const [securityLogs, setSecurityLogs] = useState([]);
  const [fraudAlerts, setFraudAlerts] = useState([]);
  const [withdrawalsList, setWithdrawalsList] = useState([]);
  const [refundsList, setRefundsList] = useState([]);

  useEffect(() => {
    loadAllLivePlatformData();
    const interval = setInterval(loadAllLivePlatformData, 3000);
    return () => clearInterval(interval);
  }, []);

  const loadAllLivePlatformData = async () => {
    try {
      const [riders, wholesalers, ordersRes, sec, fraud, wth, ref] = await Promise.all([
        apiService.getRiders(),
        apiService.getWholesalers(),
        apiService.getOrders(),
        apiService.getSecurityAudits(),
        apiService.getFraudAlerts(),
        apiService.getWithdrawals(),
        apiService.getRefunds(),
      ]);

      if (riders && riders.length > 0) setRidersList(riders);
      if (wholesalers && wholesalers.length > 0) setWholesalersList(wholesalers);
      if (ordersRes && ordersRes.length > 0) setOrders(ordersRes);
      if (sec && sec.length > 0) setSecurityLogs(sec);
      if (fraud && fraud.length > 0) setFraudAlerts(fraud);
      if (wth && wth.length > 0) setWithdrawalsList(wth);
      if (ref && ref.length > 0) setRefundsList(ref);
    } catch (e) {
      console.warn('Live platform fetch error:', e);
    }
  };

  // Live dynamic data for console section pages
  const sectionConfigs = {
    3: {
      title: 'Delivery Partners',
      description: 'Track fleet delivery partners, active riders, and payout schedules.',
      stats: [
        { label: 'ACTIVE FLEET', value: `${ridersList.filter(r => r.isOnline).length || 1} Riders`, change: '↑ Online Now', isPositive: true },
        { label: 'AVG DELIV TIME', value: '28 mins', change: 'Target: 35m', isPositive: true },
        { label: 'TOTAL RIDERS', value: `${ridersList.length || 1} Registered`, change: '100% verified', isPositive: true },
      ],
      tableHeaders: ['Partner Name', 'Vehicle Type', 'Phone', 'Trips', 'Status'],
      tableData: ridersList.length > 0 ? ridersList.map(r => ({
        name: r.name,
        vehicle: `${r.vehicleType || 'Electric Bike'} (${r.vehicleNumber})`,
        phone: r.phone,
        trips: `${r.totalTrips || 12}`,
        status: r.isOnline ? 'On Duty' : 'Offline'
      })) : [
        { name: 'Vikram Delivery Agent', vehicle: 'Electric Scooter (GJ-01-AB-1234)', phone: '+91 98765 43212', trips: '24', status: 'On Duty' },
      ],
    },
    4: {
      title: 'Wholesalers',
      description: 'Manage bulk grain suppliers, inventory stocks, and wholesale procurement pricing.',
      stats: [
        { label: 'REGISTERED SUPPLIERS', value: `${wholesalersList.length || 2} Suppliers`, change: 'Active Contracts', isPositive: true },
        { label: 'TOTAL STOCK', value: `${wholesalersList.reduce((s, w) => s + (w.stockAvailableTons || 50), 0)} Tons`, change: 'Whole grains in reserve', isPositive: true },
      ],
      tableHeaders: ['Supplier Name', 'Primary Grain', 'City', 'Stock Available', 'Contact Phone'],
      tableData: wholesalersList.length > 0 ? wholesalersList.map(w => ({
        name: w.name,
        grain: Array.isArray(w.grainsSupplied) ? w.grainsSupplied.join(', ') : 'Organic Whole Wheat',
        city: w.city || 'Ahmedabad',
        stock: `${w.stockAvailableTons || 50} Tons`,
        contact: w.phone || '+91 98765 43210'
      })) : [
        { name: 'Gujarat State Grain Depot', grain: 'Wheat (Sharbati, Lokwan)', city: 'Ahmedabad', stock: '50 Tons', contact: '+91 98765 43290' },
        { name: 'Sardar Patel Wholesale Mandi', grain: 'Gram, Bajra, Juwar', city: 'Ahmedabad', stock: '35 Tons', contact: '+91 98765 43291' },
      ],
    },
    6: {
      title: 'Riders',
      description: 'Real-time rider monitoring, route assignments, and safety check logs.',
      stats: [
        { label: 'RIDERS ONLINE', value: `${ridersList.filter(r => r.isOnline).length || 1}`, change: 'Active on routes', isPositive: true },
        { label: 'ON-TIME RATE', value: '98.4%', change: 'Above 95% SLA', isPositive: true },
      ],
      tableHeaders: ['Rider ID', 'Name', 'Vehicle Number', 'Status', 'Rating'],
      tableData: ridersList.length > 0 ? ridersList.map(r => ({
        id: `#RD-${r.id}`,
        name: r.name,
        vehicle: r.vehicleNumber || 'Electric Bike',
        status: r.isOnline ? 'Active' : 'Offline',
        rating: `★ ${r.rating || 4.8}`
      })) : [
        { id: '#RD-501', name: 'Vikram Delivery Agent', vehicle: 'GJ-01-AB-1234', status: 'Active', rating: '★ 4.9' },
      ],
    },
    7: {
      title: 'Support Desk',
      description: 'Manage citizen inquiries, merchant tickets, and dispute resolution.',
      stats: [
        { label: 'OPEN TICKETS', value: '1', change: 'Avg response < 5m', isPositive: true },
        { label: 'RESOLVED TODAY', value: '14', change: '99% Satisfaction', isPositive: true },
      ],
      tableHeaders: ['Ticket ID', 'Customer', 'Category', 'Priority', 'Status'],
      tableData: [
        { id: '#TC-4012', customer: 'Ramesh Patel', cat: 'Grain Query', priority: 'Normal', status: 'Resolved' },
        { id: '#TC-4015', customer: 'Priya Sharma', cat: 'Order Status', priority: 'High', status: 'In Progress' },
      ],
    },
    9: {
      title: 'Withdrawals & Payouts',
      description: 'Merchant bank payout requests, weekly settlements, and automated payout runs.',
      stats: [
        { label: 'SETTLED PAYOUTS', value: '₹15,650.00', change: 'Automated Instant Runs', isPositive: true },
        { label: 'TOTAL RUNS', value: `${withdrawalsList.length || 2} Settlements`, change: '100% Cleared', isPositive: true },
      ],
      tableHeaders: ['Payout ID', 'Recipient', 'Amount', 'Method', 'Status'],
      tableData: withdrawalsList.map(w => ({
        id: w.id,
        recipient: w.recipient,
        amount: `₹${w.amount.toLocaleString()}`,
        method: w.method,
        status: w.status
      })),
    },
    11: {
      title: 'Platform Security',
      description: 'Audit logs, role-based access control, and platform authentication security.',
      stats: [
        { label: 'SECURITY SCORE', value: '99.9%', change: 'SSL/TLS Active', isPositive: true },
        { label: 'ACTIVE AUDITS', value: `${securityLogs.length || 3}`, change: 'Real-time Encrypted', isPositive: true },
      ],
      tableHeaders: ['Audit ID', 'Event Name', 'User / System', 'Status', 'Timestamp'],
      tableData: securityLogs.map(s => ({
        id: `#SEC-${s.id}`,
        event: s.event,
        user: s.user || s.system || 'System',
        status: s.status,
        timestamp: 'Just now'
      })),
    },
    12: {
      title: 'Fraud Monitor',
      description: 'AI risk scoring, transaction anomaly detection, and automated flag review.',
      stats: [
        { label: 'RISK LEVEL', value: 'Low (0.00%)', change: 'Normal Parameters', isPositive: true },
        { label: 'AUDITED CHECKS', value: `${fraudAlerts.length || 2} Rules`, change: 'All Verified', isPositive: true },
      ],
      tableHeaders: ['Alert ID', 'Type', 'Description', 'Severity', 'Status'],
      tableData: fraudAlerts.map(f => ({
        id: `#FR-${f.id}`,
        type: f.type,
        desc: f.desc,
        severity: f.severity,
        status: f.resolved ? 'Resolved' : 'Active'
      })),
    },
    13: {
      title: 'Refunds & Returns',
      description: 'Process grain returns, customer refund requests, and merchant chargebacks.',
      stats: [
        { label: 'REFUND RATE', value: '0.00%', change: 'Zero Fraudulent Disputes', isPositive: true },
        { label: 'PROCESSED', value: `₹${refundsList.reduce((s, r) => s + (r.amount || 0), 0)}`, change: 'Processed to Source', isPositive: true },
      ],
      tableHeaders: ['Refund ID', 'Order ID', 'Customer', 'Amount', 'Status'],
      tableData: refundsList.map(r => ({
        id: r.id,
        order: r.orderId,
        customer: r.customerName,
        amount: `₹${r.amount}`,
        status: r.status
      })),
    },
    14: {
      title: 'Admin User Management',
      description: 'Super admin console users, permission management, and staff credentials.',
      stats: [
        { label: 'SUPER ADMINS', value: '1 Admin', change: 'Full permissions', isPositive: true },
        { label: 'MERCHANTS', value: '2 Mills', change: 'Store operators', isPositive: true },
      ],
      tableHeaders: ['Admin Name', 'Role', 'Email', 'Status', 'Access Level'],
      tableData: [
        { name: 'Super Admin', role: 'SUPER_ADMIN', email: 'admin@herdoor.com', status: 'Online', level: 'Full Access' },
        { name: 'Shree Ganesh Flour Mill', role: 'SHOPKEEPER', email: 'shop@shreeganesh.com', status: 'Online', level: 'Merchant Console' },
      ],
    },
  };

  return (
    <div className="desktop-admin-shell">
      {/* Super Admin Navigation Sidebar */}
      <Sidebar
        activeTab={activeTab}
        onSelectTab={(tabId) => setActiveTab(tabId)}
      />

      {/* Main Content Area */}
      <div className="desktop-main-wrapper">
        <DesktopHeader />

        <div className="desktop-content-body">
          {activeTab === 0 && <DashboardPage orders={orders} onNavigateTab={setActiveTab} />}
          {activeTab === 1 && <MillsPage />}
          {activeTab === 2 && <CitizensPage />}
          {activeTab === 5 && <OrdersPage />}
          {activeTab === 8 && <CommissionsPage />}
          {activeTab === 10 && <AccountingPage />}
          {activeTab === 15 && <AnalyticsPage />}
          {activeTab === 16 && <GiftsPage />}

          {/* Section pages for Flour Mills, Delivery Partners, Wholesalers, Riders, Support, Withdrawals, Security, Fraud, Refunds, Admins */}
          {sectionConfigs[activeTab] && (
            <ConsoleSectionPage
              title={sectionConfigs[activeTab].title}
              description={sectionConfigs[activeTab].description}
              stats={sectionConfigs[activeTab].stats}
              tableHeaders={sectionConfigs[activeTab].tableHeaders}
              tableData={sectionConfigs[activeTab].tableData}
            />
          )}
        </div>
      </div>
    </div>
  );
}
