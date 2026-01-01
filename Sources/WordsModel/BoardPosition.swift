import Foundation

public struct BoardPosition: Hashable, Codable, Sendable {
    public let row: Int
    public let column: Int
    
    public init(
        row: Int,
        column: Int
    ) {
        self.row = row
        self.column = column
    }
}

extension [[TileID?]] {
    /// Safely accesses `[row][column]`
    public subscript(position: BoardPosition) -> TileID? {
        guard position.row < count,
              position.column < self[position.row].count
        else {
            return nil
        }
        return [position.row][position.column]
    }
}
