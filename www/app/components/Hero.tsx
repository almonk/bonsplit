"use client";

import Logo from "./Logo/Logo";

interface HeroProps {
  padding: number;
  onIntroComplete?: () => void;
  onIntroStart?: () => void;
}

export default function Hero({ padding, onIntroComplete, onIntroStart }: HeroProps) {
  return (
    <section
      className="w-[100vw] overflow-hidden bg-background select-none"
      style={{ padding }}
    >
      <Logo showGrid padding={padding} onIntroComplete={onIntroComplete} onIntroStart={onIntroStart} />
    </section>
  );
}
