# Block-Blast

Flutter-powered mini-game inspired by the popular puzzle concept **Block Blast**: a color-matching, grid-clearing challenge.

##  Overview

**Block-Blast** is a strategic block puzzle game built with Flutter. Players drag and drop various shaped blocks onto a grid, aiming to complete and clear rows or columns. The goal is to keep the board from filling up and survive as long as possible—because once you can’t place a piece, the game ends.

##  Features

- Intuitive **drag & drop** mechanics
- Fun **animations** and smooth **gameplay**
- Strategic block placement to create **combos**
- Dynamic **score system** with bonus multipliers
- Clean **UI layout**, responsive across devices

##  Inspiration

Block Blast is a free-to-play puzzle game with simple rules but deep strategy. It uses an 8×8 grid and gives three block shapes per turn that you must place wisely to clear lines and avoid game over.:contentReference[oaicite:1]{index=1}  
Clearing multiple lines at once results in higher scores and combo multipliers.:contentReference[oaicite:2]{index=2}

##  How to Play

1. Launch the app to view a fresh 8×8 grid.
2. Drag each block (available three at a time) to the grid.
3. **Complete rows or columns** to clear them and score points.
4. Try to create chain reactions and combos for big point boosts.
5. Plan ahead—blocks can’t be rotated, and placement is permanent.
6. Game ends when there’s no more valid move left.:contentReference[oaicite:3]{index=3}

##  Installation & Running

```bash
# Clone the project
git clone https://github.com/<your-username>/block-blast-flutter.git
cd block-blast-flutter

# Install dependencies
flutter pub get

# Run in debug mode on connected device or simulator
flutter run
