"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import Hero from "./components/Hero";
import ContentSections from "./components/ContentSections";
import CodeBlock from "./components/CodeBlock";

const MIN_PADDING = 8;
const MAX_PADDING = 180;
const PADDING_RATIO = 0.08;

export default function Home() {
  const [padding, setPadding] = useState(MAX_PADDING);
  const [showOverlay, setShowOverlay] = useState(true);
  const videoRef = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    const calculatePadding = () => {
      const viewportWidth = window.innerWidth;
      const idealPadding = Math.floor(viewportWidth * PADDING_RATIO);
      const clampedPadding = Math.max(
        MIN_PADDING,
        Math.min(MAX_PADDING, idealPadding),
      );
      setPadding(clampedPadding);
    };

    requestAnimationFrame(() => {
      calculatePadding();
    });

    window.addEventListener("resize", calculatePadding);
    return () => window.removeEventListener("resize", calculatePadding);
  }, []);

  // Remove hash from URL when scrolled to top
  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY === 0 && window.location.hash) {
        history.replaceState(null, "", window.location.pathname);
      }
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const handleIntroStart = useCallback(() => {
    setShowOverlay(false);
  }, []);

  const handleIntroComplete = useCallback(() => {
    videoRef.current?.play();
  }, []);

  return (
    <div className="bg-background">
      {/* Full-page overlay to hide initial layout flash */}
      <div
        style={{
          position: "fixed",
          top: 0,
          left: 0,
          width: "100vw",
          height: "100vh",
          backgroundColor: "var(--background)",
          pointerEvents: "none",
          zIndex: 9999,
          opacity: showOverlay ? 1 : 0,
          transition: "opacity 0.3s ease-out",
        }}
      />
      <Hero padding={padding} onIntroComplete={handleIntroComplete} onIntroStart={handleIntroStart} />
      <div className="max-w-[1000px] mx-auto px-4">
        {/* Intro & Installation */}
        <section id="installation" className="mt-4 lg:-mt-12 mb-8 max-w-[600px] scroll-mt-8">
          <div className="space-y-6">
            <p className="text-lg text-[#999]">
              Bonsplit is a custom tab bar and layout split library for macOS
              apps. Enjoy out of the box 120fps animations, drag-and-drop
              reordering, SwiftUI support &amp; keyboard navigation.
            </p>
            <div>
              <CodeBlock>{`.package(url: "https://github.com/almonk/bonsplit.git", from: "1.0.0")`}</CodeBlock>
            </div>
            <div className="flex items-center gap-3 text-sm">
              <a
                href="https://github.com/almonk/bonsplit"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-4 py-2 bg-[rgba(255,255,255,0.03)] hover:bg-[rgba(255,255,255,0.06)] text-[#eee] rounded-lg transition-colors"
              >
                <svg
                  viewBox="0 0 24 24"
                  className="w-5 h-5"
                  fill="currentColor"
                >
                  <path d="M12 2C6.477 2 2 6.477 2 12c0 4.42 2.865 8.17 6.839 9.49.5.092.682-.217.682-.482 0-.237-.009-.866-.014-1.7-2.782.604-3.369-1.34-3.369-1.34-.454-1.156-1.11-1.463-1.11-1.463-.908-.62.069-.608.069-.608 1.003.07 1.531 1.03 1.531 1.03.892 1.529 2.341 1.087 2.91.831.092-.646.35-1.086.636-1.336-2.22-.253-4.555-1.11-4.555-4.943 0-1.091.39-1.984 1.029-2.683-.103-.253-.446-1.27.098-2.647 0 0 .84-.269 2.75 1.025A9.578 9.578 0 0112 6.836c.85.004 1.705.114 2.504.336 1.909-1.294 2.747-1.025 2.747-1.025.546 1.377.203 2.394.1 2.647.64.699 1.028 1.592 1.028 2.683 0 3.842-2.339 4.687-4.566 4.935.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.743 0 .267.18.578.688.48C19.138 20.167 22 16.418 22 12c0-5.523-4.477-10-10-10z" />
                </svg>
                View on GitHub
              </a>
              <a
                href="https://alasdairmonk.com"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-4 py-2 bg-[rgba(255,255,255,0.03)] hover:bg-[rgba(255,255,255,0.06)] text-[#eee] rounded-lg transition-colors"
              >
                <svg
                  viewBox="0 0 330 330"
                  className="w-5 h-5"
                  fill="currentColor"
                >
                  <path d="M255.9678,275.7774 L216.8818,167.8704 L232.0048,135.2544 L277.3398,254.0264 C273.9128,258.3414 270.2478,262.4624 266.3558,266.3574 C263.0478,269.6634 259.5798,272.8054 255.9678,275.7774 L255.9678,275.7774 Z M90.9308,288.0804 L123.1818,196.8364 L153.3858,263.5484 C155.0818,267.2994 158.7878,269.6994 162.9038,269.7184 L162.9478,269.7184 C167.0468,269.7194 170.7528,267.3554 172.4778,263.6354 L204.3408,194.9164 L238.1628,288.2924 C216.6758,301.0954 191.5858,308.4504 164.7268,308.4534 C137.7198,308.4504 112.4978,301.0154 90.9308,288.0804 L90.9308,288.0804 Z M51.3438,253.0534 L95.3398,135.3404 L110.6738,169.2104 L73.1148,275.4714 C69.6368,272.5904 66.2918,269.5494 63.0978,266.3574 C58.9118,262.1704 54.9888,257.7244 51.3438,253.0534 L51.3438,253.0534 Z M136.6298,158.7884 L163.6088,82.4604 L191.2548,158.7884 L136.6298,158.7884 Z M188.2088,179.7874 L163.0648,234.0124 L138.5148,179.7874 L188.2088,179.7874 Z M63.0978,63.0974 C89.1398,37.0704 125.0038,21.0064 164.7268,21.0024 C204.4478,21.0064 240.3128,37.0704 266.3558,63.0974 C292.3798,89.1384 308.4468,125.0024 308.4508,164.7244 C308.4478,189.2114 302.3348,212.2264 291.5558,232.3834 L242.7558,104.5244 C241.2518,100.5874 237.5228,97.9204 233.3098,97.7754 C229.0988,97.6274 225.1908,100.0274 223.4208,103.8524 L206.7308,139.8454 L173.3608,47.7194 C171.8478,43.5444 167.8868,40.7774 163.4478,40.7954 C159.0078,40.8124 155.0668,43.6094 153.5888,47.7954 L120.7808,140.6164 L103.9768,103.5004 C102.2268,99.6324 98.3018,97.1944 94.0578,97.3394 C89.8148,97.4804 86.0638,100.1794 84.5768,104.1554 L37.1658,231.0014 C26.8418,211.1764 21.0038,188.6524 20.9998,164.7244 C21.0068,125.0044 37.0708,89.1384 63.0978,63.0974 L63.0978,63.0974 Z M164.7268,0.0004 C73.7468,0.0084 0.0068,73.7474 -0.0002,164.7244 C0.0068,255.7084 73.7468,329.4464 164.7268,329.4554 C255.7058,329.4484 329.4448,255.7084 329.4498,164.7244 C329.4448,73.7474 255.7058,0.0064 164.7268,0.0004 L164.7268,0.0004 Z" />
                </svg>
                Made by @almonk
              </a>
            </div>
          </div>
        </section>
        {/* Demo video */}
        <div className="mb-12">
          <video
            ref={videoRef}
            src="/demo-compressed.mov"
            loop
            muted
            playsInline
            className="w-full rounded-lg shadow-lg"
          />
        </div>
        {/* Content section */}
        <div className="relative z-[1001] w-full">
          <ContentSections />
        </div>
      </div>
    </div>
  );
}
