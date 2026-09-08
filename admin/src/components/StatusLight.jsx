import React from 'react';
import {
  STATUS_LIGHT,
  STATUS_LIGHT_DEFS,
  getOrderLight,
  getPaymentLight,
  getDeliveryLight,
  getMillLight,
  getUserLight,
  getMillLoadLight,
  getInventoryLight,
  getBatteryLight,
  resolveStatusLight,
  getLightDef
} from '../utils/statusLightHelpers';

export {
  STATUS_LIGHT,
  STATUS_LIGHT_DEFS,
  getOrderLight,
  getPaymentLight,
  getDeliveryLight,
  getMillLight,
  getUserLight,
  getMillLoadLight,
  getInventoryLight,
  getBatteryLight,
  resolveStatusLight,
  getLightDef
};

export default function StatusLight({
  light = STATUS_LIGHT.GREY,
  size = 10,
  showGlow = true,
  showPulse = true,
  style = {},
  tooltip,
  onClick
}) {
  const def = getLightDef(light);
  const pulse = showPulse && def.pulse;

  return (
    <span
      title={tooltip || def.label}
      onClick={onClick}
      style={{
        display: 'inline-block',
        width: size,
        height: size,
        borderRadius: '50%',
        backgroundColor: def.color,
        boxShadow: showGlow ? `0 0 ${Math.round(size * 0.6)}px ${def.glow}` : 'none',
        position: 'relative',
        flexShrink: 0,
        cursor: onClick ? 'pointer' : 'default',
        ...style
      }}
    >
      {pulse && (
        <span
          style={{
            position: 'absolute',
            inset: -3,
            borderRadius: '50%',
            border: `2px solid ${def.color}`,
            opacity: 0.5,
            animation: 'status-light-pulse 1.6s cubic-bezier(0.4, 0, 0.6, 1) infinite'
          }}
        />
      )}
    </span>
  );
}

export function StatusBadge({
  status,
  type = 'order',
  light,
  label,
  size = 'md',
  showLight = true,
  lightSize,
  style = {},
  pillStyle = {},
  onClick
}) {
  const resolvedLight = light || resolveStatusLight(status, type);
  const def = getLightDef(resolvedLight);
  const displayLabel = label || status || def.label;
  const fontSize = size === 'sm' ? '0.7rem' : size === 'lg' ? '0.9rem' : '0.78rem';
  const padding = size === 'sm' ? '3px 10px' : size === 'lg' ? '6px 16px' : '4px 12px';
  const resolvedLightSize = lightSize || (size === 'sm' ? 7 : size === 'lg' ? 11 : 8);

  return (
    <span
      onClick={onClick}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 6,
        padding,
        borderRadius: 999,
        backgroundColor: def.bg,
        color: def.text,
        border: `1px solid ${def.border}`,
        fontWeight: 800,
        fontSize,
        letterSpacing: 0.2,
        cursor: onClick ? 'pointer' : 'default',
        userSelect: 'none',
        ...pillStyle
      }}
    >
      {showLight && (
        <StatusLight light={resolvedLight} size={resolvedLightSize} style={{}} />
      )}
      <span style={{ ...style }}>{displayLabel}</span>
    </span>
  );
}
