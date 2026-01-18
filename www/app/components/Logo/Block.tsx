"use client";

import type { Corner } from "./characters";

interface BlockProps {
  rounded: Corner[];
  size: number;
  isGhost?: boolean;
}

function getCornerRadius(rounded: Corner[], size: number): string {
  // All 4 corners = circle (50% radius)
  // Single corner = 100% radius (full quarter circle)
  // 2-3 corners = 50% radius
  const isCircle = rounded.length === 4 &&
    rounded.includes("tl") &&
    rounded.includes("tr") &&
    rounded.includes("bl") &&
    rounded.includes("br");

  if (isCircle) {
    return "50%";
  }

  const radius = rounded.length === 1 ? size : size / 2;
  const tl = rounded.includes("tl") ? `${radius}px` : "0";
  const tr = rounded.includes("tr") ? `${radius}px` : "0";
  const br = rounded.includes("br") ? `${radius}px` : "0";
  const bl = rounded.includes("bl") ? `${radius}px` : "0";
  return `${tl} ${tr} ${br} ${bl}`;
}

const GHOST_COLOR = "rgba(100, 100, 100, 0.3)"; // Same color as grid lines
const ACTIVE_COLOR = "#0066FF"; // Primary blue

export default function Block({
  rounded,
  size,
  isGhost = false,
}: BlockProps) {
  const borderRadius = getCornerRadius(rounded, size);

  return (
    <div
      style={{
        width: size,
        height: size,
        borderRadius,
        backgroundColor: isGhost ? GHOST_COLOR : ACTIVE_COLOR,
      }}
    />
  );
}
