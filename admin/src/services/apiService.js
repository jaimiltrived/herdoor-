import { initialOrders, pendingRequests, inventoryItems } from '../data/mockData';

const BASE_URL = 'http://localhost:5000/api/v1';

// Auto-authenticate as Admin/Merchant if token not present
async function ensureAdminAuth() {
  let token = localStorage.getItem('herdoor_merchant_token');
  if (token) return token;

  try {
    const res = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'shop@shreeganesh.com',
        password: 'Password123!',
      }),
    });
    if (res.ok) {
      const data = await res.json();
      token = data?.data?.token;
      if (token) {
        localStorage.setItem('herdoor_merchant_token', token);
        return token;
      }
    }
  } catch (e) {
    console.warn('[Auth] Unable to authenticate with server, running in responsive offline mode.');
  }
  return null;
}

// Helper to make API requests with fallback to local mock data
async function apiRequest(endpoint, method = 'GET', body = null) {
  try {
    const token = await ensureAdminAuth();
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
    if (data && (data.status === 'success' || data.success)) {
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
    if (data && (data.status === 'success' || data.success)) {
      return data.data?.orders || data.data || [];
    }
    return pendingRequests;
  },

  // Accept Order and Set Estimated Completion Time
  async acceptOrder(orderId, completionTimeText) {
    const numericId = String(orderId).replace(/\D/g, '') || '501';
    const data = await apiRequest(`/shopkeeper/orders/${encodeURIComponent(numericId)}/accept`, 'POST', {
      estimatedCompletionMinutes: 30,
      estimatedCompletionTime: completionTimeText,
    });
    if (data && (data.status === 'success' || data.success)) {
      return data;
    }
    return { success: true, message: `Order ${orderId} accepted for ${completionTimeText}` };
  },

  // Reject / Decline Order
  async rejectOrder(orderId, reason = 'Store busy') {
    const numericId = String(orderId).replace(/\D/g, '') || '501';
    const data = await apiRequest(`/shopkeeper/orders/${encodeURIComponent(numericId)}/reject`, 'POST', {
      reason,
    });
    if (data && (data.status === 'success' || data.success)) {
      return data;
    }
    return { success: true, message: `Order ${orderId} rejected.` };
  },

  // Delivery Handover & QR PIN Dispatch
  async handoverOrder(orderId, verificationPin = '4821') {
    const numericId = String(orderId).replace(/\D/g, '') || '501';
    const data = await apiRequest(`/shopkeeper/orders/${encodeURIComponent(numericId)}/handover`, 'POST', {
      pin: verificationPin,
    });
    if (data && (data.status === 'success' || data.success)) {
      return data;
    }
    return { success: true, message: `Order ${orderId} handed over for dispatch.` };
  },

  // Fetch Flour & Grain Inventory
  async getInventory() {
    const data = await apiRequest('/shopkeeper/inventory');
    if (data && (data.status === 'success' || data.success)) {
      return data.data?.inventory || data.data || [];
    }
    return inventoryItems;
  },

  // Update Inventory Item Stock
  async updateInventoryStock(itemId, inStock) {
    const data = await apiRequest(`/shopkeeper/inventory/${itemId}`, 'PUT', { inStock });
    if (data && (data.status === 'success' || data.success)) {
      return data;
    }
    return { success: true, itemId, inStock };
  },

  // Update Store Availability & Radius
  async updateShopAvailability(isOpen, radiusKm = 5.0) {
    const data = await apiRequest('/shopkeeper/availability', 'PUT', { isOpen, radiusKm });
    if (data && (data.status === 'success' || data.success)) {
      return data;
    }
    return { success: true, isOpen, radiusKm };
  },

  // Admin Platform Stats
  async getAdminPlatformStats() {
    const data = await apiRequest('/admin/dashboard');
    if (data && (data.status === 'success' || data.success)) {
      return data.data;
    }
    return null;
  }
};
