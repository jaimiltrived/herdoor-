import React, { useState } from 'react';
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
import './styles/admin.css';

export default function App() {
  // Tab 10 is 'Accounting' (Primary active tab from Image 1)
  const [activeTab, setActiveTab] = useState(10);
  const [orders] = useState(initialOrders);

  // Mock data for console section pages
  const sectionConfigs = {
    3: {
      title: 'Delivery Partners',
      description: 'Track fleet delivery partners, active riders, and payout schedules.',
      stats: [
        { label: 'ACTIVE FLEET', value: '124 Riders', change: '↑ 14 online now', isPositive: true },
        { label: 'AVG DELIV TIME', value: '38 mins', change: 'Target: 45m', isPositive: true },
        { label: 'COMPLETED TODAY', value: '342 Orders', change: '100% fulfilled', isPositive: true },
      ],
      tableHeaders: ['Partner Name', 'Vehicle Type', 'Active Area', 'Deliveries', 'Status'],
      tableData: [
        { name: 'Rajesh Kumar', vehicle: 'Electric Bike #EB-4821', area: 'North District', deliv: '48', status: 'On Duty' },
        { name: 'Priya Sharma', vehicle: 'Eco Scooter #ES-1204', area: 'Central Market', deliv: '36', status: 'On Duty' },
        { name: 'Amit Patel', vehicle: 'Delivery Van #DV-9011', area: 'Westside', deliv: '52', status: 'Offline' },
      ],
    },
    4: {
      title: 'Wholesalers',
      description: 'Manage bulk grain suppliers, inventory stocks, and wholesale procurement pricing.',
      stats: [
        { label: 'REGISTERED SUPPLIERS', value: '16 Suppliers', change: 'Active Contracts', isPositive: true },
        { label: 'TOTAL STOCK', value: '84,000 kg', change: 'Whole grains in reserve', isPositive: true },
      ],
      tableHeaders: ['Supplier Name', 'Primary Grain', 'Stock Level', 'Contract Tier', 'Contact'],
      tableData: [
        { name: 'Golden Harvest Agro', grain: 'Organic Whole Wheat', stock: '32,000 kg', tier: 'Tier 1 Wholesale', contact: 'orders@goldenharvest.com' },
        { name: 'Punjab Grain Depot', grain: 'Stoneground Rye', stock: '24,500 kg', tier: 'Tier 1 Wholesale', contact: 'sales@punjabgrain.in' },
      ],
    },
    6: {
      title: 'Riders',
      description: 'Real-time rider monitoring, route assignments, and safety check logs.',
      stats: [
        { label: 'RIDERS ONLINE', value: '42', change: 'Active on routes', isPositive: true },
        { label: 'ON-TIME RATE', value: '98.4%', change: 'Above 95% SLA', isPositive: true },
      ],
      tableHeaders: ['Rider ID', 'Name', 'Current Zone', 'Assigned Order', 'Battery Status'],
      tableData: [
        { id: '#RD-9901', name: 'Sanjay V.', zone: 'North Sector', order: '#HD-8829', battery: '92%' },
        { id: '#RD-9904', name: 'Vikram S.', zone: 'East Sector', order: '#HD-8830', battery: '78%' },
      ],
    },
    7: {
      title: 'Support Desk',
      description: 'Manage citizen inquiries, merchant tickets, and dispute resolution.',
      stats: [
        { label: 'OPEN TICKETS', value: '5', change: 'Avg response < 10m', isPositive: true },
        { label: 'RESOLVED TODAY', value: '28', change: '99% Satisfaction', isPositive: true },
      ],
      tableHeaders: ['Ticket ID', 'Customer', 'Category', 'Priority', 'Status'],
      tableData: [
        { id: '#TC-4012', customer: 'Mrs. Eleanor Rigby', cat: 'Order Delay', priority: 'High', status: 'In Progress' },
        { id: '#TC-4015', customer: 'Marcus Chen', cat: 'Grain Query', priority: 'Normal', status: 'Resolved' },
      ],
    },
    9: {
      title: 'Withdrawals & Payouts',
      description: 'Merchant bank payout requests, weekly settlements, and automated payout runs.',
      stats: [
        { label: 'PENDING PAYOUTS', value: '₹145,000', change: 'Ready for batch run', isPositive: true },
        { label: 'PROCESSED MTD', value: '₹1,840,000', change: '24 Payout runs', isPositive: true },
      ],
      tableHeaders: ['Payout ID', 'Merchant', 'Amount', 'Bank Account', 'Status'],
      tableData: [
        { id: '#PO-8812', merchant: 'Artisan Mill Co.', amount: '₹145,000.00', bank: 'HDFC Bank ****4821', status: 'Processing' },
        { id: '#PO-8810', merchant: 'Sunrise Flour Mill', amount: '₹82,500.00', bank: 'ICICI Bank ****9012', status: 'Completed' },
      ],
    },
    11: {
      title: 'Platform Security',
      description: 'Audit logs, role-based access control, and platform authentication security.',
      stats: [
        { label: 'SECURITY SCORE', value: '99/100', change: 'All systems secured', isPositive: true },
        { label: 'ACTIVE SESSIONS', value: '14', change: 'Encrypted connections', isPositive: true },
      ],
      tableHeaders: ['Timestamp', 'Event', 'User Role', 'IP Address', 'Result'],
      tableData: [
        { time: '10 mins ago', event: 'Super Admin Login', role: 'Super Admin', ip: '192.168.1.45', result: 'Success' },
        { time: '1 hour ago', event: 'API Key Rotated', role: 'System Engine', ip: '10.0.0.1', result: 'Success' },
      ],
    },
    12: {
      title: 'Fraud Monitor',
      description: 'AI risk scoring, transaction anomaly detection, and automated flag review.',
      stats: [
        { label: 'RISK THREAT LEVEL', value: 'Low (0.01%)', change: 'Normal parameters', isPositive: true },
        { label: 'FLAGGED TXNS', value: '0', change: 'Clear history', isPositive: true },
      ],
      tableHeaders: ['Alert ID', 'Entity', 'Risk Score', 'Trigger Rule', 'Status'],
      tableData: [
        { id: '#FM-102', entity: 'User #CZ-9012', score: 'Low (12/100)', rule: 'Multiple login IP check', status: 'Passed' },
      ],
    },
    13: {
      title: 'Refunds & Returns',
      description: 'Process grain returns, customer refund requests, and merchant chargebacks.',
      stats: [
        { label: 'REFUND RATE', value: '0.12%', change: 'Well below 1.0% limit', isPositive: true },
        { label: 'PROCESSED MTD', value: '₹4,500', change: '3 Customer refunds', isPositive: true },
      ],
      tableHeaders: ['Refund ID', 'Order ID', 'Customer', 'Amount', 'Reason'],
      tableData: [
        { id: '#RF-201', order: '#HD-7712', customer: 'Elena Rodriguez', amount: '₹1,500.00', reason: 'Order Cancellation' },
      ],
    },
    14: {
      title: 'Admin User Management',
      description: 'Super admin console users, permission management, and staff credentials.',
      stats: [
        { label: 'SUPER ADMINS', value: '3 Users', change: 'Full permissions', isPositive: true },
        { label: 'OPS STAFF', value: '8 Users', change: 'Console access', isPositive: true },
      ],
      tableHeaders: ['Admin Name', 'Role', 'Email', 'Last Active', 'Access Level'],
      tableData: [
        { name: 'Sarah Jenkins', role: 'Super Admin', email: 'sarah.j@herdoor.com', active: 'Active Now', level: 'Full Access' },
        { name: 'David Miller', role: 'Ops Lead', email: 'david.m@herdoor.com', active: '2 hours ago', level: 'Management' },
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
