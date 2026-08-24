import React, { useState } from 'react';
import { ShoppingBag, Store, Truck, Wheat, Plus, Pencil, Trash2, X, Check } from 'lucide-react';
import { inventoryItems } from '../data/mockData';

export default function InventoryPage() {
  const [subTab, setSubTab] = useState(0); // 0: Flour Inventory, 1: Raw Grain Vendor Hub
  const [items, setItems] = useState(inventoryItems);
  const [selectedCategory, setSelectedCategory] = useState(0);

  // Modals
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState(null);

  const [form, setForm] = useState({
    name: '',
    description: '',
    grind: 'Fine',
    weightOptions: '2kg',
    price: '',
    inStock: true,
  });

  const toggleStock = (id) => {
    setItems((prev) =>
      prev.map((item) => (item.id === id ? { ...item, inStock: !item.inStock } : item))
    );
  };

  const handleOpenAdd = () => {
    setForm({ name: '', description: '', grind: 'Fine', weightOptions: '2kg', price: '8.00', inStock: true });
    setIsAddModalOpen(true);
  };

  const handleOpenEdit = (item) => {
    setEditingItem(item);
    setForm({
      name: item.name,
      description: item.description,
      grind: item.grind,
      weightOptions: item.weightOptions,
      price: String(item.price),
      inStock: item.inStock,
    });
    setIsEditModalOpen(true);
  };

  const handleSaveNew = (e) => {
    e.preventDefault();
    const newItem = {
      id: `inv-${Date.now()}`,
      name: form.name,
      description: form.description,
      grind: form.grind,
      weightOptions: form.weightOptions,
      price: Number(form.price) || 0,
      inStock: form.inStock,
      imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
    };
    setItems([newItem, ...items]);
    setIsAddModalOpen(false);
  };

  const handleSaveEdit = (e) => {
    e.preventDefault();
    if (!editingItem) return;
    setItems(items.map(it => it.id === editingItem.id ? {
      ...it,
      name: form.name,
      description: form.description,
      grind: form.grind,
      weightOptions: form.weightOptions,
      price: Number(form.price) || 0,
      inStock: form.inStock,
    } : it));
    setIsEditModalOpen(false);
    setEditingItem(null);
  };

  const handleDelete = (id) => {
    if (window.confirm('Delete flour product from catalog?')) {
      setItems(items.filter(it => it.id !== id));
    }
  };

  return (
    <div className="inventory-page">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24 }}>
        <div>
          <h1 className="serif-heading" style={{ fontSize: '1.75rem', fontWeight: 800 }}>
            Inventory & Flour Supplies
          </h1>
          <p style={{ fontSize: '0.9rem', color: 'var(--text-secondary)', marginTop: 4 }}>
            Manage store flour stock availability & raw grain vendor procurement orders.
          </p>
        </div>
        <button
          className="btn-primary btn-with-icon"
          style={{ backgroundColor: '#8C4A3E' }}
          onClick={handleOpenAdd}
        >
          <Plus size={16} />
          <span>Add New Product</span>
        </button>
      </div>

      {/* Main Sub-Tabs Switcher */}
      <div className="filter-tabs-container" style={{ marginBottom: 24 }}>
        <button
          className={`filter-tab ${subTab === 0 ? 'active' : ''}`}
          onClick={() => setSubTab(0)}
        >
          <ShoppingBag size={16} />
          <span>FLOUR PRODUCTS CATALOG</span>
        </button>
        <button
          className={`filter-tab ${subTab === 1 ? 'active' : ''}`}
          onClick={() => setSubTab(1)}
        >
          <Store size={16} />
          <span>RAW GRAIN VENDOR HUB</span>
        </button>
      </div>

      {subTab === 0 ? (
        <>
          {/* Category Chips */}
          <div style={{ display: 'flex', gap: 10, marginBottom: 24 }}>
            {['All-Purpose', 'Whole Wheat', 'Rye'].map((label, idx) => (
              <button
                key={label}
                onClick={() => setSelectedCategory(idx)}
                style={{
                  padding: '8px 20px',
                  borderRadius: 24,
                  border: '1.5px solid ' + (selectedCategory === idx ? 'var(--primary-terracotta)' : 'var(--border-light)'),
                  backgroundColor: selectedCategory === idx ? 'var(--primary-terracotta)' : 'white',
                  color: selectedCategory === idx ? 'white' : 'var(--text-primary)',
                  fontWeight: 700,
                  fontSize: '0.85rem',
                  cursor: 'pointer',
                  boxShadow: 'var(--shadow-sm)',
                  transition: 'all 0.2s',
                }}
              >
                {label}
              </button>
            ))}
          </div>

          {/* Product Items Desktop Grid (3 Columns) */}
          <div className="grid-cards-3" style={{ marginBottom: 28 }}>
            {items.map((item) => (
              <div key={item.id} className="card" style={{ padding: 0, overflow: 'hidden', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
                <div>
                  <div style={{ position: 'relative' }}>
                    <img
                      src={item.imageUrl}
                      alt={item.name}
                      style={{ width: '100%', height: 200, objectFit: 'cover' }}
                    />
                    <span
                      style={{
                        position: 'absolute',
                        top: 14, right: 14,
                        backgroundColor: 'rgba(255,255,255,0.95)',
                        fontSize: '0.75rem',
                        fontWeight: 800,
                        padding: '4px 12px',
                        borderRadius: 14,
                        color: item.inStock ? '#2ECC71' : '#D63031',
                        boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
                      }}
                    >
                      {item.inStock ? 'In Stock' : 'Out of Stock'}
                    </span>
                  </div>

                  <div style={{ padding: 20 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                      <h3 className="serif-heading" style={{ fontSize: '1.35rem', fontWeight: 800 }}>
                        {item.name}
                      </h3>
                      {/* Action Buttons: Edit & Delete */}
                      <div style={{ display: 'flex', gap: '6px' }}>
                        <button
                          className="icon-btn"
                          style={{ padding: '6px', background: '#F7F2EB', borderRadius: '8px' }}
                          title="Edit Product"
                          onClick={() => handleOpenEdit(item)}
                        >
                          <Pencil size={14} color="#756D69" />
                        </button>
                        <button
                          className="icon-btn"
                          style={{ padding: '6px', background: '#FDEDEC', borderRadius: '8px' }}
                          title="Delete Product"
                          onClick={() => handleDelete(item.id)}
                        >
                          <Trash2 size={14} color="#C0392B" />
                        </button>
                      </div>
                    </div>

                    <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', margin: '6px 0 16px 0', height: 40, overflow: 'hidden' }}>
                      {item.description}
                    </p>

                    <div style={{ backgroundColor: 'var(--surface-cream)', padding: 12, borderRadius: 14, display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
                      <div>
                        <div style={{ fontSize: '0.7rem', color: 'var(--text-secondary)' }}>Grind Spec</div>
                        <div style={{ fontWeight: 800, fontSize: '0.85rem' }}>{item.grind}</div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{ fontSize: '0.7rem', color: 'var(--text-secondary)' }}>Weight Options</div>
                        <div style={{ fontWeight: 800, fontSize: '0.85rem' }}>{item.weightOptions}</div>
                      </div>
                    </div>
                  </div>
                </div>

                <div style={{ padding: '0 20px 20px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderTop: '1px solid var(--border-light)', paddingTop: 16 }}>
                  <span className="serif-heading" style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--primary-terracotta)' }}>
                    ${item.price.toFixed(2)}
                  </span>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Stock Toggle</span>
                    <label className="switch">
                      <input
                        type="checkbox"
                        checked={item.inStock}
                        onChange={() => toggleStock(item.id)}
                      />
                      <span className="slider"></span>
                    </label>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Delivery Banner */}
          <div style={{ backgroundColor: 'var(--soft-pink)', padding: 20, borderRadius: 20, display: 'flex', gap: 16, alignItems: 'center', border: '1px solid var(--soft-pink-border)' }}>
            <div style={{ width: 48, height: 48, borderRadius: '50%', backgroundColor: '#FFC0BD', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--primary-terracotta)' }}>
              <Truck size={24} />
            </div>
            <div>
              <div style={{ fontWeight: 800, fontSize: '1rem' }}>Standard & Express Delivery Active</div>
              <div style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', marginTop: 2 }}>
                Store products automatically reflect in customer catalog with live delivery calculations.
              </div>
            </div>
          </div>
        </>
      ) : (
        /* Raw Grain Vendor Hub Teaser View */
        <div className="card" style={{ padding: 28, background: 'linear-gradient(135deg, #6E5616, #4A3A0E)', color: 'white' }}>
          <span style={{ backgroundColor: '#F1C40F', color: '#2A2421', fontSize: '0.75rem', fontWeight: 800, padding: '4px 12px', borderRadius: 12 }}>
            RAW GRAIN VENDOR HUB
          </span>
          <h2 className="serif-heading" style={{ fontSize: '1.6rem', fontWeight: 800, marginTop: 12 }}>
            Direct Agricultural Vendor Procurement
          </h2>
          <p style={{ fontSize: '0.9rem', color: 'rgba(255,255,255,0.85)', margin: '8px 0 20px 0' }}>
            Buy raw Sharbati wheat, barley & rye directly from verified regional agricultural farmers & mill vendors.
          </p>

          <div style={{ backgroundColor: 'white', color: 'var(--text-primary)', padding: 18, borderRadius: 16, display: 'flex', alignItems: 'center', gap: 16, marginBottom: 14 }}>
            <Wheat size={28} color="var(--mustard-dark)" />
            <div style={{ flexGrow: 1 }}>
              <div style={{ fontWeight: 800, fontSize: '1rem' }}>Premium Sharbati Wheat</div>
              <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>SunRipe Organic Farms • $1.80/kg • Min order 500kg</div>
            </div>
            <button className="btn-primary" style={{ padding: '8px 18px', fontSize: '0.85rem', backgroundColor: 'var(--mustard-dark)' }}>
              Pre-Order Bulk Grain
            </button>
          </div>
        </div>
      )}

      {/* Add Modal */}
      {isAddModalOpen && (
        <div className="modal-overlay">
          <div className="modal-dialog">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2 className="serif-heading" style={{ fontSize: '1.4rem', fontWeight: 800 }}>
                Add New Product
              </h2>
              <button className="icon-btn" onClick={() => setIsAddModalOpen(false)}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveNew}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '24px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Product Name
                  </label>
                  <input
                    type="text" required
                    value={form.name}
                    onChange={(e) => setForm({ ...form, name: e.target.value })}
                    placeholder="e.g. Organic Barley Flour"
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Description
                  </label>
                  <input
                    type="text" required
                    value={form.description}
                    onChange={(e) => setForm({ ...form, description: e.target.value })}
                    placeholder="Short description..."
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Grind Spec
                    </label>
                    <select
                      value={form.grind}
                      onChange={(e) => setForm({ ...form, grind: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    >
                      <option value="Fine">Fine</option>
                      <option value="Medium">Medium</option>
                      <option value="Coarse">Coarse</option>
                    </select>
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Price ($)
                    </label>
                    <input
                      type="number" step="0.5" required
                      value={form.price}
                      onChange={(e) => setForm({ ...form, price: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    />
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" className="btn-outline" onClick={() => setIsAddModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn-primary" style={{ backgroundColor: '#8C4A3E' }}>
                  <Check size={16} /> Save Product
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Modal */}
      {isEditModalOpen && (
        <div className="modal-overlay">
          <div className="modal-dialog">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2 className="serif-heading" style={{ fontSize: '1.4rem', fontWeight: 800 }}>
                Edit Product
              </h2>
              <button className="icon-btn" onClick={() => setIsEditModalOpen(false)}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSaveEdit}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', marginBottom: '24px' }}>
                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Product Name
                  </label>
                  <input
                    type="text" required
                    value={form.name}
                    onChange={(e) => setForm({ ...form, name: e.target.value })}
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                  />
                </div>

                <div>
                  <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                    Description
                  </label>
                  <input
                    type="text" required
                    value={form.description}
                    onChange={(e) => setForm({ ...form, description: e.target.value })}
                    style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Grind Spec
                    </label>
                    <select
                      value={form.grind}
                      onChange={(e) => setForm({ ...form, grind: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    >
                      <option value="Fine">Fine</option>
                      <option value="Medium">Medium</option>
                      <option value="Coarse">Coarse</option>
                    </select>
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-secondary)', marginBottom: '4px' }}>
                      Price ($)
                    </label>
                    <input
                      type="number" step="0.5" required
                      value={form.price}
                      onChange={(e) => setForm({ ...form, price: e.target.value })}
                      style={{ width: '100%', padding: '10px 14px', borderRadius: '12px', border: '1px solid var(--border-light)', outline: 'none' }}
                    />
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" className="btn-outline" onClick={() => setIsEditModalOpen(false)}>Cancel</button>
                <button type="submit" className="btn-primary" style={{ backgroundColor: '#8C4A3E' }}>
                  <Check size={16} /> Update Product
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
