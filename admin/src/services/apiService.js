import { initialOrders, pendingRequests, inventoryItems } from '../data/mockData';

const BASE_URL = 'http://localhost:5000/api/v1';

// Auto-authenticate as Super Admin if token not present
async function ensureAdminAuth() {
  let token = localStorage.getItem('herdoor_admin_token');
  if (token) return token;

  try {
    const res = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'admin@herdoor.com',
        password: 'Password123!',
      }),
    });
    if (res.ok) {
      const data = await res.json();
      token = data?.data?.token;
      if (token) {
        localStorage.setItem('herdoor_admin_token', token);
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
    let token = await ensureAdminAuth();
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

    let response = await fetch(`${BASE_URL}${endpoint}`, config);
    if (response.status === 401 || response.status === 403) {
      localStorage.removeItem('herdoor_admin_token');
      token = await ensureAdminAuth();
      if (token) {
        config.headers['Authorization'] = `Bearer ${token}`;
        response = await fetch(`${BASE_URL}${endpoint}`, config);
      }
    }
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
    const data = await apiRequest('/admin/dashboard');
    if (data && (data.status === 'success' || data.success)) {
      return data.data;
    }
    return {
      revenueToday: 690.0,
      totalOrders: 10,
      pendingOrdersCount: 2,
      newOrdersCount: 2,
      activeOrders: initialOrders,
    };
  },

  // Flour Mills Management (CRUD)
  async getMills() {
    const data = await apiRequest('/admin/mills');
    if (data && (data.status === 'success' || data.success)) {
      return data.data?.mills || [];
    }
    return [];
  },

  async createMill(millData) {
    const data = await apiRequest('/admin/mills', 'POST', millData);
    return data;
  },

  async updateMill(id, millData) {
    const data = await apiRequest(`/admin/mills/${id}`, 'PUT', millData);
    return data;
  },

  async deleteMill(id) {
    const data = await apiRequest(`/admin/mills/${id}`, 'DELETE');
    return data;
  },

  // Merchant Applications & Onboarding
  async getMerchantApplications(status = 'ALL') {
    const query = status && status !== 'ALL' ? `?status=${encodeURIComponent(status)}` : '';
    const data = await apiRequest(`/admin/merchant-applications${query}`);
    if (data && (data.status === 'success' || data.success)) {
      return data.data || { applications: [], metrics: {} };
    }
    return { applications: [], metrics: {} };
  },

  async approveMerchantApplication(id, payload = {}) {
    const body = typeof payload === 'string' ? { adminNotes: payload } : payload;
    const data = await apiRequest(`/admin/merchant-applications/${id}/approve`, 'PUT', body);
    return data;
  },

  async rejectMerchantApplication(id, reason) {
    const data = await apiRequest(`/admin/merchant-applications/${id}/reject`, 'PUT', { reason });
    return data;
  },

  // Orders Ledger
  async getOrders(params = {}) {
    const query = new URLSearchParams(params).toString();
    const data = await apiRequest(`/admin/orders${query ? `?${query}` : ''}`);
    if (data && (data.status === 'success' || data.success)) {
      return data.data?.orders || [];
    }
    return [];
  },

  async updateOrderStatus(id, status) {
    const data = await apiRequest(`/admin/orders/${id}/status`, 'PUT', { status });
    return data;
  },

  // Delivery Fleet & Riders
  async getRiders() {
    const data = await apiRequest('/admin/riders');
    if (data && (data.status === 'success' || data.success)) {
      return data.data?.riders || [];
    }
    return [];
  },

  async updateRiderStatus(id, isOnline) {
    const data = await apiRequest(`/admin/riders/${id}/status`, 'PUT', { isOnline });
    return data;
  },

  // Wholesalers & Grains
  async getWholesalers() {
    const data = await apiRequest('/admin/wholesalers');
    if (data && (data.status === 'success' || data.success)) {
      return data.data?.wholesalers || [];
    }
    return [];
  },

  async createWholesaler(wholesalerData) {
    const data = await apiRequest('/admin/wholesalers', 'POST', wholesalerData);
    return data;
  },

  // Citizens / Customers
  async getCitizens() {
    const data = await apiRequest('/admin/citizens');
    if (data && (data.status === 'success' || data.success)) {
      return data.data?.citizens || [];
    }
    return [];
  },

  async createCitizen(citizenData) {
    const data = await apiRequest('/admin/citizens', 'POST', citizenData);
    return data;
  },

  async updateCitizen(id, citizenData) {
    const data = await apiRequest(`/admin/citizens/${id}`, 'PUT', citizenData);
    return data;
  },

  async deleteCitizen(id) {
    const data = await apiRequest(`/admin/citizens/${id}`, 'DELETE');
    return data;
  },

  // Security, Audits, Analytics
  async getSecurityAudits() {
    const data = await apiRequest('/admin/security');
    return data?.data?.logs || [];
  },

  async getFraudAlerts() {
    const data = await apiRequest('/admin/fraud');
    return data?.data?.alerts || [];
  },

  async getAnalytics() {
    const data = await apiRequest('/admin/analytics');
    return data?.data || null;
  },

  async getWithdrawals() {
    const data = await apiRequest('/admin/withdrawals');
    return data?.data?.withdrawals || [];
  },

  async getRefunds() {
    const data = await apiRequest('/admin/refunds');
    return data?.data?.refunds || [];
  },

  // Pending Order Requests
  async getPendingOrders() {
    const data = await apiRequest('/shopkeeper/orders/pending');
    if (data && (data.status === 'success' || data.success)) {
      return data.data?.orders || data.data || [];
    }
    return pendingRequests;
  },

  // Accept Order
  async acceptOrder(orderId, completionTimeText) {
    const numericId = String(orderId).replace(/\D/g, '') || '501';
    const data = await apiRequest(`/shopkeeper/orders/${encodeURIComponent(numericId)}/accept`, 'POST', {
      estimatedCompletionMinutes: 30,
      estimatedCompletionTime: completionTimeText,
    });
    return data;
  },

  // Reject / Decline Order
  async rejectOrder(orderId, reason = 'Store busy') {
    const numericId = String(orderId).replace(/\D/g, '') || '501';
    const data = await apiRequest(`/shopkeeper/orders/${encodeURIComponent(numericId)}/reject`, 'POST', {
      reason,
    });
    return data;
  },

  // Delivery Handover
  async handoverOrder(orderId, verificationPin = '4821') {
    const numericId = String(orderId).replace(/\D/g, '') || '501';
    const data = await apiRequest(`/shopkeeper/orders/${encodeURIComponent(numericId)}/handover`, 'POST', {
      pin: verificationPin,
    });
    return data;
  },

  // Inventory
  async getInventory() {
    const data = await apiRequest('/shopkeeper/inventory');
    if (data && (data.status === 'success' || data.success)) {
      return data.data?.inventory || data.data || [];
    }
    return inventoryItems;
  },

  async updateInventoryStock(itemId, inStock) {
    const data = await apiRequest(`/shopkeeper/inventory/${itemId}`, 'PUT', { inStock });
    return data;
  },

  async updateShopAvailability(isOpen, radiusKm = 5.0) {
    const data = await apiRequest('/shopkeeper/availability', 'PUT', { isOpen, radiusKm });
    return data;
  },

  async getAdminPlatformStats() {
    const data = await apiRequest('/admin/dashboard');
    if (data && (data.status === 'success' || data.success)) {
      return data.data;
    }
    return null;
  }
};
