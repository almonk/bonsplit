"use client";

import { useState, useEffect } from "react";
import Hero from "./components/Hero";
import ContentSections from "./components/ContentSections";

const MIN_PADDING = 8;
const MAX_PADDING = 180;
const PADDING_RATIO = 0.08;

export default function Home() {
  const [padding, setPadding] = useState(MAX_PADDING);

  useEffect(() => {
    const calculatePadding = () => {
      const viewportWidth = window.innerWidth;
      const idealPadding = Math.floor(viewportWidth * PADDING_RATIO);
      const clampedPadding = Math.max(MIN_PADDING, Math.min(MAX_PADDING, idealPadding));
      setPadding(clampedPadding);
    };

    requestAnimationFrame(() => {
      calculatePadding();
    });

    window.addEventListener("resize", calculatePadding);
    return () => window.removeEventListener("resize", calculatePadding);
  }, []);

  return (
    <div className="bg-background">
      <Hero padding={padding} />
      {/* Content section below the logo */}
      <div style={{ paddingLeft: padding + 1, paddingRight: padding + 2, marginTop: -7 }}>
        <div className="relative z-[1001] w-full">
          <ContentSections />
        </div>
      </div>
    </div>
  );
}
