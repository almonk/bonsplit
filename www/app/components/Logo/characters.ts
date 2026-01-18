export type Corner = "tl" | "tr" | "bl" | "br";

export interface Block {
  x: number; // grid column (0-indexed)
  y: number; // grid row (0-indexed)
  rounded: Corner[]; // which corners are rounded
}

export interface Character {
  width: number; // grid width
  height: number; // grid height
  blocks: Block[];
}

// Character definitions
// Format for defining characters:
// Row N: [corners] [corners] ...
// Use [tl,tr,bl,br] for rounded corners, [ ] for no rounding, - for empty cell

export const characters: Record<string, Character> = {
  S: {
    width: 2,
    height: 4,
    blocks: [
      // Row 0: [tl] [tr,br]
      { x: 0, y: 0, rounded: ["tl"] },
      { x: 1, y: 0, rounded: ["tr", "br"] },
      // Row 1: [bl] [tr]
      { x: 0, y: 1, rounded: ["bl"] },
      { x: 1, y: 1, rounded: ["tr"] },
      // Row 2: [tl,tr] [ ]
      { x: 0, y: 2, rounded: ["tl", "tr"] },
      { x: 1, y: 2, rounded: [] },
      // Row 3: [bl] [br]
      { x: 0, y: 3, rounded: ["bl"] },
      { x: 1, y: 3, rounded: ["br"] },
    ],
  },
  p: {
    width: 3,
    height: 4,
    blocks: [
      // Row 0: - - -
      // Row 1: - [tl] [tr]
      { x: 1, y: 1, rounded: ["tl"] },
      { x: 2, y: 1, rounded: ["tr"] },
      // Row 2: [tl,bl] [ ] [br]
      { x: 0, y: 2, rounded: ["tl", "bl"] },
      { x: 1, y: 2, rounded: [] },
      { x: 2, y: 2, rounded: ["br"] },
      // Row 3: - [ ] -
      { x: 1, y: 3, rounded: [] },
    ],
  },
  l: {
    width: 1,
    height: 4,
    blocks: [
      // Row 0: [tl,tr]
      { x: 0, y: 0, rounded: ["tl", "tr"] },
      // Row 1: [ ]
      { x: 0, y: 1, rounded: [] },
      // Row 2: [ ]
      { x: 0, y: 2, rounded: [] },
      // Row 3: [ ]
      { x: 0, y: 3, rounded: [] },
    ],
  },
  i: {
    width: 1,
    height: 4,
    blocks: [
      // Row 0: circle (dot)
      { x: 0, y: 0, rounded: ["tl", "tr", "bl", "br"] },
      // Row 1: [tl,tr]
      { x: 0, y: 1, rounded: ["tl", "tr"] },
      // Row 2: [ ]
      { x: 0, y: 2, rounded: [] },
      // Row 3: [bl,br]
      { x: 0, y: 3, rounded: ["bl", "br"] },
    ],
  },
  t: {
    width: 2,
    height: 4,
    blocks: [
      // Row 0: [ ] -
      { x: 0, y: 0, rounded: [] },
      // Row 1: [ ] [tr,br]
      { x: 0, y: 1, rounded: [] },
      { x: 1, y: 1, rounded: ["tr", "br"] },
      // Row 2: [ ] -
      { x: 0, y: 2, rounded: [] },
      // Row 3: [ ] [tr,br]
      { x: 0, y: 3, rounded: [] },
      { x: 1, y: 3, rounded: ["tr", "br"] },
    ],
  },
  B: {
    width: 3,
    height: 4,
    blocks: [
      // Row 0: [tl] [ ] [tr]
      { x: 0, y: 0, rounded: [] },
      { x: 1, y: 0, rounded: [] },
      { x: 2, y: 0, rounded: ["tr"] },
      // Row 1: [ ] [tl] [br]
      { x: 0, y: 1, rounded: [] },
      { x: 1, y: 1, rounded: ["tl"] },
      { x: 2, y: 1, rounded: ["br"] },
      // Row 2: [ ] [bl] [tr]
      { x: 0, y: 2, rounded: [] },
      { x: 1, y: 2, rounded: ["bl"] },
      { x: 2, y: 2, rounded: ["tr"] },
      // Row 3: [bl] [ ] [br]
      { x: 0, y: 3, rounded: [] },
      { x: 1, y: 3, rounded: [] },
      { x: 2, y: 3, rounded: ["br"] },
    ],
  },
  o: {
    width: 2,
    height: 4,
    blocks: [
      // Row 0: - - (blank)
      // Row 1: [tl] [tr]
      { x: 0, y: 1, rounded: ["tl"] },
      { x: 1, y: 1, rounded: ["tr"] },
      // Row 2: [ ] [ ]
      { x: 0, y: 2, rounded: [] },
      { x: 1, y: 2, rounded: [] },
      // Row 3: [bl] [br]
      { x: 0, y: 3, rounded: ["bl"] },
      { x: 1, y: 3, rounded: ["br"] },
    ],
  },
  n: {
    width: 3,
    height: 4,
    blocks: [
      // Row 0: - - (blank)
      // Row 1: [tl] [tr]
      { x: 0, y: 1, rounded: ["tl"] },
      { x: 1, y: 1, rounded: ["tr"] },
      // Row 2: [ ] [ ]
      { x: 0, y: 2, rounded: [] },
      { x: 1, y: 2, rounded: [] },
      // Row 3: [ ] [ ]
      { x: 0, y: 3, rounded: [] },
      { x: 1, y: 3, rounded: ["bl"] },
      { x: 2, y: 3, rounded: ["tr", "br"] },
    ],
  },
};
