"use client";

import { motion } from "framer-motion";
import Block from "./Block";
import type { Character as CharacterType, Block as BlockType } from "./characters";

const BASE_DELAY = 0.5;

interface CharacterProps {
  character: CharacterType;
  blockSize: number;
  gap: number;
  columnOffset: number;
  columnDelays: number[];
  extraRows: number;
  extraColumns: number;
  lastExpansionWasRow: boolean;
  onClick: () => void;
  interactive: boolean;
  isResizing: boolean;
  isGhost?: boolean;
  waveColumn?: number | null;
  visibleRows?: number;
  hiddenColumns?: number[];
  animationSettings?: {
    stiffness: number;
    damping: number;
  };
}

// Check if a block can extend into extra rows (no bottom corners)
const canExtendRow = (block: BlockType) =>
  !block.rounded.includes("bl") && !block.rounded.includes("br");

export default function Character({
  character,
  blockSize,
  gap,
  columnOffset,
  columnDelays,
  extraRows,
  extraColumns,
  lastExpansionWasRow,
  onClick,
  interactive,
  isResizing,
  isGhost = false,
  waveColumn = null,
  visibleRows = 4,
  hiddenColumns = [],
  animationSettings = { stiffness: 300, damping: 30 },
}: CharacterProps) {
  const { width, height, blocks } = character;

  // Clamp visible rows to character height
  const effectiveVisibleRows = Math.min(visibleRows, height);

  // Calculate middle indices for inserting extra rows/columns
  const middleRowIndex = Math.floor(height / 2);
  const middleColumnIndex = Math.floor(width / 2);

  // Total dimensions including extras
  const totalColumns = width + extraColumns;
  const layoutRows = height + extraRows;
  const totalHeight = layoutRows * blockSize + (layoutRows - 1) * gap;

  // Create a lookup map for original blocks by position
  const blockMap = new Map<string, BlockType>();
  blocks.forEach((block) => {
    blockMap.set(`${block.x},${block.y}`, block);
  });

  // Group blocks by their column (x position)
  const originalColumns: Map<number, BlockType[]> = new Map();
  for (let x = 0; x < width; x++) {
    originalColumns.set(x, blocks.filter((b) => b.x === x));
  }

  // Apple-like snappy cubic easing
  const blockTransition = {
    type: "tween" as const,
    duration: 0.35,
    ease: [0.4, 0, 0.2, 1] as const,
  };
  const instantTransition = { duration: 0 };

  // Ghost mode - render columns with animation for hidden columns
  if (isGhost) {
    const entries = Array.from(originalColumns.entries());
    return (
      <div className="flex">
        {entries.map(([colX, colBlocks], index) => {
          const isHidden = hiddenColumns.includes(colX);
          const isFirst = index === 0;
          return (
            <motion.div
              key={colX}
              layout
              initial={{ width: isHidden ? 0 : blockSize, marginLeft: isFirst ? 0 : (isHidden ? 0 : gap) }}
              animate={{ width: isHidden ? 0 : blockSize, marginLeft: isFirst ? 0 : (isHidden ? 0 : gap) }}
              transition={isResizing ? { duration: 0 } : blockTransition}
              style={{
                position: "relative",
                height: totalHeight,
                overflow: "hidden",
              }}
            >
              {colBlocks.map((block) => (
                <div
                  key={`${block.x}-${block.y}`}
                  style={{
                    position: "absolute",
                    top: block.y * (blockSize + gap),
                    width: blockSize,
                    height: blockSize,
                  }}
                >
                  <Block rounded={block.rounded} size={blockSize} isGhost />
                </div>
              ))}
            </motion.div>
          );
        })}
      </div>
    );
  }

  // Build column indices including extra columns inserted at middle
  // extraIndex is reversed so new columns appear on the LEFT (old ones shift right)
  const columnIndices: { originalX: number; isExtra: boolean; extraIndex?: number }[] = [];
  for (let x = 0; x < totalColumns; x++) {
    if (x < middleColumnIndex) {
      // Columns before the insertion point
      columnIndices.push({ originalX: x, isExtra: false });
    } else if (x < middleColumnIndex + extraColumns) {
      // Extra columns - reverse index so newest is at left (index 0 position)
      const extraIndex = extraColumns - 1 - (x - middleColumnIndex);
      columnIndices.push({ originalX: middleColumnIndex, isExtra: true, extraIndex });
    } else {
      // Columns after the insertion point (shifted right)
      columnIndices.push({ originalX: x - extraColumns, isExtra: false });
    }
  }

  return (
    <div
      className={interactive ? "transition-[filter] duration-200 hover:brightness-[1.15]" : ""}
      style={{
        position: "relative",
        cursor: interactive ? "pointer" : "default",
      }}
      onClick={interactive ? onClick : undefined}
    >
      {/* Animated layer - columns animate with FLIP */}
      <div className="flex">
        {columnIndices.map((colInfo, colIndex) => {
          const { originalX, isExtra, extraIndex } = colInfo;
          const globalColIndex = columnOffset + (isExtra ? middleColumnIndex : (colIndex >= middleColumnIndex + extraColumns ? colIndex - extraColumns : colIndex));

          // Get blocks from the reference column
          const colBlocks = originalColumns.get(originalX) || [];

          // Build rows for this column, including extra rows in the middle
          const rows: { rowIndex: number; block: BlockType | null; isExtraRow: boolean; isExtraColumn: boolean; hasBlock: boolean; isVisible: boolean; extraRowIndex?: number }[] = [];

          for (let y = 0; y < layoutRows; y++) {
            if (y < middleRowIndex) {
              // Original rows before middle
              const originalY = y;
              const block = colBlocks.find((b) => b.y === originalY) || null;
              const isVisible = originalY < effectiveVisibleRows;

              if (isExtra) {
                // Extra column: always add a block (full column)
                rows.push({ rowIndex: y, block: null, isExtraRow: false, isExtraColumn: true, hasBlock: true, isVisible });
              } else {
                rows.push({ rowIndex: y, block, isExtraRow: false, isExtraColumn: false, hasBlock: !!block, isVisible });
              }
            } else if (y < middleRowIndex + extraRows) {
              // Extra rows - reverse index so newest is at top (old ones shift down)
              const extraRowIndex = extraRows - 1 - (y - middleRowIndex);

              if (isExtra) {
                // Extra column AND extra row: always add a block
                rows.push({ rowIndex: y, block: null, isExtraRow: true, isExtraColumn: true, hasBlock: true, isVisible: true, extraRowIndex });
              } else {
                // Just extra row: check if the block at row above in this column can extend
                const blockAbove = blockMap.get(`${originalX},${middleRowIndex - 1}`);
                const canExtend = blockAbove && canExtendRow(blockAbove);
                rows.push({ rowIndex: y, block: null, isExtraRow: true, isExtraColumn: false, hasBlock: !!canExtend, isVisible: true, extraRowIndex });
              }
            } else {
              // Original rows after middle (shifted down by extraRows)
              const originalY = y - extraRows;
              const block = colBlocks.find((b) => b.y === originalY) || null;
              const isVisible = originalY < effectiveVisibleRows;

              if (isExtra) {
                // Extra column: always add a block (full column)
                rows.push({ rowIndex: y, block: null, isExtraRow: false, isExtraColumn: true, hasBlock: true, isVisible });
              } else {
                rows.push({ rowIndex: y, block, isExtraRow: false, isExtraColumn: false, hasBlock: !!block, isVisible });
              }
            }
          }

          const columnDelay = columnDelays[globalColIndex] || 0;
          const blockTransitionWithDelay = {
            ...blockTransition,
            delay: BASE_DELAY + columnDelay,
          };

          const isWaveHighlighted = waveColumn === globalColIndex;
          const isColumnHidden = !isExtra && hiddenColumns.includes(originalX);
          const isFirstColumn = colIndex === 0;
          const targetMargin = isFirstColumn ? 0 : (isColumnHidden ? 0 : gap);
          const initialMargin = isFirstColumn ? 0 : (isExtra || isColumnHidden ? 0 : gap);

          return (
            <motion.div
              key={isExtra ? `extra-col-${extraIndex}` : `col-${originalX}`}
              layout
              initial={isExtra || isColumnHidden ? { width: 0, marginLeft: initialMargin } : { width: blockSize, marginLeft: initialMargin }}
              animate={{ width: isColumnHidden ? 0 : blockSize, marginLeft: targetMargin }}
              transition={
                isResizing
                  ? { width: instantTransition, layout: instantTransition, marginLeft: instantTransition }
                  : {
                      width: blockTransition,
                      layout: blockTransition,
                      marginLeft: blockTransition,
                    }
              }
              style={{
                position: "relative",
                height: totalHeight,
                overflow: "hidden",
                filter: isWaveHighlighted ? "brightness(1.3)" : undefined,
              }}
            >
              {rows.map((row) => {
                const { rowIndex, block, isExtraRow, isExtraColumn, hasBlock, extraRowIndex } = row;

                if (!hasBlock) return null;

                // Determine if this is a NEW block (just added) vs existing
                // New row = at top of extra rows area (y === middleRowIndex)
                // New column = this is an extra column and we just added columns
                const isNewRow = isExtraRow && rowIndex === middleRowIndex;
                const isNewColumn = isExtraColumn && !lastExpansionWasRow;

                // For animation direction:
                // - Pure extra row (not column): top-down
                // - Pure extra column (not row): left-right
                // - Intersection: use direction based on which was JUST added
                const shouldAnimateTopDown = isExtraRow && !isExtraColumn;
                const shouldAnimateLeftRight = isExtraColumn && !isExtraRow;
                const isIntersection = isExtraRow && isExtraColumn;

                // Consistent key format for all extra blocks
                const blockKey = isExtraRow && isExtraColumn
                  ? `extra-intersection-${rowIndex}`
                  : isExtraColumn
                    ? `extra-col-${rowIndex}`
                    : `extra-row-${extraRowIndex}`;

                // Extra column blocks (not intersection) - animate left to right only when NEW
                if (shouldAnimateLeftRight) {
                  const { isVisible } = row;

                  return (
                    <motion.div
                      key={blockKey}
                      layout
                      initial={isNewColumn ? { width: 0 } : false}
                      animate={{ width: blockSize }}
                      transition={isResizing ? instantTransition : blockTransition}
                      style={{
                        position: "absolute",
                        top: rowIndex * (blockSize + gap),
                        height: blockSize,
                        overflow: "hidden",
                      }}
                    >
                      <motion.div
                        initial={isNewColumn ? { x: -(blockSize + gap), opacity: 0 } : false}
                        animate={{ x: 0, opacity: isVisible ? 1 : 0 }}
                        transition={isResizing ? instantTransition : blockTransition}
                        style={{
                          width: blockSize,
                          height: blockSize,
                          borderRadius: 0,
                          backgroundColor: "#0066FF",
                        }}
                      />
                    </motion.div>
                  );
                }

                // Extra row blocks (not intersection) - animate top to bottom only when NEW
                if (shouldAnimateTopDown) {
                  return (
                    <motion.div
                      key={blockKey}
                      layout
                      initial={isNewRow ? { height: 0 } : false}
                      animate={{ height: blockSize }}
                      transition={isResizing ? instantTransition : blockTransition}
                      style={{
                        position: "absolute",
                        top: rowIndex * (blockSize + gap),
                        width: blockSize,
                        overflow: "hidden",
                      }}
                    >
                      <motion.div
                        initial={isNewRow ? { y: -(blockSize + gap), opacity: 0 } : false}
                        animate={{ y: 0, opacity: 1 }}
                        transition={isResizing ? instantTransition : blockTransition}
                        style={{
                          width: blockSize,
                          height: blockSize,
                          borderRadius: 0,
                          backgroundColor: "#0066FF",
                        }}
                      />
                    </motion.div>
                  );
                }

                // Intersection blocks - animate based on what was just added
                if (isIntersection) {
                  const { isVisible } = row;
                  const animateLeftRight = isNewColumn || (!isNewRow && !lastExpansionWasRow);

                  if (animateLeftRight) {
                    return (
                      <motion.div
                        key={blockKey}
                        layout
                        initial={isNewColumn ? { width: 0 } : false}
                        animate={{ width: blockSize }}
                        transition={isResizing ? instantTransition : blockTransition}
                        style={{
                          position: "absolute",
                          top: rowIndex * (blockSize + gap),
                          height: blockSize,
                          overflow: "hidden",
                        }}
                      >
                        <motion.div
                          initial={isNewColumn ? { x: -(blockSize + gap), opacity: 0 } : false}
                          animate={{ x: 0, opacity: isVisible ? 1 : 0 }}
                          transition={isResizing ? instantTransition : blockTransition}
                          style={{
                            width: blockSize,
                            height: blockSize,
                            borderRadius: 0,
                            backgroundColor: "#0066FF",
                          }}
                        />
                      </motion.div>
                    );
                  } else {
                    return (
                      <motion.div
                        key={blockKey}
                        layout
                        initial={isNewRow ? { height: 0 } : false}
                        animate={{ height: blockSize }}
                        transition={isResizing ? instantTransition : blockTransition}
                        style={{
                          position: "absolute",
                          top: rowIndex * (blockSize + gap),
                          width: blockSize,
                          overflow: "hidden",
                        }}
                      >
                        <motion.div
                          initial={isNewRow ? { y: -(blockSize + gap), opacity: 0 } : false}
                          animate={{ y: 0, opacity: 1 }}
                          transition={isResizing ? instantTransition : blockTransition}
                          style={{
                            width: blockSize,
                            height: blockSize,
                            borderRadius: 0,
                            backgroundColor: "#0066FF",
                          }}
                        />
                      </motion.div>
                    );
                  }
                }

                // Original block
                if (!block) return null;
                const { isVisible } = row;

                return (
                  <motion.div
                    key={`${block.x}-${block.y}`}
                    layout
                    initial={{ height: 0, opacity: 0 }}
                    animate={{
                      height: isVisible ? blockSize : 0,
                      opacity: isVisible ? 1 : 0,
                    }}
                    transition={
                      isResizing
                        ? { layout: instantTransition, height: instantTransition, opacity: instantTransition }
                        : { layout: blockTransition, height: blockTransition, opacity: { duration: 0.2 } }
                    }
                    style={{
                      position: "absolute",
                      top: rowIndex * (blockSize + gap),
                      width: blockSize,
                      overflow: "hidden",
                    }}
                  >
                    <Block rounded={block.rounded} size={blockSize} />
                  </motion.div>
                );
              })}
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}
