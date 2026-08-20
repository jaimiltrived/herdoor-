import React from 'react';
import { Truck, Wheat, CheckCircle2, ShieldCheck, Box, HelpCircle, Handshake } from 'lucide-react';

export default function ProcessHistoryPage({ selectedOrder, onOpenHandoverModal }) {
  const order = selectedOrder || {
    id: '#HD-8829',
    customerName: 'Mrs. Eleanor Rigby',
    itemsSummary: '10kg Whole Wheat Flour',
    statusTag: 'Ready for Pickup',
    binLocation: 'Bin A-4',
    timelineSteps: [
      { title: 'Order Received', timeText: '09:00 AM', icon: CheckCircle2, isCompleted: true },
      { title: 'Security Check Passed', timeText: '09:15 AM', detailsNote: 'Grain box QR verified. Container integrity confirmed.', icon: ShieldCheck, isCompleted: true },
      { title: 'Milling Commenced', timeText: '09:30 AM', detailsNote: '⚙️ Premium Whole Wheat. Fine grind setting.', icon: Wheat, isCompleted: true },
      { title: 'Milling Complete', timeText: '10:45 AM', detailsNote: '10kg processed. Quality inspected.', icon: CheckCircle2, isCompleted: true },
      { title: 'Packing & Sealing', timeText: '11:00 AM', detailsNote: 'Eco-friendly bag sealed and labeled.', icon: Box, isCompleted: true },
      { title: 'Ready for Pickup', timeText: '11:05 AM', detailsNote: 'Stored in Bin A-4. Delivery partner notified.', icon: Truck, isCompleted: true, isHighlighted: true },
    ]
  };

  return (
    <div className="process-history-page">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
        <h1 className="serif-heading" style={{ fontSize: '1.6rem', fontWeight: 800 }}>
          Process History
        </h1>
        <button className="icon-btn" title="Help"><HelpCircle size={22} /></button>
      </div>

      {/* Customer Summary Card */}
      <div className="card" style={{ padding: 20 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <div style={{ fontSize: '0.7rem', fontWeight: 800, color: 'var(--text-secondary)', letterSpacing: 0.8 }}>
              CUSTOMER
            </div>
            <div className="serif-heading" style={{ fontSize: '1.4rem', fontWeight: 800, marginTop: 4 }}>
              {order.customerName}
            </div>
          </div>
          <span style={{ backgroundColor: '#FFB3AC', color: 'var(--primary-terracotta)', fontSize: '0.75rem', fontWeight: 800, padding: '5px 12px', borderRadius: 16, display: 'inline-flex', alignItems: 'center', gap: 5 }}>
            <Truck size={14} />
            <span>{order.statusTag}</span>
          </span>
        </div>

        <hr style={{ border: 'none', borderTop: '1px solid var(--border-light)', margin: '14px 0' }} />

        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{ width: 44, height: 44, borderRadius: 12, backgroundColor: '#F3ECE1', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--olive-green)' }}>
            <Wheat size={24} />
          </div>
          <div>
            <div style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>Item</div>
            <div style={{ fontWeight: 800, fontSize: '1rem' }}>{order.itemsSummary}</div>
          </div>
        </div>
      </div>

      {/* Vertical Step Timeline */}
      <div className="card" style={{ padding: 20 }}>
        <div className="timeline-container">
          {order.timelineSteps.map((step, idx) => {
            const StepIcon = step.icon || CheckCircle2;
            const isLast = idx === order.timelineSteps.length - 1;

            return (
              <div key={idx} className="timeline-step">
                <div className="timeline-line-col">
                  <div className={`timeline-circle ${step.isHighlighted ? 'highlighted' : (step.isCompleted ? 'completed' : '')}`}>
                    <StepIcon size={20} />
                  </div>
                  {!isLast && <div className="timeline-line"></div>}
                </div>

                <div className="timeline-content">
                  <div className="timeline-header">
                    <span className="timeline-title">{step.title}</span>
                    <span className="timeline-time">{step.timeText}</span>
                  </div>

                  {step.detailsNote && (
                    <div className={`note-box ${step.isHighlighted ? 'highlighted' : ''}`}>
                      {step.detailsNote}
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        <button
          className="btn-primary"
          style={{ width: '100%', marginTop: 10, padding: 14, borderRadius: 14 }}
          onClick={() => onOpenHandoverModal(order)}
        >
          <Handshake size={18} />
          <span>Handover to Delivery Person</span>
        </button>
      </div>
    </div>
  );
}
