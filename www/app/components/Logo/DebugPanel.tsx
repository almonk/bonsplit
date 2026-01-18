"use client";

import { useState } from "react";

export interface AnimationSettings {
  stiffness: number;
  damping: number;
  rowDelay: number;
  initialDelay: number;
}

interface DebugPanelProps {
  settings: AnimationSettings;
  onChange: (settings: AnimationSettings) => void;
  onReplay: () => void;
}

export default function DebugPanel({ settings, onChange, onReplay }: DebugPanelProps) {
  const [isCollapsed, setIsCollapsed] = useState(false);

  const handleChange = (key: keyof AnimationSettings, value: number) => {
    onChange({ ...settings, [key]: value });
  };

  if (isCollapsed) {
    return (
      <button
        onClick={() => setIsCollapsed(false)}
        style={{
          position: "fixed",
          bottom: 20,
          right: 20,
          zIndex: 10000,
          padding: "8px 12px",
          backgroundColor: "#228B22",
          color: "white",
          border: "none",
          borderRadius: 6,
          cursor: "pointer",
          fontSize: 12,
          fontFamily: "monospace",
        }}
      >
        Debug
      </button>
    );
  }

  return (
    <div
      style={{
        position: "fixed",
        bottom: 20,
        right: 20,
        zIndex: 10000,
        backgroundColor: "rgba(0, 0, 0, 0.9)",
        color: "white",
        padding: 16,
        borderRadius: 8,
        fontFamily: "monospace",
        fontSize: 12,
        minWidth: 250,
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
        <span style={{ fontWeight: "bold" }}>Animation Debug</span>
        <button
          onClick={() => setIsCollapsed(true)}
          style={{
            background: "none",
            border: "none",
            color: "white",
            cursor: "pointer",
            fontSize: 16,
          }}
        >
          ×
        </button>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
        <div>
          <label style={{ display: "block", marginBottom: 4 }}>
            Stiffness: {settings.stiffness}
          </label>
          <input
            type="range"
            min="50"
            max="500"
            value={settings.stiffness}
            onChange={(e) => handleChange("stiffness", Number(e.target.value))}
            style={{ width: "100%" }}
          />
        </div>

        <div>
          <label style={{ display: "block", marginBottom: 4 }}>
            Damping: {settings.damping}
          </label>
          <input
            type="range"
            min="5"
            max="50"
            value={settings.damping}
            onChange={(e) => handleChange("damping", Number(e.target.value))}
            style={{ width: "100%" }}
          />
        </div>

        <div>
          <label style={{ display: "block", marginBottom: 4 }}>
            Row Delay: {settings.rowDelay}ms
          </label>
          <input
            type="range"
            min="50"
            max="1000"
            value={settings.rowDelay}
            onChange={(e) => handleChange("rowDelay", Number(e.target.value))}
            style={{ width: "100%" }}
          />
        </div>

        <div>
          <label style={{ display: "block", marginBottom: 4 }}>
            Initial Delay: {settings.initialDelay}ms
          </label>
          <input
            type="range"
            min="0"
            max="1000"
            value={settings.initialDelay}
            onChange={(e) => handleChange("initialDelay", Number(e.target.value))}
            style={{ width: "100%" }}
          />
        </div>

        <button
          onClick={onReplay}
          style={{
            marginTop: 8,
            padding: "8px 12px",
            backgroundColor: "#228B22",
            color: "white",
            border: "none",
            borderRadius: 6,
            cursor: "pointer",
            fontWeight: "bold",
          }}
        >
          Replay Intro
        </button>
      </div>
    </div>
  );
}
