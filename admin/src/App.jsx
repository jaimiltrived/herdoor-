import React, { useState, useEffect } from 'react';
import Sidebar from './components/Sidebar';
import DesktopHeader from './components/DesktopHeader';

import AcceptOrderModal from './components/AcceptOrderModal';
import DeliveryHandoverModal from './components/DeliveryHandoverModal';
import ServiceAvailabilityModal from './components/ServiceAvailabilityModal';

import DashboardPage from './pages/DashboardPage';
import OrdersPage from './pages/OrdersPage';
import ProcessHistoryPage from './pages/ProcessHistoryPage';
import InventoryPage from './pages/InventoryPage';
import ProfilePage from './pages/ProfilePage';

import { apiService } from './services/apiService';
import { initialOrders } from './data/mockData';
import './styles/admin.css';

export default function App() {
  const [activeTab, setActiveTab] = useState(0); // 0: Dashboard, 1: Orders, 2: Process, 3: Inventory, 4: Profile
  const [shopStatus, setShopStatus] = useState(true);
  const [orders, setOrders] = useState(initialOrders);
  const [selectedOrder, setSelectedOrder] = useState(null);

  // Modal States
  const [isAcceptModalOpen, setIsAcceptModalOpen] = useState(false);
  const [isHandoverModalOpen, setIsHandoverModalOpen] = useState(false);
  const [isAvailabilityModalOpen, setIsAvailabilityModalOpen] = useState(false);
  const [targetOrderForAccept, setTargetOrderForAccept] = useState(null);

  // Fetch initial dashboard metrics on load
  useEffect(() => {
    async function loadAdminData() {
      const metrics = await apiService.getDashboardMetrics();
      if (metrics && metrics.activeOrders) {
        setOrders(metrics.activeOrders);
      }
    }
    loadAdminData();
  }, []);

  const handleToggleShopStatus = async (newStatus) => {
    setShopStatus(newStatus);
    await apiService.updateShopAvailability(newStatus);
  };

  const handleOpenAcceptModal = (order) => {
    setTargetOrderForAccept(order);
    setIsAcceptModalOpen(true);
  };

  const handleConfirmAcceptOrder = async (orderId, estimatedTime) => {
    await apiService.acceptOrder(orderId, estimatedTime);
    setOrders((prev) =>
      prev.map((ord) =>
        ord.id === orderId
          ? { ...ord, statusTag: 'IN PROGRESS', estimatedCompletionTime: estimatedTime }
          : ord
      )
    );
  };

  const handleConfirmDispatch = async (orderId) => {
    await apiService.handoverOrder(orderId);
    setOrders((prev) =>
      prev.map((ord) =>
        ord.id === orderId
          ? { ...ord, statusTag: 'OUT FOR DELIVERY' }
          : ord
      )
    );
  };

  const handleSelectOrderDetails = (order) => {
    setSelectedOrder(order);
    setActiveTab(2); // Jump to Process History
  };

  return (
    <div className="desktop-admin-shell">
      {/* Desktop Sidebar Navigation */}
      <Sidebar
        activeTab={activeTab}
        onSelectTab={(tabId) => setActiveTab(tabId)}
      />

      {/* Main Content Area */}
      <div className="desktop-main-wrapper">
        <DesktopHeader
          shopStatus={shopStatus}
          onToggleShopStatus={handleToggleShopStatus}
          onOpenAvailabilityModal={() => setIsAvailabilityModalOpen(true)}
        />

        <div className="desktop-content-body">
          {activeTab === 0 && (
            <DashboardPage
              orders={orders}
              shopStatus={shopStatus}
              onToggleShopStatus={handleToggleShopStatus}
              onOpenAcceptModal={handleOpenAcceptModal}
              onSelectOrderDetails={handleSelectOrderDetails}
              onNavigateTab={(tabId) => setActiveTab(tabId)}
            />
          )}

          {activeTab === 1 && (
            <OrdersPage
              onOpenAcceptModal={handleOpenAcceptModal}
              onSelectOrderDetails={handleSelectOrderDetails}
            />
          )}

          {activeTab === 2 && (
            <ProcessHistoryPage
              selectedOrder={selectedOrder}
              onOpenHandoverModal={(ord) => {
                setSelectedOrder(ord);
                setIsHandoverModalOpen(true);
              }}
            />
          )}

          {activeTab === 3 && <InventoryPage />}

          {activeTab === 4 && (
            <ProfilePage
              onOpenAvailabilityModal={() => setIsAvailabilityModalOpen(true)}
            />
          )}
        </div>
      </div>

      {/* Interactive Desktop Modals */}
      <AcceptOrderModal
        isOpen={isAcceptModalOpen}
        order={targetOrderForAccept}
        onClose={() => setIsAcceptModalOpen(false)}
        onConfirmAccept={handleConfirmAcceptOrder}
      />

      <DeliveryHandoverModal
        isOpen={isHandoverModalOpen}
        order={selectedOrder}
        onClose={() => setIsHandoverModalOpen(false)}
        onConfirmDispatch={handleConfirmDispatch}
      />

      <ServiceAvailabilityModal
        isOpen={isAvailabilityModalOpen}
        shopStatus={shopStatus}
        onClose={() => setIsAvailabilityModalOpen(false)}
        onToggleShopStatus={handleToggleShopStatus}
      />
    </div>
  );
}
