# 2D-Grid-Reachability-Check

# mgReachabilityCheckGibis

A reachability algorithm in Swift for 2D grids.

## Description

This algorithm provides a simple and efficient method to check whether a target position is reachable from a start position on a 2D grid.

**Important:**  
This algorithm **does not compute a path**, it only returns a Boolean indicating whether the target is reachable or not.

### Memory Efficiency

The algorithm is highly optimized for memory usage, requiring only **21 integers of memory** in its basic (flat terrain) form,  
and **21 integers** in the height-aware version that checks elevation differences.

In both cases, it uses **constant memory space (O(1))**, regardless of the grid size.

This minimal memory footprint makes it ideal for performance-critical applications or environments with limited resources.

## Performance

On a 128x128 grid, the average runtime is in the **low triple-digit nanosecond range** per reachability check.  
Measured peak times are around **5,000 nanoseconds (5 microseconds)**.

Importantly, the grid size itself does **not** significantly affect performance.  
What matters most is the distance between start and target and the layout of obstacles.  
Thus, even on grids as large as 2^60 x 2^60, similar performance speeds could theoretically be achieved.

## How It Works

1. The algorithm attempts a straight-line traversal from start to target, moving tile by tile.
2. At each step, it checks if the height difference is within allowed limits.
3. If it encounters an obstacle (e.g., impassable terrain or steep height change), it enters "outline tracing" mode:
    - It follows the boundary of the obstacle (clockwise or counterclockwise) until it can resume straight-line movement.
4. If the target is reached, the function returns `true`; if tracing loops back to its start, it returns `false`.

## Theoretical Significance
This algorithm is believed to be the first known **constant space** solution to the classical grid reachability problem with obstacles.

Unlike flood fill, BFS, DFS or A* variants, which require O(n) space (relative to grid or path size), mgReachabilityCheckGibis uses a fixed, constant memory model, regardless of grid dimensions or path complexity.

This may represent a milestone in the study of deterministic, memory-constrained navigation algorithms.

## Benchmarking

You can benchmark the performance of this algorithm using the iOS app **mgSearch**,  
which includes tools to test and measure reachability checks on various grid scenarios.

## Usage

Implemented as the method `mgReachabilityCheckGibis(target:)` inside the `GridPos` struct.

### Example

```swift
let start = GridPos(col: 0, row: 0)
let target = GridPos(col: 5, row: 5)
let reachable = start.mgReachabilityCheckGibis(target: target)
print("Reachable? \(reachable)")
