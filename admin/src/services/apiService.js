import { initialOrders, pendingRequests, inventoryItems } from '../data/mockData';

const BASE_URL = 'http://localhost:5000/api/v1';

// Helper to make API requests with fallback to local mock data
async function apiRequest(endpoint, method = 'GET', body = null) {
  try {
    const token = localStorage.getItem('herdoor_merchant_token');
    const headers = {
      'Content-Type': 'application/json',
    };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const config = {
      method,
      headers,
    };
    if (body) {
      config.body = JSON.stringify(body);
    }

    const response = await fetch(`${BASE_URL}${endpoint}`, config);
    if (response.ok) {
      return await response.json();
    }
  } catch (error) {
    console.warn(`[API] Server unavailable at ${endpoint}. Using responsive fallback dataset.`, error);
  }
  return null;
}

export const apiService = {
  // Fetch Dashboard Metrics & Active Orders
  async getDashboardMetrics() {
    const data = await apiRequest('/shopkeeper/dashboard');
    if (data && data.success) {
      return data.data;
    }
    return {
      revenueToday: 482.50,
      totalOrders: 24,
      pendingOrdersCount: 8,
      newOrdersCount: 12,
      activeOrders: initialOrders,
    };
  },

  // Fetch Pending Order Requests
  async getPendingOrders() {
    const data = await apiRequest('/shopkeeper/orders/pending');
    if (data && data.success) {
      return data.data;
    }
    return pendingRequests;
  },

  // Accept Order and Set Estimated Completion Time
  async acceptOrder(orderId, completionTimeText) {
    const data = await apiRequest(`/shopkeeper/orders/${encodeURIComponent(orderId)}/accept`, 'POST', {
      estimatedCompletionTime: completionTimeText,
    });
    if (data && data.success) {
      return data;
    }
    return { success: true, message: `Order ${orderId} accepted for ${completionTimeText}` };
  },

  // Reject / Decline Order
  async rejectOrder(orderId, reason = 'Store busy') {
    const data = await apiRequest(`/shopkeeper/orders/${encodeURIComponent(orderId)}/reject`, 'POST', {
      reason,
    });
    if (data && data.success) {
      return data;
    }
    return { success: true, message: `Order ${orderId} rejected.` };
  },

  // Delivery Handover & QR PIN Dispatch
  async handoverOrder(orderId, verificationPin = '4821') {
    const data = await apiRequest(`/shopkeeper/orders/${encodeURIComponent(orderId)}/handover`, 'POST', {
      pin: verificationPin,
    });
    if (data && data.success) {
      return data;
    }
    return { success: true, message: `Order ${orderId} handed over for dispatch.` };
  },

  // Fetch Flour & Grain Inventory
  async getInventory() {
    const data = await apiRequest('/shopkeeper/inventory');
    if (data && data.success) {
      return data.data;
    }
    return inventoryItems;
  },

  // Update Inventory Item Stock
  async updateInventoryStock(itemId, inStock) {
    const data = await apiRequest(`/shopkeeper/inventory/${itemId}`, 'PUT', { inStock });
    if (data && data.success) {
      return data;
    }
    return { success: true, itemId, inStock };
  },

  // Update Store Availability & Radius
  async updateShopAvailability(isOpen, radiusKm = 5.0) {
    const data = await apiRequest('/shopkeeper/availability', 'PUT', { isOpen, radiusKm });
    if (data && data.success) {
      return data;
    }
    return { success: true, isOpen, radiusKm };
  },
};
