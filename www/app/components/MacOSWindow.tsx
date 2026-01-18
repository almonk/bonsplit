"use client";

import { useState, useEffect, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";

interface Pane {
  id: string;
  children?: Pane[];
  orientation?: "horizontal" | "vertical";
  color: string;
}

const colors = [
  "#3b82f6", // blue-500
  "#60a5fa", // blue-400
  "#2563eb", // blue-600
  "#6366f1", // indigo-500
  "#0ea5e9", // sky-500
  "#06b6d4", // cyan-500
];

const springTransition = {
  type: "spring" as const,
  stiffness: 300,
  damping: 28,
};

const PaneView = ({ pane, depth = 0 }: { pane: Pane; depth?: number }) => {
  if (pane.children && pane.children.length > 0) {
    return (
      <motion.div
        layout
        transition={springTransition}
        className={`flex ${pane.orientation === "vertical" ? "flex-col" : "flex-row"} flex-1 gap-[2px]`}
      >
        <AnimatePresence mode="sync">
          {pane.children.map((child) => (
            <motion.div
              key={child.id}
              layout
              initial={{
                [pane.orientation === "vertical" ? "height" : "width"]: 0,
                opacity: 0
              }}
              animate={{
                [pane.orientation === "vertical" ? "height" : "width"]: "auto",
                opacity: 1,
                flex: 1
              }}
              exit={{
                [pane.orientation === "vertical" ? "height" : "width"]: 0,
                opacity: 0
              }}
              transition={springTransition}
              className="flex min-h-0 min-w-0"
              style={{ overflow: "hidden" }}
            >
              <PaneView pane={child} depth={depth + 1} />
            </motion.div>
          ))}
        </AnimatePresence>
      </motion.div>
    );
  }

  return (
    <motion.div
      layout
      transition={springTransition}
      className="flex-1 rounded-sm"
      style={{ backgroundColor: pane.color }}
    />
  );
};

export default function MacOSWindow() {
  const [rootPane, setRootPane] = useState<Pane>({
    id: "root",
    color: colors[0],
  });
  const [step, setStep] = useState(0);
  const [colorIndex, setColorIndex] = useState(1);

  const getNextColor = useCallback(() => {
    const color = colors[colorIndex % colors.length];
    setColorIndex((i) => i + 1);
    return color;
  }, [colorIndex]);

  const splitPane = useCallback((paneId: string, orientation: "horizontal" | "vertical") => {
    const newColor = getNextColor();

    setRootPane((root) => {
      const split = (pane: Pane): Pane => {
        if (pane.id === paneId && !pane.children) {
          return {
            id: pane.id,
            color: pane.color,
            orientation,
            children: [
              { id: `${pane.id}-a`, color: pane.color },
              { id: `${pane.id}-b`, color: newColor },
            ],
          };
        }
        if (pane.children) {
          return {
            ...pane,
            children: pane.children.map(split),
          };
        }
        return pane;
      };
      return split(root);
    });
  }, [getNextColor]);

  const resetDemo = useCallback(() => {
    setRootPane({ id: "root", color: colors[0] });
    setStep(0);
    setColorIndex(1);
  }, []);

  // Auto-animate sequence
  useEffect(() => {
    const sequence = [
      { delay: 1500, action: () => splitPane("root", "horizontal") },
      { delay: 2500, action: () => splitPane("root-b", "vertical") },
      { delay: 3500, action: () => splitPane("root-a", "vertical") },
      { delay: 4500, action: () => splitPane("root-b-a", "horizontal") },
      { delay: 6500, action: resetDemo },
    ];

    if (step < sequence.length) {
      const timer = setTimeout(() => {
        sequence[step].action();
        setStep((s) => s + 1);
      }, step === 0 ? sequence[0].delay : 1000);

      return () => clearTimeout(timer);
    }
  }, [step, splitPane, resetDemo]);

  return (
    <div className="w-full max-w-3xl mx-auto">
      {/* Window chrome */}
      <div className="rounded-xl overflow-hidden shadow-2xl border border-[#c8c8c8] dark:border-[#3a3a3a]">
        {/* Title bar */}
        <div className="flex items-center h-[38px] px-4 bg-gradient-to-b from-[#e8e8e8] to-[#d8d8d8] dark:from-[#3a3a3a] dark:to-[#2d2d2d] border-b border-[#b8b8b8] dark:border-[#2a2a2a]">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-[#ff5f57] border border-[#e0443e]" />
            <div className="w-3 h-3 rounded-full bg-[#febc2e] border border-[#dea123]" />
            <div className="w-3 h-3 rounded-full bg-[#28c840] border border-[#1aab29]" />
          </div>
          <div className="flex-1 text-center text-[11px] text-[#666] dark:text-[#999] font-medium">
            Bonsplit
          </div>
          <div className="w-[52px]" />
        </div>
        {/* Content area */}
        <div className="h-[300px] p-[2px] bg-[#e0e0e0] dark:bg-[#1a1a1a]">
          <PaneView pane={rootPane} />
        </div>
      </div>
    </div>
  );
}
