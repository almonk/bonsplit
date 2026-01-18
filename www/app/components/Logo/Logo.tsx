"use client";

import { useRef, useState, useEffect, useCallback } from "react";
import { LayoutGroup, motion } from "framer-motion";
import Character from "./Character";
import { characters } from "./characters";

interface LogoProps {
  word?: string;
  gap?: number;
  letterGap?: number;
  showGrid?: boolean;
  padding?: number;
  onIntroComplete?: () => void;
}

export default function Logo({
  word = "BonSplit",
  gap = 2,
  letterGap = 2,
  showGrid = false,
  padding = 180,
  onIntroComplete,
}: LogoProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [blockSize, setBlockSize] = useState<number | null>(null);
  const [expansions, setExpansions] = useState<Record<number, { rows: number; columns: number }>>({});
  const [clickCount, setClickCount] = useState(0);
  const [introComplete, setIntroComplete] = useState(false);
  const [visibleRows, setVisibleRows] = useState(0); // Start with no rows visible
  const [hiddenColumnsMap, setHiddenColumnsMap] = useState<Record<number, number[]>>({ 0: [1], 6: [0] }); // B's middle column and i hidden initially
  const [isResizing, setIsResizing] = useState(false);
  const [isInitializing, setIsInitializing] = useState(true);
  const [waveColumn, setWaveColumn] = useState<number | null>(null);
  const [isHovering, setIsHovering] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const [isDarkMode, setIsDarkMode] = useState(false);
  const animationSettings = {
    stiffness: 416,
    damping: 21,
    rowDelay: 300,
    initialDelay: 500,
  };
  const resizeTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const initTimeoutRef = useRef<NodeJS.Timeout | null>(null);
  const introTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Split into two lines on mobile
  const lines = isMobile ? ["Bon", "Split"] : [word];
  const letters = word.split("");

  // Calculate total columns
  const totalColumns = letters.reduce((acc, letter) => {
    const charData = characters[letter];
    return acc + (charData?.width || 0);
  }, 0);

  // Column delays (no intro animation delays)
  const columnDelays = new Array(totalColumns).fill(0);

  // Track previous resize state to detect when resize ends
  const prevIsResizing = useRef(false);
  const hasPlayedIntro = useRef(false);

  // Trigger shine animation
  const triggerShine = useCallback(() => {
    let waveInterval: NodeJS.Timeout | null = null;
    let currentCol = totalColumns - 1;

    waveInterval = setInterval(() => {
      if (currentCol >= 0) {
        setWaveColumn(currentCol);
        currentCol--;
      } else {
        setWaveColumn(null);
        if (waveInterval) clearInterval(waveInterval);
      }
    }, 30);

    return () => {
      if (waveInterval) clearInterval(waveInterval);
    };
  }, [totalColumns]);

  // Replay intro animation
  const replayIntro = useCallback(() => {
    // Clear any existing timeouts
    if (introTimeoutRef.current) {
      clearTimeout(introTimeoutRef.current);
    }

    // Reset state
    setVisibleRows(0);
    setIntroComplete(false);
    setExpansions({});
    setClickCount(0);
    setHiddenColumnsMap({ 0: [1], 6: [0] }); // Reset B's middle column and i to hidden

    const maxRows = 4;
    let currentRow = 0;

    const revealNextRow = () => {
      if (currentRow < maxRows) {
        currentRow++;
        setVisibleRows(currentRow);
        introTimeoutRef.current = setTimeout(revealNextRow, animationSettings.rowDelay);
      } else {
        // All rows revealed - now reveal B's middle column
        introTimeoutRef.current = setTimeout(() => {
          setHiddenColumnsMap({ 6: [0] }); // Reveal B's middle column, keep i hidden
          // Reveal i 300ms later
          setTimeout(() => {
            setHiddenColumnsMap({}); // Reveal i
            // Then trigger shine and complete intro
            setTimeout(() => {
              triggerShine();
              setTimeout(() => {
                setIntroComplete(true);
                onIntroComplete?.();
              }, totalColumns * 30 + 100);
            }, 300);
          }, 300);
        }, 150);
      }
    };

    introTimeoutRef.current = setTimeout(revealNextRow, animationSettings.initialDelay);
  }, [animationSettings.rowDelay, animationSettings.initialDelay, triggerShine, totalColumns, onIntroComplete]);

  // Intro animation - reveal rows one at a time, then B's middle column
  useEffect(() => {
    if (isInitializing || hasPlayedIntro.current) return;

    hasPlayedIntro.current = true;

    const maxRows = 4; // Total rows in the logo
    let currentRow = 0; // Start with no rows visible

    const revealNextRow = () => {
      if (currentRow < maxRows) {
        currentRow++;
        setVisibleRows(currentRow);
        introTimeoutRef.current = setTimeout(revealNextRow, animationSettings.rowDelay);
      } else {
        // All rows revealed - now reveal B's middle column
        introTimeoutRef.current = setTimeout(() => {
          setHiddenColumnsMap({ 6: [0] }); // Reveal B's middle column, keep i hidden
          // Reveal i 300ms later
          setTimeout(() => {
            setHiddenColumnsMap({}); // Reveal i
            // Then trigger shine and complete intro
            setTimeout(() => {
              triggerShine();
              setTimeout(() => {
                setIntroComplete(true);
                onIntroComplete?.();
              }, totalColumns * 30 + 100); // Wait for shine to complete
            }, 300);
          }, 300);
        }, 150);
      }
    };

    // Start intro animation after a short delay
    introTimeoutRef.current = setTimeout(revealNextRow, animationSettings.initialDelay);

    return () => {
      if (introTimeoutRef.current) {
        clearTimeout(introTimeoutRef.current);
      }
    };
  }, [isInitializing, triggerShine, totalColumns, animationSettings.rowDelay, animationSettings.initialDelay, onIntroComplete]);

  // Shine effect after resize ends
  useEffect(() => {
    if (blockSize === null || !introComplete) return;

    const shouldTriggerShine = prevIsResizing.current && !isResizing;
    prevIsResizing.current = isResizing;

    if (!shouldTriggerShine) return;

    const startTimeout = setTimeout(() => {
      triggerShine();
    }, 100);

    return () => {
      clearTimeout(startTimeout);
    };
  }, [blockSize, isResizing, introComplete, triggerShine]);

  const handleLogoClick = useCallback(() => {
    if (!introComplete) return;

    const isColumnExpansion = clickCount === 1; // Only second click adds a column, rest are rows
    const middleLetterIndex = Math.floor((letters.length - 1) / 2); // Middle letter for column expansion

    setExpansions((prev) => {
      const newExpansions: Record<number, { rows: number; columns: number }> = {};
      letters.forEach((letter, index) => {
        if (characters[letter]) {
          const current = prev[index] || { rows: 0, columns: 0 };
          if (isColumnExpansion) {
            // Column expansion: only affect the middle letter
            if (index === middleLetterIndex) {
              newExpansions[index] = { ...current, columns: current.columns + 1 };
            } else {
              newExpansions[index] = current;
            }
          } else {
            // Row expansion: affect all letters
            newExpansions[index] = { ...current, rows: current.rows + 1 };
          }
        }
      });
      return newExpansions;
    });

    setClickCount((prev) => prev + 1);
  }, [introComplete, letters, clickCount]);

  // Handle line click for mobile - only expand letters in that line
  const handleLineClick = useCallback((lineIndex: number) => {
    if (!introComplete) return;

    const isColumnExpansion = clickCount === 1; // Only second click adds a column, rest are rows
    const globalIndexOffset = lines.slice(0, lineIndex).join("").length;
    const lineLetters = lines[lineIndex].split("");
    const middleLetterIndex = Math.floor((letters.length - 1) / 2); // Middle letter of whole word

    setExpansions((prev) => {
      const newExpansions: Record<number, { rows: number; columns: number }> = { ...prev };
      lineLetters.forEach((letter, index) => {
        if (characters[letter]) {
          const globalIndex = globalIndexOffset + index;
          const current = prev[globalIndex] || { rows: 0, columns: 0 };
          if (isColumnExpansion) {
            // Column expansion: only affect the middle letter of the whole word
            if (globalIndex === middleLetterIndex) {
              newExpansions[globalIndex] = { ...current, columns: current.columns + 1 };
            } else {
              newExpansions[globalIndex] = current;
            }
          } else {
            // Row expansion: affect all letters in this line
            newExpansions[globalIndex] = { ...current, rows: current.rows + 1 };
          }
        }
      });
      return newExpansions;
    });

    setClickCount((prev) => prev + 1);
  }, [introComplete, lines, letters, clickCount]);

  // Calculate cumulative column offsets for staggered animation
  let cumulativeOffset = 0;
  const characterOffsets: number[] = [];
  letters.forEach((letter) => {
    const charData = characters[letter];
    if (charData) {
      characterOffsets.push(cumulativeOffset);
      cumulativeOffset += charData.width;
    } else {
      characterOffsets.push(cumulativeOffset);
    }
  });

  // Calculate total number of blocks and gaps (use widest line for mobile)
  const calculateLineMetrics = (line: string) => {
    const lineLetters = line.split("");
    return lineLetters.reduce(
      (acc, letter) => {
        const charData = characters[letter];
        if (!charData) return acc;
        return {
          totalBlocks: acc.totalBlocks + charData.width,
          totalInternalGaps: acc.totalInternalGaps + (charData.width - 1),
          letterCount: acc.letterCount + 1,
        };
      },
      { totalBlocks: 0, totalInternalGaps: 0, letterCount: 0 }
    );
  };

  // Find the widest line's metrics
  const lineMetrics = lines.map(calculateLineMetrics);
  const widestLine = lineMetrics.reduce((max, curr) =>
    curr.totalBlocks > max.totalBlocks ? curr : max
  );

  const totalBlocks = widestLine.totalBlocks;
  const totalInternalGaps = widestLine.totalInternalGaps;
  const letterGapsCount = widestLine.letterCount - 1;

  useEffect(() => {
    const updateBlockSize = () => {
      if (containerRef.current && totalBlocks > 0) {
        const containerWidth = containerRef.current.offsetWidth;
        // Total width = (totalBlocks * blockSize) + (totalInternalGaps * gap) + (letterGapsCount * letterGap)
        // Solve for blockSize:
        const gapSpace = totalInternalGaps * gap + letterGapsCount * letterGap;
        const availableForBlocks = containerWidth - gapSpace;
        setBlockSize(Math.floor(availableForBlocks / totalBlocks));
      }
    };

    const handleResize = () => {
      setIsResizing(true);
      updateBlockSize();
      setIsMobile(window.innerWidth < 890);

      // Clear any existing timeout
      if (resizeTimeoutRef.current) {
        clearTimeout(resizeTimeoutRef.current);
      }

      // Set resizing to false after resize ends
      resizeTimeoutRef.current = setTimeout(() => {
        setIsResizing(false);
      }, 150);
    };

    // Use ResizeObserver for reliable initial measurement
    const resizeObserver = new ResizeObserver(() => {
      updateBlockSize();
    });

    if (containerRef.current) {
      resizeObserver.observe(containerRef.current);
    }

    // Also recalculate after a frame to ensure layout is complete
    requestAnimationFrame(() => {
      updateBlockSize();
      setIsMobile(window.innerWidth < 890);
      // Mark initialization complete after layout stabilizes
      initTimeoutRef.current = setTimeout(() => {
        setIsInitializing(false);
      }, 100);
    });

    window.addEventListener("resize", handleResize);
    return () => {
      window.removeEventListener("resize", handleResize);
      resizeObserver.disconnect();
      if (resizeTimeoutRef.current) {
        clearTimeout(resizeTimeoutRef.current);
      }
      if (initTimeoutRef.current) {
        clearTimeout(initTimeoutRef.current);
      }
    };
  }, [totalBlocks, totalInternalGaps, letterGapsCount, gap, letterGap]);

  // Dark mode detection
  useEffect(() => {
    const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
    setIsDarkMode(mediaQuery.matches);

    const handleChange = (e: MediaQueryListEvent) => {
      setIsDarkMode(e.matches);
    };

    mediaQuery.addEventListener("change", handleChange);
    return () => mediaQuery.removeEventListener("change", handleChange);
  }, []);

  // Grid cell size includes the block and gap
  const cellSize = blockSize !== null ? blockSize + gap : 0;


  return (
    <div ref={containerRef} className="w-full">
      {/* Overlay to hide initial layout flash */}
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
          opacity: isInitializing ? 1 : 0,
          transition: "opacity 0.3s ease-out",
        }}
      />
      {showGrid && blockSize !== null && (
        <div
          style={{
            position: "absolute",
            top: 0,
            left: 0,
            width: "100vw",
            height: 7 * cellSize + padding,
            pointerEvents: "none",
            zIndex: 1000,
            backgroundImage: `
              linear-gradient(to right, ${isDarkMode ? "rgba(255, 255, 255, 0.12)" : "rgba(200, 200, 200, 0.5)"} 1px, transparent 1px),
              linear-gradient(to bottom, ${isDarkMode ? "rgba(255, 255, 255, 0.12)" : "rgba(200, 200, 200, 0.5)"} 1px, transparent 1px)
            `,
            backgroundSize: `${cellSize}px ${cellSize}px`,
            backgroundPosition: `${padding - gap + 1}px ${padding - gap + 1}px`,
            maskImage: "linear-gradient(to bottom, black 0%, black 60%, transparent 100%)",
            WebkitMaskImage: "linear-gradient(to bottom, black 0%, black 60%, transparent 100%)",
          }}
        />
      )}
      {blockSize !== null && (
        <LayoutGroup>
          <div
            style={{ position: "relative" }}
            onMouseEnter={() => setIsHovering(true)}
            onMouseLeave={() => setIsHovering(false)}
          >
            {/* Highlight line on hover - alternates between horizontal (row mode) and vertical (column mode) */}
            {!isMobile && (
              <>
                {/* Horizontal line for row expansion mode (even clicks) */}
                <div
                  style={{
                    position: "absolute",
                    left: -padding + gap - 1,
                    top: 2 * cellSize - gap, // Middle row (row 2) for 4-row letters
                    width: "100vw",
                    height: 1,
                    backgroundColor: "#0066FF",
                    opacity: isHovering && clickCount % 2 === 0 ? 0.5 : 0,
                    pointerEvents: "none",
                    zIndex: 1001,
                    transition: "opacity 0.2s ease-in-out",
                  }}
                />
                {/* Vertical line for column expansion mode (odd clicks) - positioned at middle of S */}
                {(() => {
                  const middleLetterIndex = Math.floor((letters.length - 1) / 2);
                  const middleLetter = letters[middleLetterIndex];
                  const middleLetterData = characters[middleLetter];
                  const columnsBeforeMiddleLetter = characterOffsets[middleLetterIndex] || 0;
                  const middleColumnWithinLetter = middleLetterData ? Math.floor(middleLetterData.width / 2) : 0;
                  // Account for flex gap being between items only (last column of each letter has no gap after it)
                  const internalGapsBeforeMiddleLetter = columnsBeforeMiddleLetter - middleLetterIndex;
                  const verticalLineLeft = (columnsBeforeMiddleLetter * blockSize) + (internalGapsBeforeMiddleLetter * gap) + (middleLetterIndex * letterGap) + (middleColumnWithinLetter * cellSize) - gap;

                  return (
                    <div
                      style={{
                        position: "absolute",
                        left: verticalLineLeft,
                        top: -padding + gap - 1,
                        width: 1,
                        height: "100vh",
                        backgroundColor: "#0066FF",
                        opacity: isHovering && clickCount % 2 === 1 ? 0.5 : 0,
                        pointerEvents: "none",
                        zIndex: 1001,
                        transition: "opacity 0.2s ease-in-out",
                      }}
                    />
                  );
                })()}
              </>
            )}
            {/* Ghost layer - shows full logo shape before intro completes */}
            {!introComplete && (
              <div style={{ position: "absolute", top: 0, left: 0, pointerEvents: "none" }}>
                {lines.map((line, lineIndex) => {
                  const lineLetters = line.split("");
                  let lineColumnOffset = 0;
                  const lineCharacterOffsets: number[] = [];
                  lineLetters.forEach((letter) => {
                    const charData = characters[letter];
                    if (charData) {
                      lineCharacterOffsets.push(lineColumnOffset);
                      lineColumnOffset += charData.width;
                    } else {
                      lineCharacterOffsets.push(lineColumnOffset);
                    }
                  });

                  return (
                    <div
                      key={`ghost-${lineIndex}`}
                      className="flex items-start"
                      style={{ marginTop: lineIndex > 0 ? gap : 0 }}
                    >
                      {lineLetters.map((letter, letterIndex) => {
                        const charData = characters[letter];
                        if (!charData) return null;
                        const globalIndexOffset = lines.slice(0, lineIndex).join("").length;
                        const globalLetterIndex = globalIndexOffset + letterIndex;
                        const hiddenCols = hiddenColumnsMap[globalLetterIndex] || [];
                        const isLetterFullyHidden = charData.width > 0 && hiddenCols.length >= charData.width;
                        const isFirst = letterIndex === 0;
                        const targetMargin = isFirst ? 0 : (isLetterFullyHidden ? 0 : letterGap);
                        return (
                          <motion.div
                            key={letterIndex}
                            animate={{ marginLeft: targetMargin }}
                            transition={isResizing || isInitializing ? { duration: 0 } : { type: "tween", duration: 0.35, ease: [0.4, 0, 0.2, 1] }}
                          >
                            <Character
                              character={charData}
                              blockSize={blockSize}
                              gap={gap}
                              columnOffset={lineCharacterOffsets[letterIndex]}
                              columnDelays={columnDelays}
                              extraRows={0}
                              extraColumns={0}
                              lastExpansionWasRow={true}
                              onClick={() => {}}
                              interactive={false}
                              isResizing={isResizing || isInitializing}
                              isGhost
                              hiddenColumns={hiddenCols}
                            />
                          </motion.div>
                        );
                      })}
                    </div>
                  );
                })}
              </div>
            )}

            {/* Animated layer */}
            {lines.map((line, lineIndex) => {
              const lineLetters = line.split("");
              // Calculate the global letter index offset for this line
              const globalIndexOffset = lines.slice(0, lineIndex).join("").length;

              // Calculate column offsets for this line
              let lineColumnOffset = 0;
              const lineCharacterOffsets: number[] = [];
              lineLetters.forEach((letter) => {
                const charData = characters[letter];
                if (charData) {
                  lineCharacterOffsets.push(lineColumnOffset);
                  lineColumnOffset += charData.width;
                } else {
                  lineCharacterOffsets.push(lineColumnOffset);
                }
              });

              return (
                <div
                  key={lineIndex}
                  className="flex items-start"
                  style={{ marginTop: lineIndex > 0 ? gap : 0 }}
                >
                  {lineLetters.map((letter, letterIndex) => {
                    const charData = characters[letter];
                    if (!charData) {
                      return null;
                    }
                    const globalLetterIndex = globalIndexOffset + letterIndex;
                    const hiddenCols = hiddenColumnsMap[globalLetterIndex] || [];
                    const isLetterFullyHidden = charData.width > 0 && hiddenCols.length >= charData.width;
                    const isFirst = letterIndex === 0;
                    const targetMargin = isFirst ? 0 : (isLetterFullyHidden ? 0 : letterGap);

                    return (
                      <motion.div
                        key={letterIndex}
                        animate={{ marginLeft: targetMargin }}
                        transition={isResizing || isInitializing ? { duration: 0 } : { type: "tween", duration: 0.35, ease: [0.4, 0, 0.2, 1] }}
                      >
                        <Character
                          character={charData}
                          blockSize={blockSize}
                          gap={gap}
                          columnOffset={lineCharacterOffsets[letterIndex]}
                          columnDelays={columnDelays}
                          extraRows={expansions[globalLetterIndex]?.rows || 0}
                          extraColumns={expansions[globalLetterIndex]?.columns || 0}
                          lastExpansionWasRow={clickCount !== 2}
                          onClick={isMobile ? () => handleLineClick(lineIndex) : handleLogoClick}
                          interactive={introComplete}
                          isResizing={isResizing || isInitializing}
                          waveColumn={waveColumn}
                          visibleRows={isMobile ? visibleRows : (lineIndex === 0 ? visibleRows : 4)}
                          hiddenColumns={hiddenCols}
                          animationSettings={animationSettings}
                        />
                      </motion.div>
                    );
                  })}
                </div>
              );
            })}
          </div>
        </LayoutGroup>
      )}
    </div>
  );
}
