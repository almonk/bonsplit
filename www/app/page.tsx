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
  const videoRef = useRef<HTMLVideoElement>(null);

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

  const handleIntroComplete = useCallback(() => {
    videoRef.current?.play();
  }, []);

  return (
    <div className="bg-background">
      <Hero padding={padding} onIntroComplete={handleIntroComplete} />
      <div className="max-w-[1000px] mx-auto px-4">
        {/* Intro & Installation */}
        <section className="mt-4 lg:-mt-12 mb-8 max-w-[600px]">
          <div className="space-y-6">
            <p className="text-lg text-[#666] dark:text-[#999]">
              Bonsplit is a native macOS tab bar library with split pane support for SwiftUI. Smooth 120fps animations, drag-and-drop reordering, and keyboard navigation.
            </p>
            <div>
              <CodeBlock>{`.package(url: "https://github.com/almonk/bonsplit.git", from: "1.0.0")`}</CodeBlock>
            </div>
            <div className="flex items-center gap-3 text-sm text-[#666] dark:text-[#999]">
              <span>or</span>
              <a
                href="https://github.com/almonk/bonsplit"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-4 py-2 bg-[rgba(0,0,0,0.03)] dark:bg-[rgba(255,255,255,0.03)] hover:bg-[rgba(0,0,0,0.06)] dark:hover:bg-[rgba(255,255,255,0.06)] text-[#333] dark:text-[#eee] rounded-lg transition-colors"
              >
                <svg viewBox="0 0 24 24" className="w-5 h-5" fill="currentColor">
                  <path d="M12 2C6.477 2 2 6.477 2 12c0 4.42 2.865 8.17 6.839 9.49.5.092.682-.217.682-.482 0-.237-.009-.866-.014-1.7-2.782.604-3.369-1.34-3.369-1.34-.454-1.156-1.11-1.463-1.11-1.463-.908-.62.069-.608.069-.608 1.003.07 1.531 1.03 1.531 1.03.892 1.529 2.341 1.087 2.91.831.092-.646.35-1.086.636-1.336-2.22-.253-4.555-1.11-4.555-4.943 0-1.091.39-1.984 1.029-2.683-.103-.253-.446-1.27.098-2.647 0 0 .84-.269 2.75 1.025A9.578 9.578 0 0112 6.836c.85.004 1.705.114 2.504.336 1.909-1.294 2.747-1.025 2.747-1.025.546 1.377.203 2.394.1 2.647.64.699 1.028 1.592 1.028 2.683 0 3.842-2.339 4.687-4.566 4.935.359.309.678.919.678 1.852 0 1.336-.012 2.415-.012 2.743 0 .267.18.578.688.48C19.138 20.167 22 16.418 22 12c0-5.523-4.477-10-10-10z" />
                </svg>
                View on GitHub
              </a>
            </div>
          </div>
        </section>
        {/* Demo video */}
        <div className="mb-12">
          <video
            ref={videoRef}
            src="/demo.mov"
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
