"use client";

import Logo from "./Logo/Logo";

interface HeroProps {
  padding: number;
}

export default function Hero({ padding }: HeroProps) {
  return (
    <section
      className="w-[100vw] overflow-hidden bg-background"
      style={{ padding }}
    >
      <Logo showGrid padding={padding} />
    </section>
  );
}
