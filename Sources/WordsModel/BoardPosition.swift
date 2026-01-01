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
    public subscript(position: BoardPosition) -> TileID? {
        [position.row][position.column]
    }
}
