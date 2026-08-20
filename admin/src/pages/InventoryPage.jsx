import React, { useState } from 'react';
import { ShoppingBag, Store, Truck, Wheat } from 'lucide-react';
import { inventoryItems } from '../data/mockData';

export default function InventoryPage() {
  const [subTab, setSubTab] = useState(0); // 0: Flour Inventory, 1: Raw Grain Vendor Hub
  const [items, setItems] = useState(inventoryItems);
  const [selectedCategory, setSelectedCategory] = useState(0);

  const toggleStock = (id) => {
    setItems((prev) =>
      prev.map((item) => (item.id === id ? { ...item, inStock: !item.inStock } : item))
    );
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
                    <h3 className="serif-heading" style={{ fontSize: '1.35rem', fontWeight: 800 }}>
                      {item.name}
                    </h3>
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
    </div>
  );
}
