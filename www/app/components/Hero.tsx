"use client";

import Logo from "./Logo/Logo";

interface HeroProps {
  padding: number;
  onIntroComplete?: () => void;
}

export default function Hero({ padding, onIntroComplete }: HeroProps) {
  return (
    <section
      className="w-[100vw] overflow-hidden bg-background"
      style={{ padding }}
    >
      <Logo showGrid padding={padding} onIntroComplete={onIntroComplete} />
    </section>
  );
}
