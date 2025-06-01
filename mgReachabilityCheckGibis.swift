Algorithm: mgReachabilityCheckGibis
Autor: Matthias Gibis
Created: 01.06.2025
Copyright (c) 2025 Matthias Gibis

struct GridPos {
    let col: Int
    let row: Int
    
    init(col: Int, row: Int) {
        self.col = col
        self.row = row
    }

    static var mapSideSize: Int = 32 // square, but can be changed

    static var walkAbleTileCache = Array( 		// row | col
           repeating: Array(repeating: true,
           count: mapSideSize),
           count: mapSideSize
    )

    func mgReachabilityCheckGibis(target: GridPos) -> Bool {
        // Direction vectors for 4-way movement (right, down, left, up)
        let dxs = [0, 1, 0, -1]
        let dys = [1, 0, -1, 0]

        // 2D cache of walkable tiles (precomputed static data)
        let cache = GridPos.walkAbleTileCache

        // Extract target position (column and row)
        let targetCol = target.col, targetRow = target.row

        // Early exit if the target tile is not walkable
        if !cache[targetRow][targetCol] { return false }

        var currentRow = row, currentCol = col

        // Determine step direction on X and Y axes (−1, 0, or +1)
        let stepX = targetCol > currentCol ? 1 : (targetCol < currentCol ? -1 : 0)
        let stepY = targetRow > currentRow ? 1 : (targetRow < currentRow ? -1 : 0)

        // Alternative way to access cache quickly – slightly faster (by a few ns),
        // but less readable than "cache[currentRow][currentCol]"
        var fastCacheAccess: Bool {
            cache.withUnsafeBufferPointer({ $0[currentRow] })
                 .withUnsafeBufferPointer({ $0[currentCol] })
        }

        // Side length of the square map (used for bounds checking)
        let cacheCount = cache.count

        while true {
            // Move horizontally towards the target column while on walkable tiles
            while currentCol != targetCol, fastCacheAccess {
                currentCol += stepX
            }
            // If stepped onto a non-walkable tile, step back
            if !fastCacheAccess {
                currentCol -= stepX
            }
            
            // If aligned horizontally, move vertically towards the target row
            if currentCol == targetCol {
                while currentRow != targetRow, fastCacheAccess {
                    currentRow += stepY
                }
                // Step back if stepped onto a non-walkable tile
                if !fastCacheAccess {
                    currentRow -= stepY
                }
            }
            
            // If reached the target position, return true
            if currentCol == targetCol && currentRow == targetRow { return true }
            
            // Save current position as start for outline tracing
            let startX = currentCol, startY = currentRow
            
            // Helper to check if we've reached the other side (aligned with target)
            var reachedOtherSide: Bool {
                if currentRow == self.row {
                    // Moving horizontally: check if currentCol is between startX and targetCol
                    stepX == 1 ? (currentCol > startX && currentCol <= targetCol) : (currentCol < startX && currentCol >= targetCol)
                } else if currentCol == targetCol {
                    // Moving vertically: check if currentRow is between startY and targetRow
                    stepY == 1 ? (currentRow > startY && currentRow <= targetRow) : (currentRow < startY && currentRow >= targetRow)
                } else { false }
            }
            
            // Initialize direction for outline following:
            // 0=up,1=right,2=down,3=left
            var dir = targetCol != currentCol ? (stepX == 1 ? 0 : 2) : (stepY == 1 ? 3 : 1)
            var startDirValue = dir
            var outlineDir = 1 // direction increment (1 = clockwise)
            
            // Begin outline following loop to find a path around obstacles
            while true {
                dir = (dir + outlineDir) & 3 // rotate direction clockwise or counterclockwise
                currentCol += dxs[dir]
                currentRow += dys[dir]
                
                if !fastCacheAccess {
                    // If new position not walkable, backtrack and adjust direction
                    currentCol -= dxs[dir]
                    currentRow -= dys[dir]
                    
                    dir = (dir - outlineDir) & 3 // rotate direction back
                    
                    currentCol += dxs[dir] // move straight ahead
                    currentRow += dys[dir] //
                    
                    // Check for out-of-bounds and handle accordingly
                    if currentCol < 0 || currentRow < 0 || currentCol >= cacheCount || currentRow >= cacheCount {
                        if outlineDir == 3 { // Already tried both directions and went out of map a second time,
                        // so the start or target tile cannot be reached
                            return false
                        }

                        outlineDir = 3 // try counterclockwise direction
                        
                        currentCol = startX // reset position to start of outline trace
                        currentRow = startY //
                        
                        dir = (startDirValue + 2) & 3 // turn 180 degrees
                        startDirValue = dir
                        continue // Skip the rest of the loop to avoid further checks this iteration
                    } else if !fastCacheAccess {
                        // Still blocked, turn direction counterclockwise and continue
                        currentCol -= dxs[dir]
                        currentRow -= dys[dir]
                        dir = (dir - outlineDir) & 3 // -90° drehen
                    } else if reachedOtherSide {
                        // found a path around obstacle to target
                        break
                    }
                } else if reachedOtherSide {
                    // found a path around obstacle to target
                    break
                }
                
                // If returned to the start position and direction, we've looped in a circle,
                // meaning the start or target is trapped with no path available
                if currentCol == startX, currentRow == startY, dir == startDirValue {
                    return false
                }
            }
        }
    }
}








