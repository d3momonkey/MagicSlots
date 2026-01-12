# MagicSlots

**MagicSlots** is a prototype slot machine game designed for the Playdate handheld console. It features a classic 3-reel, 3-row layout with multiple paylines and interactive crank controls.

## Features

*   **Interactive Controls**: Use the Playdate's signature **Crank** to spin the reels!
*   **3x3 Grid**: Expanded view showing 3 rows of symbols across 3 reels.
*   **5 Paylines**: Win on horizontal lines (Top, Center, Bottom) and both diagonals.
*   **Advanced Scoring**:
    *   Multi-line win calculation.
    *   Partial payouts for Cherry symbols.
*   **Mock Leaderboard**: Simulation of submitting high scores to an online server.

## Controls

*   **Crank**: Spin the reels (rotate forward or backward).
*   **A Button**: 
    *   Stop the reels while spinning.
    *   Reset the game after a win.

## Scoring System

### Symbol Values (3-of-a-kind)
*   💎 **GEM**: 1000 Points (Jackpot)
*   7️⃣ **7**: 500 Points
*   🔔 **BELL**: 200 Points
*   ➖ **BAR**: 100 Points
*   🍒 **CHERRY**: 50 Points

### Special Rules
*   **Cherry Partial Wins** (Left-to-Right):
    *   **1 Cherry** (Reel 1): 5 Points
    *   **2 Cherries** (Reel 1 & 2): 20 Points

### Paylines
1.  **Center Horizontal**
2.  **Top Horizontal**
3.  **Bottom Horizontal**
4.  **Diagonal** (Top-Left to Bottom-Right)
5.  **Diagonal** (Bottom-Left to Top-Right)

## Building & Running

1.  Ensure you have the [Playdate SDK](https://play.date/dev/) installed.
2.  Open the project directory in your terminal.
3.  Compile using `pdc`:
    ```bash
    pdc Source MagicSlots.pdx
    ```
4.  Open `MagicSlots.pdx` in the Playdate Simulator.

## Credits

Developed as a prototype for the Playdate.
