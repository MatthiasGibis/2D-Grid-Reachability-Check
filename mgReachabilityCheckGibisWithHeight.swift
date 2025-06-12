struct GridPos {
    let col: Int
    let row: Int
    
    init(col: Int, row: Int) {
        self.col = col
        self.row = row
    }

    static var mapSideSize: Int = 32 // square, but can be changed
    static let maxHeightDifference: Int16 = 60

    /// 2D height map cache – stores height values for each tile
    /// Access: heightCostCache[row][col]
    static var heightCostCache = Array(           // row | col
        repeating: Array(repeating: Int16.zero,
        count: mapSideSize),
        count: mapSideSize
    )

    /// Checks if there's a walkable path from this position to the target,
    /// accounting for height differences between tiles
    func mgReachabilityCheckGibisWithHeight(target: GridPos) -> Bool {
        // Direction vectors for 4-way movement (right, down, left, up)
        let dxs = [0, 1, 0, -1]
        let dys = [1, 0, -1, 0]

        // 2D cache of walkable tiles (precomputed static data)
        let cache = GridPos.heightCostCache
        let maxHeightDifference = GridPos.maxHeightDifference

        // Extract target position (column and row)
        let targetCol = target.col, targetRow = target.row

        // Early exit if start or target tile is marked as blocked.
        // Int16.max is used as a "blocked" marker – i.e., no valid height value.
        // This typically represents terrain that cannot be traversed at all,
        // such as water, trees, buildings, or impassable map boundaries.
        if cache[targetRow][targetCol] == Int16.max || cache[self.row][self.col] == Int16.max { return false }
      
        var currentRow = self.row, currentCol = self.col
        
        // Determine step direction on X and Y axes (−1, 0, or +1)
        let stepX = targetCol > currentCol ? 1 : (targetCol < currentCol ? -1 : 0)
        let stepY = targetRow > currentRow ? 1 : (targetRow < currentRow ? -1 : 0)

        // Alternative way to access cache quickly – slightly faster (by a few ns),
        // but less readable than "cache[currentRow][currentCol]"
        var fastCacheAccess: Int16 {
            cache.withUnsafeBufferPointer({ $0[currentRow] })
                 .withUnsafeBufferPointer({ $0[currentCol] })
        }

        // Side length of the square map (used for bounds checking)
        let cacheCount = cache.count

        while true {
            var currentHeight = fastCacheAccess
            
            // Move horizontally towards the target column while on walkable tiles
            while currentCol != targetCol {
                currentHeight = fastCacheAccess
                currentCol += stepX
                if abs(fastCacheAccess - currentHeight) > maxHeightDifference {
                    currentCol -= stepX // Undo move if height difference too high
                    break
                }
            }

            // If aligned horizontally, move vertically towards the target row
            if currentCol == targetCol {
                while currentRow != targetRow {
                    currentHeight = fastCacheAccess
                    currentRow += stepY
                    if abs(fastCacheAccess - currentHeight) > maxHeightDifference {
                        currentRow -= stepY // Undo move if height difference too high
                        break
                    }
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
                
                if abs(fastCacheAccess - currentHeight) > maxHeightDifference {
                    // If new position not walkable, backtrack and adjust direction
                    currentCol -= dxs[dir]
                    currentRow -= dys[dir]
                    currentHeight = fastCacheAccess
                    
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
                    } else if abs(fastCacheAccess - currentHeight) > maxHeightDifference {
                        // Still blocked, turn direction counterclockwise and continue
                        currentCol -= dxs[dir]
                        currentRow -= dys[dir]
                        dir = (dir - outlineDir) & 3 // -90°
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
