import Foundation

public struct TilePlacement: Equatable, Codable, Sendable {
    public let tileID: TileID
    public let position: BoardPosition
    /// For blank tiles, specify what letter it represents (required for blanks, must be nil for regular tiles)
    public let blankLetterUsedAs: Tile.Letter?
    
    public enum CodingKeys: String, CodingKey {
        case tileID = "tileId"
        case position
        case blankLetterUsedAs
    }
    
    /// - Parameters:
    ///   - tileID: The ID of the tile to place
    ///   - position: The board position where to place the tile
    ///   - letter: For blank tiles, specify the letter it represents (e.g., `.a`, `.e`). Must be `nil` for regular tiles.
    ///
    /// Example usage:
    /// ```swift
    /// // Regular tile
    /// WordPlacement(tileID: tileID, position: position)
    ///
    /// // Blank tile representing 'A'
    /// WordPlacement(tileID: blankTileID, position: position, letter: .a)
    /// ```
    public init(
        tileID: TileID,
        position: BoardPosition,
        blankLetterUsedAs: Tile.Letter? = nil
    ) {
        self.tileID = tileID
        self.position = position
        self.blankLetterUsedAs = blankLetterUsedAs
    }
}

public struct PlaceWordForm: Equatable, Codable, Sendable {
    public let placements: [TilePlacement]
    
    public init(placements: [TilePlacement]) {
        self.placements = placements
    }
}

